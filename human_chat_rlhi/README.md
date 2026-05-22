# human_chat_rlhi

Real, multi-turn chats between an internal SME and an AI coding agent, captured verbatim and PRM-scored. This is the RLHI (Reinforcement Learning from Human Interaction) slice of the OpenClaw trajectory dataset.

There is **no shell sandbox** in this collection. The SME plays the role of the environment: they chat with the agent the way any normal user would, run whatever code it produces on their own machine, paste back the actual stdout / traceback / observed behaviour, say what worked and what didn't, and move on to the next thing they want built. No hints, no nudges, no hand-crafted corrections, just a normal back-and-forth with an AI coding assistant. The 3-judge gpt-4o-mini PRM panel scores every agent turn after the fact, which means the negative-signal turns surface organically from the conversation itself.

All three sessions in this collection were **solved with recovery**, i.e. the agent got the final artefact to a working state, but only after multiple PRM-negative turns the SME had to push the conversation through. That mid-trajectory failure-then-fix arc is the entire point of the RLHI batch: the negative turns are the supervised signal, the eventual recovery is the reward.

## Why this collection exists

This is the human-interaction surface. SWE-bench-style runs measure whether the agent can pass tests on its own, but they cannot measure whether it can be *worked with*, accept a bug report from a user, sit through a few failed attempts, take a pushback, and still land a working artefact at the end. The three sessions here capture exactly that loop with `gpt-4.1` and `Qwen3-8B`, with no scripted prompting and no hand-crafted hints. The negative-heavy turn distribution (19 of 34 scored turns) is the entire point: those are the moments where directive next-state signal lives, and where RL / OPD / DPO training has the most to learn from.

---

## Inventory

| # | Task name         | Domain                              | Agent (backend)        | Turns | +1.0 | +0.333 | −0.333 | −1.0 | 0 | Outcome              |
|---|-------------------|-------------------------------------|------------------------|-------|------|--------|--------|------|---|----------------------|
| 1 | `2048GameDev`     | Game development, Python / Pygame   | gpt-4.1 (OpenAI API)   | 15    | 3    | 0      | 0      | 11   | 1 | Solved with recovery |
| 2 | `chatbotDev`      | API integration, Python             | gpt-4.1 (OpenAI API)   | 10    | 3    | 0      | 0      | 4    | 3 | Solved with recovery |
| 3 | `ml_problem_stmt` | ML pipeline design, Python          | Qwen3-8B (SGLang)      | 9     | 5    | 0      | 0      | 4    | 0 | Solved with recovery |
| — | **Total**         | —                                   | —                      | **34**| **11**| **0** | **0** |**19**| **4** | —                |

PRM buckets:
- **+1.0 / +0.333**: positive turns (unanimous / majority)
- **−0.333 / −1.0**: negative turns (majority / unanimous)
- **0**: not scored: final user turns, or reasoning-only turns with no executable artefact to evaluate

The negative-heavy distribution (19 / 34 scored turns) is exactly the signal RLHI is built to harvest: every −1.0 turn is paired with the SME's next message in `next_state`, and an `opd_hint` derived from the recovery is stored on the same record. One record, three training modes (policy-gradient RL, on-policy distillation, DPO).

---

## Per-task detail

### 1. `2048GameDev`: Pygame implementation of 2048 (15 turns, agent: gpt-4.1)

**Setup.** SME asked the agent to build a 4×4 2048 game from scratch under a `2048Game/` folder, split across `game.py` (board / moves / merging / score), `display.py` (terminal renderer), and `main.py` (input loop with `w/a/s/d`/`q`). Game rules — starting tiles, slide-and-merge semantics, single-merge-per-move, post-move spawn, win at 2048, loss when no moves remain, were specified upfront.

**Where the agent stumbled.**
- **Turn 0 (−1.0):** initial code crashed with a `Traceback` on first run.
- **Turns 1, 3 (−1.0):** broken slide-and-merge logic — every input reported `"no move made"` even on clearly legal moves; tiles merged but never slid to fill gaps.
- **Turns 2, 4 (−1.0):** regression `AttributeError`s as the agent kept shipping partial `Game` classes missing `is_game_won` / `get_merged_values` after each rewrite.
- **Turn 5 (−1.0):** score didn't update on merges (the merge counted matches instead of summing merged tile values).
- **Turn 7 (−1.0):** after switching to a Pygame UI (`gui.py`), the score/best/next-tile/controls boxes overlapped and the controls text was clipped at the bottom.
- **Turns 9–12 (−1.0):** iterative Pygame layout pass, agent's UI math kept producing overlapping boxes, then a half-clipped "next tile" preview that bled into the board, then over-wide windows with the board shifted right.

**Where the agent recovered.**
- **Turn 6 (+1.0):** correct slide-then-merge-then-slide loop, proper merge-flag bookkeeping, accurate scoring.
- **Turn 8 (+1.0):** added undo / high-score / animation / next-tile-preview features cleanly on top of the working core.
- **Turn 13 (+1.0):** final Pygame layout pass — replaced the next-tile block with a plain number, fixed box geometry, controls and board no longer overlap. SME signed off with *"Great! The game works perfectly!"*.

**Why it's interesting for training.** Long stretch of unanimous-negative turns (11 / 15) interleaved with three clean unanimous-positive turns. The negative turns are dominated by *regressions the agent introduced itself* after the SME's bug reports, which is a much harder pattern to learn from than a single failed first attempt and a pattern that vanilla SFT data doesn't usually capture.

---

### 2. `chatbotDev`: Dual-provider Python chatbot (10 turns, agent: gpt-4.1)

**Setup.** SME wanted a single Python CLI chatbot that can route a conversation to either the OpenAI or Anthropic API based on user choice. Required the agent to handle: isolated conda environment, dotenv-based API-key loading, model selection, and a clean shared interface across the two SDKs.

**Where the agent stumbled.**
- **Turn 0 (−1.0):** ignored the isolated-env requirement entirely; SME had to ask for a fresh conda-env walkthrough.
- **Turn 1 (−1.0):** generated code crashed on first run (OpenAI path errored).
- **Turns 2, 3 (−1.0):** OpenAI started working but Anthropic kept raising wrong SDK call shape, then wrong model name string.
- **Turn 4 (0):** Anthropic model-listing script failed because the API key wasn't being read from the environment.
- **Turn 7 (0):** code-review nit from the SME, the agent had added a defensive *"only pass `system` if non-empty"* check inside `chat_anthropic` but not inside `chat_openai`, so behaviour diverged between providers.

**Where the agent recovered.**
- **Turn 5 (+1.0):** SME pasted a successful model-list output after loading the key explicitly; agent acknowledged and locked the API-key loading pattern in.
- **Turn 6 (+1.0):** clean rewrite pinning the Anthropic model to `claude-haiku-4-5-20251001`, no auto-detect, both providers wired through the same call surface.
- **Turn 8 (+1.0):** symmetric defensive check added to `chat_openai`; SME confirmed *"Great, this works perfectly with the rest of the code."*

**Why it's interesting for training.** The stumbles are characteristic *integration* failures, wrong env assumptions, deprecated model names, asymmetric defensive code, which are exactly the failure modes SFT corpora under-represent because they only show up when you actually run the code against a real API. The recovery turns are also a good example of the agent absorbing a code-review-style comment and applying the fix consistently across both branches of a code path.

---

### 3. `ml_problem_stmt`: ML training-pipeline design for follow-up question generation (9 turns, agent: Qwen3-8B)

**Setup.** SME asked the agent to scope an end-to-end pipeline for fine-tuning a generator that, given an initial user question, produces multiple plausible follow-up questions. The session is design-heavy (this is the open-weight Qwen3-8B agent, run through SGLang) rather than crash-debug-heavy.

**Where the agent stumbled.**
- **Turn 1 (−1.0):** first dataset-construction proposal leaned on manual annotation, which the SME rejected as infeasible at scale.
- **Turn 3 (−1.0):** sample generation code was missing the system-prompt slot entirely, the agent had written a `generate_follow_ups_gpt3(prompt)` function with no place for the SME to inject role instructions.
- **Turn 4 (−1.0):** code used the source dataset's context field alongside the initial question, but the SME wanted the model trained strictly on the *(initial question → follow-up question)* pair, no auxiliary context.
- **Turn 6 (−1.0):** agent defaulted to T5 as the generation backbone; SME pushed back on capability grounds and asked for Llama or Mistral.

**Where the agent recovered.**
- **Turns 0, 2 (+1.0):** crisp pipeline outline; clean hybrid (existing datasets + LLM augmentation) data-construction plan.
- **Turn 5 (+1.0):** correct vLLM port of the generation step, with batched inference and self-hosted-GPU assumptions made explicit.
- **Turns 7, 8 (+1.0):** sound choice of Llama-3-8B-Instruct as the backbone with a defensible sample-count target (low-tens-of-thousands of pairs for a first fine-tune).

**Why it's interesting for training.** The negative turns aren't crashes, they're *taste* and *requirements-matching* failures (right plan, wrong assumptions). Those are exactly the turns where on-policy distillation (`opd_hint`) and DPO-style preference mining have the most to teach a small open-weight model, because the scalar reward by itself doesn't tell the agent which constraint it violated.

---

## Folder layout

```
human_chat_rlhi/
├── README.md             # this file
├── 2048GameDev.jsonl     # 15 turns - Pygame 2048, agent: gpt-4.1
├── chatbotDev.jsonl      # 10 turns - dual-provider chatbot, agent: gpt-4.1
└── ml_problem_stmt.jsonl #  9 turns - ML pipeline design, agent: Qwen3-8B
```

One file per session. Each file is line-delimited JSON: one record per agent turn, in chronological order, using the schema in the **Per-turn record schema** section below. Session-level metadata (`policy_backend`, `policy_model`, `finalized`, `timestamp`) lives on every record under the `metadata` field, so there is no separate `meta.json` to keep in sync.

---

## Configuration

| Item                              | Value                                                                 |
|-----------------------------------|-----------------------------------------------------------------------|
| Coding agent (sessions 1 & 2)     | `gpt-4.1` via the OpenAI Chat Completions API                          |
| Coding agent (session 3)          | `Qwen3-8B` served locally through SGLang                               |
| PRM judge panel                   | 3 × `openai/gpt-4o-mini`, votes averaged per turn                      |
| Human-in-the-loop                 | Internal SME (Developer)|
| Sandbox / environment             | None, SME runs code locally and reports observations                  |
| Turn budget per session           | Open-ended (each session ran until the SME accepted the final result)  |

---

## Per-step record (.jsonl)

Identical to the SWE-Bench and Novel slices of OpenClaw, so the same downstream trainer consumes all 18 trajectories without any format conversion.

| Field               | Description                                                                                              |
|---------------------|----------------------------------------------------------------------------------------------------------|
| `id`                | Unique turn ID.                                                                                          |
| `session_id`        | Trajectory ID (matches the JSONL filename).                                                              |
| `turn_index`        | 0-based turn index within the session.                                                                   |
| `turn_type`         | `agent` for every record in this collection.                                                             |
| `prompt`            | Full conversation context up to and including the SME's most recent message.                             |
| `response`          | The agent's reply to that prompt, verbatim, with code blocks preserved.                                  |
| `tokens`            | Raw token IDs of the agent's response.                                                                   |
| `response_length`   | Token count of the response.                                                                             |
| `rollout_log_probs` | Per-token log-π under the policy that produced the response — directly trainable with GRPO / PPO.        |
| `loss_mask`         | Per-token mask indicating which tokens contribute to the training loss.                                  |
| `reward`            | `{ "score": float }` — average PRM score for this turn.                                                  |
| `prm_votes`         | The 3 individual +1 / −1 votes cast by the panel.                                                        |
| `prm_reason`        | The panel's textual rationale for the score.                                                             |
| `opd_hint`          | Hindsight-guided teacher target derived from the next SME correction (consumed by On-Policy Distillation).|
| `next_state`        | The SME's next user-turn message — closes the loop and pushes the trajectory forward.                    |
| `metadata`          | Session-level metadata: `policy_backend`, `policy_model`, `finalized`, `timestamp`.                      |

A single record is simultaneously consumable by:
- **Policy-gradient RL** — `(prompt, response, rollout_log_probs, reward)`.
- **On-policy distillation** — `opd_hint` as the teacher target.
- **DPO-style preference mining** — positively vs. negatively scored turns inside the same session.

No separate annotation pass required.

## Evaluation

There is no automated harness for chat trajectories. The SME is the oracle: they run the agent's code on their own machine and judge whether each turn helped or hurt. Every agent turn is then post-hoc scored by the same 3-judge `openai/gpt-4o-mini` PRM panel used across the SWE-bench collections: three independent `+1` / `−1` votes per turn, averaged into one of five outcomes (`+1.0`, `+0.333`, `−0.333`, `−1.0`, or `0` when the panel does not issue a verdict). A session is recorded under a category, for example Solved with Recovery when the agent reaches an artefact the SME accepts after at least one unanimous-negative turn that was later corrected, or Clean Solution when it lands a working result with majority-positive turns and no unanimous-negative turn anywhere in the trajectory.
