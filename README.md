# agent-speech-copilot-cli

A macOS TTS (voice notification) plugin for GitHub Copilot CLI.

## Installation

```bash
copilot plugin marketplace add https://github.com/welico/agent-speech-copilot-cli
copilot plugin install agent-speech-copilot-cli@welico
```

> Copilot CLI accepts only one source in `marketplace add`, and `plugin install` requires the `plugin@marketplace` format.

## Behavior

- On the `agentStop` hook, it plays a voice notification with macOS `say` when a response is complete.
- Default message: `Copilot has finished responding.`

## Environment Variables

- `AGENT_SPEECH_ENABLED=false` : Disable speech
- `AGENT_SPEECH_VOICE=Yuna` : Select voice (see `say -v ?`)
- `AGENT_SPEECH_RATE=220` : Speaking rate
- `AGENT_SPEECH_MAX_CHARS=240` : Maximum number of characters to read