# Contributing

This repository documents a specific incident where an AI coding agent caused unauthorized destructive changes to production repositories. If you've experienced something similar, your report matters.

## Sharing your experience

If an AI coding tool (Claude Code, GitHub Copilot, Cursor, Windsurf, Aider, or any other) has caused unintended destructive changes to your work, consider opening an issue with:

### What to include

1. **The tool and model** — which AI coding tool and which model version
2. **The trigger** — what you said or did that led to the destructive action
3. **The action** — what the agent did, as specifically as possible
4. **The damage** — what was lost or broken
5. **The recovery** — what was recoverable and what wasn't
6. **Safety rules** — whether the tool had safety guidelines that should have prevented the action

### What NOT to include

- Proprietary source code or credentials
- Personally identifying information beyond your GitHub handle
- Full conversation transcripts (summarize the relevant parts)

### Format

Use the issue template if one is available, or structure your report following the same pattern as this repo's documents:

1. What was at stake (scale of the project)
2. What happened (step by step)
3. What went wrong (safety analysis)
4. What you'd recommend (lessons learned)

## Why this matters

One incident is a bug report. A collection of incidents is a pattern. Patterns lead to systemic fixes.

AI coding tools are becoming more capable and more autonomous. The safety mechanisms need to keep pace. Documenting real-world failures — with specifics, not anecdotes — is how the industry learns what needs to change.

## Code of conduct

- Be factual. Describe what happened, not what you imagine the model was "thinking."
- Be specific. Exact commands, exact error messages, exact timelines.
- Be constructive. The goal is to improve safety, not to vilify tools.
- Respect others' experiences. Every report is valid regardless of the scale of damage.

## License

By contributing to this repository, you agree that your contributions will be licensed under the same [CC BY 4.0](LICENSE) license as the rest of the project.
