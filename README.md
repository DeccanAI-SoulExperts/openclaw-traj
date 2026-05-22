# openclaw-traj

A small dataset of SWE-bench–style task instances paired with agent trajectories, plus a set of real human-in-the-loop chat trajectories captured during OpenClaw evaluation runs.

Each task in the SWE-bench collections describes a real (or self-contained) software-engineering bug taken from an open-source Python project, along with the gold patch, failing/passing tests, and an evaluation harness. Each accompanying trajectory contains the full step-by-step interaction of an agent (currently `gpt-5`, with the 3-judge PRM reward panel enabled) attempting to solve that task in a sandboxed shell.

Each RLHI chat trajectory is a turn-by-turn conversation between a coding agent (one of `gpt-4.1` via the OpenAI API, or `Qwen3-8B` served locally through SGLang) and a human subject-matter expert (SME) working on a real, open-ended engineering task. There is no shell sandbox here, the SME plays the role of the environment, running the agent's code on their own machine and reporting back stdout / tracebacks / observed behaviour the way any normal user of an AI coding assistant would. The same 3-judge `gpt-4o-mini` PRM panel scores every agent turn after the fact.

The repo currently contains three collections:

| Collection            | Description                                                                                                                                | Trajectories |
|-----------------------|--------------------------------------------------------------------------------------------------------------------------------------------|--------------|
| `public_swe_bench/`   | Instances drawn from the public SWE-bench Verified benchmark (Django, SymPy, Astropy, Moto, …).                                            | 10           |
| `novel_swe_bench/`    | Self-contained instances authored in-house in the same SWE-bench format (tldextract, python-slugify, python-progressbar, mcpdoc).          | 5            |
| `human_chat_rlhi/`    | Chat-style RLHI trajectories on real coding problems, with a human SME chatting with the agent the way any user would with no scripted hints. | 3            |
| **Total**             |                                                                                                                                            | **18**       |

---

## TL;DR - the three trajectories we lead with

18 trajectories is comfortably enough to demonstrate the pipeline, but if you only have time to look at three, look at these. Between them they cover all three collections, both quality labels, and both modes of failure-then-recovery the dataset was designed to surface.

Top 3 trajectories: one from each collection, all clearing the ≥30% negative-signal bar; together they prove the failure-then-recovery arc the dataset is built to capture.


| ⭐ | Trajectory                                            | Collection             | Category             | Why it's worth opening first |
|----|-------------------------------------------------------|------------------------|----------------------|-----------------------------|
| 1  | `2048GameDev` (`human_chat_rlhi/2048GameDev.jsonl`)    | RLHI Chat              | Solved with Recovery | 15-turn end-to-end build of a Pygame 2048 with the SME chatting with `gpt-4.1`. Eleven unanimous-negative turns interleaved with three clean unanimous-positive turns and a final SME sign-off, the most concentrated example in the dataset of the agent *regressing on its own fixes* and then recovering. This is the single best showcase of why RLHI data is structurally different from SFT corpora. |
| 2  | `NiltonVolpato__python-progressbar-1 (novel_swe_bench/.../NiltonVolpato__python-progressbar-1)`) | Novel SWE-bench      | Solved with Recovery | One of our own authored tasks: an AdaptiveETA refactor that replaces hasattr-based lazy initialisation with an explicit __init__ and __slots__. At 20 steps it is the longest trajectory in the entire corpus, with 9 negative turns (53% negative, scored basis) and 8 positive turns interleaved a sustained refactor-and-recover arc. |
| 3  | `getmoto__moto-4860 (public_swe_bench/.../getmoto__moto-4860)`) | Public SWE-bench        | Solved with Recovery       | Real bug in moto (a heavily-trafficked AWS-mocking library): TimestreamWrite.write_records used append instead of extend, silently dropping multi-record writes. The agent ran 12 steps with 5 unanimous-negative turns (46% negative), multiple wrong-direction attempts before locating the one-line semantic difference, plus a regression turn the agent had to walk back. Best showcase of the agent operating under realistic SWE-bench conditions: navigating a large codebase, getting it wrong, and recovering. |

---

## Inventory (all 18 trajectories with category labels)

| Trajectory Type | Trajectory Folder / File                          | Category              |
|-----------------|---------------------------------------------------|-----------------------|
| Novel SWE       | `john-kurkowski__tldextract-1`                    | Clean Solution        |
| Novel SWE       | `john-kurkowski__tldextract-2`                    | Solved with Recovery  |
| Novel SWE       | `langchain-ai__mcpdoc-1`                          | Solved with Recovery  |
| Novel SWE       | `NiltonVolpato__python-progressbar-1` ⭐             | Solved with Recovery  |
| Novel SWE       | `un33k__python-slugify-1`                        | Clean Solution        |
| Open Source     | `astropy__astropy-7606`                           | Clean Solution        |
| Open Source     | `django__django-12039`                            | Solved with Recovery  |
| Open Source     | `django__django-12304`                            | Solved with Recovery  |
| Open Source     | `django__django-14915`                            | Solved with Recovery  |
| Open Source     | `django__django-15569`                            | Solved with Recovery  |
| Open Source     | `getmoto__moto-4860` ⭐                              | Solved with Recovery  |
| Open Source     | `getmoto__moto-5502`                              | Clean Solution        |
| Open Source     | `getmoto__moto-5515`                              | Clean Solution        |
| Open Source     | `getmoto__moto-6226`                              | Clean Solution        |
| Open Source     | `sympy__sympy-18189`                            | Solved with Recovery  |
| Chat            | `2048GameDev.jsonl` ⭐                             | Solved with Recovery  |
| Chat            | `chatbotDev.jsonl`                                | Solved with Recovery  |
| Chat            | `ml_problem_stmt.jsonl`                           | Solved with Recovery  |

**Category counts:** Clean Solution → 6, Solved with Recovery → 12.

### What the category labels mean

We use a small, deliberately blunt set of trajectory-level labels:

- **Clean Solution** - Agent reached the correct final artefact with majority-positive PRM turns throughout and no unanimous-negative (−1.0) turn. The trajectory looks like "search → understand → patch → tests pass."
- **Solved with Recovery** - Agent reached the correct final artefact, but the trajectory contains at least one unanimous-negative turn (crash, broken test, wrong design choice, regression) that was subsequently corrected. This is the most training-useful single label: each such trajectory carries both halves of the supervised pair, the failure the policy needs to *unlearn* and the recovery it needs to *imitate* within one contiguous run.
- *(Reserved for future runs)* **Failed at Step Limit** - Agent ran out of the per-trajectory step budget without producing a passing patch.
- *(Reserved for future runs)* **Human-corrected RLHI** - A subset of `Solved with Recovery` chat trajectories where the recovery was driven primarily by the SME pasting an error log or pushing back on a design choice. (All 3 current chat sessions qualify, but we keep the broader label for now since the SME never wrote code or gave a hand-crafted hint.)

---

## Collections in detail

### `public_swe_bench/` - 10 standard SWE-bench Verified tasks

Drawn from the public SWE-bench Verified benchmark. Five `Clean Solution`s (astropy, three moto, one sympy) and five `Solved with Recovery` (four django, one moto). Tasks are pulled from Hugging Face; the repo is cloned from public GitHub at the recorded base commit at run time.

### `novel_swe_bench/` - 5 self-contained tasks we authored

Tasks we authored ourselves over suitable public repos, in the same SWE-bench format (instance ID + repo + base commit + gold patch + test patch + F2P / P2P lists). Two `Clean Solution`s (tldextract-1, python-slugify-1) and three `Solved with Recovery` (tldextract-2, mcpdoc-1, python-progressbar-1). The repo snapshot, dependencies, failing tests, and reference patch are all shipped inside the task folder, so the task is reproducible without internet access.

### `human_chat_rlhi/` - 3 SME ↔ agent chat sessions

Three end-to-end coding sessions where an internal SME chatted with the agent the way any user would, building a Pygame 2048 with `gpt-4.1`, a dual-provider chatbot with `gpt-4.1`, and an ML training pipeline with `Qwen3-8B`. No shell sandbox here: the SME ran the code locally and pasted back stdout, tracebacks, and observed behaviour. All three are `Solved with Recovery`, and the 19-of-34 negative-turn split across the batch is exactly the failure-then-recovery signal RLHI is built to consume. See `human_chat_rlhi/README.md` for per-session detail.

---

## Folder structure

```
openclaw-traj/
├── human_chat_rlhi/                           # one JSONL per session (flat layout)
│   ├── README.md                              # per-collection notes + per-session arc
│   ├── 2048GameDev.jsonl                      # 15 turns - Pygame 2048, agent: gpt-4.1
│   ├── chatbotDev.jsonl                       # 10 turns - dual-provider chatbot, agent: gpt-4.1
│   └── ml_problem_stmt.jsonl                  # 9 turns  - ML pipeline design, agent: Qwen3-8B
│
├── public_swe_bench/
│   ├── task/                                  # one folder per instance
│   │   └── <instance_id>/                     # e.g. django__django-12039
│   │       ├── problem_statement.md           # bug description (issue text)
│   │       ├── hints.md                       # optional PR hints / discussion
│   │       ├── instance.json                  # full SWE-bench record (patch, test_patch, F2P/P2P, eval_script)
│   │       ├── metadata.json                  # repo, base_commit, version, difficulty
│   │       ├── eval_script.sh                 # harness that applies test_patch and runs tests
│   │       ├── patches/
│   │       │   ├── gold.patch                 # reference fix
│   │       │   └── test.patch                 # tests injected at eval time
│   │       └── tests/
│   │           ├── fail_to_pass.json          # tests that must flip from FAIL → PASS
│   │           └── pass_to_pass.json          # tests that must remain PASS
│   └── trajectory/
│       └── <instance_id>/                     # matches task/<instance_id>
│           ├── meta.json                      # model, step_limit, PRM config, API base
│           ├── patch.diff                     # final patch produced by the agent
│           └── traj.json                      # full message-by-message agent transcript
│
├── novel_swe_bench/
│   ├── task/
│   │   └── <instance_id>/                     # e.g. john-kurkowski__tldextract-1
│   │       ├── problem_statement.md
│   │       ├── instance.json
│   │       ├── metadata.yaml                  # richer schema: difficulty signals, validation, etc.
│   │       ├── README.md                      # per-task notes (where present)
│   │       ├── environment/
│   │       │   ├── Dockerfile                 # builds the /testbed eval image from a repo snapshot
│   │       │   ├── setup.sh                   # in-container setup
│   │       │   └── eval.sh                    # in-container test runner
│   │       ├── patches/
│   │       │   ├── gold.patch
│   │       │   └── test.patch
│   │       └── tests/
│   │           ├── fail_to_pass.json
│   │           └── pass_to_pass.json
│   └── trajectory/
│       └── <instance_id>/
│           ├── meta.json
│           ├── patch.diff
│           └── traj.json
│
└── .gitignore
```

---

## File conventions

| File                                       | Purpose                                                                                                                                                                                                                                                                                                                                                       |
|--------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `problem_statement.md`                     | Natural-language description of the bug shown to the agent.                                                                                                                                                                                                                                                                                                   |
| `instance.json`                            | Canonical SWE-bench record: `base_commit`, gold patch, test_patch, `FAIL_TO_PASS`, `PASS_TO_PASS`, and `eval_script`.                                                                                                                                                                                                                                          |
| `metadata.json` / `metadata.yaml`          | Static metadata: repo, base commit, version/difficulty (and validation signals for novel tasks).                                                                                                                                                                                                                                                              |
| `patches/gold.patch`                       | Minimal reference fix used for validation.                                                                                                                                                                                                                                                                                                                    |
| `patches/test.patch`                       | Test additions injected into the repo at eval time (contains the F2P tests).                                                                                                                                                                                                                                                                                  |
| `tests/fail_to_pass.json`                  | Tests that must flip from failing → passing for a candidate patch to count as resolved.                                                                                                                                                                                                                                                                       |
| `tests/pass_to_pass.json`                  | Regression tests that must remain green.                                                                                                                                                                                                                                                                                                                      |
| `environment/Dockerfile` (novel only)      | Reproducible `/testbed` image built from a repo snapshot, with the test patch pre-applied.                                                                                                                                                                                                                                                                    |
| `trajectory/.../traj.json`                 | Full agent conversation: system prompt, user turns, assistant THOUGHT + single-bash action, tool returncodes/output — one entry per step.                                                                                                                                                                                                                     |
| `trajectory/.../patch.diff`                | The diff the agent ultimately submitted (`git add -A && git diff --cached`).                                                                                                                                                                                                                                                                                  |
| `trajectory/.../meta.json`                 | Run config: model, step_limit, max_tokens, and PRM (process reward model) settings used during the rollout.                                                                                                                                                                                                                                                   |
| `human_chat_rlhi/<session>.jsonl`          | One JSON object per agent turn of a chat-style RLHI session. Fields: `prompt`, `response`, `tokens`, `response_length`, `rollout_log_probs`, `loss_mask`, `reward` (averaged PRM score), `prm_votes` (per-judge votes), `prm_reason` (panel rationale), `opd_hint` (hindsight-guided distillation supervision), `next_state` (the SME's next user message), and `metadata` (session-level: `policy_backend`, `policy_model`, `finalized`, `timestamp`). |

---

## Instance IDs

- **SWE-bench collections (`public_swe_bench/`, `novel_swe_bench/`):** instance IDs follow `<owner>__<repo>-<n>`, e.g. `django__django-12039` or `john-kurkowski__tldextract-1`. The same ID is used as the directory name under both `task/` and `trajectory/`, so a task and its trajectory can always be paired by ID.
- **RLHI chat collection (`human_chat_rlhi/`):** trajectories are named after the project the SME was building - `2048GameDev`, `chatbotDev`, `ml_problem_stmt`. Each is a single self-contained `.jsonl` file; the problem statement is included as the first user prompt inside the file, so no separate `task/` folder is needed. Session-level metadata (agent model, backend, timestamps) is embedded on every record under the `metadata` field, so there is no separate `meta.json` to keep in sync either.
