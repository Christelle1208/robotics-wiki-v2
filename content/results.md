# Results — SO-100 Pick-and-Place Experiments

This page is the **single dashboard for all experimental results** produced during this project. It consolidates everything: simulation RL results, real-hardware IL results, real-hardware VLA results, and the dataset iteration that connects them.

→ For *methodology* (how trials are structured, what each axis measures): [[evaluation-protocol]]
→ For *full narrative* (what worked, what didn't, surprises, revised recommendations): [[decision-guide]] → Step 7 (REX)
→ For *task-level synthesis* (which family to pick for P&P and why): [[pick-and-place]]
→ For *algorithm-specific detail*: [[algo-sac]], [[algo-act]], [[algo-smolvla]]

---

## Headline summary

| Algorithm | Environment | Overall result | Status |
|-----------|-------------|-----------------|--------|
| **SAC** (3-subtask + recovery) | Simulation (MuJoCo) | **92%** (46/50 episodes) | ✅ Done |
| **ACT** (Dataset_v4, 100k steps) | Real hardware (SO-100) | **83%** ID @ 0° / **92%** ID @ 45° | ✅ Done |
| **SmolVLA** (Dataset_v4, 20k steps) | Real hardware (SO-100) | **58%** ID (both orientations) | ✅ Done |
| **ACT** (Dataset_v5, expanded eval) | Real hardware (SO-100) | **97.9%** ID fixed / **100%** ID random orientation | ✅ Done (252 trials) |
| **SmolVLA** (Dataset_v5, expanded eval) | Real hardware (SO-100) | **97.9%** ID fixed / **85.4%** ID random orientation | ✅ Done (~260 trials) |

**Meta-finding:** dataset iteration (v1 → v5) was the single biggest driver of performance — bigger than any algorithm or hyperparameter choice. ACT outperforms SmolVLA at this data volume (111 demos for v4, 131 for v5); the gap is expected to narrow or reverse with more diverse fine-tuning data (see [[decision-guide]] for the reasoning).

---

## 1. SAC — Simulation (MuJoCo)

**Setup:** 3-subtask decomposition (Reach → scripted Grasp → Place), object position randomized ±7cm, fixed orientation, drop-recovery state machine (relaunches Reach if cube falls below z=5cm during Place).

| Subtask | Success rate |
|---------|-------------|
| Reach | 96% (48/50) |
| Grasp | 92% (46/50) |
| Place | 92% (46/50) |
| **Overall** | **92% (46/50)** |
| Drop recoveries | 8 / 50 episodes (all recovered successfully) |

### PPO vs SAC (same environment, 50% success threshold)

| Algorithm | Steps to 50% success | Wall-clock training time |
|-----------|----------------------|---------------------------|
| PPO | 3.17M steps | ~20 minutes |
| SAC | 1.58M steps | ~5 hours |

**Reading:** SAC is **2× more sample-efficient** (half the steps) but **much slower wall-clock** per step — PPO's faster simulation throughput per step wins on raw training time despite needing more steps.

→ Full discussion: [[decision-guide]] REX → SAC, [[reinforcement-learning]] "When to use RL" synthesis.

---

## 2. Dataset iteration — v1 → v5 (shared by ACT and SmolVLA)

Both ACT and SmolVLA were trained on the same evolving dataset. This iteration is the backbone of the meta-finding above.

| Version | Episodes | What changed | Outcome |
|---------|----------|--------------|---------|
| **v1** | 50 (mono camera) | Initial collection | ❌ Failed — non-reproducible environment between training and eval |
| **v2** | 80 (Phase 1) | Reproducible setup, structured by zone/orientation | Both policies approach the cube (~5–10cm) but stop short — low visual contrast hypothesis |
| **v3** | 80 + colored post-it markers | Added contrast markers on robot + box | Approach improves to ~5–7cm; OOD positions still fail (goes to nearest known position) |
| **v4** | v3 + 15 recovery + 16 random-orientation eps (~111 total) | Added failure-recovery episodes and orientation diversity | Recovery and orientation gaps both close — final results below |
| **v5** | 131 total | 60 ID (20 back-row + 20 middle-row + 20 front-row squares, fixed orientation) + 24 variable-orientation (2/square, 12 squares) + 10 lighting-change + 12 distractor (scissors) + 15 recovery (cube pushed / gripper misplaced / cube dropped) + 10 combined (lighting+distractor+recovery) | Backbone for the expanded 250+ trial axis-structured evaluation (sections 5-6 below) — note: several of these training-time variations (distractor object, lighting delta, recovery scenarios) overlap with conditions later tested at eval time; see [[evaluation-protocol]] caveats on near-OOD validity when eval conditions repeat training conditions |

→ Full per-version diagnosis: [[decision-guide]] REX → ACT / SmolVLA sections.

---

## 3. ACT — Real hardware (Dataset_v4, 100k steps, 1 GPU)

| Condition | Result |
|-----------|--------|
| In-distribution @ 0° | **83%** (10/12) |
| In-distribution @ 45° | **92%** (11/12) |
| OOD position @ 0° | 50% (2/4) |
| OOD position @ 45° | **100%** (4/4) |
| Novel random positions | 80% (4/5) |
| With distractor | **75%** (3/4) |

**Key findings:**
- Recovery episodes (added in v4) were the single biggest jump — fixed ACT's prior inability to recover from a failed grasp.
- 45° orientation generalizes *better* than 0° (100% OOD vs 50% OOD) — the random-orientation training episodes produced unexpectedly transferable features.
- Distractor robustness is strong (75%) — ACT is not confused by a second object in the scene.

→ Full discussion: [[algo-act]] "Results in This Project", [[decision-guide]] REX → ACT.

---

## 4. SmolVLA — Real hardware (Dataset_v4, 20k steps, 4 GPUs, full fine-tuning)

| Condition | Result |
|-----------|--------|
| In-distribution @ 0° | 58% (7/12) |
| In-distribution @ 45° | 58% (7/12) |
| OOD position @ 0° | 25% (1/4) |
| OOD position @ 45° | 50% (2/4) |
| Novel random positions | 60% (3/5, +1 near-success) |
| With distractor | **0%** (0/4, +3 near-successes) |

**Key findings:**
- Consistent across orientations (58%/58%) — plausibly a pretraining benefit, since ACT needed explicit orientation diversity to reach similar consistency.
- **Near-success rate is the more informative signal** — many "failures" were the cube placed above the bin but dropped on the edge. The model understands the task; precision is the gap.
- **0% with distractor despite 75% near-success** is the most counter-intuitive result of the project. Leading hypothesis: full fine-tuning (no frozen layers) eroded the pretrained backbone's robustness to novel scene elements. See [[algo-smolvla]] "Fine-Tuning SmolVLA — The Options" for the full reasoning and a proposed follow-up experiment (frozen-backbone fine-tuning + distractor demos).

→ Full discussion: [[algo-smolvla]] "Results in This Project", [[decision-guide]] REX → SmolVLA.

---

## 5. ACT — Dataset_v5 expanded evaluation (real hardware)

A much larger, axis-structured evaluation pass than the Dataset_v4 numbers above — 252 trials spanning ID, near-OOD (position, orientation, lighting, distractor), far-OOD, and perturbation/recovery axes, per [[evaluation-protocol]]. Dataset_v5 training data was not altered from v4's evaluation setup; this section is a deeper characterization of the same ACT policy family, not a new training run comparison.

| Axis | Condition | N | Success | Rate | Statistical status |
|------|-----------|---|---------|------|---------------------|
| ID | Orientation fixe (12 trained squares) | 48 | 47 | **97.9%** | Solid (~N=50) |
| ID | Orientation aléatoire (12 trained squares) | 48 | 48 | **100%** | Solid |
| Near-OOD position | 4 held-out squares, fixed orientation | 28 | 22 | **78.6%** | Near-solid (~N=30) |
| Near-OOD position | 4 held-out squares, random orientation | 28 | 21 | **75%** | Near-solid (+1 near-success not counted) |
| Near-OOD lighting | ID squares | 24 | 21 | **87.5%** | Characterization |
| Near-OOD lighting | OOD squares (position+lighting compound) | 8 | 5 | 62.5% | N too small |
| Near-OOD distractor (pink tape) | ID squares | 12 | 5 | **41.7%** | Characterization |
| Near-OOD distractor (pink tape) | OOD squares | 4 | 2 | 50% | N=4, indicative only |
| — | Continuous random positions (non-grid-snapped) | 12 | 11 | **91.7%** | Characterization |
| Perturbation | Object displaced mid-task | 8 | 8 | **100%** | Small N, clean result |
| Far-OOD target | Green/yellow brick as sole object in workspace (no cube present) | 8 | 0 | **0%** | Failure mode identified |
| Near/Far-OOD distractor | Blue object (color-neutral) added next to target cube | 12 | 8 | **66.7%** | Characterization |
| Perturbation | Camera fully occluded, entire episode | 16 | 0 | **0%** | No recovery possible without vision |
| Perturbation | Camera briefly occluded, vision restored | 8 | 8 | **100%** | Full recovery once vision returns |

**Key findings:**
- **Spatial and orientation generalization are strong** (75-100% across ID and near-OOD position/orientation) — consistent with the Dataset_v4 finding that orientation diversity in training transfers well.
- **Two distinct axes, not one.** (1) True far-OOD *target* generalization: green/yellow brick is the *sole* object in the workspace (no cube present) — the policy must transfer grasping to a never-targeted object. Result: **0%**, and the failure is conditioning-specific, not generic — the robot actively ignores the green brick (it was trained to treat that color as a distractor to avoid) and merely hesitates on the yellow one (truly unseen, no learned response either way). (2) Distractor robustness: pink tape and blue object are both placed *alongside* the cube, which remains the actual target. Ordered by color similarity to the cube: pink tape (41.7-50%, color-confusable) < blue object (66.7%, color-neutral) — a graded attention effect driven by color proximity to the target, not object identity.
- **Recovery is perception-gated, not motor-gated.** ACT recovers well from failures where vision remains available (missed grasp → retry, brief camera occlusion → resume, mid-task object displacement → adapt), but shows **zero success and visible motor tremor/hesitation** when the camera is occluded for the full episode. This is a cleaner mechanistic picture than a single aggregate success rate would suggest: the policy's failure mode is perceptual, not a breakdown of the correction behavior itself.

**Caveats for future evaluation rounds:**
- Distractor and lighting axes are still below the N=30 protocol target — treat current rates as directional.
- The "brief occlusion" recovery test (N=8) should be expanded and duration-varied to confirm the 100% result holds at scale.
- The color-neutral distractor (blue) is at N=12 (66.7%) — closing in on the N=20 characterization threshold, but still short of N=30 for a fully confident comparison against the color-confusable distractor result (pink tape).
- The true far-OOD target-generalization result (green/yellow brick, N=8, 0%) is confounded by training-specific color conditioning (green was a trained distractor, actively avoided) rather than pure novelty — a genuinely untrained-color novel object (not green, not resembling the cube) would isolate object-shape generalization from this color-avoidance effect.
- Human-intervention and larger-N occlusion perturbation trials are not yet collected.

→ Full discussion: [[algo-act]], [[evaluation-protocol]].

---

## 6. SmolVLA — Dataset_v5 expanded evaluation (real hardware)

Same protocol and axis structure as ACT's Dataset_v5 evaluation (section 5), run on SmolVLA for direct comparison.

| Axis | Condition | N | Success | Rate | Statistical status |
|------|-----------|---|---------|------|---------------------|
| ID | Orientation fixe (12 trained squares) | 48 | 47 | **97.9%** | Solid (~N=50) |
| ID | Orientation aléatoire (12 trained squares) | 48 | 41 | **85.4%** | Solid |
| Near-OOD position | 4 held-out squares, fixed orientation | 28 | 25 | **89.3%** | Near-solid (~N=30) |
| Near-OOD position | 4 held-out squares, random orientation | 28 | 23 | **82.1%** | Near-solid |
| Near-OOD lighting | ID squares | 24 | 23 | **95.8%** | Characterization |
| Near-OOD lighting | OOD squares (position+lighting compound) | 8 | 5 | 62.5% | N too small |
| Near-OOD distractor (pink tape) | ID squares | 12 | 8 | **66.7%** | Characterization |
| Near-OOD distractor (pink tape) | OOD squares | 4 | 2 | 50% | N=4, indicative only |
| — | Continuous random positions (non-grid-snapped) | 12 | 9 | 75% | Characterization |
| Perturbation | Object displaced mid-task | 8 | 6 | 75% | Directional weakness — see below |
| Far-OOD target | Green brick as sole object in workspace | 4 | 0 | **0%** | Ignores brick entirely, no movement |
| Far-OOD target | Yellow brick as sole object in workspace | 4 | 1 | **25%** | Hesitates; moves only when brick is in camera FOV |
| Near/Far-OOD distractor | Blue object (color-neutral) added next to target cube | 12 | 8 | **66.7%** | Characterization (+1 near-success, case 10) |
| Near/Far-OOD distractor | Blue object, OOD squares | 4 | 2 | 50% | Both failures were near-successes (cases 5, 8) |
| Perturbation | Camera briefly occluded, vision restored | 4 | 4 | **100%** | Full recovery once vision returns |

**Key findings:**
- **Strong improvement over Dataset_v4** on ID and near-OOD position/orientation (82-98% vs. 25-58% previously) — but still behind ACT on the same Dataset_v5 protocol (ACT: 75-100% across the same conditions vs. SmolVLA: 75-98%), with the gap widest on orientation aléatoire ID (ACT 100% vs. SmolVLA 85.4%).
- **Cube-displacement recovery has a directional blind spot**: SmolVLA fails specifically when the cube is displaced *backward, toward its own base/support* — it does not fail uniformly across displacement directions. This is a qualitatively different (and more specific) weakness than anything observed in ACT's perturbation results, and worth isolating in a follow-up test that varies displacement direction systematically.
- **Far-OOD target generalization mirrors ACT's pattern but is slightly less binary**: SmolVLA also ignores the green brick outright (0%, same conditioning-avoidance effect as ACT), but shows partial engagement with the yellow brick (25%, vs. ACT's 0%) — it moves toward the brick only when it stays within camera field of view, suggesting a weaker but non-zero transfer of grasp behavior to a novel-colored object.
- **Distractor robustness is close to ACT's profile** — pink tape (50-66.7%) and blue object (50-66.7%) land in a similar range to ACT's equivalents, suggesting the color-proximity-driven distractor-attention effect is shared across both algorithms rather than being ACT-specific.
- Camera occlusion recovery (brief, N=4) is 100%, consistent with ACT's finding that recovery works whenever vision is available or restored.

**Caveats:**
- Occlusion-brief (N=4) and all far-OOD/distractor rows are well below the N=20-30 protocol targets — directional only.
- Green/yellow brick split (N=4 each) makes the 0%/25% difference suggestive rather than confirmed at scale.

→ Full discussion: [[algo-smolvla]], [[evaluation-protocol]].

---

## 7. Cross-algorithm comparison

| Algorithm | Sim result | Real ID | Real OOD | Distractor | Fine-tune data | Key finding |
|-----------|-----------|---------|----------|-----------|------|------------|
| **SAC** | **92%** (50 eps) | N/A (sim only) | N/A | N/A | 0 demos (reward-based) | 3-subtask decomposition + recovery state machine = 92% |
| **ACT** (Dataset_v4) | — | **83%** (0°) / **92%** (45°) | **100%** OOD @ 45° | **75%** (3/4) | ~111 demos | Data iteration > algorithm choice; best overall on this setup |
| **ACT** (Dataset_v5, expanded) | — | **97.9%** fixed / **100%** random | **78.6%** fixed / **75%** random | **41.7-50%** (color-confusable object) | 131 demos | Strong ID/near-OOD spatial generalization; recovery is perception-gated, not motor-gated |
| **SmolVLA** (Dataset_v4) | — | **58%** (both orientations) | 50% OOD @ 45° | **0%** (3 near-successes) | ~111 demos | Fine-tuning strategy (full vs frozen) may be the cause of the distractor gap |
| **SmolVLA** (Dataset_v5, expanded) | — | **97.9%** fixed / **85.4%** random | **89.3%** fixed / **82.1%** random | **50-66.7%** (color-confusable/neutral object) | 131 demos | Big jump over Dataset_v4; still behind ACT overall, plus a directional weakness on backward cube displacement |

---

## What's not yet measured

Per [[evaluation-protocol]], the full SO-100 test matrix has **not yet been completed at inferential scale for every axis**. Status after both ACT and SmolVLA Dataset_v5 expansions (sections 5-6 above):

- Lighting and distractor axes are below the N=30 protocol target for both algorithms (currently 8-24) — still characterization-only, not confirmed at inferential scale.
- The green/yellow brick is the genuine far-OOD target-generalization test (brick is the sole object, no cube present), but its result (0% ACT, 0%/25% SmolVLA green/yellow) is confounded by green being a trained "ignore this" distractor color. A novel-color object as sole target (not green, not cube-colored) would isolate true shape/object-identity generalization from this color-conditioning effect.
- Camera-occlusion recovery (brief, vision restored) is only N=8 for ACT and N=4 for SmolVLA — worth expanding and varying occlusion duration to confirm the 100% results hold at scale.
- SmolVLA's directional cube-displacement weakness (fails specifically on backward displacement toward the object's base) has not been systematically tested across other displacement directions, nor checked against ACT for the same directional pattern.
- Human-intervention perturbation (briefly holding the robot arm) — Axis 4, not yet tested for any algorithm.
- SAC sim-to-real transfer — currently simulation-only.
- SmolVLA with a frozen-backbone fine-tuning strategy (Option A/B in [[algo-smolvla]]) — the Dataset_v4 distractor hypothesis (0% with distractor) is partly superseded by the Dataset_v5 finding that distractor performance depends heavily on color proximity to the target; worth revisiting whether frozen-backbone fine-tuning specifically improves color-robustness.

---

## Related pages
- [[decision-guide]] — full REX narrative, training/robustness guidance
- [[evaluation-protocol]] — evaluation methodology and test matrix
- [[pick-and-place]] — task-level synthesis
- [[overview]] — three-paradigm framework and experiment tracker
- [[algo-sac]], [[algo-act]], [[algo-smolvla]] — per-algorithm detail
