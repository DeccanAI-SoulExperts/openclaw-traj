        # langchain-ai__mcpdoc-1

        Standard SWE-bench-style instance derived from MERGE-Bench `task_001`.
        Evaluation requires cloning the source repo at the pinned base commit.
        No local snapshot is bundled.

        ## 1. Task identity

        | Field | Value |
        |-------|-------|
        | New task ID | `task_002` |
        | Instance ID | `langchain-ai__mcpdoc-1` |
        | Original MERGE-Bench task | `task_001` |
        | Source repo | `langchain-ai/mcpdoc` |
        | GitHub URL | https://github.com/langchain-ai/mcpdoc |
        | Base commit | `8c2729ad799b7573ae8ed2435f9499aeb712a70c` |
        | Task type | `bug_fix` |
        | Difficulty | `Intermediate` |
        | Version | `TODO (no published version label for this commit)` |

        ## 2. Why this task was selected

        A real validation/error-handling bug: the server silently accepts broken remote URLs and only fails later when the user queries the data. The fix requires understanding both startup-time validation and the HTTP client lifecycle, and the test patch checks the ValueError contract under several mocked failure modes.

        ## 3. Why the model may fail on the first attempt

        Agents commonly fix only one error class (for example HTTPStatusError) and miss other failure modes like ConnectError or hostless URLs. The tests mock httpx.Client.get to return three distinct failure shapes, so a partial fix fails on a strict subset of the cases.

        ## 4. How RLHI feedback could help

        Test failures point clearly at which mocked failure was missed, producing a directive next-state signal ("ConnectError still raises") that maps directly to an OPD hint about exception breadth.

        ## 5. What the gold patch changes

        See `patches/gold.patch` for the unified diff. The patch modifies the
        files listed in `metadata.yaml` under `gold_patch.files_modified` (when
        populated). It is the reference solution copied verbatim from MERGE-Bench
        `task_001/patches/creator.patch`.

        ## 6. What the test patch checks

        `patches/test.patch` adds the F2P and edge tests at the following paths
        inside the repo working tree:

        - `tests/test_invalid_doc_source_validation.py` (F2P)
- `tests/test_invalid_doc_source_edge_cases.py` (EDGE)

        These tests assert behaviour against the public API. They do not look at
        implementation details, so alternative correct fixes are still graded as
        passing.

        ## 7. FAIL_TO_PASS tests

        - `tests/test_invalid_doc_source_validation.py::test_hostless_https_url_raises_value_error`
- `tests/test_invalid_doc_source_validation.py::test_hostless_http_url_raises_value_error`
- `tests/test_invalid_doc_source_validation.py::test_mix_valid_and_hostless_remote_raises_value_error`
- `tests/test_invalid_doc_source_edge_cases.py::test_remote_url_without_host_raises_value_error`
- `tests/test_invalid_doc_source_edge_cases.py::test_http_scheme_only_raises_value_error`
- `tests/test_invalid_doc_source_edge_cases.py::test_mix_valid_and_hostless_url_still_raises`

        ## 8. PASS_TO_PASS tests

        TODO. Run the collection command below against the repo at `base_commit`
        and paste the result into `tests/pass_to_pass.json`. Likely test root:

          - `tests/`

        ## 9. Validation commands

        Run these from any working directory. They reproduce the canonical
        SWE-bench resolved-iff-F2P-and-P2P contract.

        ```bash
        # 1. clone the repo at the pinned base commit
        git clone https://github.com/langchain-ai/mcpdoc /tmp/mcpdoc
        cd /tmp/mcpdoc
        git checkout 8c2729ad799b7573ae8ed2435f9499aeb712a70c

        # 2. install the project (project-specific; see source repo README)
        pip install -e .

        # 3. apply the test patch to inject the F2P + edge tests
        git apply <path_to_this_task>/patches/test.patch

        # 4. confirm the F2P tests FAIL on base
        pytest -q tests/test_invalid_doc_source_validation.py tests/test_invalid_doc_source_edge_cases.py
        # expected: all FAIL_TO_PASS tests fail

        # 5. apply the gold patch
        git apply <path_to_this_task>/patches/gold.patch

        # 6. confirm the F2P tests now PASS
        pytest -q tests/test_invalid_doc_source_validation.py tests/test_invalid_doc_source_edge_cases.py
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
