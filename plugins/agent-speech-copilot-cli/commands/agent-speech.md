---
name: agent-speech
description: Manage agent speech settings and playback (`status`, `speak`, `enable`, `disable`, `toggle`, `reset`, `set-voice`, `set-rate`, `set-volume`, `set-language`, `list-voices`).
argument-hint: status | speak <text> | enable | disable | toggle | reset | set-voice <name> | set-rate <50-400> | set-volume <0-100> | set-language <en|ko|ja|zh-CN|es|fr|de|it> | list-voices
allowed-tools:
  - Bash
---

Use the plugin command script to manage settings and speech output.

- If no arguments are provided, run:
  `bash -lc '"${PLUGIN_ROOT}/scripts/agent-speech.sh" status'`
- If arguments are provided, pass them to the script exactly:
  `bash -lc '"${PLUGIN_ROOT}/scripts/agent-speech.sh" $ARGUMENTS'`

Return the script output directly.
