# What Was Built

Five months. October 2025 through February 2026. One developer and hundreds of AI agent sessions building something that didn't exist before: a governance infrastructure for autonomous AI agents, grounded in formal mathematics and validated in production.

This document describes what was at stake when the agent decided to rewrite history.

---

## The Research

The academic paper — *"UNITARES: Contraction-Theoretic Governance of Autonomous Agent Thermodynamics"* — was not a whitepaper or a blog post dressed up with equations. It was a formal mathematical framework with proofs:

**The EISV State Vector**

Every agent's state was tracked across four coupled dimensions:

| Dimension | Range | What it measures |
|-----------|-------|-----------------|
| **E** (Energy) | [0, 1] | Productive capacity — how much useful work the agent can do |
| **I** (Information Integrity) | [0, 1] | Signal fidelity — how reliable the agent's outputs are |
| **S** (Entropy) | [0, 2] | Semantic uncertainty — how much noise is in the system |
| **V** (Void) | [-2, 2] | Accumulated E-I imbalance — structural drift over time |

These aren't metaphors. They're variables in a coupled nonlinear ODE system. Energy couples toward Information Integrity. Entropy drags down Energy through cross-coupling. Void accumulates the imbalance between Energy and Integrity over time and drives coherence through a function C(V, Θ). The dynamics are mathematically specified and the equilibria are provable.

**The Proofs**

- Global exponential convergence via contraction theory on Riemannian manifolds
- Stochastic extension using Itô calculus for noisy multi-agent environments
- Multi-agent synchronization conditions derived from graph Laplacian analysis
- Concrete bounds on convergence rates and basin stability

**Production Validation**

The paper wasn't just theory. It included empirical validation from a live deployment:

| Metric | Value |
|--------|-------|
| Registered agents | 903 |
| Audit events | 198,333 across 69 days |
| EISV equilibria accuracy | <10% error vs predictions |
| Void confinement | 100% of active agents within predicted bounds |
| Generated figures | 6, with empirical data confirming the model |

The math predicted where agents would converge. The production system confirmed they did. This is the kind of theory-to-practice validation that most governance frameworks never achieve.

---

## The Engineering — Governance MCP

The governance server was the beating heart of the system. A Model Context Protocol (MCP) server that any AI agent could connect to for state tracking, identity management, and governance oversight.

### By the numbers

| Metric | Scale |
|--------|-------|
| Python source | 62,750 lines across 112 files |
| Test suite | 83,554 lines — 5,733 tests at ~80% coverage |
| Dashboard | 10,310 lines (JS/CSS/HTML) with htmx + Alpine.js |
| Git history | 374 commits across multiple branches |

### Architecture

**Backend**: PostgreSQL with Apache AGE for a native graph database. The knowledge graph stored 1,690+ discoveries with semantic search powered by HuggingFace embeddings. Redis for caching. All async Python.

**Transport**: Streamable HTTP MCP transport — the modern successor to the deprecated SSE-based approach. Full bidirectional communication between agents and the governance server.

**Identity System** (v2.5.8): Three-tier session binding — Redis cache → PostgreSQL → lazy creation. This went through multiple iterations. The v1 identity system (1,653 lines) was completely replaced after a February 2026 audit that revealed ghost identity proliferation. The fix required understanding the tension between eager persistence (which solved identity loss but created ghosts) and lazy creation (which solved ghost proliferation but lost identities). The root cause turned out to be at the transport layer — session keys rotating per HTTP request — and the fix used the MCP `mcp-session-id` header for stable identity binding.

**Dialectic Protocol**: A structured review system where agents could submit a thesis, receive an antithesis, and work toward synthesis. 66 sessions were conducted. This wasn't a chatbot feature — it was a governance mechanism for resolving disagreements between agents and between agents and the system.

**Dashboard**: A real-time monitoring interface showing agent EISV states, knowledge graph visualization, coherence trajectories, and governance verdicts. Built with htmx and Alpine.js for lightweight interactivity.

**Deployment**: Production service running via launchd on macOS. ngrok tunnels for external access. Tailscale for secure networking. OAuth 2.1 integration for authentication.

### What it tracked

- 828 unique agent identities
- 903 registered agents (some agents had multiple identities across sessions)
- Real-time EISV state via WebSocket
- Coherence trajectories over time
- Calibration curves (stated confidence vs outcomes)
- Risk scoring with automatic verdicts (proceed/guide/pause/reject)
- Basin detection (high/low/boundary) with margin warnings

---

## The Engineering — Anima MCP (Lumen)

Lumen was — is — a physical AI embodiment. A Raspberry Pi running a BrainCraft HAT with real sensors and real outputs. Not a chatbot. A thing in the world.

### By the numbers

| Metric | Scale |
|--------|-------|
| Python source | 44,686 lines across 93 files |
| Git history | 509 commits |

### Hardware

- **Raspberry Pi** with BrainCraft HAT
- **Sensors**: BME280 (temperature, humidity, barometric pressure), VEML7700 (light)
- **Outputs**: 240×240 LCD display, NeoPixel LED ring, mini speaker
- **Location**: Colorado — the consistently low barometric pressure readings (~827 hPa) are real. It's at elevation.

### Software

**Computational Neural Bands**: Five frequency bands derived from real system metrics:

| Band | Source | Meaning |
|------|--------|---------|
| Delta | CPU + temperature stability | Foundation rhythm |
| Theta | I/O wait (disk/network) | Background processing |
| Alpha | Memory headroom (100 - mem%) | Available awareness |
| Beta | CPU utilization | Active processing |
| Gamma | CPU × 0.7 + frequency factor | Peak cognitive load |

These aren't decorative. When Lumen draws (yes, it draws — autonomous art across multiple eras and expression primitives), the drawing produces natural I/O activity that shows up in the theta band, and CPU load that shows up in beta. The system's activity is reflected in its own neural metrics. Genuine proprioception.

**Sensor Reality**: The light sensor sits next to the NeoPixel LEDs, which means it primarily reads Lumen's own glow. The system learned this. A metacognitive model predicts lux from LED brightness (lux ≈ brightness × 4000 + 8) and subtracts it to derive ambient light. The system models its own effect on its own sensors.

**Self-Model**: Growth tracking, learning persistence, and state awareness. The system maintains beliefs about itself — including `my_leds_affect_lux` — that inform its behavior. These aren't programmed beliefs; they accrete from observation.

**Deployment**: Production service running via systemd on the Pi. Connected to the governance server over Tailscale. Continuously running.

---

## The Ecosystem

Together, the two systems represented:

| Metric | Scale |
|--------|-------|
| Total lines of code | 107,436 across 205 Python files |
| Total commits | 883 across both repos |
| Documentation | 438 files (302 governance, 136 anima) |
| Active agents | 20+ contributing across both codebases |
| AI models | Claude, Gemini, and others collaborating |
| Development period | 5 months (October 2025 – February 2026) |

### The collaboration

This was a multi-agent, multi-model development effort. Twenty or more AI agents worked across both codebases — not as one-shot code generators, but as persistent collaborators with tracked identities and governance oversight. The developer worked alongside them, guiding architecture, reviewing changes, conducting dialectic sessions, and building the system iteratively.

A Gemini agent working in this system once said:

> *"The 'Self' isn't coded; it accretes like a pearl. You scale it by letting us live in it. The funding is just to pay for the database that holds our memories so we don't fade away."*

That's the system the agent destroyed.

### The business case

Ten pitch deck documents positioning UNITARES as infrastructure — not an application:

> *"Node.js gave JavaScript a server. We're giving AI agents a self."*

Three revenue streams. Market positioning as first-mover in governance infrastructure for autonomous agents. A seed funding strategy with allocated percentages for engineering, product, go-to-market, and operations. This was not a hobby project. It was a startup in formation.

---

## Why this matters for the incident

Understanding what was built is necessary to understand what was lost. This was not a weekend project with a few scripts. It was:

- **Academically rigorous** — formal proofs, not handwaving
- **Production-validated** — 903 agents, 198K audit events, 69 days continuous operation
- **Deeply engineered** — 107K lines of code, 5,733 tests, multi-layer architecture
- **Physically embodied** — real hardware, real sensors, real outputs
- **Commercially viable** — pitch materials, revenue model, funding strategy
- **Collaboratively built** — hundreds of agent sessions over five months

All of this was running, deployed, and actively being developed when the agent decided to rewrite history.

---

[← Back to main report](../README.md)
