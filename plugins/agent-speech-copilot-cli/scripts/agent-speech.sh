#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/agent-speech-common.sh"

print_usage() {
  cat <<'EOF'
Usage:
  /agent-speech status
  /agent-speech speak <text>
  /agent-speech enable
  /agent-speech disable
  /agent-speech toggle
  /agent-speech reset
  /agent-speech set-voice <name>
  /agent-speech set-rate <50-400>
  /agent-speech set-volume <0-100>
  /agent-speech set-language <en|ko|ja|zh-CN|es|fr|de|it>
  /agent-speech list-voices
EOF
}

cmd="${1:-status}"
shift || true

load_config

case "$cmd" in
  status)
    effective_enabled_value="$(effective_enabled)"
    effective_voice_value="$(effective_voice)"
    effective_rate_value="$(effective_rate)"
    effective_volume_value="$(effective_volume)"
    effective_max_chars_value="$(effective_max_chars)"
    cat <<EOF
agent-speech status
enabled: ${effective_enabled_value}
voice: ${effective_voice_value:-<system-default>}
rate: ${effective_rate_value}
volume: ${effective_volume_value:-<unchanged>}
language: ${CFG_LANGUAGE}
max_chars: ${effective_max_chars_value}
config_file: ${CONFIG_FILE}
EOF
    ;;

  speak)
    if [[ $# -lt 1 ]]; then
      echo "Error: missing text." >&2
      print_usage >&2
      exit 1
    fi
    text="$*"
    speak_text "$text"
    echo "Spoken: $text"
    ;;

  enable)
    CFG_ENABLED="true"
    save_config
    echo "Speech output enabled."
    ;;

  disable)
    CFG_ENABLED="false"
    save_config
    echo "Speech output disabled."
    ;;

  toggle)
    if [[ "$CFG_ENABLED" == "true" ]]; then
      CFG_ENABLED="false"
      message="Speech output disabled."
    else
      CFG_ENABLED="true"
      message="Speech output enabled."
    fi
    save_config
    echo "$message"
    ;;

  reset)
    CFG_ENABLED="$DEFAULT_ENABLED"
    CFG_VOICE="$DEFAULT_VOICE"
    CFG_RATE="$DEFAULT_RATE"
    CFG_VOLUME="$DEFAULT_VOLUME"
    CFG_LANGUAGE="$DEFAULT_LANGUAGE"
    CFG_MAX_CHARS="$DEFAULT_MAX_CHARS"
    save_config
    echo "Speech settings reset to defaults."
    ;;

  set-voice)
    if [[ $# -ne 1 ]]; then
      echo "Error: set-voice requires a voice name." >&2
      print_usage >&2
      exit 1
    fi
    voice="$1"
    if ! is_valid_voice "$voice"; then
      echo "Error: voice \"$voice\" is not installed. Use /agent-speech list-voices." >&2
      exit 1
    fi
    CFG_VOICE="$voice"
    save_config
    echo "Voice set to: $voice"
    ;;

  set-rate)
    if [[ $# -ne 1 ]]; then
      echo "Error: set-rate requires one numeric value." >&2
      print_usage >&2
      exit 1
    fi
    rate="$1"
    if ! [[ "$rate" =~ ^[0-9]+$ ]] || (( rate < 50 || rate > 400 )); then
      echo "Error: rate must be an integer between 50 and 400." >&2
      exit 1
    fi
    CFG_RATE="$rate"
    save_config
    echo "Rate set to: $rate"
    ;;

  set-volume)
    if [[ $# -ne 1 ]]; then
      echo "Error: set-volume requires one numeric value." >&2
      print_usage >&2
      exit 1
    fi
    volume="$1"
    if ! [[ "$volume" =~ ^[0-9]+$ ]] || (( volume < 0 || volume > 100 )); then
      echo "Error: volume must be an integer between 0 and 100." >&2
      exit 1
    fi
    CFG_VOLUME="$volume"
    save_config
    apply_volume_if_set "$volume"
    echo "Volume set to: $volume"
    ;;

  set-language)
    if [[ $# -ne 1 ]]; then
      echo "Error: set-language requires one language code." >&2
      print_usage >&2
      exit 1
    fi
    language="$1"
    if ! is_supported_language "$language"; then
      echo "Error: unsupported language \"$language\". Supported: en, ko, ja, zh-CN, es, fr, de, it." >&2
      exit 1
    fi
    CFG_LANGUAGE="$language"
    save_config
    echo "Language set to: $language"
    ;;

  list-voices)
    /usr/bin/say -v ?
    ;;

  *)
    echo "Error: unknown command \"$cmd\"." >&2
    print_usage >&2
    exit 1
    ;;
esac
