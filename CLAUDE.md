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

# 비밀값(토큰·키) 처리 규칙
- API 키·토큰·비밀번호·DB 접속 문자열·웹훅 URL·배포된 클라우드 주소(`*.workers.dev` 등)는 코드에 직접 쓰지 않는다. 항상 `.env`(Cloudflare Worker는 `.dev.vars`/`wrangler secret`)에 두고 코드는 환경변수로 읽는다(`os.getenv`, `process.env` 등).
- 새 프로젝트나 키를 처음 쓰는 프로젝트에는 값 없이 이름만 적은 `.env.example`을 만들고, `.gitignore`에 `.env`·`.env.*`·`!.env.example`·`.dev.vars`가 있는지 확인한다.
- 사용자가 키 값을 대화에 붙여 넣어도 코드·문서·커밋 메시지에 옮겨 적지 않고 `.env`에만 넣는다. 답변에도 값을 다시 출력하지 않는다(필요하면 앞 몇 글자만).
- 커밋 전에 스테이징된 변경에 키·토큰 패턴이 없는지 확인한다. 전역 pre-commit 훅(`~/.git-hooks/pre-commit`)이 막으면 우회(`--no-verify`)하지 말고 값을 `.env`로 옮긴다.
- 이미 커밋·push된 키를 발견하면 즉시 사용자에게 알리고, 히스토리 정리보다 먼저 키 재발급(회수)을 권한다.
