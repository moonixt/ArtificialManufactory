# Artificial Manufactory

Proprietary agent skills by [Artificial Manufactory](https://bot.artificialmanufactory.com), used in the AI assistants we set up for small businesses.

## Skills

| Skill | What it does |
| --- | --- |
| [client-management](skills/client-management/SKILL.md) | Set up and operate a client's customer management system (Atomic CRM based) through its MCP: contacts, deals, tasks and notes. |
| [video-motion-am](skills/video-motion-am/SKILL.md) | Create and edit motion videos (ads, LinkedIn/Reels/TikTok posts) in the Artificial Manufactory style: animated HTML rendered frame by frame to MP4 with ffmpeg. |
| [setup-cloud-agent](skills/setup-cloud-agent/SKILL.md) | Interactive setup that installs linear-worker on this or a remote machine: asks frequency, schedule and Linear API key, then installs a systemd timer. |
| [linear-worker](skills/linear-worker/SKILL.md) | Unattended Claude Code worker: picks one labeled Linear issue per run, solves it in a git worktree from main and opens a PR for human review. |
| [connect-your-bank-brazil](skills/connect-your-bank-brazil/SKILL.md) | Free personal Open Finance in Brazil via Meu Pluggy + Pluggy API: connect banks, then read accounts and transactions. |

## Install

```bash
npx skills add moonixt/ArtificialManufactory --skill client-management
npx skills add moonixt/ArtificialManufactory --skill connect-your-bank-brazil
npx skills add moonixt/ArtificialManufactory --skill video-motion-am
npx skills add moonixt/ArtificialManufactory --skill setup-cloud-agent
npx skills add moonixt/ArtificialManufactory --skill linear-worker
```

## License

Source-available under the [Artificial Manufactory Subscription License](LICENSE). Anyone can read it; use is allowed for active Artificial Manufactory subscribers while their subscription lasts. For other uses, contact [Artificial Manufactory](https://bot.artificialmanufactory.com).
