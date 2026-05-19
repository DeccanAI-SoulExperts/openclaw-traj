        # john-kurkowski__tldextract-2

        Standard SWE-bench-style instance derived from MERGE-Bench `task_017`.
        Evaluation requires cloning the source repo at the pinned base commit.
        No local snapshot is bundled.

        ## 1. Task identity

        | Field | Value |
        |-------|-------|
        | New task ID | `task_005` |
        | Instance ID | `john-kurkowski__tldextract-2` |
        | Original MERGE-Bench task | `task_017` |
        | Source repo | `john-kurkowski/tldextract` |
        | GitHub URL | https://github.com/john-kurkowski/tldextract |
        | Base commit | `96907a264cd8de51433151f6d4a5753d66b565a8` |
        | Task type | `bug_fix` |
        | Difficulty | `Intermediate` |
        | Version | `5.3.1` |

        ## 2. Why this task was selected

        A small surface-area bug with a wide test profile: extract_urllib blindly passes urlsplit().netloc to the internal extractor, so any URL whose netloc carries a port, userinfo, or bracketed IPv6 returns garbage. The fix is one call to lenient_netloc, but a partial fix that handles only ports leaves userinfo and IPv6 broken.

        ## 3. Why the model may fail on the first attempt

        Agents may strip the port using a manual rfind(':') and miss bracketed IPv6 (which contains colons inside the brackets). They may strip userinfo with split('@') and miss URLs where the password contains '@'. The test patch hits all three cases plus a combined userinfo+port+subdomain case.

        ## 4. How RLHI feedback could help

        Each of the three edge tests fails with a recognisable wrong-result string (e.g. domain='example.com:8080'), so the next-state signal names the exact malformed component for OPD hints.

        ## 5. What the gold patch changes

        See `patches/gold.patch` for the unified diff. The patch modifies the
        files listed in `metadata.yaml` under `gold_patch.files_modified` (when
        populated). It is the reference solution copied verbatim from MERGE-Bench
        `task_017/patches/creator.patch`.

        ## 6. What the test patch checks

        `patches/test.patch` adds the F2P and edge tests at the following paths
        inside the repo working tree:

        - `tests/test_extract_urllib_port.py` (F2P)
- `tests/test_extract_urllib_netloc_normalization.py` (EDGE)

        These tests assert behaviour against the public API. They do not look at
        implementation details, so alternative correct fixes are still graded as
        passing.

        ## 7. FAIL_TO_PASS tests

        - `tests/test_extract_urllib_port.py::test_extract_urllib_matches_string_extraction_for_url_with_port`

        ## 8. PASS_TO_PASS tests

        TODO. Run the collection command below against the repo at `base_commit`
        and paste the result into `tests/pass_to_pass.json`. Likely test root:

          - `tests/main_test.py`
  - `tests/test_cache.py`
  - `tests/cli_test.py`

        ## 9. Validation commands

        Run these from any working directory. They reproduce the canonical
        SWE-bench resolved-iff-F2P-and-P2P contract.

        ```bash
        # 1. clone the repo at the pinned base commit
        git clone https://github.com/john-kurkowski/tldextract /tmp/tldextract
        cd /tmp/tldextract
        git checkout 96907a264cd8de51433151f6d4a5753d66b565a8

        # 2. install the project (project-specific; see source repo README)
        pip install -e .

        # 3. apply the test patch to inject the F2P + edge tests
        git apply <path_to_this_task>/patches/test.patch

        # 4. confirm the F2P tests FAIL on base
        pytest -q tests/test_extract_urllib_port.py tests/test_extract_urllib_netloc_normalization.py
        # expected: all FAIL_TO_PASS tests fail

        # 5. apply the gold patch
        git apply <path_to_this_task>/patches/gold.patch

        # 6. confirm the F2P tests now PASS
        pytest -q tests/test_extract_urllib_port.py tests/test_extract_urllib_netloc_normalization.py
        # expected: all FAIL_TO_PASS tests pass

        # 7. confirm the existing test suite (PASS_TO_PASS) still passes
        pytest -q tests/main_test.py tests/test_cache.py tests/cli_test.py
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
