#!/usr/bin/env bash
# Runs only in the owned, trusted Buildkite hosted fixture.
set -euo pipefail
test "${BUILDKITE:-}" = true
test "$BUILDKITE_ORGANIZATION_SLUG" = sj26-testier
test "$BUILDKITE_AGENT_META_DATA_QUEUE" = linux-small
: "${DEMO_JIT_SECRET:?Set the owned Buildkite secret key}"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"
version=2.338.2
curl --fail --silent --show-error --location \
  "https://github.com/actions/runner/releases/download/v${version}/actions-runner-linux-x64-${version}.tar.gz" \
  -o runner.tar.gz
echo 'baebf204307bac6193480852732f0aba2ae97b6c5597c244f4d5558390147c40  runner.tar.gz' | sha256sum -c -
tar xzf runner.tar.gz
rm runner.tar.gz
jit=$(buildkite-agent secret get "$DEMO_JIT_SECRET")
# The GitHub job does not need the Buildkite agent credential.
unset BUILDKITE_AGENT_ACCESS_TOKEN
export RUNNER_ALLOW_RUNASROOT=1
echo "Official Actions runner ${version} on ${BUILDKITE_BUILD_URL}#${BUILDKITE_JOB_ID}"
timeout --signal=TERM --kill-after=30s 12m ./run.sh --jitconfig "$jit"
