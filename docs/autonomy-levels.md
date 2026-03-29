# Autonomy Levels

Reference for how Claude Code agents operate at different levels of independence.

## Level 1 — Supervised

- Agent works on one task at a time
- Human reviews each output before the agent moves on
- Best for: early setup, unfamiliar codebases, high-risk changes

**QC integration:** Human review replaces automated QC.

## Level 2 — Semi-Autonomous

- Agent chains 2-5 tasks with QC gates between each
- Uses the qc-reviewer subagent after each task
- Asks on Telegram for approval on external actions (push, deploy, delete)
- Best for: active development sessions where you're monitoring Telegram

**QC integration:** Per-task QC via subagent. Max 3 QC loops per task. After loop 3, commit with `review:` prefix and notify on Telegram.

## Level 3 — Autonomous

- Agent works through an entire epic or sprint backlog
- QC gates are mandatory between every task
- Daily summary cron reports progress
- Context save cron ensures recovery on crash
- Best for: overnight runs, batch processing, well-defined task lists

**QC integration:** Same as Level 2, plus daily QC summary via cron. Human reviews `review:` commits async.

## Choosing a Level

| Factor | Level 1 | Level 2 | Level 3 |
|--------|---------|---------|---------|
| Task clarity | Vague | Well-defined | Fully specified |
| Risk tolerance | Low | Medium | High |
| Human availability | At keyboard | Watching Telegram | Async/overnight |
| Codebase familiarity | New | Familiar | Well-mapped |

## Escalation

Agents should escalate (drop to a lower autonomy level) when:
- A task requires changes outside their scope constraints
- QC fails 3 times on the same task
- They encounter an error they can't diagnose
- The task spec is ambiguous or contradictory
