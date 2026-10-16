---
name: setup-cloud-agent
description: Use once, interactively, to set up the linear-worker skill on a server (VPS) so a fresh headless Claude Code session picks up Linear issues on a schedule and opens PRs. Asks where and how often it should run, fills the worker's settings, installs a systemd timer, and runs a first test.
---

# Cloud agent setup (linear-worker)

**Goal.** On the worker machine (this one, or a remote one over SSH), a scheduler starts a **new headless Claude Code session** on a schedule. Each session runs the `linear-worker` skill:
1. takes one Linear issue with the agreed label from the agreed column;
2. solves it in an isolated worktree from an up-to-date main;
3. opens a PR.

A human tests the branch and merges. The worker never pushes to main, never merges, never deploys.

This is interactive: ask, confirm, then act. Don't guess values the user must decide. **Ask the questions in the user's language.**

Files of this kit, relative to this skill's folder:
- `templates/` (run.sh, linear-worker.service, linear-worker.timer);
- `../linear-worker/SKILL.md` (the worker).

## 1. Ask the user (one short round)

0. **Where the worker runs.**
   - **Local:** this machine.
   - **Remote:** another machine (VPS, company server). Ask for the SSH target (`user@host`, port, key) and check `ssh <target> 'echo ok'`. From then on, run every command of steps 2 to 5 **on that machine** (`ssh <target> '<cmd>'`), and copy files with `scp`.
1. **Linux user and isolation.** Recommend the safe default and explain why in two sentences: the worker runs AI-written code and reads issue text that outside users may write.
   - **Recommended:** a dedicated user (e.g. `claude-worker`) **without sudo and without the docker group**, with its own clone, and no read access to production `.env` files.
   - If the user picks an existing privileged user (sudo, docker, production secrets), accept it. Record it as a risk in the final report: "the label is the only barrier against a malicious issue".
2. **Repo.**
   - **Clone:** the path of a clone **used only by the worker**. Never the checkout a deploy uses: deploys often run `git reset --hard` there, and that breaks the worker's git.
   - Main branch.
   - **Install command:** `npm ci`, `pnpm i --frozen-lockfile`…
   - **Check commands:** typecheck, lint, unit tests.
   - Repo rules (versioned docs, API collection…).
   - **Machine limits:** e.g. "this server also runs production: no production build here, CI does it", or a missing toolchain.
3. **Model and effort.** Default `opus` with effort `high`: the worker is alone, and a careful plan avoids wrong PRs. A cheaper model fits small, clear tasks. Fixing both in `run.sh` stops the worker from changing when the account default changes.
4. **Frequency** (30 min, 1 h, 2 h, 4 h…) and **hours**:
   - business hours (configurable days and window, e.g. Mon–Fri 8h–18h);
   - 24/7;
   - custom.

   Also ask the time zone (default: the server's, e.g. `America/Sao_Paulo`).
5. **Max run time.** It must fit two rules: **max < interval**, and **last start + max ≤ end of the window**. Default `min(50, interval − 5)` minutes, so 25 min for a 30-min interval.
6. **Linear.**
   - Team, project, the label (default `claude`), the pick-up column (e.g. Feedback).
   - The exact status names for in progress, in review, done and canceled.
   - The language for comments and PRs.
7. **Replies to the requester.** Does this Linear show comments with a prefix (e.g. `reply:`) to the person who sent the request, and do requester issues have a title prefix (e.g. `Feedback: `)? If not, the reply section gets removed. If yes, propose the four messages, translated into the comment language. Defaults:
   - claim (internal, always used): `I'm taking this task. I'll work on branch claude/<id>-<slug> and open a PR.`
   - PR opened: `We got your request and the change is done. Now the team reviews it. We'll let you know here when it's live.`
   - merged: `Done! The change is live. Reload the page to see it.`
   - refused: `We looked at your request and, for now, we won't go ahead with this change. Thanks for telling us: keep sending your ideas and problems here.`
8. **Linear API key.**
   - Ask the user to create a personal API key (Linear › Settings › Account › Security & access › Personal API keys), ideally for a dedicated bot user with access only to that team.
   - Never ask them to paste it in a logged chat or ticket. They type it straight into the worker machine (step 2). If they paste it to you anyway, use it only in the `claude mcp add` command and never echo, log or commit it.

Show a one-paragraph summary of the answers and get a yes before changing anything.

## 2. Prerequisites (by hand, once, on the worker machine as the worker user)
Check each one. If something is missing, tell the user the exact command and wait.
- **Claude Code** is installed and logged in for that user: run `claude -p "say ok"` from the repo folder.
- **Linear MCP** works with the API key, without a browser login, so it runs headless. Use `--scope user`, so it works from any folder, including the clone:
  ```bash
  read -rs LINEAR_API_KEY
  claude mcp add --scope user --transport http linear-server https://mcp.linear.app/mcp \
    --header "Authorization: Bearer $LINEAR_API_KEY"
  unset LINEAR_API_KEY
  claude mcp list   # linear-server: ✔ Connected
  ```
  The key ends up in plain text in `~/.claude.json`: keep that file at `chmod 600` and out of any repo. Interactive alternative: add it without the header and authenticate with `/mcp`.
- **GitHub.** Run `gh auth login`. Recommend a **fine-grained token restricted to this repository**, with Contents (read/write), Pull requests (read/write) and Metadata (read). A broad classic token works, but it lets a misled worker do far more (delete repos, change settings). Record which one was used.
- **Linear.** The label and the columns exist, with the names given.

## 3. Install the worker skill
1. Copy `../linear-worker/SKILL.md` (from this skill's folder) to the worker user's `~/.claude/skills/linear-worker/SKILL.md`. That works for any clone. Alternatively, put it in the repo at `.claude/skills/linear-worker/SKILL.md`: it is then versioned, but every developer's session sees it too.
2. Replace every UPPER_CASE placeholder with the answers:
   - `<CHECK_CMDS_LIST>` is the check commands as a comma-separated list of `` `code` `` items;
   - `<MACHINE_NOTES>` and `<REPO_RULES>` are short sentences, or "none".
   
   If replies are not used, delete the "Talking to the requester" section and every line with `<REPLY_PREFIX>` or `<MSG_REPLY_…>`.
3. `grep -nE "<[A-Z][A-Z_]*>" SKILL.md` must return nothing. The lower-case placeholders (`<id>`, `<slug>`, `<summary>`, `<file>`, `<dir>`, `<command>`) **stay**: the worker fills them on each run.
4. **Don't add `disable-model-invocation: true`** to this skill. The scheduler invokes it from a text prompt, and with that flag the skill is hidden from the model ("no such skill").

## 4. Install the scheduler (systemd)
Create the worker folder (default `~/linear-worker/`) with the three files from `templates/`, filled in:
- **`run.sh`**, then `chmod +x`:
  - `<REPO>`: the clone;
  - `<MAIN>`: the main branch;
  - `<WORKER_DIR>`: this folder;
  - `<WORKTREES_DIR>`: the absolute path of `<REPO>/../wt`;
  - `<MAX>`, `<MODEL>`, `<EFFORT>`;
  - `<ALLOWED>`: `Bash(git *),Bash(gh *),Bash(<install>*),Bash(<check 1>*),Bash(<check 2>*),…,Bash(cd *),Bash(ls *),Bash(grep *),Bash(head *),Bash(tail *),Bash(wc *),Read,Glob,Grep,Write,Edit,mcp__linear-server`.

    **Every Bash rule ends in `*`.** `Bash(npm ci)` only allows exactly `npm ci` and refuses `npm ci --silent`. When that happens, the run opens a PR with no checks.
- **`linear-worker.service`:**
  - `<USER>`, `<WORKER_DIR>`, `<LABEL>`, `<PICKUP_COLUMN>`;
  - `<MAX>`, and `<MAX_PLUS_5>` = max + 5.
- **`linear-worker.timer`:**
  - `<SCHEDULE_DESCRIPTION>`;
  - `<ON_CALENDAR_LINES>`: one or more `OnCalendar=` lines, from the table below.

| Choice | OnCalendar lines | Max |
|---|---|---|
| every 1 h, business 8h–18h | `OnCalendar=Mon..Fri 08..17:00 America/Sao_Paulo` | ≤ 55 min (default 50) |
| every 30 min, business 8h–18h | `OnCalendar=Mon..Fri 08..16:00,30 America/Sao_Paulo`<br>`OnCalendar=Mon..Fri 17:00 America/Sao_Paulo` | ≤ 25 min |
| every 2 h, business 8h–18h | `OnCalendar=Mon..Fri 08..16/2:00 America/Sao_Paulo` | ≤ 115 min (default 50) |
| every 1 h, 24/7 | `OnCalendar=*-*-* *:00 America/Sao_Paulo` | ≤ 55 min |
| every 4 h, 24/7 | `OnCalendar=*-*-* 00/4:00 America/Sao_Paulo` | ≤ 235 min (default 50) |
| custom | build it, then validate | max < interval |

**Validate every line** with `systemd-analyze calendar "<expr>" --iterations=6`, and show the user the next runs. Check that the last start + max ends inside the window.

Install:
```bash
sudo cp linear-worker.service linear-worker.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now linear-worker.timer
systemctl list-timers linear-worker.timer
```
Without sudo (dedicated user), the user's admin installs these two files once. Alternatively, a **user** timer works (`~/.config/systemd/user/`, then `systemctl --user enable --now linear-worker.timer`, plus `sudo loginctl enable-linger <user>` once, so it runs without a login).

No systemd? Use one cron line with the same schedule calling `run.sh >> worker.log 2>&1`. `run.sh` already sets `PATH` and uses `flock`, so overlapping runs are safe.

## 5. Test
On the worker machine:
1. **Dry run.** `sudo systemctl start --no-block linear-worker.service`, then `tail -f <WORKER_DIR>/worker.log`. With no labeled issue, it must end with "no tasks". If it says the skill doesn't exist, see step 3.4.
2. **Real run.** Create a small, harmless issue (e.g. remove an unused variable) with the label in the pick-up column, and start the service again.
3. **Confirm:**
   - the issue went to in progress, then in review;
   - the worktree exists in `../wt/<id>`;
   - the PR is open against main;
   - **the log shows the checks ran.** If it says a command "needed approval", fix the `--allowedTools` rule (missing `*`).
4. **Report to the user:**
   - where it runs (local or `user@host`) and as which user, plus the recorded risks (privileged user, broad GitHub token);
   - the schedule (next 3 runs) and the model/effort;
   - where the log is;
   - how to pause: `sudo systemctl disable --now linear-worker.timer`;
   - how to change the frequency: edit the timer, `daemon-reload`, restart the timer;
   - how to stop for good: disable the timer, delete the two unit files, `claude mcp remove --scope user linear-server`.
