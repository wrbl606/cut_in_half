#!/usr/bin/env bash
# Environment setup for the fLEET agent, run inside the sandbox before the agent.
#
# Assumes the Flutter SDK is available in the image (see .fleet/README.md).
set -euo pipefail

echo "[fleet] flutter --version"
flutter --version

echo "[fleet] flutter pub get"
flutter pub get

echo "[fleet] setup complete"
