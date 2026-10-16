#!/usr/bin/env bash
# Starts a fresh, headless Claude Code session that runs the linear-worker skill once.
# Called by linear-worker.service (systemd) or by a cron line.
set -uo pipefail
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
cd "<REPO>" || exit 1
echo "=== $(date -Is) start ==="

# Keep the clone's main equal to the remote: every worktree starts from it, and a
# project-level skill (in .claude/skills) is read from here.
git fetch -q origin && git checkout -q "<MAIN>" && git merge -q --ff-only "origin/<MAIN>"

# flock: with cron, two runs could overlap (systemd already prevents that on its own).
# --add-dir: worktrees live outside this folder (../wt); without it acceptEdits can't reach
# them and the session stops waiting for approval. Every --allowedTools Bash rule ends in "*":
# without the wildcard, "Bash(npm ci)" refuses "npm ci --silent".
flock -n "<WORKER_DIR>/.lock" timeout "<MAX>m" claude -p "Run the linear-worker skill." \
  --model "<MODEL>" --effort "<EFFORT>" \
  --permission-mode acceptEdits \
  --add-dir "<WORKTREES_DIR>" \
  --allowedTools "<ALLOWED>"
echo "=== $(date -Is) end (exit code $?) ==="
