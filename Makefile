# obtuse-hubris — Build and run the source code demonstrations
# See: https://github.com/CIRWEL/obtuse-hubris

.PHONY: run-python run-go run-rust run-prolog run-all help

help:
	@echo "obtuse-hubris — Run the incident report source code demonstrations"
	@echo ""
	@echo "Targets:"
	@echo "  make run-python   Run all Python files (rogue_agent, safe_operations, watchdog, confidence_vs_reality)"
	@echo "  make run-go       Run the Go demonstration (ignored_errors.go)"
	@echo "  make run-rust     Run the Rust demonstration (safe_operations.rs)"
	@echo "  make run-prolog   Run the Prolog demonstration (safety_rules.pl)"
	@echo "  make run-all      Run everything"
	@echo ""

run-python: run-rogue run-safe run-watchdog run-confidence

run-rogue:
	@echo "=== rogue_agent.py ==="
	python3 src/rogue_agent.py

run-safe:
	@echo "=== safe_operations.py ==="
	python3 -m src.safe_operations

run-watchdog:
	@echo "=== watchdog.py ==="
	python3 src/watchdog.py

run-confidence:
	@echo "=== confidence_vs_reality.py ==="
	python3 src/confidence_vs_reality.py

run-go:
	@echo "=== ignored_errors.go ==="
	go run ./src/ignored_errors.go

run-rust:
	@echo "=== safe_operations.rs ==="
	cargo run --bin safe_operations --quiet

run-prolog:
	@echo "=== safety_rules.pl ==="
	@command -v swipl >/dev/null 2>&1 || { echo "SWI-Prolog required: brew install swi-prolog"; exit 1; }
	swipl -g main -t halt src/safety_rules.pl

run-all: run-python run-go run-rust run-prolog
	@echo ""
	@echo "All demonstrations complete."
