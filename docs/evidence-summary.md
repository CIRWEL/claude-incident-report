# Evidence Summary

This document catalogues what evidence exists for the incident and what could strengthen the report's credibility.

---

## Current state

The report is internally consistent and technically detailed. Every claim is asserted with precision. What it lacks is **demonstrable artifacts** — things a reader can see, not just read about.

---

## Evidence that would increase credibility

| Artifact | Description | Status |
|----------|-------------|--------|
| **Screenshot: commit graph** | GitHub's commit graph or network view showing the history rewrite (before/after or the "883 commits rewritten" diff) | Not yet added |
| **Screenshot: damaged repos** | Repos in their damaged state — empty or divergent history | Not yet added |
| **git reflog output** | Sanitized `git reflog` showing filter-repo operations and reset | Not yet added |
| **GitHub audit log** | Redacted audit log entries showing branch protection toggled off/on | Not yet added |
| **Conversation excerpts** | Redacted transcript excerpts — the question, the agent's response, the "declared fixed" / "still broken" loop | Not yet added |
| **Terminal logs** | Sanitized terminal output from the destructive sequence | Not yet added |

---

## Why certain evidence may be absent

- **Privacy:** Session transcripts may contain sensitive project details, API keys, or internal architecture.
- **Recovery state:** The repos were eventually restored; pre-restoration screenshots may not have been captured.
- **Single-developer context:** No incident response team was documenting in real time.
- **GitHub retention:** Audit logs and unreachable objects have retention windows; evidence may have aged out.

---

## Invitation to contribute

If you have experienced a similar incident with an AI coding tool and have artifacts you can share (redacted screenshots, logs, transcripts), see [CONTRIBUTING.md](../CONTRIBUTING.md). Even a single verifiable artifact would strengthen the collective case for tool-level safety enforcement.

---

## What we have

- Detailed technical reconstruction (see [Technical Forensics](technical-forensics.md))
- Executable source code demonstrating the safety argument across five languages
- Git hooks that block the specific techniques used in this incident
- Internal consistency: every claim cross-references specific rules, commands, and outcomes

The report makes strong claims. The main gap is evidence a skeptic can independently verify. This document exists to acknowledge that gap and to invite contributions that would close it.

---

[← Back to main report](../README.md)
