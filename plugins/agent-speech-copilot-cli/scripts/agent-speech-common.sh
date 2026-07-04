#!/usr/bin/env bash
set -euo pipefail

DEFAULT_ENABLED="true"
DEFAULT_VOICE=""
DEFAULT_RATE="220"
DEFAULT_VOLUME=""
DEFAULT_LANGUAGE="en"
DEFAULT_MAX_CHARS="240"

PLUGIN_DATA_DIR="${COPILOT_PLUGIN_DATA:-${HOME}/.copilot/plugin-data/agent-speech-copilot-cli}"
CONFIG_FILE="${PLUGIN_DATA_DIR}/config.env"

CFG_ENABLED="$DEFAULT_ENABLED"
CFG_VOICE="$DEFAULT_VOICE"
CFG_RATE="$DEFAULT_RATE"
CFG_VOLUME="$DEFAULT_VOLUME"
CFG_LANGUAGE="$DEFAULT_LANGUAGE"
CFG_MAX_CHARS="$DEFAULT_MAX_CHARS"

ensure_data_dir() {
  mkdir -p "$PLUGIN_DATA_DIR"
}

default_voice_for_language() {
  case "$1" in
    en) echo "Samantha" ;;
    ko) echo "Yuna" ;;
    ja) echo "Kyoko" ;;
    zh-CN) echo "Tingting" ;;
    es) echo "Monica" ;;
    fr) echo "Thomas" ;;
    de) echo "Anna" ;;
    it) echo "Alice" ;;
    *) echo "" ;;
  esac
}

is_supported_language() {
  case "$1" in
    en|ko|ja|zh-CN|es|fr|de|it) return 0 ;;
    *) return 1 ;;
  esac
}

normalize_boolean() {
  local value="${1:-}"
  local lower
  lower="$(printf "%s" "$value" | tr '[:upper:]' '[:lower:]')"
  case "$lower" in
    true|1|yes|on) echo "true" ;;
    false|0|no|off) echo "false" ;;
    *) echo "" ;;
  esac
}

load_config() {
  CFG_ENABLED="$DEFAULT_ENABLED"
  CFG_VOICE="$DEFAULT_VOICE"
  CFG_RATE="$DEFAULT_RATE"
  CFG_VOLUME="$DEFAULT_VOLUME"
  CFG_LANGUAGE="$DEFAULT_LANGUAGE"
  CFG_MAX_CHARS="$DEFAULT_MAX_CHARS"

  if [[ ! -f "$CONFIG_FILE" ]]; then
    return 0
  fi

  while IFS='=' read -r key value; do
    case "$key" in
      ENABLED) CFG_ENABLED="$value" ;;
      VOICE) CFG_VOICE="$value" ;;
      RATE) CFG_RATE="$value" ;;
      VOLUME) CFG_VOLUME="$value" ;;
      LANGUAGE) CFG_LANGUAGE="$value" ;;
      MAX_CHARS) CFG_MAX_CHARS="$value" ;;
    esac
  done < "$CONFIG_FILE"

  local normalized
  normalized="$(normalize_boolean "$CFG_ENABLED")"
  CFG_ENABLED="${normalized:-$DEFAULT_ENABLED}"

  if ! [[ "$CFG_RATE" =~ ^[0-9]+$ ]]; then
    CFG_RATE="$DEFAULT_RATE"
  fi
  if ! [[ "$CFG_MAX_CHARS" =~ ^[0-9]+$ ]]; then
    CFG_MAX_CHARS="$DEFAULT_MAX_CHARS"
  fi
  if [[ -n "$CFG_VOLUME" ]] && ! [[ "$CFG_VOLUME" =~ ^[0-9]+$ ]]; then
    CFG_VOLUME="$DEFAULT_VOLUME"
  fi
  if ! is_supported_language "$CFG_LANGUAGE"; then
    CFG_LANGUAGE="$DEFAULT_LANGUAGE"
  fi
}

save_config() {
  ensure_data_dir
  cat > "$CONFIG_FILE" <<EOF
ENABLED=$CFG_ENABLED
VOICE=$CFG_VOICE
RATE=$CFG_RATE
VOLUME=$CFG_VOLUME
LANGUAGE=$CFG_LANGUAGE
MAX_CHARS=$CFG_MAX_CHARS
EOF
}

effective_enabled() {
  if [[ -n "${AGENT_SPEECH_ENABLED:-}" ]]; then
    local normalized
    normalized="$(normalize_boolean "${AGENT_SPEECH_ENABLED}")"
    if [[ -n "$normalized" ]]; then
      echo "$normalized"
      return 0
    fi
  fi
  echo "$CFG_ENABLED"
}

effective_voice() {
  if [[ -n "${AGENT_SPEECH_VOICE:-}" ]]; then
    echo "${AGENT_SPEECH_VOICE}"
    return 0
  fi
  if [[ -n "$CFG_VOICE" ]]; then
    echo "$CFG_VOICE"
    return 0
  fi
  default_voice_for_language "$CFG_LANGUAGE"
}

effective_rate() {
  if [[ -n "${AGENT_SPEECH_RATE:-}" ]]; then
    echo "${AGENT_SPEECH_RATE}"
    return 0
  fi
  echo "$CFG_RATE"
}

effective_max_chars() {
  if [[ -n "${AGENT_SPEECH_MAX_CHARS:-}" ]]; then
    echo "${AGENT_SPEECH_MAX_CHARS}"
    return 0
  fi
  echo "$CFG_MAX_CHARS"
}

effective_volume() {
  echo "$CFG_VOLUME"
}

is_valid_voice() {
  local voice="$1"
  /usr/bin/say -v ? | awk '{print $1}' | grep -Fxq "$voice"
}

apply_volume_if_set() {
  local volume="$1"
  if [[ -n "$volume" ]] && [[ "$volume" =~ ^[0-9]+$ ]] && (( volume >= 0 && volume <= 100 )); then
    osascript -e "set volume output volume ${volume}" >/dev/null 2>&1 || true
  fi
}

sanitize_text() {
  printf "%s" "$1" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//'
}

speak_text() {
  local text="$1"
  if ! command -v say >/dev/null 2>&1; then
    return 0
  fi

  load_config

  local enabled
  enabled="$(effective_enabled)"
  if [[ "$enabled" != "true" ]]; then
    return 0
  fi

  text="$(sanitize_text "$text")"
  if [[ -z "${text// }" ]]; then
    text="Copilot has finished responding."
  fi

  local max_chars
  max_chars="$(effective_max_chars)"
  if [[ "$max_chars" =~ ^[0-9]+$ ]] && (( ${#text} > max_chars )); then
    text="${text:0:max_chars}..."
  fi

  local voice rate volume
  voice="$(effective_voice)"
  rate="$(effective_rate)"
  volume="$(effective_volume)"
  apply_volume_if_set "$volume"

  local -a say_args=()
  if [[ -n "$voice" ]] && is_valid_voice "$voice"; then
    say_args+=(-v "$voice")
  fi
  if [[ "$rate" =~ ^[0-9]+$ ]]; then
    say_args+=(-r "$rate")
  fi

  /usr/bin/say "${say_args[@]}" "$text"
}
