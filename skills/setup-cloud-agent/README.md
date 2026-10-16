# Cloud agent kit: a Claude Code worker for Linear

A scheduled, headless Claude Code session that takes Linear issues your team has approved, solves each one in an isolated git worktree, and opens a pull request. A human tests the branch and merges. The worker **never pushes to main, never merges, never deploys**.

## What's inside

| Path | What it is |
|---|---|
| `linear-worker/SKILL.md` | The worker. Every scheduled run follows it. It has `<PLACEHOLDERS>` that the setup fills. |
| `setup-cloud-agent/SKILL.md` | Interactive setup. You run it once: it asks the questions, fills the worker, installs the schedule and runs a test. |
| `setup-cloud-agent/templates/` | `run.sh`, `linear-worker.service`, `linear-worker.timer`: the files the setup fills and installs. |

## How a run works

1. **Close finished work.** For issues with the label that are in progress or in review, the worker checks their PRs:
   - PR merged: the issue goes to done;
   - PR closed without merge: the issue goes to canceled;
   - PR still open: the issue isn't touched.

   The worker also cleans up their worktrees.
2. **Find work.** It looks for at most **one** open issue with the agreed label (default `claude`) in the agreed column (e.g. Feedback). If there is none, it stops.
3. **Claim it.** It moves the issue to in progress and comments, so a second run doesn't take the same issue.
4. **Isolated worktree.** It runs `git worktree add ../wt/<id> -b claude/<id>-<slug> origin/<main>` and installs the dependencies there.
5. **Solve it.** It makes the smallest change, then runs the project's checks (typecheck, lint, unit tests).
6. **Hand off.** It pushes the branch, opens a PR with `Closes <id>`, comments the link on the issue and moves the issue to in review.

**Unclear issues.** If an issue is ambiguous, too big, or asks for anything on the safety list, the worker comments the question and puts the issue back in the pick-up column.

**Replies to the requester (optional).** Some teams show Linear comments with a prefix (e.g. `reply:`) to the person who sent the request. The worker can then post three plain-language messages, at three moments: PR opened, merged, and refused.

## Requirements

On the worker machine:
- Linux, with **systemd**. Cron works too.
- **Claude Code**, installed and logged in for the worker user.
- **`gh`**, logged in, with permission to push branches and open PRs.
- **`git`**, and the project's toolchain (Node, pnpm…).

In Linear:
- a team and a project;
- the label;
- the columns for pick-up, in progress, in review, done and canceled;
- a **personal API key**, ideally from a dedicated bot user.

## Install

1. Copy both skill folders into `~/.claude/skills/` on the machine where you'll talk to Claude Code. That can be your laptop, even if the worker runs on a VPS.
   ```bash
   cp -r linear-worker setup-cloud-agent ~/.claude/skills/
   ```
2. Open Claude Code and say: **"Run the setup-cloud-agent skill"**. It asks the questions:
   - where the worker runs;
   - which user it runs as;
   - the repo and its checks;
   - the model and effort;
   - the frequency and hours;
   - the Linear names;
   - the replies.

   It shows a summary, waits for your yes, installs everything, then does a dry run and a real run.
3. After that, put the label on an issue in the pick-up column. At the next run, the PR shows up.

**Pause:** `sudo systemctl disable --now linear-worker.timer`. **Log:** `~/linear-worker/worker.log`.

**Remove:**
1. Disable the timer.
2. Delete `/etc/systemd/system/linear-worker.{service,timer}`, then run `daemon-reload`.
3. Run `claude mcp remove --scope user linear-server`.
4. Delete `~/linear-worker` and the skill.

## Security: read before you install

The worker runs code written by an AI, based on issue text. That text may come from people outside the team. Treat it like any automation that executes untrusted input.

- **The label is the gate.** Only a human adds it, after reading the issue. The worker never adds it, and never picks an issue without it. Don't automate the label.
- **Run it as a dedicated user, without sudo and without docker,** with its own clone. If it runs as a privileged user on a production server, a malicious issue that slips past the label can reach root, the containers and the production secrets. The setup recommends the safe option, and it records the risk if you choose otherwise.
- **Use its own clone, never the deploy checkout.** Deploys often run `git reset --hard`, and that breaks the worker's git.
- **Use a narrow GitHub token.** A fine-grained token restricted to the one repo, with Contents and Pull requests write. A broad classic token lets a misled worker delete repos or change settings.
- **Limit the commands.** The scheduler allows only `git`, `gh`, the install command, the check commands and a few read-only tools (`--allowedTools`). The skill also refuses to touch CI, deploy, Docker, dependencies, env files or itself, even when an issue asks.
- **Know where the Linear key lives.** It ends up in plain text in the worker user's `~/.claude.json`. Keep that file at `chmod 600` and out of any repo.

## Cost and load

- **Cost.** Each run is a new session. A run with nothing to do is short, but it isn't free. A run that implements an issue costs about as much as doing it yourself with Claude Code, at the model and effort you chose. Business hours alone means about 10 runs a day.
- **Load on a production server.** If the worker shares the server with production:
  - the service runs with `Nice=10` and idle I/O;
  - tell the setup "no production build here", so the worker runs typecheck, lint and tests, and leaves the build to CI.

## Troubleshooting (things that already happened)

| Symptom | Cause | Fix |
|---|---|---|
| The run says the skill "doesn't exist" | `disable-model-invocation: true` in the worker's frontmatter hides it from the model | Remove that line |
| The PR was opened but "no checks ran"; the log says a command "needed approval" | An `--allowedTools` rule without the wildcard: `Bash(npm ci)` refuses `npm ci --silent` | End every Bash rule with `*` |
| The session stops when editing files | Worktrees are outside the run folder, and `acceptEdits` doesn't cover them | Pass `--add-dir <repo>/../wt` (the template does) |
| The worker doesn't see Linear | The MCP was added in another folder's local scope | Use `claude mcp add --scope user` |
| The worker changes model or behavior by itself | No `--model` or `--effort`, so it follows the account default | Pin both in `run.sh` |
| The last run of the day goes past the window | Last start + max run time > end of the window | The setup checks it. For 30-min runs, use max ≤ 25 min |
