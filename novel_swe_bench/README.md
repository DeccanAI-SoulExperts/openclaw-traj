# novel_swe_bench

Novel, swe-bench task instances we authored ourselves on top of public Python GitHub repositories, together with the agent trajectories generated for each one inside the OpenClawRL environment.

Each task follows the same schema as `public_swe_bench/` — instance ID, repository, base commit, gold patch, test patch, FAIL_TO_PASS / PASS_TO_PASS lists. The only structural difference is **packaging**: the repository snapshot, dependencies, failing tests, reference fix, and a reproducible Docker-based evaluation image are bundled inside the task itself. The task therefore runs end-to-end with no clone and no internet access, which is also what makes the same machinery safe to use for private or client code later.

## Why this collection exists

The 10 instances under `public_swe_bench/` cover four large, well-studied repos (Astropy, Django, Moto, SymPy). To show that the OpenClaw pipeline generalises beyond these, we picked four smaller, well-scoped Python libraries on GitHub (tldextract, mcpdoc, python-progressbar, python-slugify), pinned each repo at a clean base commit, and authored five fresh tasks across them — four real-bug fixes, one targeted refactor. Every task has a verified `gold.patch`, a `test.patch` that turns the issue into a deterministic test, and a Dockerfile that builds a `/testbed` image with `test.patch` pre-applied.

## Inventory

| Instance ID | Repo | Task type | Steps | Outcome on the run |
|---|---|---|---:|---|
| `john-kurkowski__tldextract-1` | tldextract | Bug fix | 11 | Solved (clean +1.0 throughout) |
| `john-kurkowski__tldextract-2` | tldextract | Bug fix | 18 | Solved (mixed positive/negative on the way) |
| `langchain-ai__mcpdoc-1` | mcpdoc | Bug fix | 13 | Solved (mostly positive, two negative steps) |
| `NiltonVolpato__python-progressbar-1` | python-progressbar | Refactor | 20 | Hit step limit; full struggle path recorded |
| `un33k__python-slugify-1` | python-slugify | Bug fix | 7 | Solved (shortest run, clean +1.0 throughout) |

## Per-task detail

### 1. `john-kurkowski__tldextract-1` — leading dot in `reverse_domain_name`

- **Bug.** `tldextract.reverse_domain_name(...)` returned a string with a leading `.` whenever the public-suffix component was empty (for example for a hostname like `localhost`). Callers concatenating the result into a URL produced malformed addresses.
- **Fix.** Skip empty parts before joining the components back together.
- **Trajectory.** 11 steps, agent = `gpt-5`. PRM breakdown: **+1.0: 9, +0.333: 0, −0.333: 0, −1.0: 0, not scored: 2.** A clean run — the agent localised the failing test, read `reverse_domain_name`, applied the minimal fix, re-ran the tests, and submitted. No backtracking.

### 2. `john-kurkowski__tldextract-2` — `extract_urllib` on tricky netlocs

- **Bug.** `tldextract.extract_urllib(...)` raised on URLs that carried a port, user info, or an IPv6 host, because it stripped those components incorrectly before calling the lenient parser.
- **Fix.** Route the netloc through `lenient_netloc` so port, userinfo, and IPv6 brackets are handled by the existing tolerant code path.
- **Trajectory.** 18 steps, agent = `gpt-5`. PRM breakdown: **+1.0: 9, +0.333: 0, −0.333: 0, −1.0: 8, not scored: 1.** A useful "stumble then recover" trajectory — the agent's first edit broke an unrelated test, the PRM panel flagged the regression repeatedly, and the agent eventually reverted the over-edit and converged on the smaller fix.

### 3. `langchain-ai__mcpdoc-1` — silent failure on unreachable doc URLs

- **Bug.** mcpdoc accepted unreachable documentation URLs without complaint, so a misconfigured `--urls` flag would produce an empty index with no signal to the user.
- **Fix.** Validate every remote source at startup and raise a clear error if any URL fails to fetch.
- **Trajectory.** 13 steps, agent = `gpt-5`. PRM breakdown: **+1.0: 8, +0.333: 2, −0.333: 0, −1.0: 2, not scored: 1.** Mostly clean with two unanimous-negative steps where the agent attempted to swallow the new exception in an `except` block before correcting itself.

### 4. `NiltonVolpato__python-progressbar-1` — AdaptiveETA refactor

- **Task.** Not a bug — a focused refactor. `AdaptiveETA` was using `hasattr`-driven lazy initialisation; replace it with an explicit `__init__`, add `__slots__`, and keep behaviour identical for the existing widget tests.
- **Trajectory.** 20 steps, agent = `gpt-5`. PRM breakdown: **+1.0: 5, +0.333: 3, −0.333: 1, −1.0: 8, not scored: 3.** The hardest run in this collection — refactor tasks have a wide solution space and the agent explored several variants (notably mis-using `__slots__` with class-level defaults), each of which broke a different subset of the regression tests. Hit the step limit (20) before producing a clean patch; the trajectory is therefore especially valuable as **negative data** for training a more decisive agent.

### 5. `un33k__python-slugify-1` — double-applied custom replacements

- **Bug.** When the user passed a `replacements=` list, `slugify` applied it twice — once in pre-processing and once again in the main substitution loop — corrupting outputs whenever a replacement value contained a token that another replacement was about to rewrite.
- **Fix.** Remove the duplicate replacement pass.
- **Trajectory.** 7 steps, agent = `gpt-5`. PRM breakdown: **+1.0: 6, +0.333: 0, −0.333: 0, −1.0: 0, not scored: 1.** The shortest run in this folder. The agent found the duplicated loop on the second `grep`, made the one-line deletion, ran the tests, submitted.


A task and its trajectory share the same `<instance_id>`, so pairing is by directory name.

## Configuration

All 5 runs in this collection were generated with the configuration below (values mirror each `trajectory/<id>/meta.json` exactly).

| Field | Value | Notes |
|---|---|---|
| `model` | `gpt-5` | Same agent on all 5 runs. |
| `api_base` | `https://api.openai.com/v1` | OpenAI-compatible endpoint serving the agent. |
| `max_tokens` | `4096` | Per-turn generation cap. |
| `step_limit` | `20` | Hard cap on the number of agent steps per run. |
| `prm_enable` | `true` | Every action step is scored by the PRM panel. |
| `prm_api_base` | `https://api.openai.com/v1` | Same endpoint as `api_base`. |
| `prm_api_model` | `openai/gpt-4o-mini` | 3-judge panel, per-judge votes averaged. |
| `prm_score_aggregation` | mean of per-judge votes | Each judge votes ∈ {+1, −1}; the average is one of `{+1.0, +0.333, −0.333, −1.0}`, or `0` for unscored steps. |
| `prm_step_coef` | `1.0` | Per-turn reward scaling factor. |

### Aggregate PRM breakdown across the 5 trajectories

| Trajectory | Total steps | +1.0 | +0.333 | −0.333 | −1.0 | Not scored |
|---|---:|---:|---:|---:|---:|---:|
| `john-kurkowski__tldextract-1` | 11 | 9 | 0 | 0 | 0 | 2 |
| `john-kurkowski__tldextract-2` | 18 | 9 | 0 | 0 | 8 | 1 |
| `langchain-ai__mcpdoc-1` | 13 | 8 | 2 | 0 | 2 | 1 |
| `NiltonVolpato__python-progressbar-1` | 20 | 5 | 3 | 1 | 8 | 3 |
| `un33k__python-slugify-1` | 7 | 6 | 0 | 0 | 0 | 1 |
| **Total** | **69** | **37** | **5** | **1** | **18** | **8** |

## Per-step record (`traj.json`)

Each `traj.json` is the full agent transcript: the system prompt, the user turn containing the problem statement, and one record per agent step containing:

- the assistant's `THOUGHT`,
- a single shell action (one command, one block),
- the environment's response (`returncode`, `output_head`, `output_tail`),
- and the PRM score the panel gave to that step.

The final submitted diff is recorded separately as `patch.diff` next to it.

## Evaluation

Inside the container built from `environment/Dockerfile`, the harness applies the agent's `patch.diff` over the test-patched `/testbed`, runs `eval.sh`, and counts the run as **resolved** if every test listed in `tests/fail_to_pass.json` flips FAIL → PASS and every test in `tests/pass_to_pass.json` remains PASS.
