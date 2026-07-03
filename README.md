# agent-speech-copilot-cli

GitHub Copilot CLI용 macOS TTS(음성 알림) 플러그인입니다.

## 설치

```bash
copilot plugin marketplace add https://github.com/welico/agent-speech-copilot-cli
copilot plugin install agent-speech-copilot-cli@welico
```

> Copilot CLI는 `marketplace add`에 source 1개만 받고, `plugin install`은 `plugin@marketplace` 형식을 요구합니다.

## 동작

- `agentStop` 훅에서 응답 완료 시 macOS `say`로 음성 알림을 재생합니다.
- 기본 멘트: `Copilot 응답이 완료되었습니다.`

## 환경 변수

- `AGENT_SPEECH_ENABLED=false` : 음성 비활성화
- `AGENT_SPEECH_VOICE=Yuna` : 음성 선택 (`say -v ?` 참고)
- `AGENT_SPEECH_RATE=220` : 읽기 속도
- `AGENT_SPEECH_MAX_CHARS=240` : 읽을 최대 글자 수