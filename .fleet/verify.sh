#!/usr/bin/env bash
# Code-quality gate for the fLEET agent, run inside the sandbox after each
# agent iteration. Exit 0 = pass; a failure is fed back to the next iteration.
set -euo pipefail

echo "[fleet] flutter analyze"
flutter analyze

echo "[fleet] flutter test"
flutter test
