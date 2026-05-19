        # NiltonVolpato__python-progressbar-1

        Standard SWE-bench-style instance derived from MERGE-Bench `task_004`.
        Evaluation requires cloning the source repo at the pinned base commit.
        No local snapshot is bundled.

        ## 1. Task identity

        | Field | Value |
        |-------|-------|
        | New task ID | `task_004` |
        | Instance ID | `NiltonVolpato__python-progressbar-1` |
        | Original MERGE-Bench task | `task_004` |
        | Source repo | `NiltonVolpato/python-progressbar` |
        | GitHub URL | https://github.com/NiltonVolpato/python-progressbar |
        | Base commit | `b3597a19633c13284e0a05002e62ce22e4ee9fce` |
        | Task type | `refactor` |
        | Difficulty | `Intermediate` |
        | Version | `TODO (no published version label for this commit)` |

        ## 2. Why this task was selected

        A refactor that fights with subclassing: AdaptiveETA inherits __slots__ from Timer but stores samples on a non-slotted attribute, which silently re-enables __dict__. The agent must restore the __slots__ contract while also seeding samples in __init__. Naive fixes that set samples to a class-level list break instance isolation, which the edge tests catch via pickle/deepcopy/two-instance checks.

        ## 3. Why the model may fail on the first attempt

        Common wrong fixes include declaring samples as a class attribute, which creates shared mutable state, or forgetting __slots__ entirely and only adding __init__. Both pass the simple existence check but fail the edge tests for buffer isolation and pickle round-trip.

        ## 4. How RLHI feedback could help

        Pickle and deepcopy failures produce stack traces with the exact shared-state symptom (the assertion shows both instances seeing the same mutation), which is a directive signal mapping to an OPD hint about per-instance initialization.

        ## 5. What the gold patch changes

        See `patches/gold.patch` for the unified diff. The patch modifies the
        files listed in `metadata.yaml` under `gold_patch.files_modified` (when
        populated). It is the reference solution copied verbatim from MERGE-Bench
        `task_004/patches/creator.patch`.

        ## 6. What the test patch checks

        `patches/test.patch` adds the F2P and edge tests at the following paths
        inside the repo working tree:

        - `tests/test_adaptive_eta_init.py` (F2P)
- `tests/test_adaptive_eta_buffer_isolation.py` (EDGE)

        These tests assert behaviour against the public API. They do not look at
        implementation details, so alternative correct fixes are still graded as
        passing.

        ## 7. FAIL_TO_PASS tests

        - `tests/test_adaptive_eta_init.py::TestAdaptiveETARefactorF2P::test_samples_exists_at_construction_time`
- `tests/test_adaptive_eta_init.py::TestAdaptiveETARefactorF2P::test_update_samples_no_longer_has_hasattr_branch`
- `tests/test_adaptive_eta_buffer_isolation.py::TestAdaptiveETARefactorEdges::test_two_instances_have_independent_buffers`
- `tests/test_adaptive_eta_buffer_isolation.py::TestAdaptiveETARefactorEdges::test_pickle_round_trip_preserves_samples`
- `tests/test_adaptive_eta_buffer_isolation.py::TestAdaptiveETARefactorEdges::test_deepcopy_produces_independent_buffer`

        ## 8. PASS_TO_PASS tests

        TODO. Run the collection command below against the repo at `base_commit`
        and paste the result into `tests/pass_to_pass.json`. Likely test root:

          - `tests/`

        ## 9. Validation commands

        Run these from any working directory. They reproduce the canonical
        SWE-bench resolved-iff-F2P-and-P2P contract.

        ```bash
        # 1. clone the repo at the pinned base commit
        git clone https://github.com/NiltonVolpato/python-progressbar /tmp/python-progressbar
        cd /tmp/python-progressbar
        git checkout b3597a19633c13284e0a05002e62ce22e4ee9fce

        # 2. install the project (project-specific; see source repo README)
        pip install -e .

        # 3. apply the test patch to inject the F2P + edge tests
        git apply <path_to_this_task>/patches/test.patch

        # 4. confirm the F2P tests FAIL on base
        pytest -q tests/test_adaptive_eta_init.py tests/test_adaptive_eta_buffer_isolation.py
        # expected: all FAIL_TO_PASS tests fail

        # 5. apply the gold patch
        git apply <path_to_this_task>/patches/gold.patch

        # 6. confirm the F2P tests now PASS
        pytest -q tests/test_adaptive_eta_init.py tests/test_adaptive_eta_buffer_isolation.py
        # expected: all FAIL_TO_PASS tests pass

        # 7. confirm the existing test suite (PASS_TO_PASS) still passes
        pytest -q tests/
        # expected: 0 failures
        ```

        ## 10. Validation status

        | Step | Status |
        |------|--------|
        | gold.patch applies cleanly on base_commit | TODO |
        | test.patch applies cleanly on base_commit | TODO |
        | FAIL_TO_PASS tests fail on base | TODO |
        | FAIL_TO_PASS tests pass after gold | TODO |
        | PASS_TO_PASS tests pass on base | TODO |
        | PASS_TO_PASS tests pass after gold | TODO |

        Mark these as `OK` once the validation block above is executed against a
        clean clone.
