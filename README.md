# claude-setup

A personal harness that constrains an AI coding agent (Claude Code) with rules, tools and verification hooks, with a record of why each piece was chosen and what was left out ([docs/decisions.md](docs/decisions.md), in Korean).

## Problem

Coding agents repeat a few mistakes: over-engineering, edits outside the task, outdated APIs, "done" without verification, and committed secrets. Adding more tools does not fix this by itself, and rules in a prompt are suggestions the model may or may not follow.

## Approach

Each layer targets one kind of waste. Where a rule (a suggestion) is not enough, it is paired with a hook (a guarantee).

| Layer | What it changes | Component | Loaded |
|---|---|---|---|
| Working principles | think first, touch only what is needed, verify | [Karpathy Skills](https://github.com/forrestchang/andrej-karpathy-skills) | skill, on demand |
| Prompting basics | finish the task, control scope | [oh-my-fable](https://github.com/Junhan2/oh-my-fable) | SessionStart hook |
| Code volume | YAGNI, standard library first, no speculative abstraction | [Ponytail](https://github.com/DietrichGebert/ponytail) | hook, incl. subagents |
| Output | compressed replies | [caveman](https://github.com/JuliusBrussee/caveman) | **off by default**, `/caveman` to enable |
| Knowledge | current library docs | [Context7](https://github.com/upstash/context7) | MCP, on call |
| Structure | codebase knowledge graph | [graphify](https://github.com/safishamsi/graphify) | skill + per-repo output |
| Global rules | output location, secret handling, README format | [global/CLAUDE.md](global/CLAUDE.md) | always |
| **Guarantee** | block secret files and key patterns at commit | [hooks/pre-commit](hooks/pre-commit), [hooks/gitignore_global](hooks/gitignore_global) | global git hook |
| **Guarantee** | block hook bypasses, run the secret check on every commit | [hooks/git-commit-guard.sh](hooks/git-commit-guard.sh) | Claude Code PreToolUse hook |

- Third-party plugins are referenced through their marketplaces, not copied; each keeps its own license.
- `global/CLAUDE.md` is a copy of `~/.claude/CLAUDE.md`. It is kept out of the repo root so it is not loaded as this repo's project instructions.
- The secret layers were added after a real incident: a deployed cloud URL and an API token ended up in commits (decision D7).

## Results

The hook has a regression test; the plugin layers are not measured yet.

```bash
./tests/test-pre-commit.sh   # 11 passed / 0 failed
```

The savings each plugin claims are not copied here. Only numbers measured in this environment will be added, using the Ponytail ledger (`~/.config/ponytail/band/`), `/caveman-stats`, and the same task run with a tool on and off.

## Tech stack

- Claude Code: plugins, skills, MCP, hooks (`settings.json`)
- Bash: git hooks, Claude Code hook, install script
- git: global `core.hooksPath` and `core.excludesfile`

## Run

Requires Claude Code, Node.js and [uv](https://github.com/astral-sh/uv) (for graphify).

```bash
./scripts/install.sh
```

The script does not overwrite existing settings. `global/CLAUDE.md` is not copied automatically; take the sections you need into `~/.claude/CLAUDE.md`. The Claude Code guard is not registered by the script yet: add `hooks/git-commit-guard.sh` as a `PreToolUse` hook with matcher `Bash` in `~/.claude/settings.json`.

Typical use:
- Clean up an existing repo: `/ponytail-audit` → apply the chosen items → `/ponytail-review`
- Learn a new repo: `/graphify .`
- Long implementation session: `/caveman`, then `/caveman off`

## Lessons learned

- A rule in `CLAUDE.md` is a suggestion; only a hook is a guarantee. Secret handling needed both: the rule covers values with no fixed format, the hook covers the ones it can match.
- A git hook alone can be skipped (`--no-verify`, a repo-level `core.hooksPath`), so the agent-side guard blocks those and runs the check itself.
- The guard's first version blocked harmless commands that only mentioned a bypass flag inside a string; it now checks only the `git` segments of a command. Pattern-based checks still have false positives and misses.
- Two output plugins conflicted (progress reports vs. terse replies), so caveman stays off by default (D1).

---
한국어 문서: [README.ko.md](README.ko.md)
