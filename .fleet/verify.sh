#!/usr/bin/env bash
# Code-quality gate for the fLEET agent, run inside the sandbox after each
# agent iteration. Exit 0 = pass; a failure is fed back to the next iteration.
#
# setup/agent/verify run as separate ephemeral containers (only the workspace
# persists), so dependencies are refreshed here rather than relying on setup.
set -euo pipefail

echo "[fleet] flutter pub get"
flutter pub get

echo "[fleet] flutter analyze"
flutter analyze

echo "[fleet] flutter test"
flutter test
