#!/usr/bin/env bash
set -euo pipefail

if [[ "${AGENT_SPEECH_ENABLED:-true}" == "false" ]]; then
  exit 0
fi

if ! command -v say >/dev/null 2>&1; then
  exit 0
fi

payload="$(cat || true)"
max_chars="${AGENT_SPEECH_MAX_CHARS:-240}"

text="$(
  printf "%s" "$payload" | python3 -c '
import json
import re
import sys

raw = sys.stdin.read().strip()
fallback = "Copilot has finished responding."
if not raw:
    print(fallback)
    raise SystemExit(0)

try:
    data = json.loads(raw)
except Exception:
    print(fallback)
    raise SystemExit(0)

def pick(obj):
    if isinstance(obj, str):
        s = obj.strip()
        return s if s else None
    if isinstance(obj, list):
        for item in obj:
            found = pick(item)
            if found:
                return found
        return None
    if isinstance(obj, dict):
        for key in ("message", "assistant_response", "assistantResponse", "text", "output"):
            if key in obj:
                found = pick(obj[key])
                if found:
                    return found
        for value in obj.values():
            found = pick(value)
            if found:
                return found
    return None

result = pick(data) or fallback
result = re.sub(r"\s+", " ", result).strip()
print(result or fallback)
'
)"

if [[ -z "${text// }" ]]; then
  text="Copilot has finished responding."
fi

if [[ "$max_chars" =~ ^[0-9]+$ ]] && (( ${#text} > max_chars )); then
  text="${text:0:max_chars}..."
fi

say_args=()
if [[ -n "${AGENT_SPEECH_VOICE:-}" ]]; then
  say_args+=(-v "${AGENT_SPEECH_VOICE}")
fi
if [[ -n "${AGENT_SPEECH_RATE:-}" ]]; then
  say_args+=(-r "${AGENT_SPEECH_RATE}")
fi

/usr/bin/say "${say_args[@]}" "$text"
