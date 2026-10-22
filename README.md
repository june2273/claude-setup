# claude-setup

AI 코딩 에이전트(Claude Code)를 **규칙 · 도구 · 검증 루프**로 통제하는 개인 하네스입니다.

플러그인 목록보다 **무엇을 고르고 무엇을 뺐는지, 그 근거**가 이 레포의 핵심입니다. 결정 기록은 [docs/decisions.md](docs/decisions.md)에 있습니다.

## 왜 만들었나

코딩 에이전트는 몇 가지 실수를 반복합니다. 과잉 설계, 범위 밖 수정, 오래된 API 사용, 검증 없는 "완료", 그리고 비밀값 커밋입니다.

도구를 늘리는 대신 **층마다 한 가지 낭비를 줄이도록** 구성했습니다. 규칙(제안)만으로 부족한 곳에는 훅(보장)을 짝지었습니다.

## 구조

| 층 | 바꾸는 것 | 구성 | 로드 방식 |
|---|---|---|---|
| 작업 원칙 | 생각 먼저 · 필요한 곳만 수정 · 검증 | [Karpathy Skills](https://github.com/forrestchang/andrej-karpathy-skills) | 스킬, 필요할 때만 |
| 프롬프팅 기본기 | 끝까지 수행 · 범위 통제 | [oh-my-fable](https://github.com/Junhan2/oh-my-fable) | SessionStart hook |
| 코드 양 | YAGNI · 표준 라이브러리 우선 · 추상화 금지 | [Ponytail](https://github.com/DietrichGebert/ponytail) | hook, 서브에이전트 포함 |
| 출력 | 응답 압축 | [caveman](https://github.com/JuliusBrussee/caveman) | **기본 off**, `/caveman`으로 켬 |
| 지식 | 최신 라이브러리 문서 | [Context7](https://github.com/upstash/context7) | MCP, 호출할 때만 |
| 구조 파악 | 코드베이스 지식 그래프 | [graphify](https://github.com/safishamsi/graphify) | 스킬 + 저장소별 결과물 |
| 전역 규칙 | 산출물 저장 위치 · 비밀값 처리 · README 형식 | [global/CLAUDE.md](global/CLAUDE.md) | 항상 |
| **보장** | 비밀값 커밋 차단 | [hooks/pre-commit](hooks/pre-commit) · [hooks/gitignore_global](hooks/gitignore_global) | git 전역 훅 |
| **보장** | 훅 우회 차단 + 커밋마다 검사 | [hooks/git-commit-guard.sh](hooks/git-commit-guard.sh) | Claude Code PreToolUse 훅 |

서드파티 플러그인은 코드를 복사하지 않고 마켓플레이스로 참조합니다. 각 플러그인의 라이선스는 해당 저장소를 따릅니다.

## 레포 구성

```
claude-setup/
├── global/CLAUDE.md         # 전역 규칙 사본 (~/.claude/CLAUDE.md용, 이 레포의 지시문 아님)
├── settings.example.json    # 플러그인 · 마켓플레이스
├── config/caveman.json      # caveman 기본 off
├── hooks/
│   ├── pre-commit           # 전역 시크릿 차단 훅 (값은 가려서 출력)
│   ├── git-commit-guard.sh  # Claude Code 가드: 훅 우회 차단 + 커밋마다 검사
│   └── gitignore_global     # 비밀값 파일 무시 목록
├── scripts/install.sh       # 위 구성 설치 (기존 설정은 덮어쓰지 않음)
├── tests/test-pre-commit.sh # 훅 회귀 테스트
└── docs/decisions.md        # 설계 결정 기록 D1–D7
```

## 설치

```bash
./scripts/install.sh
```

필요한 것: Claude Code, Node.js, [uv](https://github.com/astral-sh/uv)(graphify용).

`global/CLAUDE.md`는 자동으로 덮어쓰지 않습니다. 필요한 절만 `~/.claude/CLAUDE.md`에 복사하세요.

## 검증

```bash
./tests/test-pre-commit.sh   # 통과 11 / 실패 0
```

## 측정

**아직 측정값이 없습니다.** 각 플러그인이 주장하는 절감 수치는 여기에 옮기지 않았습니다. 이 환경에서 직접 측정한 값만 추가할 예정입니다.

측정 수단:
- Ponytail 작업 장부 (`~/.config/ponytail/band/`)
- `/caveman-stats`
- 같은 과제를 도구를 켜고 끈 상태로 수행해 비교

## 사용 예

- 기존 저장소 정리: `/ponytail-audit` → 항목을 골라 적용 → `/ponytail-review`
- 새 저장소 파악: `/graphify .`
- 긴 구현 세션: `/caveman` 켜기 → 끝나면 `/caveman off`
