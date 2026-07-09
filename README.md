# agent-skills

Agent Skills for Claude Code and other [skills.sh](https://www.skills.sh)-compatible coding agents.

## Skills

### `fable-reasoning`

Elite, stack-agnostic **reasoning and coding discipline** — a process layer that raises problem-solving quality on any task, in any language. It enforces hypothesis-driven thinking, evidence-before-belief, root-cause (not symptom) fixes, calibrated effort, and adversarial self-verification before anything is called "done."

Load it at the **start** of any non-trivial task — debugging, implementing a feature, refactoring, an architecture decision, code review, or a multi-step investigation. The main `SKILL.md` carries a 6-phase operating loop (understand → gather context → hypothesize → plan → execute → self-verify), an effort-calibration table, and an anti-pattern list; three reference files go deep on debugging, coding craft, and verification, loaded only when the task centers on that activity.

## Install

With the [`skills`](https://www.skills.sh) CLI (no install needed):

```bash
# Add every skill in this repo to the current project
npx skills add sijirama/agent-skills

# Or install globally (user-level), available in every project
npx skills add sijirama/agent-skills --global

# List what's in this repo without installing
npx skills add sijirama/agent-skills --list
```

This works with Claude Code and any other agent the `skills` CLI supports.

## Layout

```
skills/
└── fable-reasoning/
    ├── SKILL.md                       # 6-phase reasoning loop, effort calibration, anti-patterns
    └── references/
        ├── debugging.md               # reproduction, bisection, hypothesis trees, heisenbugs
        ├── coding.md                  # reading order, idiom-matching, edge-case taxonomy, safe refactors
        └── verification.md            # evidence hierarchy, discriminating tests, adversarial self-review
```

## License

MIT © sijirama
