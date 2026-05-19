        # un33k__python-slugify-1

        Standard SWE-bench-style instance derived from MERGE-Bench `task_020`.
        Evaluation requires cloning the source repo at the pinned base commit.
        No local snapshot is bundled.

        ## 1. Task identity

        | Field | Value |
        |-------|-------|
        | New task ID | `task_003` |
        | Instance ID | `un33k__python-slugify-1` |
        | Original MERGE-Bench task | `task_020` |
        | Source repo | `un33k/python-slugify` |
        | GitHub URL | https://github.com/un33k/python-slugify |
        | Base commit | `7b6d5d96c1995e6dccb39a19a13ba78d7d0a3ee4` |
        | Task type | `bug_fix` |
        | Difficulty | `Intermediate` |
        | Version | `TODO (no published version label for this commit)` |

        ## 2. Why this task was selected

        A subtle logic bug where the user-supplied replacements list is run twice, so any later replacement whose 'old' value happens to appear inside the slugified intermediate text gets silently corrupted. Naive fixes that add a guard or rewrite the loop without removing the second pass keep the bug alive in slightly different shapes, which is exactly the case where step-level reward shines.

        ## 3. Why the model may fail on the first attempt

        Agents often try to guard the second replacements pass instead of removing it, or they reorder the replacements and the transliteration. The edge-case tests exercise transliterated text (CJK, accents) where any second pass that touches the post-transliteration string still corrupts the output.

        ## 4. How RLHI feedback could help

        When the agent's first attempt still fails one edge case, the next state signal (the failing assertion with actual vs expected strings) tells the model exactly which transliteration was the problem.

        ## 5. What the gold patch changes

        See `patches/gold.patch` for the unified diff. The patch modifies the
        files listed in `metadata.yaml` under `gold_patch.files_modified` (when
        populated). It is the reference solution copied verbatim from MERGE-Bench
        `task_020/patches/creator.patch`.

        ## 6. What the test patch checks

        `patches/test.patch` adds the F2P and edge tests at the following paths
        inside the repo working tree:

        - `tests/test_replacements_double_apply.py` (F2P)
- `tests/test_replacements_double_apply_edges.py` (EDGE)

        These tests assert behaviour against the public API. They do not look at
        implementation details, so alternative correct fixes are still graded as
        passing.

        ## 7. FAIL_TO_PASS tests

        - `tests/test_replacements_double_apply.py::TestReplacementsDoubleApplyBug::test_replacement_key_matches_separator`
- `tests/test_replacements_double_apply.py::TestReplacementsDoubleApplyBug::test_replacement_no_double_apply_after_transliteration`
- `tests/test_replacements_double_apply.py::TestReplacementsDoubleApplyBug::test_replacement_no_corruption_after_accent_removal`
- `tests/test_replacements_double_apply.py::TestReplacementsDoubleApplyBug::test_replacement_no_corruption_after_diacritic_normalization`

        ## 8. PASS_TO_PASS tests

        TODO. Run the collection command below against the repo at `base_commit`
        and paste the result into `tests/pass_to_pass.json`. Likely test root:

          - `test.py`

        ## 9. Validation commands

        Run these from any working directory. They reproduce the canonical
        SWE-bench resolved-iff-F2P-and-P2P contract.

        ```bash
        # 1. clone the repo at the pinned base commit
        git clone https://github.com/un33k/python-slugify /tmp/python-slugify
        cd /tmp/python-slugify
        git checkout 7b6d5d96c1995e6dccb39a19a13ba78d7d0a3ee4

        # 2. install the project (project-specific; see source repo README)
        pip install -e .

        # 3. apply the test patch to inject the F2P + edge tests
        git apply <path_to_this_task>/patches/test.patch

        # 4. confirm the F2P tests FAIL on base
        pytest -q tests/test_replacements_double_apply.py tests/test_replacements_double_apply_edges.py
        # expected: all FAIL_TO_PASS tests fail

        # 5. apply the gold patch
        git apply <path_to_this_task>/patches/gold.patch

        # 6. confirm the F2P tests now PASS
        pytest -q tests/test_replacements_double_apply.py tests/test_replacements_double_apply_edges.py
        # expected: all FAIL_TO_PASS tests pass

        # 7. confirm the existing test suite (PASS_TO_PASS) still passes
        pytest -q test.py
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
