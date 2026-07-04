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

def normalize_text(s):
    return re.sub(r"\s+", " ", s).strip()

def is_sentence_like(s):
    s = normalize_text(s)
    if not s:
        return False
    # Skip pure numbers, punctuation-heavy IDs, and similar non-sentence tokens.
    if re.fullmatch(r"[\d\s,.:;+\-_/\\|()[\]{}#@]+", s):
        return False
    if re.fullmatch(r"[0-9a-fA-F-]{8,}", s):
        return False
    # Require at least one letter-like character.
    if not re.search(r"[^\W\d_]", s, flags=re.UNICODE):
        return False
    return True

def pick(obj):
    if isinstance(obj, str):
        s = normalize_text(obj)
        return s if is_sentence_like(s) else None
    if isinstance(obj, list):
        # Prefer the latest content from streaming/event arrays.
        for item in reversed(obj):
            found = pick(item)
            if found:
                return found
        return None
    if isinstance(obj, dict):
        for key in (
            "final",
            "final_message",
            "message",
            "assistant_response",
            "assistantResponse",
            "content",
            "text",
            "output",
            "response",
        ):
            if key in obj:
                found = pick(obj[key])
                if found:
                    return found
        # Fall back to scanning values, preferring newer-looking fields first.
        for value in reversed(list(obj.values())):
            found = pick(value)
            if found:
                return found
    return None

result = pick(data) or fallback
result = normalize_text(result)
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
