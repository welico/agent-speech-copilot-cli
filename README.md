# agent-speech-copilot-cli

A macOS TTS (voice notification) plugin for GitHub Copilot CLI.

## Installation

```bash
# Clean up old plugin name (if present)
copilot plugin uninstall agent-speech@welico || true

# Register (or re-register) marketplace
copilot plugin marketplace remove welico --force || true
copilot plugin marketplace add https://github.com/welico/agent-speech-copilot-cli
copilot plugin marketplace browse welico

# Install from marketplace
copilot plugin install agent-speech-copilot-cli@welico
```

> Copilot CLI accepts only one source in `marketplace add`, and `plugin install` requires the `plugin@marketplace` format.

## Troubleshooting

- `Marketplace "welico" already registered`
  - This is expected on re-install. Run:
    ```bash
    copilot plugin marketplace update welico
    ```
- `[fetchManagedSettings] ... TimeoutError`
  - Usually a transient network/auth issue. Retry:
    ```bash
    copilot auth status
    copilot plugin marketplace update welico
    copilot plugin install agent-speech-copilot-cli@welico
    ```
  - Temporary fallback (if marketplace install keeps timing out):
    ```bash
    copilot plugin install welico/agent-speech-copilot-cli:plugins/agent-speech-copilot-cli
    ```
- `Plugin "agent-speech-copilot-cli" not found in marketplace "welico". Available plugins: agent-speech`
  - Your local `welico` marketplace is pointing to an older/different catalog. Re-register it:
    ```bash
    copilot plugin uninstall agent-speech@welico || true
    copilot plugin marketplace remove welico --force
    copilot plugin marketplace add https://github.com/welico/agent-speech-copilot-cli
    copilot plugin marketplace browse welico
    ```
- `Cannot remove marketplace "welico"... Installed plugins from this marketplace: agent-speech`
  - Remove the old plugin first, or force-remove the marketplace:
    ```bash
    copilot plugin uninstall agent-speech@welico || true
    copilot plugin marketplace remove welico --force
    ```

## Behavior

- On the `agentStop` hook, it plays a voice notification with macOS `say` when a response is complete.
- It prioritizes sentence-like final response text and skips numeric-only tokens/IDs.
- Default message: `Copilot has finished responding.`
- Persistent settings are stored per-plugin in `${COPILOT_PLUGIN_DATA}/config.env`.

## Slash Command

After installing/updating the plugin, restart Copilot CLI and use:

- `/agent-speech status`
- `/agent-speech speak <text>`
- `/agent-speech enable`
- `/agent-speech disable`
- `/agent-speech toggle`
- `/agent-speech reset`
- `/agent-speech set-voice <name>`
- `/agent-speech set-rate <50-400>`
- `/agent-speech set-volume <0-100>`
- `/agent-speech set-language <en|ko|ja|zh-CN|es|fr|de|it>`
- `/agent-speech list-voices`

## Environment Variables

- `AGENT_SPEECH_ENABLED=false` : Disable speech
- `AGENT_SPEECH_VOICE=Yuna` : Select voice (see `say -v ?`)
- `AGENT_SPEECH_RATE=220` : Speaking rate
- `AGENT_SPEECH_MAX_CHARS=240` : Maximum number of characters to read

`AGENT_SPEECH_ENABLED`, `AGENT_SPEECH_VOICE`, `AGENT_SPEECH_RATE`, and `AGENT_SPEECH_MAX_CHARS` override slash-command settings when set.