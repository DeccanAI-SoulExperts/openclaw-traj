# human_chat_rlhi

Human-in-the-loop chat trajectories collected during the OpenClaw **RLHI** (Reinforcement Learning from Human Interaction).

Each file in this folder is one complete chat session between a coding agent (`Qwen3-8B`) and a human subject-matter expert (SME) co-solving a real competitive-programming problem inside the OpenClawRL environment. The PRM judge panel scores every agent turn just as in the SWE-bench batches, so the trajectory ends up in the same `(state, action, reward)` shape as everything else in this repo and feeds the same training pipeline.

## Contents

| File | Source problem | Turns |
|---|---|---:|
| `super-permutation.jsonl` | Codeforces 1822D — Super-Permutation | 13 |
| `snail-and-tree.jsonl` | Codeforces 1810D - Snail climbing a tree | 20 |
| `dishonest-sellers.jsonl` | Codeforces 779C — Dishonest Sellers + 2 SME-authored extensions | 11 |
| `cutting-out.jsonl` | Codeforces 1077D — Cutting Out + planned SME extensions | 13 |

Each file is JSON-Lines: one JSON object per agent turn. The original problem statement is the first `user` message of the first turn's `prompt`, so no separate task file is needed.

## Configuration

All four sessions were run with the same configuration. The field names follow the same `meta.json` schema used in `public_swe_bench/` and `novel_swe_bench/` so the three collections can be compared field-by-field.

| Field | Value | Notes |
|---|---|---|
| `model` | `Qwen3-8B` | Coding agent under evaluation. |
| `api_base` | `https://api.openai.com/v1` | OpenAI-compatible endpoint serving the agent. |
| `max_tokens` | `4096` | Per-turn generation cap. |
| `step_limit` | unbounded (SME-terminated) | Chat sessions end when the SME considers the task solved; the four trajectories here range from 11 to 20 turns. |
| `prm_enable` | `true` | Every action turn is scored by the PRM panel. |
| `prm_api_base` | `https://api.openai.com/v1` | Same endpoint as `api_base`. |
| `prm_api_model` | `openai/gpt-4o-mini` | Identical to the SWE-bench setup. |
| `prm_panel_size` | `3` | Three independent judges per scored turn. |
| `prm_score_aggregation` | mean of per-judge votes | Each judge votes ∈ {+1, −1}; the average is one of `{+1.0, +0.333, −0.333, −1.0}`, or `0` when no verdict was issued. |
| `prm_step_coef` | `1.0` | Per-turn reward scaling factor; identical to the SWE-bench setup. |
| `human_in_the_loop` | internal SME | Writes the next user message whenever the agent stalls or produces a negatively-scored step. |
| `record_log_probs` | `true` | Per-token rollout log-probabilities and a loss mask are recorded with every agent response. |
| `record_opd_hint` | `true` | A hindsight-guided directive is stored on negatively-scored turns for use as OPD teacher supervision. |

## Per-turn record schema

Every line in `*.jsonl` is one turn with the following fields:

| Field | Type | Meaning |
|---|---|---|
| `id` | string | Stable per-turn identifier. |
| `session_id` | string | Identifier of the chat session this turn belongs to. |
| `turn_index` | int | Zero-based index inside the session. |
| `turn_type` | string | `main` for normal agent turns. |
| `prompt` | list of `{role, content}` | Full conversation context up to and including the most recent SME message. The first turn's `prompt[0].content` is the original problem statement. |
| `response` | string | The agent's reply, verbatim, with code blocks preserved. |
| `tokens` | list of int | Token IDs of `response` under the agent's tokenizer. |
| `response_length` | int | Number of tokens in `response`. |
| `rollout_log_probs` | list of float | Per-token log-probability under the policy that produced `response`. |
| `loss_mask` | list of int | Per-token mask (1 = trainable, 0 = skip) for downstream loss computation. |
| `reward.score` | float | Averaged PRM score for this turn ∈ `{+1.0, +0.333, −0.333, −1.0, 0}`. |
| `prm_votes` | list of int | Individual +1 / −1 votes cast by the panel. Length equals `prm_panel_size` for scored turns; `[]` for unscored turns. |
| `prm_reason` | string | The panel's textual rationale for the score. |
| `opd_hint` | string | Hindsight-guided directive used as teacher supervision by the OPD trainer. |
| `next_state.role` | `"user"` | Always `"user"` — this is what the SME sends back to close the loop. |
| `next_state.content` | string | The next message that pushes the trajectory forward. |
| `metadata.timestamp` | float | Unix timestamp at which the turn was finalised. |
| `metadata.finalized` | bool | `true` once the turn has been scored and `next_state` has been written. |

## How these trajectories can be used

Because each turn carries reward, per-token log-probabilities, a loss mask, an OPD hint, and the SME's correction, a single chat trajectory feeds several training tracks at once:

- **Policy-gradient RL (PPO / GRPO)** — `(state, action, reward, log-π)` tuples are present per turn with no extra preprocessing.
- **On-policy distillation (OPD)** — `opd_hint` converts the SME's next-state correction into a teacher-style supervised target.
- **DPO-style preference pairs** — a positively-scored turn and a negatively-scored turn on the same prompt prefix form a natural preference pair; many such pairs can be mined from one trajectory.
- **Recovery training** — the `(negative turn → SME correction → positive turn)` triplet teaches the model how to interpret a corrective message at inference time.
- **PRM training and stress-testing** — every action has both a PRM score and a downstream SME correction, so the same data fine-tunes the next-generation PRM.
