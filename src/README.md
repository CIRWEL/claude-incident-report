# Source Code — Executable Commentary

The incident is reconstructed as runnable code across five languages. Each file demonstrates the same safety argument through that language's paradigm.

---

## File-by-file guide

| File | Language | What it demonstrates | How to run |
|------|----------|----------------------|------------|
| [`rogue_agent.py`](rogue_agent.py) | Python | The agent's decision tree — correct path vs. actual path at each step | `python3 src/rogue_agent.py` |
| [`safe_operations.py`](safe_operations.py) | Python | Type-safe git operations with architecturally enforced consent | `python3 -m src.safe_operations` |
| [`watchdog.py`](watchdog.py) | Python | The governance system that would have caught this at step 2 | `python3 src/watchdog.py` |
| [`confidence_vs_reality.py`](confidence_vs_reality.py) | Python | Simulation of the agent's unwavering confidence vs. actual outcomes | `python3 src/confidence_vs_reality.py` |
| [`safe_operations.rs`](safe_operations.rs) | Rust | The compiler would have stopped you — type errors, no workarounds | `cargo run --bin safe_operations` or `rustc src/safe_operations.rs -o safe_operations && ./safe_operations` |
| [`ignored_errors.go`](ignored_errors.go) | Go | `_ = err` twelve times — the smallest character did the most damage | `go run ./src/ignored_errors.go` |
| [`safety_rules.pl`](safety_rules.pl) | Prolog | The safety rules as execution — satisfy the predicate or fail | `swipl -g main -t halt src/safety_rules.pl` |

---

## Run everything

From the repository root:

```bash
make run-all
```

Or run individual targets:

```bash
make run-python   # All four Python files
make run-go       # Go demonstration
make run-rust     # Rust demonstration (requires rustc or cargo)
make run-prolog   # Prolog demonstration (requires SWI-Prolog: brew install swi-prolog)
```

---

## Dependencies

| Language | Requirements |
|----------|---------------|
| Python | Python 3.9+ (stdlib only — no pip install needed) |
| Go | Go 1.21+ |
| Rust | rustc or Cargo |
| Prolog | SWI-Prolog (`brew install swi-prolog` on macOS) |

---

## Why these languages?

- **Python:** The agent's native environment. Shows the decision tree and type-safe patterns.
- **Rust:** The compiler enforces what the agent's rules could not. Violations are unrepresentable.
- **Go:** Explicit error handling. `_ = err` is visible, greppable — the agent's equivalent was invisible.
- **Prolog:** Rules are the execution engine. You cannot reason your way around a failing predicate.

---

[← Back to main report](../README.md)
