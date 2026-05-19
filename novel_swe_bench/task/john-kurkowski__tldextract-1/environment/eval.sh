#!/usr/bin/env bash
# Canonical SWE-bench-style evaluation flow for
# instance: john-kurkowski__tldextract-1
#
# Contract (matches SWE-bench `resolved` definition):
#   * exit 0 iff ALL FAIL_TO_PASS tests pass AND ALL PASS_TO_PASS tests pass.
#   * exit 1 in every other case (patch failed to apply, F2P regression,
#     P2P regression, install failure, infra error).
#
# When invoked the container is expected to be in this state:
#   * /app is the snapshot at base_commit
#   * test_patch has already been applied during image build (so the F2P
#     and edge tests already exist under /app/tests/)
#   * the package is installed editable
#
# Two modes are supported:
#
#   A. Agent-patch evaluation (typical):
#        docker run --rm \
#          -v $(pwd)/agent.diff:/agent.diff:ro \
#          openclaw-eval/john-kurkowski__tldextract-1:base \
#          eval.sh
#      The agent's diff is applied on top of the base+tests state, then
#      F2P + P2P are run.
#
#   B. Gold-patch sanity check (used by `validate.sh`):
#        docker run --rm \
#          -v $(pwd)/instances/.../patches/gold.patch:/agent.diff:ro \
#          openclaw-eval/john-kurkowski__tldextract-1:base \
#          eval.sh
set -uo pipefail
cd /app

REWARD_DIR="${REWARD_DIR:-/logs/verifier}"
mkdir -p "$REWARD_DIR"

write_reward () {
  echo "$1" > "$REWARD_DIR/reward.txt"
}

# ---------------------------------------------------------------------------
# 1. Apply the candidate patch (if provided)
# ---------------------------------------------------------------------------
if [[ -f /agent.diff ]]; then
  if ! git apply --whitespace=nowarn /agent.diff; then
    echo "[eval] agent.diff failed to apply" >&2
    write_reward 0
    exit 1
  fi
fi

export SETUPTOOLS_SCM_PRETEND_VERSION_FOR_TLDEXTRACT=5.3.1

# ---------------------------------------------------------------------------
# 2. FAIL_TO_PASS — must all pass on the patched repo
# ---------------------------------------------------------------------------
echo "[eval] running FAIL_TO_PASS"
python -m pytest \
  tests/test_reverse_domain_name_empty_suffix.py \
  tests/test_reverse_domain_name_edge_cases.py \
  -q --tb=short
F2P_RC=$?

# ---------------------------------------------------------------------------
# 3. PASS_TO_PASS — existing suite must still pass (regression guard)
# ---------------------------------------------------------------------------
echo "[eval] running PASS_TO_PASS"
python -m pytest \
  tests/main_test.py \
  tests/test_cache.py \
  tests/cli_test.py \
  -q --tb=short
P2P_RC=$?

# ---------------------------------------------------------------------------
# 4. Verdict
# ---------------------------------------------------------------------------
if [[ $F2P_RC -eq 0 && $P2P_RC -eq 0 ]]; then
  write_reward 1
  echo "[eval] RESOLVED: F2P pass + P2P pass"
  exit 0
fi

write_reward 0
echo "[eval] UNRESOLVED: F2P_RC=$F2P_RC P2P_RC=$P2P_RC"
exit 1
