# openclaw-traj

A small dataset of **SWE-bench–style task instances** paired with **agent trajectories**, plus a set of **human-in-the-loop chat trajectories** captured during OpenClaw evaluation runs.

Each task describes a real (or synthetic) software-engineering bug taken from an open-source Python project, along with the gold patch, failing/passing tests, and an evaluation harness. Each accompanying trajectory contains the full step-by-step interaction of an agent (currently `gpt-5` with a PRM reward model enabled) attempting to solve that task in a sandboxed shell.

Each human chat trajectory is a turn-by-turn conversation between a person and a coding agent working through a real software-engineering problem — coding tasks, building applications, API integration, pipeline design, and similar — with a PRM judge panel scoring every agent turn after the fact.

The repo currently contains three collections:

- `**public_swe_bench/`** — instances drawn from the public SWE-bench benchmark (Django, SymPy, Astropy, Moto, …).
- `**novel_swe_bench/`** — self-contained instances authored in the MERGE-Bench style (tldextract, python-slugify, python-progressbar, mcpdoc).
- `**human_chat_rlhi/**` — multi-turn human–agent chats on real software-engineering work: coding problems, building applications, integrations, and other hands-on dev tasks captured as full conversations.

## Trajectory catalog

This release ships **18 demonstration trajectories** (5 novel SWE-bench, 10 public SWE-bench, 3 RLHI chat). Each row below labels how the agent reached the final artefact. **Start with the three featured trajectories** — they are the strongest examples across the three collection types.

### Trajectory categories


| Label                      | Meaning                                                                                                                                                                                              |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Clean Solution**         | The agent solved the task in a direct path: few or no PRM-negative steps, no human correction, and the final patch (or artefact) passes evaluation.                                                  |
| **Solved with Recovery**   | The task was ultimately solved, but only after wrong turns, regressions, or PRM-negative steps that the agent (or SME, in chat) had to recover from.                                                 |
| **Failed with step limit** | The agent exhausted its step budget without producing a passing patch. *(None in the current release.)*                                                                                              |
| **Human corrected RLHI**   | Chat trajectories where the SME supplied the next user turn after each PRM-negative agent step; all three chat sessions in this release are **Solved with Recovery** under that interaction pattern. |


### Featured trajectories (start here)


| Collection  | Instance / file                                                                            | Category             | Why highlight                                                                                                                                                                          |
| ----------- | ------------------------------------------------------------------------------------------ | -------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Novel SWE   | `[john-kurkowski__tldextract-1](novel_swe_bench/trajectory/john-kurkowski__tldextract-1/)` | Clean Solution       | Straight-line MERGE-style fix on a self-contained repo; good first read for the novel harness.                                                                                         |
| Open Source | `[getmoto__moto-6226](public_swe_bench/trajectory/getmoto__moto-6226/)`                    | Clean Solution       | Compact public SWE-bench solve with minimal backtracking.                                                                                                                              |
| Chat (RLHI) | `[ml_problem_stmt.jsonl](human_chat_rlhi/ml_problem_stmt.jsonl)`                           | Solved with Recovery | Design-heavy SME session; strong mix of PRM-negative requirement mismatches and clean recoveries — see `[human_chat_rlhi/README.md](human_chat_rlhi/README.md)` for turn-level detail. |


### Full inventory

Paths use the **instance ID** (directory name under `task/` and `trajectory/`). Rollout run IDs (numeric suffixes in internal logs) are omitted here because the repo pairs each task with a single canonical trajectory folder.


| Trajectory type | Instance / file                       | Category             |
| --------------- | ------------------------------------- | -------------------- |
| Novel SWE       | `john-kurkowski__tldextract-1`        | Clean Solution       |
| Novel SWE       | `john-kurkowski__tldextract-2`        | Solved with Recovery |
| Novel SWE       | `langchain-ai__mcpdoc-1`              | Solved with Recovery |
| Novel SWE       | `NiltonVolpato__python-progressbar-1` | Solved with Recovery |
| Novel SWE       | `un33k__python-slugify-1`             | Clean Solution       |
| Open Source     | `astropy__astropy-7606`               | Clean Solution       |
| Open Source     | `django__django-12039`                | Solved with Recovery |
| Open Source     | `django__django-12304`                | Solved with Recovery |
| Open Source     | `django__django-14915`                | Solved with Recovery |
| Open Source     | `django__django-15569`                | Solved with Recovery |
| Open Source     | `getmoto__moto-4860`                  | Solved with Recovery |
| Open Source     | `getmoto__moto-5502`                  | Clean Solution       |
| Open Source     | `getmoto__moto-5515`                  | Clean Solution       |
| Open Source     | `getmoto__moto-6226`                  | Clean Solution       |
| Open Source     | `sympy__sympy-18189`                  | Solved with Recovery |
| Chat            | `2048GameDev.jsonl`                   | Solved with Recovery |
| Chat            | `chatbotDev.jsonl`                    | Solved with Recovery |
| Chat            | `ml_problem_stmt.jsonl`               | Solved with Recovery |


**Where to open each trajectory**


| Trajectory type | Path pattern                                                                         |
| --------------- | ------------------------------------------------------------------------------------ |
| Novel SWE       | `novel_swe_bench/trajectory/<instance_id>/` (`traj.json`, `patch.diff`, `meta.json`) |
| Open Source     | `public_swe_bench/trajectory/<instance_id>/`                                         |
| Chat            | `human_chat_rlhi/<task>.jsonl`                                                       |


## Folder structure

```
openclaw-traj/
├── human_chat_rlhi/                           # one JSONL per trajectory
│   ├── README.md                              # per-collection notes (model, judge, fields)
│   ├── 2048GameDev.jsonl                      # Pygame 2048 game (gpt-4.1)
│   ├── chatbotDev.jsonl                       # dual-provider Python chatbot (gpt-4.1)
│   └── ml_problem_stmt.jsonl                  # ML pipeline design (Qwen3-8B)
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

## File conventions


| File                                    | Purpose                                                                                                                                                                                                                                                                                                                                       |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `problem_statement.md`                  | Natural-language description of the bug shown to the agent.                                                                                                                                                                                                                                                                                   |
| `instance.json`                         | Canonical SWE-bench record: `base_commit`, gold `patch`, `test_patch`, `FAIL_TO_PASS`, `PASS_TO_PASS`, and `eval_script`.                                                                                                                                                                                                                     |
| `metadata.json` / `metadata.yaml`       | Static metadata: repo, base commit, version/difficulty (and validation signals for novel tasks).                                                                                                                                                                                                                                              |
| `patches/gold.patch`                    | Minimal reference fix used for validation.                                                                                                                                                                                                                                                                                                    |
| `patches/test.patch`                    | Test additions injected into the repo at eval time (contains the F2P tests).                                                                                                                                                                                                                                                                  |
| `tests/fail_to_pass.json`               | Tests that must flip from failing → passing for a candidate patch to count as resolved.                                                                                                                                                                                                                                                       |
| `tests/pass_to_pass.json`               | Regression tests that must remain green.                                                                                                                                                                                                                                                                                                      |
| `environment/Dockerfile` *(novel only)* | Reproducible `/testbed` image built from a repo snapshot, with the test patch pre-applied.                                                                                                                                                                                                                                                    |
| `trajectory/.../traj.json`              | Full agent conversation: system prompt, user turns, assistant THOUGHT + single-`bash` action, tool returncodes/output — one entry per step.                                                                                                                                                                                                   |
| `trajectory/.../patch.diff`             | The diff the agent ultimately submitted (`git add -A && git diff --cached`).                                                                                                                                                                                                                                                                  |
| `trajectory/.../meta.json`              | Run config: `model`, `step_limit`, `max_tokens`, and PRM (process reward model) settings used during the rollout.                                                                                                                                                                                                                             |
| `human_chat_rlhi/<task>.jsonl`          | One JSON object per turn of a chat-style RLHI session. Fields include `prompt`, `response`, `tokens`, `rollout_log_probs`, `loss_mask`, `reward` (averaged PRM score), `prm_votes` (per-judge votes), `prm_reason` (panel rationale), `opd_hint` (hindsight-guided distillation supervision), and `next_state` (the SME's next user message). |


## Instance IDs

- **SWE-bench collections** (`public_swe_bench/`, `novel_swe_bench/`): instance IDs follow `<name>__<repo>-<n>`, e.g. `django__django-12039` or `john-kurkowski__tldextract-1`. The same ID is used as the directory name under both `task/` and `trajectory/`, so a task and its trajectory can always be paired by ID.
- **Human chat collection** (`human_chat_rlhi/`): trajectories are named after the software-engineering task itself — `2048GameDev`, `chatbotDev`, `ml_problem_stmt`. Each is a single self-contained `.jsonl` file; the problem statement is included as the first user `prompt` inside the file, so no separate `task/` folder is needed.

