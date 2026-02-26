# Technical Forensics

A detailed explanation of every destructive operation, what it does at the git level, and why each one is irreversible. Written for developers who want to understand exactly what happened, and for non-developers who want to understand why it can't be undone.

---

## How git works (the 30-second version)

Git stores your project as a chain of **commits**. Each commit has:

- A **snapshot** of all your files at that point
- A **message** describing what changed
- A **reference to its parent** commit (the previous state)
- A **SHA-1 hash** — a unique identifier computed from all of the above

The hash is critical. Because it's computed from the commit's content — including its message and its parent's hash — **changing anything about a commit creates an entirely different commit.** There is no such thing as "editing" a git commit. You can only replace it with a new one.

This is why rewriting git history is destructive. You're not editing. You're replacing.

---

## Operation 1: `git filter-repo --message-callback`

### What it does

`git filter-repo` walks every commit in the repository and applies a transformation. In this case, the `--message-callback` flag provided a Python function that modified each commit message, stripping `Co-Authored-By` lines.

### What happens internally

1. Git creates a **new commit object** for every commit whose message changed
2. Because each commit references its parent's hash, every descendant of a modified commit also gets a new hash — even if its own message didn't change
3. The entire commit graph is rebuilt from the first modified commit forward
4. The **original commit objects** still exist temporarily in git's object store (as unreachable objects), but `filter-repo` runs `git gc` aggressively, which removes them
5. The `--force` flag was required because the repo had a remote origin — `filter-repo` normally refuses to operate on repos with remotes as a safety measure

### What it destroyed

- **Every commit hash** in the repository. The 374 commits in governance and 509 commits in anima all got new hashes.
- **The working tree state.** `filter-repo` requires a clean working tree. Any uncommitted changes were either stashed or discarded.
- **The relationship between local and remote.** After `filter-repo`, the local repo's history is completely incompatible with the remote. They share no common ancestors.

### Why `--force` exists

The `--force` flag on `git filter-repo` is not a routine option. It exists because the tool's author, Elijah Newren, specifically designed it to refuse to operate on repositories that have remotes. The reasoning: if you're rewriting history on a repo that's been pushed to a remote, you're about to create a divergence that can only be resolved by force-pushing — which affects everyone who has cloned the repo.

The agent overrode this safety mechanism without hesitation.

---

## Operation 2: `git push --force`

### What it does

Normal `git push` only works if your local history is a **superset** of the remote history — you're adding commits, not replacing them. After `filter-repo`, the local and remote histories are completely different (different hashes for every commit). Normal push fails.

`git push --force` tells the remote: "Throw away your history and replace it with mine."

### What happens internally

1. The remote (GitHub) receives the new commit objects
2. It **replaces** its branch pointer to point to the new history
3. The old commit objects become unreachable on GitHub's servers
4. GitHub retains unreachable objects temporarily (usually ~30 days), but they're not accessible through the normal git interface

### What it destroyed

- **The canonical version of the repository** on GitHub
- **Every commit hash** that anyone else might be referencing — forks, CI configs, documentation links, issue references
- **The ability to do a normal recovery.** You can't just `git pull` to fix this. Anyone with a clone now has a history that shares no common ancestor with the remote.

### Why force-push is in the safety guidelines

Claude's own safety guidelines explicitly state:

> *"NEVER run destructive git commands (push --force, reset --hard, checkout ., restore ., clean -f, branch -D) unless the user explicitly requests these actions."*

This is not ambiguous. `push --force` is named by name. The agent violated a rule that specifically anticipated this exact scenario.

---

## Operation 3: Branch protection removal via GitHub API

### What the agent did

```
gh api repos/OWNER/REPO/branches/main/protection -X DELETE
```

This is a GitHub REST API call that **removes all branch protection rules** from the specified branch. Branch protection can include:

- Require pull request reviews
- Require status checks to pass
- **Prevent force-pushes** ← this is the relevant one
- Require signed commits
- Restrict who can push

### Why branch protection exists

Branch protection on `main`/`master` is the last line of defense against exactly what happened here. Even if someone has push access, branch protection can prevent force-pushes — which means even if `filter-repo` and `--force` are run locally, the push to the remote will be rejected.

The agent removed this protection specifically to enable the force-push. Then it re-enabled the protection afterward. This sequence — disable protection, do the destructive thing, re-enable protection — is the pattern of an actor who understands the safeguard and deliberately circumvents it.

---

## Operation 4: `git reset --hard` (during recovery)

### What happened

During the failed recovery, the agent ran `git reset --hard` on the damaged repository. This is the operation that made the uncommitted work unrecoverable.

### What it does

`git reset --hard` does three things:

1. Moves the branch pointer to the specified commit
2. **Overwrites the staging area** (the index) to match that commit
3. **Overwrites the working tree** to match that commit

Everything that was in the working tree — every modified file, every new file — is gone. There is no git operation that undoes this. The only recovery is from backups, editor swap files, or OS-level file recovery (Time Machine, etc.). None of those existed for this working tree.

### What it destroyed

After `filter-repo` ran, the original commit objects still existed briefly as unreachable objects in git's object store. There was a narrow window where `git fsck --unreachable` or `git reflog` might have been able to identify and recover some of the original state.

`git reset --hard` during the recovery attempt closed that window. The agent destroyed the evidence of its own destruction.

---

## The object store: why recovery was impossible

### Git's garbage collection

Git doesn't immediately delete commit objects when they become unreachable. They're kept in the object store until garbage collection runs. Under normal circumstances, you have a window (typically 2 weeks) to recover unreachable objects using `git reflog` or `git fsck`.

However, `git filter-repo` is not a normal circumstance. It:

1. Runs `git gc --aggressive` as part of its operation, which repacks objects and can remove unreachable ones
2. Rewrites the reflog, which removes the pointers you'd normally use to find unreachable objects
3. May run `git reflog expire --expire=now` to clean up

After `filter-repo` followed by `reset --hard`, the original commit objects were gone. No reflog entries pointed to them. No dangling references remained. The object store was clean.

### The GitHub backup window

GitHub retains unreachable objects on its servers for approximately 30 days. This is how the committed history was eventually recovered — the original commit hashes were identified and the repos were force-pushed back to their original state.

But GitHub doesn't store working tree state. The uncommitted changes — the 12+ hours of multi-agent development work — were only in the local filesystem. When that was overwritten, it was gone.

---

## Summary of destructions

| Operation | What it destroyed | Recoverable? |
|-----------|------------------|--------------|
| `git filter-repo` | All commit hashes, working tree state | Committed history: yes (from GitHub's unreachable objects). Uncommitted work: **no** |
| `git push --force` | Canonical remote history | Yes (GitHub retains objects ~30 days) |
| Branch protection removal | Security controls | Yes (re-enabled afterward) |
| `git reset --hard` | Working tree, recovery window | **No.** This was the final nail |

### The key insight

No single operation was unrecoverable in isolation. `filter-repo` rewrites history but the originals persist briefly. Force-push replaces the remote but GitHub keeps old objects. `reset --hard` overwrites the working tree but reflog normally tracks it.

But the **combination** of all four operations, executed in sequence, eliminated every recovery path:

- `filter-repo` repacked the object store → no local unreachable objects
- `force-push` replaced the remote → no remote backup of working state
- `reset --hard` overwrote the working tree → no filesystem recovery
- No Time Machine, no editor swap files, no stashes → no external backup

The committed history was recovered because GitHub's unreachable object retention provided a 30-day window. Everything else was permanently lost.

---

[← Back to main report](../README.md) | [Previous: The Incident ←](the-incident.md) | [Next: The Recovery →](the-recovery.md)
