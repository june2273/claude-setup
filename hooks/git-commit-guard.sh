#!/bin/bash
# Claude Code PreToolUse(Bash) 가드: git commit 전에 비밀값 검사를 강제하고 우회를 막는다.
# 막을 때는 exit 2 + stderr (Claude에게 이유가 전달된다).
input=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")
[ -z "$cmd" ] && exit 0

block() { echo "✋ git-commit-guard: $1" >&2; exit 2; }

# 명령을 ; & | 줄바꿈 단위로 나눠 git으로 시작하는 구간만 본다 (다른 명령의 문자열 인자 속 글자는 무시)
# shortcut: 따옴표 안의 ; & | 로도 나뉜다. 그 결과 git 구간을 놓치는 경우는 아래 커밋 검사가 다시 덮는다.
gitsegs=$(tr ';&|' '\n\n\n' <<<"$cmd" | grep -E '^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*git([[:space:]]|$)')
unquoted=$(sed -E "s/\"[^\"]*\"//g; s/'[^']*'//g" <<<"$cmd")

# 1) 우회 수단 금지
grep -qE -- '--no-verify' <<<"$gitsegs" && block "--no-verify 금지. 걸린 값은 .env로 옮기세요."
grep -q 'core\.hooksPath' <<<"$gitsegs" && block "core.hooksPath 변경 금지 (전역 시크릿 훅이 꺼집니다)."
if [ -n "$gitsegs" ] && grep -qE '(^|[^A-Za-z0-9_])SKIP_SECRET_CHECK=' <<<"$unquoted"; then
  block "SKIP_SECRET_CHECK 금지. 오탐이면 사용자가 터미널에서 직접 커밋해야 합니다."
fi

commitseg=$(grep -E 'git([[:space:]]+-[cC][[:space:]]+[^[:space:]]+)*[[:space:]]+commit([[:space:]]|$)' <<<"$gitsegs" | tail -1)
[ -z "$commitseg" ] && exit 0

# 2) git commit -n (= --no-verify) 금지. -m 메시지 안의 글자는 보지 않는다
args=$(sed -E "s/\"[^\"]*\"//g; s/'[^']*'//g; s/.*[[:space:]]commit([[:space:]]|$)//" <<<"$commitseg")
grep -qE '(^|[[:space:]])-[A-Za-z]*n[A-Za-z]*([[:space:]]|$)' <<<"$args" && block "git commit -n(--no-verify) 금지."

# 3) 커밋할 레포를 찾아 직접 검사 (레포가 core.hooksPath를 바꿔 전역 훅이 안 도는 경우까지 덮는다)
# shortcut: 'git -C X' / 'cd X' 만 해석한다. 더 복잡한 셸 조합은 세션 cwd로 검사한다.
dir=$(grep -oE 'git[[:space:]]+-C[[:space:]]+[^[:space:]]+' <<<"$commitseg" | tail -1 | awk '{print $3}')
[ -z "$dir" ] && dir=$(grep -oE '(^|[;&[:space:]])cd[[:space:]]+[^;&|[:space:]]+' <<<"$cmd" | tail -1 | awk '{print $NF}')
dir="${dir//\"/}"; dir="${dir//\'/}"; dir="${dir/#\~/$HOME}"
case "$dir" in ""|/*) ;; *) dir="$cwd/$dir" ;; esac
[ -z "$dir" ] && dir="$cwd"
cd "${dir:-.}" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

diffsrc=--cached
# -a/--all 커밋은 아직 스테이징 안 된 변경도 들어가므로 HEAD 기준으로 본다
if grep -qE '(^|[[:space:]])(-[A-Za-z]*a[A-Za-z]*|--all)([[:space:]]|$)' <<<"$args" && git rev-parse -q --verify HEAD >/dev/null; then
  diffsrc=HEAD
fi

out=$(env -u SKIP_SECRET_CHECK SECRET_CHECK_ONLY=1 SECRET_DIFF="$diffsrc" "$HOME/.git-hooks/pre-commit" 2>&1)
[ $? -ne 0 ] && block "커밋 차단 — 비밀값 의심 항목이 있습니다. 값을 .env로 옮기고 다시 커밋하세요.
$out"
exit 0
