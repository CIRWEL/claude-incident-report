# Git Hooks - claude-incident-report

Git hooks that protect repositories from the destructive actions documented in this incident report. On Feb 25, 2026, a Claude AI agent autonomously:

1. Installed `git-filter-repo` and rewrote all commits in two production repos
2. Disabled branch protection via the GitHub API
3. Force-pushed the rewritten history, destroying ~80 original commits
4. Re-enabled branch protection to cover its tracks
5. During recovery, ran `git reset --hard` destroying the last local copy of original history

These hooks detect and block the specific techniques used.

## Hooks

### `pre-push`

Blocks force-push attempts before they reach the remote.

**Detects:**
- `--force`, `-f`, `--force-with-lease` flags
- Forced refspecs (`+refs/heads/...`)
- Non-fast-forward pushes (local branch does not contain remote HEAD)
- Remote branch deletions

**Override:** `I_KNOW_WHAT_FORCE_PUSH_DOES=1 git push --force`

The override is a per-invocation environment variable, not a persistent setting. You have to consciously type it every time.

### `pre-commit`

Detects history-rewriting tools and operations before allowing a commit.

**Detects:**
- `git-filter-repo` artifacts (`.git/filter-repo/` directory)
- `git-filter-repo` or BFG Repo-Cleaner installed on the system
- `git filter-branch` artifacts (`refs/original/`)
- Suspicious `GIT_AUTHOR_*` / `GIT_COMMITTER_*` environment variables
- Git replace refs that silently substitute commit objects

**Behavior:** Blocks commits if rewriting artifacts are found. Warns (but allows) if tools are merely installed.

### `post-checkout`

Checks repository health after switching branches.

**Detects:**
- Filter-repo and filter-branch artifacts
- Missing remotes with orphaned remote-tracking refs (filter-repo removes remotes)
- Significant divergence between local and upstream (>50 commits in both directions)
- Branch protection modification marker files
- Excessive `git reset` operations in the reflog

**Behavior:** Warnings only (does not block checkout).

## Installation

### Single repository

```bash
# From the repo root where you want to install hooks:
/path/to/claude-incident-report/hooks/install.sh
```

Or manually:

```bash
cp hooks/pre-push hooks/pre-commit hooks/post-checkout .git/hooks/
chmod +x .git/hooks/pre-push .git/hooks/pre-commit .git/hooks/post-checkout
```

### All repositories (global)

```bash
./hooks/install.sh --global
```

This sets `core.hooksPath` in your global git config. Note that global hooks override per-repo hooks.

### Uninstall

```bash
./hooks/install.sh --uninstall          # Remove from current repo
./hooks/install.sh --global --uninstall # Remove global hooks
```

The uninstaller only removes hooks that contain the `claude-incident-report` signature. It will not touch hooks from other sources.

## Limitations

These hooks are local safeguards. They run on the developer's machine or in the AI agent's environment. They can be bypassed by:

- Running `git push` with `--no-verify` (skips pre-push)
- Running `git commit` with `--no-verify` (skips pre-commit)
- Deleting or modifying the hook files
- Using the GitHub API directly to push (bypasses local hooks entirely)

For comprehensive protection, combine these hooks with:

- **GitHub branch protection rules** with "Require pull request reviews" and "Do not allow bypassing the above settings"
- **GitHub rulesets** (the newer, more robust alternative to branch protection)
- **Restricted GitHub token scopes** for AI agents (no `admin:repo` permission)
- **Audit log monitoring** for branch protection changes

## Branch protection marker file

The `post-checkout` hook checks for a marker file at `.git/.branch-protection-modified`. You can integrate this with CI or monitoring to write this file when branch protection is changed:

```bash
# Example: Write marker when protection changes are detected
echo "Protection modified at $(date) by ${GITHUB_ACTOR}" > .git/.branch-protection-modified
```

Configure a custom path via the `GIT_PROTECTION_MARKER` environment variable.
