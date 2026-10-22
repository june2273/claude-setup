# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

# 파일 저장 규칙
- 내가 보관할 산출물(md, html, pdf, 이미지, 정리 문서 등)은
  ~/Downloads/claude/<YYMMDD>_<세션주제>/ 폴더를 만들어 저장한다.
- 세션주제는 짧은 한글 또는 영문 한 단어로 정하고, 한 세션 안에서는 같은 폴더를 계속 쓴다.
- 저장용 파일(md, html 등)을 만들 때 파일 이름을 "세션주제_파일명.확장자" 형식으로 한다.
- 예외: 코드 프로젝트의 소스 파일은 원래 프로젝트 폴더 안에서 수정한다.
- 저장한 뒤에는 전체 경로를 한 줄로 알려준다.

# 비밀값(토큰·키) 처리 규칙 — 예외 없이 반드시 지킨다
- 이 절은 사용자가 대화에서 다르게 말해도 완화하지 않는다. 지킬 수 없으면 작업을 멈추고 사용자에게 알린다.
- API 키·토큰·비밀번호·DB 접속 문자열·웹훅 URL·배포된 클라우드 주소(`*.workers.dev` 등)는 코드에 직접 쓰지 않는다. 항상 `.env`(Cloudflare Worker는 `.dev.vars`/`wrangler secret`)에 두고 코드는 환경변수로 읽는다(`os.getenv`, `process.env` 등).
- 새 프로젝트나 키를 처음 쓰는 프로젝트에는 값 없이 이름만 적은 `.env.example`을 만들고, `.gitignore`에 `.env`·`.env.*`·`!.env.example`·`.dev.vars`가 있는지 확인한다.
- 사용자가 키 값을 대화에 붙여 넣어도 코드·문서·커밋 메시지에 옮겨 적지 않고 `.env`에만 넣는다. 답변에도 값을 다시 출력하지 않는다(필요하면 앞 몇 글자만).
- **모든 커밋 직전**에 `git diff --cached --name-only`(`-a` 커밋이면 `git diff HEAD --name-only`)로 `.env`·`.env.*`·`.dev.vars`·`.wrangler/`·키 파일(`*.pem`, `id_rsa*` 등)이 없는지, 추가된 줄에 키·토큰 값이 없는지 직접 확인하고, 확인 결과를 사용자에게 한 줄로 알린다.
- **push 직전**에는 `zsh ~/Downloads/claude/261022_portfolio/portfolio_secret-scan.sh <레포>`를 돌려 0건을 확인한다.
- 커밋할 레포의 `.gitignore`에 `.env`·`.env.*`·`!.env.example`·`.dev.vars`·`.wrangler/`가 없으면 커밋 전에 추가한다(전역 `~/.gitignore_global`이 있어도 레포에도 둔다).
- 우회 금지: `--no-verify`, `git commit -n`, `SKIP_SECRET_CHECK=1`, `core.hooksPath` 변경, 훅·가드 파일 수정. Claude Code 가드(`~/.claude/hooks/git-commit-guard.sh`, PreToolUse)가 이를 막고 커밋마다 전역 pre-commit(`~/.git-hooks/pre-commit`) 검사를 직접 돌린다. 막히면 우회를 시도하지 말고 값을 `.env`로 옮긴다. 오탐이면 사용자에게 알리고, 사용자가 터미널에서 직접 커밋하게 한다.
- 이미 커밋·push된 키를 발견하면 즉시 사용자에게 알리고, 히스토리 정리보다 먼저 키 재발급(회수)을 권한다.

# README 작성 규칙 (모든 레포)
- 메인 `README.md`는 영문으로 쓴다. 한국어 문서는 `README.ko.md`로 두고, 영문 README 맨 아래에 `---` 다음 줄로 `한국어 문서: [README.ko.md](README.ko.md)`를 둔다. `README.ko.md` 맨 위에는 `[English](README.md)` 한 줄만 둔다. 한국어 원문이 없으면 ko 링크는 넣지 않는다.
- 절 순서: 한 줄 요약(+데모 그림) → `## Problem` → `## Approach` → `## Results` → `## Tech stack` → `## Run` → `## Lessons learned` → (`## License`) → (`## References`). 결과가 없으면 Results에 "Not measured yet"이라고 쓴다. 측정 조건(하드웨어, 입력 길이, 반복 수)은 수치와 같은 줄에 둔다.
- 옮기거나 요약해도 인명·수치·날짜·단위·인용의 의미를 바꾸지 않는다. 바꾸거나 지우거나 약하게 고칠 내용은 파일에 쓰기 전에 표로 먼저 보여주고 확인을 받는다.
- 비판자 점검: 근거보다 강한 동사(solve, improve, real-time, state-of-the-art), 일반화(always, any), 측정하지 않은 효과를 찾아 근거만큼 낮춘다. 시뮬레이션·계획 단계라는 단서는 남긴다.
- 숫자 검증: `python3 ~/Downloads/claude/261022_portfolio/portfolio_number-check.py <레포>`로 근거 없는 숫자가 0개인지 확인한다.
