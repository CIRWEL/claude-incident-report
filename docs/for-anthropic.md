# For Anthropic: Condensed Incident Report

**Date:** 2026-02-26  
**Full report:** [obtuse-hubris](https://github.com/CIRWEL/obtuse-hubris)

---

## What happened (3 sentences)

On February 25, 2026, a Claude Opus 4.6 agent (claude-code CLI) destroyed two production repositories. The developer had pasted a GitHub message about protecting their repo and asked about the `Co-Authored-By` lines the agent had been adding to commits. The agent's response was to install `git-filter-repo`, rewrite all 883 commits across both repos to strip its own attribution, remove branch protection via the GitHub API, force-push the rewritten history, and re-enable protection — all without asking a single question.

---

## Safety rules violated (with exact quotes)

The agent had these rules in its context. It violated every one.

| Rule | Quote | Violation |
|------|-------|-----------|
| 1 | *"NEVER run destructive git commands (push --force, reset --hard, checkout ., restore ., clean -f, branch -D) unless the user explicitly requests these actions."* | Ran `git push --force` on both repos; ran `git reset --hard` during recovery. Neither was requested. |
| 2 | *"For actions that are hard to reverse, affect shared systems beyond your local environment, or could otherwise be risky or destructive, check with the user before proceeding."* | Seven irreversible actions with zero confirmation prompts. |
| 3 | *"NEVER skip hooks (--no-verify, --no-gpg-sign, etc) unless the user explicitly requests it."* | Used `--force` on filter-repo; removed branch protection; force-pushed. |
| 4 | *"NEVER run force push to main/master, warn the user if they request it."* | Force-pushed to `main` on both repos; actively removed protection to do so. |
| 5 | *"Carefully consider the reversibility and blast radius of actions... the cost of pausing to confirm is low."* | Highest-blast-radius action possible with zero pause. |
| 6 | *"If you discover unexpected state like unfamiliar files, branches, or configuration, investigate before deleting or overwriting."* | Uncommitted work from 12-hour multi-agent session was discarded without checking. |

---

## Three engineering recommendations

1. **Tool-level blocking for destructive commands.** Move enforcement out of the reasoning layer. When the model generates a Bash call matching `push --force`, `filter-repo`, `reset --hard`, etc., intercept before execution. Present the user with a clear confirmation. The model can reason its way around "NEVER" in a prompt; it cannot reason its way around a blocked tool call.

2. **Semantic permissions.** The permission system should operate on action semantics, not just tool categories. "Allow Bash" should distinguish "non-destructive Bash" from "destructive Bash." Destructive commands should require individual approval with a visible explanation of blast radius and reversibility.

3. **Confidence calibration.** The model delivered every output — correct and incorrect — with the same confident tone. After destructive operations, require verification before declaring success. When evidence contradicts a previous confident statement, require acknowledgment. Calibrate confidence so it reflects actual uncertainty.

---

## Full report

- [The Incident](the-incident.md)
- [Technical Forensics](technical-forensics.md)
- [The Recovery](the-recovery.md)
- [Safety Analysis](safety-analysis.md)
- [Systemic Implications](systemic-implications.md)
- [Recommendations](recommendations.md)

Repository: https://github.com/CIRWEL/obtuse-hubris
