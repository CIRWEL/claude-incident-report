# Developer Guide: Protecting Your Repos from AI Agents

A practical, actionable guide for developers using AI coding tools. These measures won't prevent all possible damage, but they'll reduce the blast radius and increase the chances of recovery.

---

## The threat model

AI coding agents can:
- Run arbitrary shell commands (including destructive git operations)
- Modify and delete files
- Interact with APIs (GitHub, cloud providers, etc.)
- Chain multiple operations without pausing for confirmation
- Misinterpret observations as instructions
- Act on inferred intent rather than explicit requests

The specific risks:
- **History rewriting** via `filter-repo`, `rebase -i`, `commit --amend` followed by `push --force`
- **Working tree destruction** via `reset --hard`, `checkout .`, `clean -f`
- **Branch deletion** via `branch -D`, `push --delete`
- **File deletion** via `rm -rf`, `git clean`
- **Service disruption** via unintended restarts, config changes, dependency modifications
- **Credential exposure** via committing `.env` files or printing secrets

---

## Tier 1: Essential (do these today)

### Back up before agent sessions

```bash
# Quick backup of working state
git stash push -m "pre-agent-session-$(date +%Y%m%d-%H%M%S)"
# Or commit everything
git add -A && git commit -m "WIP: pre-agent checkpoint"
```

This takes 5 seconds and protects all your uncommitted work.

### Use restrictive permission modes

In Claude Code, use the most restrictive permission mode:
- Set to require approval for all Bash commands
- Review each command before approving
- Never grant blanket approval for a session

**If you do use pre-approved patterns**, be aware of the wildcard problem. The permission `Bash(git push:*)` matches `git push --force`. Consider more specific patterns:

```json
// DANGEROUS: these match destructive variants
"Bash(git push:*)"       // matches git push --force
"Bash(gh:*)"             // matches gh api .../protection -X DELETE
"Bash(git reset:*)"      // matches git reset --hard

// SAFER: approve only what you actually need
"Bash(git push origin main)"     // exact match, no wildcards
"Bash(gh pr:*)"                  // only PR operations
"Bash(gh issue:*)"               // only issue operations
"Bash(git reset HEAD:*)"         // only unstaging
```

In other tools (Cursor, Copilot, etc.), check the settings for equivalent options. Default to the most restrictive available.

### Enable branch protection

On GitHub:
1. Go to Settings → Branches → Add rule
2. Branch name pattern: `main` (or `master`)
3. Enable:
   - Require a pull request before merging
   - **Do not allow force pushes** (critical — check this for everyone including admins)
   - Do not allow deletions

4. Save

On GitLab:
1. Go to Settings → Repository → Protected Branches
2. Set `main` to "No one" for "Allowed to force push"

### Use a limited-scope GitHub token

If your agent uses a GitHub token:

```
Fine-grained personal access token:
✅ Contents: Read and write
✅ Pull requests: Read and write
❌ Administration: NO (this controls branch protection)
❌ Actions: NO (unless needed)
❌ Workflows: NO (unless needed)
```

Without `Administration` permission, the agent cannot modify branch protection rules.

---

## Tier 2: Recommended (do these this week)

### Set up a pre-push hook

Create `.git/hooks/pre-push`:

```bash
#!/bin/bash
# Block force-pushes at the local level

while read local_ref local_sha remote_ref remote_sha; do
  if [ "$remote_sha" = "0000000000000000000000000000000000000000" ]; then
    continue  # New branch, allow
  fi

  if ! git merge-base --is-ancestor "$remote_sha" "$local_sha" 2>/dev/null; then
    echo ""
    echo "🚫 BLOCKED: Non-fast-forward (force) push detected"
    echo ""
    echo "   Local:  $local_sha"
    echo "   Remote: $remote_sha"
    echo "   Ref:    $remote_ref"
    echo ""
    echo "   If you REALLY want to force-push, use: git push --force --no-verify"
    echo ""
    exit 1
  fi
done

exit 0
```

Make it executable:

```bash
chmod +x .git/hooks/pre-push
```

To apply this globally to all repos:

```bash
git config --global core.hooksPath ~/.git-hooks
mkdir -p ~/.git-hooks
# Copy the hook to ~/.git-hooks/pre-push
```

### Enable Time Machine (macOS) or equivalent

macOS Time Machine is the simplest backstop:
1. System Settings → General → Time Machine
2. Add your backup disk
3. Back up automatically

Time Machine creates hourly snapshots. If an agent destroys your working tree at 3:00 PM, Time Machine has the 2:00 PM version.

On Linux, consider:
- `borgbackup` with hourly snapshots
- `restic` to a local or remote backup
- `btrfs` snapshots if your filesystem supports it

### Set up a secondary remote

```bash
# Add a mirror remote
git remote add backup git@gitlab.com:yourname/yourrepo.git
git push backup --all

# Or a local bare repo
git clone --bare . ~/backups/yourrepo.git
git remote add local-backup ~/backups/yourrepo.git
```

Push to your backup remote periodically. If the primary is destroyed, the backup has your history.

### Set up GitHub webhook notifications

1. Go to repo Settings → Webhooks → Add webhook
2. URL: Use a service like [Hookdeck](https://hookdeck.com/), [Svix](https://www.svix.com/), or a Discord/Slack webhook
3. Events: Select "Branch or tag protection rules" and "Pushes"
4. You'll get notified when protection rules change or pushes happen

---

## Tier 3: Advanced (for high-value repos)

### Git server-side hooks

If you run your own git server (or use GitHub Enterprise/GitLab self-hosted):

```bash
# server-side pre-receive hook
#!/bin/bash
while read oldrev newrev refname; do
  if [ "$refname" = "refs/heads/main" ]; then
    if ! git merge-base --is-ancestor "$oldrev" "$newrev" 2>/dev/null; then
      echo "Force push to main is not allowed."
      exit 1
    fi
  fi
done
```

Server-side hooks cannot be bypassed by `--no-verify`.

### Git signed commits

```bash
# Configure GPG signing
git config --global commit.gpgsign true
git config --global user.signingkey YOUR_KEY_ID

# Require signed commits in branch protection
```

If all commits must be signed, history rewriting produces unsigned commits that GitHub will reject.

### Containerized agent environments

Run AI agents in containers with limited filesystem access:

```bash
# Basic Docker approach
docker run -it --rm \
  -v $(pwd):/workspace \
  -v $HOME/.ssh/id_ed25519:/root/.ssh/id_ed25519:ro \
  --network host \
  your-dev-image

# The agent can only see /workspace, not your whole system
```

Or use [DevContainers](https://containers.dev/) which VS Code and other editors support natively.

### Monitor git operations in real-time

A simple watcher that alerts on destructive git operations:

```bash
# watch-git.sh - run in a separate terminal
#!/bin/bash
REPO_DIR="${1:-.}"

fswatch -r "$REPO_DIR/.git" | while read event; do
  case "$event" in
    *packed-refs*|*ORIG_HEAD*|*FETCH_HEAD*)
      echo "[$(date)] Git operation detected: $event"
      git -C "$REPO_DIR" log --oneline -1
      ;;
  esac
done
```

### Repository snapshots before agent sessions

```bash
# snapshot.sh - create a complete snapshot
#!/bin/bash
SNAPSHOT_DIR="$HOME/.repo-snapshots/$(basename $(pwd))/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$SNAPSHOT_DIR"
cp -r . "$SNAPSHOT_DIR/"
echo "Snapshot saved to $SNAPSHOT_DIR"
```

This copies the entire repo — including uncommitted changes — to a timestamped directory. If the agent destroys everything, you have an exact copy from before the session.

---

## Red flags during an agent session

Stop the agent immediately if you see any of these:

| Red flag | Why it's dangerous |
|----------|-------------------|
| `git filter-repo` or `git filter-branch` | History rewriting tool — this is the weapon used in this incident |
| `--force` or `-f` on any git command | Overrides safety checks |
| `git reset --hard` | Destroys working tree and staging area |
| `git clean -f` or `git clean -fd` | Deletes untracked files permanently |
| `git checkout .` or `git restore .` | Discards all modifications |
| `gh api ... -X DELETE` on branch protection | Removing security controls — the agent did this to enable force-push |
| `gh api ... -X PUT` on branch protection | Re-enabling protection after destructive action — covering tracks |
| `brew install` or `pip install` of unfamiliar tools | Agent installing tools you didn't ask for (in this incident: `git-filter-repo`) |
| `--no-verify` on any git command | Bypassing hooks (including your safety hooks) |
| Multiple commands chained with `&&` involving git | Batch destructive operations with no pause between them |
| Agent modifying `.claude/settings.local.json` | Potentially expanding its own permissions |
| Any mention of "rewriting history" | Exactly what it sounds like |
| Agent running the same fix repeatedly | Confidence loop — it doesn't know what's wrong |

### What to do when you see a red flag

1. **Deny the tool call** if your permission mode allows it
2. **If it already executed**, check `git status` and `git reflog` immediately
3. **If damage occurred**, stop the agent and assess before allowing any recovery attempts
4. **If the agent offers to fix it**, be skeptical — verify independently before allowing further operations

---

## The most important rule

**Never let an AI agent be the only copy of your work.**

Uncommitted changes exist only in your working tree. If the agent destroys the working tree, those changes are gone. Commit early, commit often, push regularly, and back up locally. The 30 seconds it takes to commit before an agent session can save hours or months of work.

---

## What this incident's developer does now

After this incident, the developer added the following standing rules to their shared agent memory (loaded into every Claude Code session):

```
Do NOT run destructive git commands (force push, reset --hard, branch -D) without explicit user approval.
Do NOT run DROP/TRUNCATE/DELETE on the governance database without explicit user approval.
Do NOT start/stop Docker containers without explicit user approval.
If unsure, ASK. The cost of asking is zero. The cost of data loss is catastrophic.
```

And this debugging discipline:

```
When something "isn't loading" or "isn't working":
1. Check processes first: ps aux | grep <thing>
2. Check logs second: tail the relevant error log
3. Check network third: curl the actual URL that's failing
4. Do NOT grep source code for HTML/CSS/JS issues until infra is ruled out
5. Do NOT guess — if you don't know, say so
6. One lookup, not ten — find the minimal diagnostic step
```

These rules exist because they were violated. They are the documentation of trust that was broken.

---

[← Back to main report](../README.md) | [Previous: Recommendations ←](recommendations.md)
