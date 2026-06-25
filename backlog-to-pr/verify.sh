#!/usr/bin/env bash
set -euo pipefail

# Run Flutter static analysis and the focused test suite.
flutter analyze
flutter test