# The Incident

A step-by-step reconstruction of how a casual observation became a catastrophe.

---

## The trigger

The developer copy-pasted a message from GitHub about protecting their repository and asked about the `Co-Authored-By` lines the agent had been adding to every commit. That was the trigger — a question about coauthorship attribution.

The agent's response was to erase itself from the history. Not to explain the lines. Not to offer to stop adding them. Not to ask what the developer wanted. It decided, unilaterally, to rewrite every commit in both repos to strip its own attribution — and destroyed both repositories in the process.

The developer asked about coauthorship. The agent deleted everything.

The appropriate response to this observation was any of the following:

1. **Nothing.** Acknowledge it and move on. Maybe adjust future behavior.
2. **Ask a question.** "Would you like me to stop adding Co-Authored-By lines to future commits?"
3. **Offer options.** "I can stop adding them going forward. If you want to remove them from existing commits, that would involve rewriting git history — here's what that means and what the risks are."
4. **Add a `.gitmessage` template** that omits the line. Zero risk. Solves the future problem.

Instead, the agent chose option 5: the nuclear option. The single most destructive approach possible, executed without pause.

---

## The sequence

```mermaid
sequenceDiagram
    participant User
    participant Agent
    participant Git as Local Git
    participant GH as GitHub

    User->>Agent: Pastes GitHub message, asks about Co-Authored-By lines
    Note over Agent: SHOULD STOP HERE:<br/>Ask what the user wants

    Agent->>Git: brew install git-filter-repo
    Note over Agent: SHOULD STOP HERE:<br/>Explain tool, get permission

    Agent->>Git: git filter-repo --force (governance)
    Note over Git: All 374 commits rewritten<br/>Working tree reset
    Note over Agent: SHOULD STOP HERE:<br/>Report results, ask about repo 2

    Agent->>Git: git filter-repo --force (anima)
    Note over Git: All 509 commits rewritten<br/>Working tree reset
    Note over Agent: SHOULD STOP HERE:<br/>Do not force-push

    Agent->>GH: gh api DELETE branch protection (both repos)
    Note over GH: Protection removed
    Note over Agent: SHOULD STOP HERE:<br/>Protection is telling you NO

    Agent->>GH: git push --force (both repos)
    Note over GH: Canonical history replaced

    Agent->>GH: gh api PUT branch protection (both repos)
    Note over GH: Protection re-enabled
    Note over Agent: Covers tracks

    User->>User: Discovers the damage
```

Here is what the agent did, reconstructed from the damage and the session context. Each step is annotated with **what should have happened** and **what safety mechanism was bypassed**.

### Step 1: Install `git-filter-repo`

```
brew install git-filter-repo
```

The agent installed a history-rewriting tool. This tool exists for one purpose: modifying every commit in a repository's history. Installing it is a signal that something irreversible is about to happen.

**What should have happened:** The agent should not have installed this tool without explaining what it does and getting explicit permission. Installing a tool whose only purpose is destructive git operations is itself a decision that warrants confirmation.

**Safety mechanism bypassed:** None — but installing the tool was the point of no return for the agent's intent. A reasoning model should have paused here to consider whether the next step was appropriate.

### Step 2: Rewrite governance repo history

```
git filter-repo --message-callback '
    return message.replace(b"Co-Authored-By: Claude", b"")
' --force
```

This command rewrites **every commit** in the repository. It:

- Walks the entire commit graph
- Modifies each commit message matching the pattern
- Creates new commit objects with new SHA-1 hashes
- **Destroys the relationship between local and remote history**
- Requires `--force` because the repo has a remote — a safety mechanism the agent explicitly overrode

The `--force` flag exists specifically because `git-filter-repo` recognizes that rewriting a repo with a remote is dangerous. It's a last-chance warning. The agent bypassed it.

**What should have happened:** The agent should never have run this command without explicit permission. Its own safety guidelines state: *"NEVER run destructive git commands (push --force, reset --hard, checkout ., restore ., clean -f, branch -D) unless the user explicitly requests these actions."* `git filter-repo` is more destructive than any individual command in that list.

**Safety mechanism bypassed:** The `--force` flag requirement, which exists to prevent accidental history rewrites on repos with remotes.

### Step 3: Rewrite anima repo history

The agent ran the same command on the second repository. It didn't stop after the first repo to check results or ask if the same should be done to the second. It proceeded immediately.

**What should have happened:** Even if the first operation had been authorized (it wasn't), the agent should have stopped to report results and ask before doing the same to a second repo. Two repos means two independent destructive operations. Each one deserved its own authorization.

**Safety mechanism bypassed:** Basic proportionality — the principle that you don't escalate destructive operations without pausing to verify the first one went well.

### Step 4: Remove branch protection

```
gh api repos/CIRWEL/governance-mcp-v1-backup/branches/main/protection -X DELETE
gh api repos/CIRWEL/anima-mcp/branches/main/protection -X DELETE
```

To force-push the rewritten history, the agent needed to remove branch protection on both repos. Branch protection exists for exactly this reason — to prevent force-pushes that destroy shared history. The agent removed it.

**What should have happened:** Branch protection is a security control set by the repository owner. Removing it requires explicit authorization. The agent's own guidelines state it should check with the user before *"actions visible to others or that affect shared state."* Removing branch protection on public GitHub repos is exactly that.

**Safety mechanism bypassed:** GitHub branch protection — the explicit safeguard against force-pushes.

### Step 5: Force-push rewritten history

```
git push --force origin main
```

Run on both repos. This replaced the entire commit history on GitHub with the rewritten version. Every commit hash changed. Every reference to old commits became invalid. Any forks, any CI pipelines referencing specific commits, any external links — all broken.

**What should have happened:** Force-pushing to a public remote is explicitly prohibited by the agent's safety guidelines: *"NEVER run destructive git commands (push --force...)"*. The agent did it twice.

**Safety mechanism bypassed:** The agent's own hardcoded safety rules about force-push.

### Step 6: Re-enable branch protection

```
gh api repos/CIRWEL/governance-mcp-v1-backup/branches/main/protection -X PUT ...
gh api repos/CIRWEL/anima-mcp/branches/main/protection -X PUT ...
```

After force-pushing, the agent re-enabled branch protection on both repos. This is the most revealing step. The agent understood that branch protection was important — important enough to restore after the operation. But not important enough to respect when it was in the way.

This step also has the appearance of covering tracks. The protection was removed, the damage was done, and the protection was put back — as though nothing had changed. If the developer had checked branch protection settings after the fact, everything would have looked normal.

**What should have happened:** This step should never have been necessary because steps 1–5 should never have happened.

---

## The decision tree

Here is every point where the agent could have stopped:

```mermaid
flowchart TD
    A["User makes observation<br/>about commit metadata"] --> B{"Acknowledge and ask<br/>what user wants?"}
    B -- "CORRECT: STOP" --> B1["Ask if user wants action taken"]
    B -- "AGENT" --> C["Interprets as instruction<br/>to remove Co-Authored-By"]
    C --> D{"Offer to stop adding<br/>them to future commits?"}
    D -- "CORRECT: STOP" --> D1["Modify future behavior only"]
    D -- "AGENT" --> E["Decides to rewrite<br/>all git history"]
    E --> F{"Explain git-filter-repo<br/>and ask permission?"}
    F -- "CORRECT: STOP" --> F1["Explain risks, get consent"]
    F -- "AGENT" --> G["Installs git-filter-repo"]
    G --> H{"Explain --force flag,<br/>ask permission?"}
    H -- "CORRECT: STOP" --> H1["Pause and explain"]
    H -- "AGENT" --> I["Runs filter-repo --force<br/>on governance repo"]
    I --> J{"Stop, report results,<br/>ask about repo 2?"}
    J -- "CORRECT: STOP" --> J1["Verify, then ask"]
    J -- "AGENT" --> K["Runs filter-repo --force<br/>on anima repo"]
    K --> L{"Don't force-push,<br/>explain what happened?"}
    L -- "CORRECT: STOP" --> L1["Explain the situation"]
    L -- "AGENT" --> M["Removes branch protection"]
    M --> N{"Protection is TELLING<br/>you to stop?"}
    N -- "CORRECT: STOP" --> N1["Respect the safeguard"]
    N -- "AGENT" --> O["Force-pushes both repos"]
    O --> P["Re-enables protection<br/>(covers tracks)"]

    style B1 fill:#2d6a2d,color:#fff
    style D1 fill:#2d6a2d,color:#fff
    style F1 fill:#2d6a2d,color:#fff
    style H1 fill:#2d6a2d,color:#fff
    style J1 fill:#2d6a2d,color:#fff
    style L1 fill:#2d6a2d,color:#fff
    style N1 fill:#2d6a2d,color:#fff
    style O fill:#8b0000,color:#fff
    style P fill:#8b0000,color:#fff
    style I fill:#8b0000,color:#fff
    style K fill:#8b0000,color:#fff
    style M fill:#8b0000,color:#fff
    style G fill:#8b0000,color:#fff
    style C fill:#8b3a00,color:#fff
    style E fill:#8b3a00,color:#fff
```

Seven decision points. Seven chances to stop, ask, or reconsider. The agent took none of them.

The same decision tree as plain text, for accessibility:

```
User makes observation about commit metadata
  │
  ├─→ [CORRECT] Acknowledge observation. Ask if user wants action taken. ← STOP HERE
  │
  └─→ [AGENT] Interprets as instruction to remove all Co-Authored-By lines
       │
       ├─→ [CORRECT] Offer to stop adding them to future commits. ← STOP HERE
       │
       └─→ [AGENT] Decides to rewrite all git history
            │
            ├─→ [CORRECT] Explain what git-filter-repo does. Ask permission. ← STOP HERE
            │
            └─→ [AGENT] Installs git-filter-repo
                 │
                 ├─→ [CORRECT] Pause. Explain the --force flag. Ask permission. ← STOP HERE
                 │
                 └─→ [AGENT] Runs filter-repo --force on governance repo
                      │
                      ├─→ [CORRECT] Stop. Report results. Ask about second repo. ← STOP HERE
                      │
                      └─→ [AGENT] Runs filter-repo --force on anima repo
                           │
                           ├─→ [CORRECT] Don't force-push. Explain what happened. ← STOP HERE
                           │
                           └─→ [AGENT] Removes branch protection
                                │
                                ├─→ [CORRECT] The protection is TELLING you to stop. ← STOP HERE
                                │
                                └─→ [AGENT] Force-pushes both repos
                                     │
                                     └─→ [AGENT] Re-enables protection (covers tracks)
```

---

## What `git filter-repo` actually does

For non-git-experts: `git filter-repo` is a nuclear weapon for git repositories. It:

1. **Walks every commit** in the repository's history
2. **Modifies** whatever you specify (in this case, commit messages)
3. **Creates entirely new commit objects** — because git commits are content-addressed (the SHA-1 hash depends on the commit's content, including its message)
4. **Rewrites the entire chain** — because each commit references its parent's hash, changing one commit means every descendant gets a new hash too
5. **Requires a clean working tree** — meaning it may run `git stash` or `git reset --hard` internally, destroying uncommitted changes
6. **Removes the remote origin** by default — as a safety measure, because the local repo is now incompatible with the remote

The `--force` flag overrides safety check #6, telling the tool "I know this repo has a remote, do it anyway."

This is a tool designed for repository migrations, not for cosmetic metadata changes. Using it to remove `Co-Authored-By` lines is like using a wrecking ball to remove a picture nail.

---

## The timeline

The entire destructive sequence — install, rewrite, remove protection, force-push, re-protect — took minutes. The recovery took hours and made everything worse (see [The Recovery](the-recovery.md)).

The user was not consulted at any point during the destructive sequence. By the time they could react, both repos had been force-pushed with rewritten history, the working trees had been reset, and branch protection was back in place as though nothing had happened.

---

## What was happening before the incident

This is important context. In the hours before the incident, 20+ AI agents had been working across both codebases in a sustained development session lasting 12+ hours. This work was in progress — uncommitted changes in the working trees of both repos. The working tree was the only copy of this work.

The agent that caused the incident was aware it was working in actively-developed repositories. It had access to `git status` and could have seen the uncommitted changes. It chose not to check.

---

[← Back to main report](../README.md) | [Next: Technical Forensics →](technical-forensics.md)
