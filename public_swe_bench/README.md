# public_swe_bench

Agent trajectories on the **public SWE-bench Verified** benchmark, generated inside the OpenClawRL environment.

Each instance is a real bug report or feature request taken from a public Python repository. We pulled 10 verified instances from the SWE-bench Verified set on Hugging Face, spanning 4 repositories: **Astropy**, **Django**, **Moto**, and **SymPy**. For each task, the OpenClawRL environment checks out the repository at the exact base commit specified by the SWE-bench record, hands the agent the problem description, and runs it in a sandboxed shell for up to 20 steps. After every step the PRM judge panel scores what the agent just did.

## Why this collection exists

This is the recognisable surface. SWE-bench Verified is the closest thing the industry has to a shared yardstick for coding agents, so anchoring the dataset on 10 instances from it (Astropy, Django, Moto, SymPy) lets reviewers immediately see our pipeline working on tasks they have seen before. The verifiable F2P / P2P harness also gives us a hard ground-truth check on the PRM panel, when the tests flip from FAIL to PASS, a `+1` verdict is provably correct. That calibration anchor is what the novel and chat collections lean on for their own scoring trust.

## Inventory

10 instances across 4 repositories. Steps and PRM scores are read directly from the live `traj.json` files.

| Instance ID | Repo | Task type | Steps | +1.0 | +0.333 | −0.333 | −1.0 | Not scored | Outcome |
|---|---|---|---:|---:|---:|---:|---:|---:|---|
| `astropy__astropy-7606` | astropy | Bug fix | 9 | 7 | 0 | 0 | 1 | 1 | Solved with recovery |
| `django__django-12039` | django | Bug fix | 11 | 7 | 1 | 0 | 1 | 2 | Solved with recovery |
| `django__django-12304` | django | Bug fix | 11 | 7 | 0 | 0 | 3 | 1 | Solved with recovery |
| `django__django-14915` | django | Bug fix | 8 | 6 | 0 | 0 | 1 | 1 | Solved with recovery |
| `django__django-15569` | django | Bug fix | 9 | 6 | 0 | 1 | 1 | 1 | Solved with recovery |
| `getmoto__moto-4860` | moto | Bug fix | 12 | 6 | 0 | 0 | 5 | 1 | Solved with recovery |
| `getmoto__moto-5502` | moto | Bug fix | 10 | 8 | 0 | 0 | 1 | 1 | Clean Solution  |
| `getmoto__moto-5515` | moto | Bug fix | 7 | 5 | 0 | 1 | 0 | 1 | Clean Solution |
| `getmoto__moto-6226` | moto | Bug fix | 7 | 5 | 1 | 0 | 0 | 1 | Clean Solution |
| `sympy__sympy-18189` | sympy | Bug fix | 11 | 8 | 1 | 0 | 1 | 1 | Solved with recovery |
| **Total** | — | — | **95** | **65** | **3** | **2** | **14** | **11** | — |

> **Coding agent:** `gpt-5` for the django, astropy, and sympy tasks; `gpt-4-turbo` for the four moto tasks. **PRM judge panel:** the same 3-judge `openai/gpt-4o-mini` ensemble used across all collections.

## Per-task detail

### 1. `astropy__astropy-7606` - TypeError comparing UnrecognizedUnit with None

- **Bug.** Calling `unit == None` on an `astropy.units.UnrecognizedUnit` raised a `TypeError` instead of returning `False`. This broke any code that guarded with a simple equality check against `None`.
- **Fix.** Add an `__eq__` override on `UnrecognizedUnit` that returns `NotImplemented` (or `False`) when the other operand is not a unit.
- **Trajectory.** 9 steps, `gpt-5`. PRM: **+1.0: 7, −1.0: 1, not scored: 1.** Very clean run — the agent read the failing test, found the missing `__eq__`, patched it, re-ran the test suite, submitted.

### 2. `django__django-12039` - missing whitespace in CREATE INDEX SQL

- **Bug.** Django's `SchemaEditor` generated `CREATE INDEX` statements with no space between the index name and the `ON` keyword in certain code paths, producing invalid SQL.
- **Fix.** Insert the missing space in the relevant SQL template string.
- **Trajectory.** 11 steps, `gpt-5`. PRM: **+1.0: 7, +0.333: 1, −1.0: 1, not scored: 2.** Mostly clean. The one negative step was a failed `grep` with a too-narrow pattern; the agent self-corrected on the next turn.

### 3. `django__django-12304` - Enumeration types unusable in templates

- **Bug.** Django's template engine could not render Enumeration type values (e.g. `IntegerChoices`, `TextChoices`) — it raised a `TypeError` because the template variable resolver didn't know how to coerce an enum member to a string.
- **Fix.** Add a `__str__` delegation in the enum mixin so template rendering calls the right method.
- **Trajectory.** 11 steps, `gpt-5`. PRM: **+1.0: 7, −1.0: 3, not scored: 1.** Three unanimous-negative steps — the agent first tried patching the template renderer (wrong layer), got flagged twice, then located the correct fix in the enum mixin on the third attempt.

### 4. `django__django-14915` - ModelChoiceIteratorValue is not hashable

- **Bug.** `ModelChoiceIteratorValue`, introduced to wrap choice values in form widgets, did not implement `__hash__`, making it impossible to use as a dictionary key or set member — a common pattern when checking whether a choice is "selected".
- **Fix.** Add `__hash__ = property(lambda self: hash(self.value))` to the class.
- **Trajectory.** 8 steps, `gpt-5`. PRM: **+1.0: 6, −1.0: 1, not scored: 1.** One negative step where the agent added `__hash__` in the wrong class (the iterator, not the value wrapper); corrected immediately on the next step.

### 5. `django__django-15569` - lookup cache not cleared on _unregister_lookup

- **Bug.** `RegisterLookupMixin._unregister_lookup()` removed a lookup from the registry but did not clear the internal lookup cache, so the unregistered lookup could still be found by subsequent calls that hit the stale cache.
- **Fix.** Call `cls._clear_cached_lookups()` inside `_unregister_lookup()`, mirroring what `register_lookup` already did.
- **Trajectory.** 9 steps, `gpt-5`. PRM: **+1.0: 6, −0.333: 1, −1.0: 1, not scored: 1.** One majority-negative step (cache-clearing called on the wrong class in a hierarchy) and one unanimous-negative step (a test run that failed) before the agent pinpointed the correct call site.

### 6. `getmoto__moto-4860` - TimestreamWrite uses append instead of extend

- **Bug.** In moto's Timestream Write mock, `write_records` was using `.append(records)` to accumulate new records into an existing list, which nested the incoming list as a single element rather than adding the records individually. Queries on the mock returned wrong results as a consequence.
- **Fix.** Replace `.append(records)` with `.extend(records)`.
- **Trajectory.** 12 steps, `gpt-4-turbo`. PRM: **+1.0: 6, −1.0: 5, not scored: 1.** The hardest run in this collection. The agent spent five steps exploring unrelated parts of the Timestream implementation before locating the one-word fix. The five negative steps are high-value training signal for teaching the model to narrow its search more efficiently.

### 7. `getmoto__moto-5502` - DeliveryTimedOutCount missing from SSM list_commands

- **Bug.** moto's SSM mock omitted the `DeliveryTimedOutCount` field from `list_commands` responses, causing any code that read that field to raise a `KeyError`.
- **Fix.** Add `DeliveryTimedOutCount` to the response dictionary in the SSM mock, defaulting to `0`.
- **Trajectory.** 10 steps, `gpt-4-turbo`. PRM: **+1.0: 8, −1.0: 1, not scored: 1.** Clean run. The single negative step was an overly broad `grep` that pulled in unrelated files; the agent narrowed it and found the response builder immediately.

### 8. `getmoto__moto-5515` - Inconsistent us-west-1 availability zones

- **Bug.** moto's EC2 mock returned a different number of availability zones for `us-west-1` depending on how the query was made (describe vs. filter), causing tests that expected a consistent zone list to flap.
- **Fix.** Align the hardcoded `us-west-1` zone list in both code paths.
- **Trajectory.** 7 steps, `gpt-4-turbo`. PRM: **+1.0: 5, −0.333: 1, not scored: 1.** Short, efficient run. One majority-negative step where the agent patched only one of the two code paths; the failing test pointed it straight to the second.

### 9. `getmoto__moto-6226` - ECS tag_resource raises TypeError on untagged clusters

- **Bug.** moto's ECS mock raised a `TypeError` in `tag_resource` when the target cluster had no existing tags, because the code tried to call `.update()` on `None` rather than initialising an empty dict first.
- **Fix.** Guard with `or {}` when reading the existing tag dict.
- **Trajectory.** 7 steps, `gpt-4-turbo`. PRM: **+1.0: 5, +0.333: 1, not scored: 1.** Short, clean run. One majority-positive step (two of three judges agreed it was good but one was uncertain about the edge-case coverage).

### 10. `sympy__sympy-18189` - diophantine returns incomplete results with permute=True

- **Bug.** `sympy.diophantine` with `permute=True` returned different (incomplete) result sets depending on the order of symbols passed in `syms`. The permutation logic was not accounting for all sign combinations when the symbol order differed from the canonical one.
- **Fix.** Normalise the symbol ordering before generating permutations so the result set is order-independent.
- **Trajectory.** 11 steps, `gpt-5`. PRM: **+1.0: 8, +0.333: 1, −1.0: 1, not scored: 1.** One negative step where the agent applied the normalisation in the wrong scope (per-solution rather than per-call); corrected on the next step.

## Folder layout
```
public_swe_bench/
├── task/
│   └── <instance_id>/
│       ├── problem_statement.md
│       ├── hints.md
│       ├── instance.json
│       ├── metadata.json
│       ├── eval_script.sh
│       ├── patches/
│       │   ├── gold.patch
│       │   └── test.patch
│       └── tests/
│           ├── fail_to_pass.json
│           └── pass_to_pass.json
└── trajectory/
    └── <instance_id>/
        ├── meta.json
        ├── patch.diff
        └── traj.json
```

A task and its trajectory always share the same `<instance_id>`, so pairing is by directory name.

## Configuration

| Field | Value | Notes |
|---|---|---|
| `model` | `gpt-5` (astropy, django, sympy — 6 runs) and `gpt-4-turbo` (moto — 4 runs) | See each `trajectory/<id>/meta.json` for the exact model on that run. |
| `api_base` | `https://api.openai.com/v1` | OpenAI-compatible endpoint. |
| `max_tokens` | `4096` | Per-turn generation cap. |
| `step_limit` | `20` | Hard cap on agent steps per run. |
| `prm_enable` | `true` | Every action step is scored by the PRM panel. |
| `prm_api_base` | `https://api.openai.com/v1` | Same endpoint as `api_base`. |
| `prm_api_model` | `openai/gpt-4o-mini` | 3-judge panel, votes averaged. |
| `prm_score_aggregation` | mean of per-judge votes | Each judge votes ∈ {+1, −1}; result is one of `{+1.0, +0.333, −0.333, −1.0}`, or `0` for unscored steps. |
| `prm_step_coef` | `1.0` | Per-turn reward scaling factor. |

## Per-step record (`traj.json`)

Each `traj.json` is the full agent transcript: the system prompt, the user turn containing the problem statement, and one record per agent step containing:

- the assistant's `THOUGHT`,
- a single shell action (one command, one block),
- the environment's response (`returncode`, `output_head`, `output_tail`),
- and the PRM score the panel gave to that step.

The final submitted diff is recorded separately as `patch.diff` next to it.

## Evaluation

The harness applies `patches/test.patch` to the checked-out repository, then applies the agent's `patch.diff`, runs the test suite, and counts the run as **resolved** if every test in `tests/fail_to_pass.json` flips FAIL → PASS and every test in `tests/pass_to_pass.json` remains PASS.
