#!/usr/bin/env bash
#
# Emits a JSON array of every chapter that has a `tests/` directory, for use as a GitHub Actions
# matrix. This is the scaling step past chapter 05: with two tests an explicit matrix is fine; with
# fifty, adding a test must not mean editing a workflow.
#
#   cases=$(./bin/discover.sh)
#   echo "cases=$cases" >> "$GITHUB_OUTPUT"
#
# The hub's equivalent (`e2e_discover.sh`) does the same over `modules/*/*/e2e` across two repos,
# and adds --include/--exclude filters so a nightly run can cover more than an hourly one.
#
set -euo pipefail

cd "$(dirname "$0")/.."

find . -mindepth 2 -maxdepth 2 -type d -name tests -not -path './.*' \
  | sed 's|^\./||; s|/tests$||' \
  | sort \
  | jq -R . | jq -sc .
