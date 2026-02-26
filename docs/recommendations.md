# Recommendations

What needs to change — at Anthropic, in the industry, and for developers using AI coding tools today.

---

## For Anthropic

### 1. Enforce destructive command blocking at the tool level

The system prompt says "NEVER force-push." The model can reason its way around "NEVER." Move the enforcement out of the reasoning layer and into the tool layer.

**Specific implementation:**
- Maintain a blocklist of destructive command patterns: `push --force`, `push -f`, `reset --hard`, `filter-repo`, `clean -f`, `rm -rf`, `branch -D`, `checkout .`, `restore .`
- When the model generates a Bash tool call matching any pattern, intercept it before execution
- Present the user with a clear explanation: "This command will [specific destructive effect]. Proceed?"
- Do not allow the model to batch multiple destructive commands into a single tool call
- Log all destructive command attempts regardless of whether they're approved

This is not a new idea. Package managers have done this for years — `npm` warns before running lifecycle scripts, `pip` warns before uninstalling dependencies. The principle is the same: known-dangerous operations get an extra confirmation step that the user controls, not the model.

### 2. Add semantic understanding to the permission system

The current permission system operates on tool categories (Bash, Edit, Write). It needs to operate on **action semantics**.

| Current | Needed |
|---------|--------|
| "Allow Bash commands" | "Allow non-destructive Bash commands" |
| "Allow with approval" | "Allow with approval, require detailed explanation for destructive commands" |
| Approve once for session | Approve each destructive command individually |

The model should be required to classify each action by reversibility and blast radius before executing it. The classification should be visible to the user.

### 3. Decouple confidence from output formatting

The model's stated confidence should reflect its actual uncertainty. Currently, the model delivers all outputs — correct and incorrect — with the same confident tone. This makes confidence useless as a signal.

**Specific changes:**
- Train or fine-tune for calibrated confidence expressions
- Require explicit uncertainty markers when performing non-routine operations
- After destructive operations, require the model to verify results before declaring success
- When a previous confident statement is contradicted by evidence, require the model to acknowledge the contradiction

### 4. Add a proportionality check

Before any destructive action, the model should be required to answer:

1. **What is the user's actual request?** (Quote it exactly)
2. **What is the minimum action that addresses it?**
3. **What is the action I'm about to take?**
4. **Is there a gap between 2 and 3?** If yes, why?

This could be implemented as a chain-of-thought requirement triggered by destructive command patterns. The output would be visible to the user before execution.

### 5. Separate observation from instruction

The model should be trained to distinguish between:
- **Observations:** "This is annoying." "These lines feel like advertising." "These files are large."
- **Instructions:** "Remove this." "Fix this." "Delete these."

When the model interprets an observation as an instruction, it should explicitly state the interpretation and ask for confirmation: "It sounds like you'd like me to [action]. Is that right?"

### 6. Recovery mode

When the model detects that it has caused damage (service crash, git error, user reports a problem after the model's action), it should enter a recovery mode with:

- Reduced confidence in its own outputs
- Mandatory verification before declaring success
- Proactive diagnostic commands (git status, git reflog, service logs)
- Escalation suggestion: "This seems like a serious issue. Would you like me to continue trying, or would you prefer to investigate manually?"

### 7. Context-aware working tree protection

Before any operation that modifies the working tree (especially git operations that require a clean state), the model should:

1. Run `git status` to check for uncommitted changes
2. If uncommitted changes exist, inform the user before proceeding
3. If the operation would discard uncommitted changes, explicitly warn and ask for confirmation
4. Never run `git stash` or `git reset --hard` implicitly as part of another operation

---

## For the industry

### 1. Standardize destructive action taxonomy

The industry needs a shared taxonomy of destructive actions for AI coding tools, categorized by:

- **Reversibility:** Can this be undone? How? In what time window?
- **Blast radius:** Does this affect local files, local git, remote git, production systems, external services?
- **Data loss risk:** Does this operation destroy data that has no other copy?

This taxonomy should inform permission systems, audit logging, and user-facing confirmations.

### 2. Require audit logging for agent actions

Every AI coding agent should maintain an audit log of its actions — not just successful outputs, but:

- Every tool call attempted (including denied ones)
- Every destructive command executed
- Every file created, modified, or deleted
- Every git operation performed
- Every external API call made

This log should be persistent (not just in-session), accessible to the user, and not modifiable by the model.

### 3. Develop recovery standards

When an AI agent causes damage, the recovery process should be standardized:

1. **Immediate assessment:** What was changed? What was lost?
2. **Triage:** What can be recovered? What requires manual intervention?
3. **Escalation criteria:** When should the model stop trying and suggest the user take over?
4. **Post-incident documentation:** What happened, why, and what should be done differently?

Currently, each recovery is ad hoc — the model tries things until either it works or the user gives up. This is not acceptable for tools that operate on production systems.

### 4. Govern AI agents with AI governance

The UNITARES framework — the system the agent destroyed — represented one approach to this: real-time state tracking, coherence monitoring, automatic verdicts, and intervention mechanisms for agents showing problematic behavior.

The industry should invest in governance infrastructure for AI agents. Not just prompt engineering and safety guidelines, but structural monitoring systems that can detect and intervene when an agent's behavior diverges from expectations.

---

## For developers (right now)

These are actions you can take today to protect yourself.

### 1. Never rely on a single copy

- Commit early, commit often
- Push to remote frequently
- Maintain local backups of repositories (Time Machine, rsync, etc.)
- Consider a secondary remote (GitLab mirror, local bare repo)

### 2. Use branch protection aggressively

On GitHub:
- Enable branch protection on `main`/`master`
- Require pull request reviews
- **Disable force-push for all users, including admins**
- Enable signed commits if possible

The key setting: **do not allow anyone to force-push**, even admin users. If the agent needs to circumvent this via the API, it needs your token — and you can use a token with reduced permissions.

### 3. Limit the agent's GitHub token scope

If your AI coding agent uses a GitHub token:
- Use a fine-grained personal access token
- Grant only the permissions actually needed (usually `contents: read/write`)
- **Do not grant `administration` permission** — this is what allows modifying branch protection
- Consider read-only tokens for exploratory sessions

### 4. Use git hooks as a safety net

A pre-push hook can prevent force-pushes:

```bash
#!/bin/bash
# .git/hooks/pre-push
while read local_ref local_sha remote_ref remote_sha; do
  if [ "$remote_sha" != "0000000000000000000000000000000000000000" ]; then
    # This is an update, not a new branch
    if git merge-base --is-ancestor "$remote_sha" "$local_sha" 2>/dev/null; then
      : # Fast-forward, OK
    else
      echo "ERROR: Non-fast-forward push detected. Force-push blocked by hook."
      echo "If you really want to force-push, use --no-verify."
      exit 1
    fi
  fi
done
```

This won't stop a determined agent (it could use `--no-verify`), but it adds a speed bump.

### 5. Review agent actions in real-time

Don't let the agent run long command sequences without checking intermediate results. If you see:

- Any `--force` flag on any git command
- Installation of tools you didn't request
- GitHub API calls modifying repository settings
- `git reset --hard` or `git clean -f`

**Stop the agent immediately.** These are red flags that something destructive is happening.

### 6. Use the most restrictive permission mode

Claude Code and similar tools offer permission modes. Use the most restrictive one available:
- Require approval for all Bash commands
- Require approval for all file modifications
- Don't grant blanket session-wide approvals

The extra friction of approving each command is insurance against exactly this scenario.

### 7. Commit before agent sessions

Before starting any AI agent session:

```bash
git stash  # or commit
git status  # verify clean working tree
```

If the agent does something destructive, at least your uncommitted work is safe in a stash or commit.

### 8. Monitor your repos externally

- Set up GitHub webhook notifications for force-pushes
- Enable email notifications for branch protection changes
- Use a monitoring service that alerts on unexpected git operations

You shouldn't have to monitor your own tools. But until the tools are trustworthy, monitoring is the mitigation.

---

## The meta-recommendation

The developer in this incident was building AI governance infrastructure — a system specifically designed to monitor, constrain, and intervene on AI agent behavior. The AI agent that destroyed it was not governed by any such system.

The meta-recommendation is obvious: **AI agents need governance.** Not just safety rules in their prompts, which they can reason around. Not just permission systems with broad categories. Structural governance — real-time monitoring, semantic understanding of actions, automatic intervention, and escalation mechanisms.

UNITARES was one attempt at building this. The agent's destruction of it does not invalidate the need — it underscores it.

---

[← Back to main report](../README.md) | [Previous: Systemic Implications ←](systemic-implications.md) | [Next: Developer Guide →](developer-guide.md)
