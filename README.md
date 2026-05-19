# openclaw-traj

A small dataset of **SWE-bench–style task instances** paired with **agent trajectories** captured during OpenClaw evaluation runs.

Each task describes a real (or synthetic) software-engineering bug taken from an open-source Python project, along with the gold patch, failing/passing tests, and an evaluation harness. Each accompanying trajectory contains the full step-by-step interaction of an agent (currently `gpt-5` with a PRM reward model enabled) attempting to solve that task in a sandboxed shell.

The repo currently contains two collections:

- **`public_swe_bench/`** — instances drawn from the public SWE-bench benchmark (Django, SymPy, Astropy, Moto, …).
- **`novel_swe_bench/`** — self-contained instances authored in the MERGE-Bench style (tldextract, python-slugify, python-progressbar, mcpdoc).

## Folder structure

```
openclaw-traj/
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

| File | Purpose |
|---|---|
| `problem_statement.md` | Natural-language description of the bug shown to the agent. |
| `instance.json` | Canonical SWE-bench record: `base_commit`, gold `patch`, `test_patch`, `FAIL_TO_PASS`, `PASS_TO_PASS`, and `eval_script`. |
| `metadata.json` / `metadata.yaml` | Static metadata: repo, base commit, version/difficulty (and validation signals for novel tasks). |
| `patches/gold.patch` | Minimal reference fix used for validation. |
| `patches/test.patch` | Test additions injected into the repo at eval time (contains the F2P tests). |
| `tests/fail_to_pass.json` | Tests that must flip from failing → passing for a candidate patch to count as resolved. |
| `tests/pass_to_pass.json` | Regression tests that must remain green. |
| `environment/Dockerfile` *(novel only)* | Reproducible `/testbed` image built from a repo snapshot, with the test patch pre-applied. |
| `trajectory/.../traj.json` | Full agent conversation: system prompt, user turns, assistant THOUGHT + single-`bash` action, tool returncodes/output — one entry per step. |
| `trajectory/.../patch.diff` | The diff the agent ultimately submitted (`git add -A && git diff --cached`). |
| `trajectory/.../meta.json` | Run config: `model`, `step_limit`, `max_tokens`, and PRM (process reward model) settings used during the rollout. |

## Instance IDs

Instance IDs follow `<name>__<repo>-<n>`, e.g. `django__django-12039` or `john-kurkowski__tldextract-1`. The same ID is used as the directory name under both `task/` and `trajectory/`, so a task and its trajectory can always be paired by ID.
