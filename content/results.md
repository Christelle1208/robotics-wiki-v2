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
| **SmolVLA** (Dataset_v5, LoRA rank 64) | Real hardware (SO-100) | **81.3%** ID fixed / **60.4%** ID random orientation | ✅ Done (176 trials) |

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

## 7. SmolVLA — Dataset_v5 with LoRA (rank 64) fine-tuning (real hardware)

Same protocol and axis structure as ACT's and SmolVLA's full-fine-tune Dataset_v5 evaluations (sections 5-6), but with a parameter-efficient fine-tuning strategy (LoRA rank 64 instead of full model tuning). 4 GPUs, ~20k training steps.

| Axis | Condition | N | Success | Rate | Statistical status |
|------|-----------|---|---------|------|---------------------|
| ID | Orientation fixe (12 trained squares) | 48 | 39 | **81.3%** | Solid (~N=50) |
| ID | Orientation aléatoire (12 trained squares) | 48 | 29 | **60.4%** | Below baseline |
| Near-OOD lighting | ID squares | 24 | 10 | **41.7%** | Characterization — major degradation |
| Near-OOD lighting | OOD squares | 8 | 4 | 50% | N too small |
| Near-OOD distractor (pink tape) | ID squares | 12 | 2 | **16.7%** | Severe collapse |
| Near-OOD distractor (pink tape) | OOD squares | 4 | 0 | **0%** | Total failure |
| — | Continuous random positions (non-grid-snapped) | 12 | 4 | 33.3% | Characterization |
| Perturbation | Object displaced (any direction) | 8 | 1 | **12.5%** | Quasi-ineffective |
| Perturbation | Object in random grid position | 12 | 4 | 33.3% | Highly variable |
| Far-OOD target | Green brick as sole object in workspace | 4 | 0 | **0%** | Ignores brick entirely, no movement |
| Far-OOD target | Yellow brick as sole object in workspace | 4 | 0 | **0%** | *Hallucinated grasp*: moves toward brick, attempts to grasp despite failure (faux-positif, see below) |
| Near/Far-OOD distractor | Blue object (color-neutral) added next to target cube | 12 | 1 | **8.3%** | Near-total collapse |

**Key findings:**

- **LoRA rank-64 is a narrow adaptation of the pretrained backbone, not a robust fine-tune.** This is visible in the ID fixed-orientation baseline: LoRA (81.3%) is *measurably worse* than full fine-tuning (97.9%) even under zero distribution shift — a 16.6-point gap that indicates the rank bottleneck is already bleeding performance in the training distribution. By contrast, ACT (97.9% fixed) and full SmolVLA (97.9% fixed) converge at the same performance, confirming that dataset quality, not algorithm choice, sets the ceiling. LoRA's deficit is purely a capacity constraint.

- **The collapse pattern is hierarchical and predictable: ID < near-OOD < far-OOD, with magnitude tied to visual novelty.** (1) ID: fixed orientation (81.3%) > random orientation (60.4%) — a 21-point drop, smaller than full SmolVLA's 12-point drop (100% → 85.4%). This suggests LoRA's random-orientation handling is already compromised by rank limits. (2) Near-OOD lighting: 41.7% (ID with lighting change) — a catastrophic 40-point collapse from 81.3%. By contrast, full SmolVLA's lighting robustness (95.8%) is nearly perfect, implying the frozen backbone cannot reweight visual features to adapt to photometric shifts, and the rank-64 adapter cannot compensate. (3) Near-OOD distractor: 0-16.7%, even lower than full SmolVLA's 50-66.7%. (4) Far-OOD novel target: 0%, same as full SmolVLA on green brick (color-avoidance conditioning), but the yellow brick behavior is the key divergence (see below).

- **The yellow brick hallucination reveals a "gating failure" in LoRA's decision boundary.** LoRA achieves 0% success on the yellow brick (never grasps successfully) but crucially, the model *moves toward the brick and attempts to grasp it anyway* — a faux-positif that is catastrophic for real hardware. Full SmolVLA also fails (0/4) but does not show the same attempted grasp; it either ignores or hesitates without committing to a grasp action. The hypothesis: LoRA has sufficient capacity to retain the pre-trained "execute grasp" motor policy, but the rank-64 bottleneck starves the "gate: when to grasp" discrimination network. The model hallucinates a grasp on a never-seen object because it cannot learn to inhibit the grasping action when the target is outside its training distribution. This is not a near-success (like full SmolVLA's 25% on yellow brick) — it's a safety failure, because the model commits a motor action with high confidence to an invalid target.

- **Perturbation robustness collapses non-uniformly, with a striking inversion at random vs. fixed displacement.** Cube displaced (fixed direction): 12.5% (1/8). Cube in random grid position: 33.3% (4/12). This is counter-intuitive: random positions should be harder (higher variance), yet they perform 2.7× better. Hypothesis: LoRA may have overfit to the *specific* data augmentation used during training (Dataset_v5 includes fixed-direction displacement as a recovery scenario), and the random-position trials — while out-of-distribution — happen to land in regions of the decision boundary where the pretrained backbone's object-detection features still work. Fixed displacement may trigger a specific failure mode (e.g., systematic loss of the displaced cube in the feature map when it moves along a learned trajectory). Full fine-tuning does not show this inversion (it recovers from both uniformly well, 75-100%), suggesting the full backbone learns a more generalizable tracking policy that is not brittle to a single displacement direction.

- **Orientation generalization is weaker in LoRA than full fine-tuning, but follows the same direction as the pretrained baseline.** LoRA on random orientation (60.4%) is 21 points below LoRA fixed (81.3%); full SmolVLA is 12 points below (85.4% vs 97.9%). LoRA's larger gap is expected — rank limits mean fewer parameters are available to learn orientation-invariant features — but the *pattern is the same*: random orientation is always the first to fail when moving away from the training distribution. This is a shared property of the pretrained backbone, not a LoRA-specific failure.

- **Summary of the rank-64 trade-off: parameter efficiency (minimal additional compute) is purchased with catastrophic robustness loss.** The pretrained foundation is stable and reliable in-distribution (81% is still usable), but the adapter is too narrow to learn the adaptations needed for any distribution shift: photometric changes, novel scene elements, or dynamic perturbations all trigger near-total collapse (0-50% after training-data overlap is removed). The yellow brick hallucination is a critical safety signal — the model does not gracefully fail (inhibit action or hesitate), it commits to a grasp on a hallucinated target. This is unsuitable for real-world deployment without additional safeguards (e.g., grasp success classifiers, vision-based pre-grasping validation).

**Caveats:**
- All far-OOD and distractor rows are well below N=20 — directional only, not fully confirmed at scale.
- The yellow brick "hallucination" (faux-positif) needs deeper analysis: does LoRA retain grasp-execution knowledge but lose the "when to grasp" gate, or is this random motor noise coinciding with object proximity? Separate trajectory analysis recommended.
- Lighting delta (24 trials) is the largest near-OOD sample; still below N=30 protocol target, but directional signal is strong enough to warrant immediate follow-up.

**Recommendation:**
LoRA rank 64 is **not suitable for this task** in its current form — the pretrained backbone is too frozen for real-world deployment across even modest distribution shifts. Consider: (1) increasing LoRA rank (96, 128) to relax the bottleneck; (2) unfreezing final N layers of the backbone + LoRA on middle layers (hybrid strategy); (3) accepting parameter efficiency loss and returning to full fine-tuning for this task domain. The hallucination on novel yellow brick is a safety concern for real hardware.

→ Full discussion: [[algo-smolvla]] "LoRA fine-tuning analysis", [[decision-guide]] REX → SmolVLA.

---

## 8. Cross-algorithm comparison

| Algorithm | Sim result | Real ID | Real OOD | Distractor | Fine-tune data | Key finding |
|-----------|-----------|---------|----------|-----------|------|------------|
| **SAC** | **92%** (50 eps) | N/A (sim only) | N/A | N/A | 0 demos (reward-based) | 3-subtask decomposition + recovery state machine = 92% |
| **ACT** (Dataset_v4) | — | **83%** (0°) / **92%** (45°) | **100%** OOD @ 45° | **75%** (3/4) | ~111 demos | Data iteration > algorithm choice; best overall on this setup |
| **ACT** (Dataset_v5, expanded) | — | **97.9%** fixed / **100%** random | **78.6%** fixed / **75%** random | **41.7-50%** (color-confusable object) | 131 demos | Strong ID/near-OOD spatial generalization; recovery is perception-gated, not motor-gated |
| **SmolVLA** (Dataset_v4) | — | **58%** (both orientations) | 50% OOD @ 45° | **0%** (3 near-successes) | ~111 demos | Fine-tuning strategy (full vs frozen) may be the cause of the distractor gap |
| **SmolVLA** (Dataset_v5, expanded) | — | **97.9%** fixed / **85.4%** random | **89.3%** fixed / **82.1%** random | **50-66.7%** (color-confusable/neutral object) | 131 demos | Big jump over Dataset_v4; still behind ACT overall, plus a directional weakness on backward cube displacement |
| **SmolVLA** (Dataset_v5, LoRA 64) | — | **81.3%** fixed / **60.4%** random | 33.3% fixed / — random | **0-16.7%** (complete collapse) | 131 demos | Parameter-efficient LoRA is insufficient for robustness; frozen backbone cannot adapt to lighting/distractor; safety concern (yellow brick hallucination) |

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
