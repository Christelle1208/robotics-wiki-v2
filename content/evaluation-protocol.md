# Evaluation Protocol — Robot Learning Policies

Evaluating a robot learning policy is not just about measuring success rate on the training distribution. A policy that achieves 95% in-distribution success may completely fail when an object is 5cm further away, or when a lamp is turned on. This page defines a standardized evaluation protocol that measures performance across multiple axes to give an honest picture of what a policy *actually* does.

This protocol is designed to be algorithm-agnostic — it applies equally to SAC, ACT, SmolVLA, and any other approach, enabling fair cross-algorithm comparison.

→ See [[decision-guide]] for training guidance. See [[overview]] for the three paradigm families.

---

## Glossary

| Term | Meaning |
|------|---------|
| **ID** | In-Distribution — conditions that match the training setup exactly (same object positions, orientations, lighting) |
| **OOD** | Out-of-Distribution — conditions not seen during training |
| **N** | Number of trials run for a given condition |
| **CI** | Confidence Interval — the range of true success rates consistent with what you observed. A 95% CI means: if you repeated the experiment many times, 95% of those intervals would contain the true rate |
| **pp** | Percentage points — the unit of a CI width. "±12 pp at 80%" means the true rate is likely between 68% and 92% |

---

## Why a standardized protocol matters

Without a protocol, results are incomparable:
- "90% success" means nothing if it was measured on 10 trials in ideal conditions
- A policy that achieves 85% with fixed objects but 20% with varied positions is not as good as one that achieves 75% on both
- Generalization to new objects is the key advantage of VLAs — but it only shows up if you test for it

The goal is not just a single number, but a **profile** across multiple axes.

---

## Evaluation axes

### Axis 1 — In-Distribution (ID)
> *Does the policy work on the exact conditions it was trained/tuned for?*

This is the baseline. If the policy can't pass this, nothing else matters.

**Conditions:** exact training distribution — same objects, same positions (sampled from training range), same lighting, same camera setup.

**What to measure:** success rate, execution time, trajectory smoothness (optional).

**Number of trials:** minimum 50. Use 100+ for publication-quality results. Stratify across the training position range (don't just test the center).

---

### Axis 2 — Near Out-of-Distribution (near-OOD)
> *Does the policy generalize to small, realistic variations it wasn't trained on?*

These are the variations that will inevitably appear in real deployment even if you try to replicate training conditions exactly.

**Conditions to test:**

| Variation | How to test | Notes |
|-----------|------------|-------|
| Object position — unseen grid squares | Place object in the 4 held-out grid squares (within the same 24×16cm workspace) | Tests spatial interpolation within the known workspace |
| Object orientation — random angles | Place the cube at a random angle not snapped to 0° or 45° (e.g. 22°, 67°) | Cube symmetry means 0°/90°/180° are equivalent faces — arbitrary angles are the true OOD condition |
| Slight lighting change (+/- 30% ambient) | Change room lighting or time of day | Keep object and camera positions identical |
| One distractor object added | Place one irrelevant object in the workspace | Use object clearly distinct from the target |
| Camera position shift (1–2cm) | Move camera slightly from trained position | Record exact offset for reproducibility |

**Number of trials:** 30 per condition (5–6 conditions = 150–180 trials total).

---

### Axis 3 — Far Out-of-Distribution (far-OOD)
> *What does the policy do when it encounters conditions very different from training?*

This tests the limits of generalization. Expected to be lower; the goal is to understand *how* the policy fails, not just whether it does.

**Conditions to test:**

| Variation | How to test | Notes |
|-----------|------------|-------|
| New object color/texture | Replace trained object with same shape, different color | Record whether failure is at approach, grasp, or place phase |
| New object shape (same category) | Replace cube with cylinder or irregular shape | Note if robot attempts grasp at all |
| Multiple distractors (3–5) | Add several irrelevant objects of varied types | Note whether robot ignores them or fixates on them |
| Strong lighting change | Test under spotlight/shadow vs training lighting | Document lighting setup precisely |
| Object position outside the training grid | Place object beyond the 24×16cm boundary | Quantifies spatial extrapolation vs interpolation |
| Language instruction paraphrase (VLA only) | "Pick up the X" → "Grab the X" / "Take the X" | VLA-specific: tests instruction robustness |
| New object category (VLA only) | Replace with semantically related but untrained object | Cross-category generalization via pretrained knowledge |

**Number of trials:** 20 per condition. These results are **qualitative/characterization only** — sample size is insufficient for inferential statistics (see Statistical Reporting below). Focus on failure mode, not success rate.

---

### Axis 4 — Robustness to perturbations
> *Does the policy recover when something unexpected happens mid-execution?*

Real deployments involve unexpected events. A policy that achieves 95% in clean conditions but cannot recover from a light perturbation is less deployable than a 80% policy that recovers gracefully.

**Perturbation types to test:**

| Perturbation | Method | Recovery criterion |
|-------------|--------|-------------------|
| **Object slip** (grasp disturbed mid-air) | Gently push object during grasp phase | Does the robot re-attempt grasp? |
| **Object displacement** (repositioned mid-task) | Move object 5cm while robot is approaching | Does the robot track the new position? |
| **Temporary occlusion** | Block camera view for 1 second | Does the policy resume on vision recovery? |
| **Human intervention** | Briefly hold the robot arm during execution | Does it resume smoothly? |
| **Missed grasp** (object not picked up) | Let gripper close on empty air | Does the robot detect failure and retry? |

**Protocol:**
1. Run 20 trials per perturbation type
2. For each trial, record: (a) did the robot detect the perturbation?, (b) did it recover?, (c) what was the final task success?
3. Report: perturbation recovery rate separately from task success rate

---

### Axis 5 — Consistency and reliability
> *Is the policy consistently good, or does it have high variance?*

A policy with 80% mean success but ±30% standard deviation across runs is less reliable than a 75% policy with ±5% deviation.

**What to measure:**
- **Success rate per grid square**: break down success by position within the training grid. Reveals spatial blind spots.
- **Success rate vs episode index**: does performance drop across a session (fatigue effects, actuator heating, visual drift)?
- **Failure mode classification**: categorize failures into: (a) grasping failure, (b) placement failure, (c) approach failure, (d) perception failure, (e) timeout. The distribution tells you where to focus improvement.

---

## Standard metrics

| Metric | Definition | When to use |
|--------|-----------|-------------|
| **Success rate** | Fraction of trials where task completes fully | Primary metric for all evaluations |
| **Progress score** | Fraction of task stages completed (0–1) | Better than binary for long-horizon tasks |
| **Recovery rate** | Fraction of perturbation trials where policy recovers | Axis 4 specifically |
| **Execution time** | Mean time to task completion in successful trials | Efficiency comparison |
| **Trajectory smoothness** | Mean jerk across execution | Optional; proxy for control quality |
| **Failure mode breakdown** | % of failures attributable to each failure type | Diagnostic metric for improvement |

---

## Statistical reporting

Never report a success rate without saying how many trials it came from. "83% success" measured on 12 trials is very different from 83% on 100 trials — the first could plausibly be anywhere from 55% to 95% true success rate.

**How to read the table below:** each cell gives the margin of error (±) around your observed success rate, at 95% confidence. Example: if you run 30 trials and observe 83% success, the true success rate is likely somewhere between 70% and 96% — a ±13 pp margin. This means you cannot confidently distinguish 83% from 75% at that sample size.

**95% CI margin of error by (N, observed success rate):**

| N \ success rate | 60% | 75% | 83% | 90% |
|-----------------|-----|-----|-----|-----|
| **12** (small batch) | ±27 pp | ±24 pp | ±21 pp | ±16 pp |
| **20** (far-OOD) | ±21 pp | ±19 pp | ±16 pp | ±13 pp |
| **30** (near-OOD) | ±17 pp | ±15 pp | ±13 pp | ±11 pp |
| **50** (ID) | ±13 pp | ±12 pp | ±10 pp | ±8 pp |
| **100** (publication) | ±9 pp | ±8 pp | ±7 pp | ±6 pp |

*Computed using the Wilson score interval, which is more accurate than the standard formula at small N or extreme proportions.*

**How to report results depending on how many trials you ran:**

**N ≥ 30** — you have enough trials to make a real claim. Report the full number: e.g. `83% (25/30) [CI: 70%–96%]`. The CI tells the reader exactly how precise your estimate is, and they can compare it against other algorithms with the same format.

**N = 20** — the margin is still ±16–21 pp, which is wide. You can still report the number, but signal clearly that it's not precise enough for direct comparison. Write something like: `75% (15/20) — characterization only`. This means: "this tells us roughly what happens in this condition, but don't read too much into the exact number."

**N < 20** — the margin is so wide (±27 pp at N=12) that the point estimate is nearly meaningless for comparison. You can still note qualitative observations ("the robot failed every time" or "it mostly succeeded") — that's useful. But don't write `58% vs 25%` and imply one is meaningfully better than the other.

**For the current SO-100 results** — most OOD cells have N=4–5 (e.g. `2/4`, `1/4`), giving a margin of ~±40 pp. Those numbers are directional signals, not measurements. The only cells with any inferential value are the 12-trial ID batches, and even those carry ±21 pp uncertainty.

---

## Protocol for the SO-100 pick-and-place experiments

This section operationalizes the axes above for the specific experimental setup.

### Test configuration

| Parameter         | Value                                                      |
| ----------------- | ---------------------------------------------------------- |
| Robot             | SO-100 (6-DoF)                                             |
| Task              | Pick-and-place: grasp object from the ground, place in bin |
| Objects           | Cubes of different colors : red, green, yellow             |
| Camera setup      | Side camera + Wrist camera                                 |
| Episode timeout   | 60 seconds                                                 |
| Success criterion | Cube dropped in the box                                    |

---

### Training zone definition

The object position space is a **4×4 grid of 6×4 cm squares**, covering a total workspace of **24×16 cm** in front of the robot.

| Property | Value |
|----------|-------|
| Total workspace | 24 cm × 16 cm (4×4 grid of 6×4 cm squares) |
| Training squares | 12 of 16 squares (75% of grid) |
| Held-out squares | 4 of 16 squares (25% of grid) — used as near-OOD evaluation positions |
| Training orientations | 0° (majority of demos) and 45° |
| Held-out orientations | Random/arbitrary angles — cube symmetry means 0°/90°/180° are the same face, so near-OOD = any angle not snapped to 0° or 45° |

**OOD thresholds expressed as % of training coverage:**
- **Near-OOD (position):** held-out squares are within the same 24×16 cm boundary — the policy has never seen these positions but the workspace is identical. Coverage gap: 25% of the grid.
- **Far-OOD (position):** object placed outside the 24×16 cm boundary — full extrapolation beyond the known workspace.
- **Near-OOD (orientation):** random angles not snapped to 0° or 45° (e.g. 22°, 67°) — same object, same workspace, but the cube face the robot sees is genuinely new. Note: for a cube, 90°/180° are equivalent to 0°, so these are not OOD.
- **Far-OOD (orientation):** random angle combined with OOD position — both axes unseen simultaneously.

---

### Trial count justification

| Axis | N per condition | Justification |
|------|----------------|---------------|
| **ID** | 50 | At 80% success, Wilson 95% CI = ±12 pp — sufficient for cross-algorithm comparison |
| **Near-OOD** | 30 | Minimum N to detect a 20 pp difference at 80% power between two policies; CI ≈ ±15 pp at 75% success |
| **Far-OOD** | 20 | Characterization only — not inferential. Goal is to identify failure mode, not estimate success rate. Flag all far-OOD results accordingly |
| **Perturbation** | 20 | Same as far-OOD: qualitative characterization of recovery behavior |

N = 100+ is recommended for any result intended for publication or formal comparison.

---

### Model training context

Comparison is only fair when the training compute behind each model is made explicit. SmolVLA brings a pretrained backbone trained on millions of demonstrations at industrial scale; ACT and SAC are trained from scratch or from a small demo set on standard hardware. These are not equivalent starting points.

| Model       | Hardware                         | Training time | Dataset                                                      | Parameters                              |
| ----------- | -------------------------------- | ------------- | ------------------------------------------------------------ | --------------------------------------- |
| **ACT**     | 1× NVIDIA A10G (AWS g5.2xlarge)  | 4h 28m 10s    | ~111 demos (Dataset_v4), 100k steps                          | ~87M                                    |
| **SmolVLA** | 4× NVIDIA A10G (AWS g5.12xlarge) | 2h 41m 01s    | ~111 demos (Dataset_v4), 20k steps — *full fine-tuning only* | ~450M (pretrained on millions of demos) |
| **SAC**     | *[to fill]*                      | *[to fill]*   | 0 demos (reward-based), *[to fill]* sim steps                | *[to fill]*                             |

**Key interpretive note:** SmolVLA's 450M parameters encode knowledge from large-scale pretraining — the 2h41m fine-tuning is only the adaptation phase. ACT's 4h28m is the full training from the demo set. Comparing their wall-clock time directly is misleading; the relevant question is what each method achieves given its total compute and data budget.

---

### Test matrix (minimum required)

| Axis | Conditions | Trials per condition | Total trials |
|------|-----------|---------------------|-------------|
| ID | Training distribution (12 training squares, 0° and 45°) | 50 | 50 |
| Near-OOD: position | 4 held-out grid squares | 30 | 30 |
| Near-OOD: orientation | Object at random angle (not 0° or 45°) | 30 | 30 |
| Near-OOD: lighting | Ambient light ±30% | 30 | 30 |
| Near-OOD: distractor | 1 irrelevant object added | 30 | 30 |
| Far-OOD: new color | Same object, different color | 20 | 20 |
| Perturbation: slip | Object pushed during grasp | 20 | 20 |
| **Total** | | | **~210 trials** |

---

### Per-algorithm comparison table (Dataset_v4 results)

| Algorithm | ID (0°) | ID (45°) | Near-OOD pos. (0°) | Near-OOD pos. (45°) | Novel random pos. | Distractor |
|-----------|---------|---------|-------------------|--------------------|--------------------|-----------|
| SAC (sim) | 92% | N/A | N/A | N/A | N/A | N/A |
| **ACT** | **83%** (10/12) | **92%** (11/12) | 50% (2/4) | **100%** (4/4) | **80%** (4/5) | **75%** (3/4) |
| SmolVLA | 58% (7/12) | 58% (7/12) | 25% (1/4) | 50% (2/4) | 60% (3/5) | 0% (0/4)* |

*SmolVLA: 3 near-successes with distractor (cube above box but dropped on edge). All OOD and distractor cells have N ≤ 5 — treat as indicative only (see Statistical Reporting). Full 30-trial near-OOD batches are pending Phase 2 evaluation.

---

## Expected outcome profiles by algorithm family

These are predictions based on the literature, not post-hoc rationalization. Compare against actual results to identify surprises and guide the next experiment cycle.

### Axis 1 — ID performance

| Family            | Expected profile                         | Why                                                                                                         |
| ----------------- | ---------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| **RL (SAC/PPO)**  | High (>85%) — but simulation only        | Reward signal optimizes precisely for the training task; no generalization needed                           |
| **IL (ACT)**      | High (80–90%)                            | ACT was designed for precise bimanual manipulation from demonstrations; strong on trained distribution      |
| **VLA (SmolVLA)** | Moderate (60–75%) at current data volume | Pretrained backbone adds generalization cost — precise fine-tuning on 111 demos is insufficient to overcome |

### Axis 2 — Near-OOD (position: held-out grid squares)

| Family            | Expected profile                               | Why                                                                                                              |
| ----------------- | ---------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| **RL (SAC/PPO)**  | N/A (sim only, not evaluated on real hardware) | —                                                                                                                |
| **IL (ACT)**      | Moderate drop (50–70%)                         | BC models interpolate within seen positions; held-out squares within the same workspace may partially generalize |
| **VLA (SmolVLA)** | Smaller drop than ACT                          | Pretrained visual backbone provides spatial generalization; less sensitive to exact pixel configuration          |

### Axis 2 — Near-OOD (distractor object)

| Family            | Expected profile                            | Why                                                                                                                                                                         |
| ----------------- | ------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **RL (SAC/PPO)**  | N/A                                         | —                                                                                                                                                                           |
| **IL (ACT)**      | Moderate drop (60–80%)                      | ACT attends to the full scene; a distractor may divert attention but the action distribution is conditioned on the instruction                                              |
| **VLA (SmolVLA)** | Large drop (expected robust, *actually 0%*) | Pretrained backbone *should* suppress irrelevant objects — the 0% result is a key anomaly pointing to full fine-tuning eroding pretrained robustness (see [[algo-smolvla]]) |

### Axis 3 — Far-OOD (new color/texture)

| Family            | Expected profile           | Why                                                                                     |
| ----------------- | -------------------------- | --------------------------------------------------------------------------------------- |
| **RL (SAC/PPO)**  | Likely fails (close to 0%) | State representation tied to pixel patterns seen during training                        |
| **IL (ACT)**      | Depends on augmentation    | Without color jitter in training, likely large drop; ACT has no pretrained visual prior |
| **VLA (SmolVLA)** | Most robust                | Pretrained CLIP/VLM backbone generalizes across colors and textures by design           |

### Axis 4 — Perturbation recovery

| Family                          | Expected profile   | Why                                                                                                     |
| ------------------------------- | ------------------ | ------------------------------------------------------------------------------------------------------- |
| **RL (SAC/PPO)**                | Low recovery       | Trained to succeed; no failure detection mechanism                                                      |
| **IL (ACT)**                    | Low recovery       | BC replans from current observation but has no explicit "I failed" signal                               |
| **VLA (SmolVLA with thinking)** | Potentially higher | Models like GR 1.5 use reasoning traces for failure detection — SmolVLA at current scale likely limited |

---

## Practical tips for running evaluations

**Randomize trial order** — don't run all SAC trials then all ACT trials. Interleave them so any session-level effects (lighting drift, robot wear) are distributed across algorithms.

**Reset completely between trials** — return robot to home position, reset object to initial position, close gripper fully. Partial resets are a common source of evaluation bias.

**Record every trial** — always record video. Failures often look surprising on video and reveal issues you'd miss from success rate alone.

**Report confidence intervals** — use the Wilson score interval (see Statistical Reporting above). Don't report results from fewer than 30 trials as inferentially meaningful.

**Separate training evaluator from training designer** — if possible, have someone who didn't tune the algorithm run the evaluation. Unconscious bias in trial setup (e.g., placing objects in easier positions) is a real confound.

---

## Related pages
- [[decision-guide]] — how to choose and train each approach
- [[results]] — consolidated SO-100 results dashboard
- [[pick-and-place]] — task-specific synthesis including SO-100 results
- [[algo-smolvla]] — SmolVLA architecture and distractor anomaly hypothesis
- [[reinforcement-learning]], [[imitation-learning]], [[vision-language-action-models]] — per-paradigm details
