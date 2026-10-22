#!/bin/bash
# claude-setup 설치: 플러그인 · MCP · graphify · caveman 설정 · 전역 시크릿 훅.
# 기존 설정은 덮어쓰지 않는다. 이미 있으면 건너뛰고 알려준다.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "== Claude Code 플러그인 (user scope)"
for m in Junhan2/oh-my-fable JuliusBrussee/caveman DietrichGebert/ponytail forrestchang/andrej-karpathy-skills; do
  claude plugin marketplace add "$m"
done
for p in oh-my-fable@oh-my-fable caveman@caveman ponytail@ponytail andrej-karpathy-skills@karpathy-skills; do
  claude plugin install "$p" --scope user
done

echo "== Context7 MCP"
claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp || echo "   이미 등록됨"

echo "== graphify (uv 필요)"
uv tool install graphifyy && graphify install --platform claude

echo "== caveman 기본 off"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}/caveman/config.json"
if [ -e "$CFG" ]; then echo "   $CFG 이미 있음, 건너뜀"; else mkdir -p "$(dirname "$CFG")" && cp "$ROOT/config/caveman.json" "$CFG"; fi

echo "== 전역 pre-commit 시크릿 훅"
cur=$(git config --global --get core.hooksPath || true)
if [ -n "$cur" ] && [ "$cur" != "$HOME/.git-hooks" ]; then
  echo "   core.hooksPath가 이미 $cur 로 설정됨, 건너뜀 (hooks/pre-commit을 직접 연결하세요)"
else
  mkdir -p "$HOME/.git-hooks"
  if [ -e "$HOME/.git-hooks/pre-commit" ]; then echo "   ~/.git-hooks/pre-commit 이미 있음, 건너뜀"
  else cp "$ROOT/hooks/pre-commit" "$HOME/.git-hooks/pre-commit" && chmod +x "$HOME/.git-hooks/pre-commit"; fi
  git config --global core.hooksPath "$HOME/.git-hooks"
fi

echo "== 전역 gitignore 비밀값 절"
IGN=$(git config --global --get core.excludesfile || echo "$HOME/.gitignore_global")
IGN="${IGN/#\~/$HOME}"
if grep -q '^\.dev\.vars$' "$IGN" 2>/dev/null; then echo "   이미 있음, 건너뜀"
else cat "$ROOT/hooks/gitignore_global" >> "$IGN" && git config --global core.excludesfile "$IGN"; fi

echo "완료. CLAUDE.md는 덮어쓰지 않습니다: 필요한 절만 ~/.claude/CLAUDE.md에 복사하세요."
