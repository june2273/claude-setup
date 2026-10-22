#!/bin/bash
# hooks/pre-commit 회귀 테스트: 임시 레포에서 파일을 스테이징하고 차단/통과를 확인한다.
# 테스트용 키는 실행 중에 조립해서, 이 파일 자체는 훅에 걸리지 않는다.
HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/pre-commit"
pass=0; fail=0

check() {  # check <기대: block|pass> <설명> <파일명> <내용>
  local dir; dir=$(mktemp -d)
  git -C "$dir" init -q
  mkdir -p "$dir/$(dirname "$3")"
  printf '%s\n' "$4" > "$dir/$3"
  git -C "$dir" add -A -f  # -f: 전역 gitignore를 지나친 경우(git add -f)도 훅이 막는지 본다
  if (cd "$dir" && bash "$HOOK" >/dev/null 2>&1); then got=pass; else got=block; fi
  if [ "$got" = "$1" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL: $2 (기대 $1, 결과 $got)"; fi
  rm -rf "$dir"
}

R=$(printf 'A%.0s' {1..40})  # 40자 더미
check block ".env 파일"               .env                    "X=1"
check block ".env.local 파일"         .env.local              "X=1"
check pass  ".env.example 허용"       .env.example            "API_KEY="
check block ".dev.vars 파일"          .dev.vars               "X=1"
check block ".pem 키 파일"            certs/server.pem        "x"
check block "Anthropic 키"            app.py                  "k = \"sk""-ant-${R}\""
check block "GitHub 토큰"             app.py                  "t = 'ghp_${R:0:36}'"
check block "Notion 토큰"             app.py                  "t = 'ntn_${R}'"
check block "하드코딩 api_key 대입"    config.py               "api_key = \"${R}\""
check pass  "환경변수로 읽기"          config.py               "api_key = os.getenv(\"API_KEY\")"
check pass  "일반 코드"               main.py                 "print('hello')"

echo "통과 $pass / 실패 $fail"
[ "$fail" = 0 ]
