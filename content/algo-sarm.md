# Algorithm: SARM — Stage-Aware Reward Modeling

**Paper:** "SARM: Stage-Aware Reward Modeling for Long Horizon Robot Manipulation" — Chen, Yu, Schwager, Abbeel, Shentu, Wu (Stanford/UC Berkeley/xdof.ai, ICLR 2026)  
**Category:** Reward modeling for imitation learning + data filtering  
**Related:** [[imitation-learning]], [[hybrid-il-rl]], [[grasping-and-manipulation]], [[algo-diffusion-policy]], [[reinforcement-learning]]

---

## The Problem It Solves

**Long-horizon, contact-rich manipulation is data-quality sensitive.** Tasks like T-shirt folding have:
- Variable trajectory lengths (flattening takes different times depending on initial crumpling)
- Multi-stage structure (grab → flatten → fold → place)
- Diverse demonstrations with inconsistent quality (expert vs. less-skilled operators)
- Deformable object dynamics (no fixed end-state)

**Prior work assumes frame-based labeling** (progress = elapsed time) — but this introduces severe label noise. A fully flattened T-shirt appears at frame 200 in one demo and frame 500 in another. This breaks reward model training and downstream policy learning.

**Standard behavior cloning** (BC) on diverse, noisy datasets fails dramatically:
- BC-All (full dataset): 0–1% success on hard tasks (crumpled → folded)
- BC-2min (filtered by duration): 0% success on hard tasks

**SARM's goal:** Learn a robust reward model from natural language subtask annotations that captures semantic progress (not elapsed time), then use it to filter and reweight demonstrations during training.

---

## How It Works

### 1. Stage-Aware Reward Labeling from Natural Language

Instead of frame indices, SARM uses **subtask annotations** (natural language labels like "flatten", "fold left side", "place in corner").

**Process:**
1. **Annotation protocol:** Manually design what task stages mean. For T-shirt folding: {grab, move to center, flatten, fold (multiple folds), place}
2. **Temporal segmentation:** Annotators watch video and mark when each stage begins/ends
3. **Automatic progress labels:** Compute dataset-wide average duration of each stage (e.g., "flatten" typically takes 25% of total time)
4. **Dense interpolation:** Within each stage, linearly interpolate progress from 0→1 based on temporal position

**Formula:**
```
For frame t in stage k with local position τ_t ∈ [0,1]:
  progress(t) = (cumulative prior up to stage k-1) + (stage k duration) × τ_t
  
Example: If "flatten" occupies 25% of task and you're halfway through it:
  progress = 0.05 (grab+move) + 0.25 × 0.5 = 0.175
```

This ensures **semantically equivalent states get consistent labels** across all trajectories, regardless of duration.

### 2. Dual Architecture: Stage Classifier + Progress Estimator

SARM uses two task-specific heads sharing a frozen CLIP backbone:

```
Input: RGB frames + joint state
  ↓
[Frozen CLIP encoder] → visual embeddings
[Transformer temporal aggregator] → cross-modal fusion
  ↓
├─ Stage Estimator → argmax over K discrete stages (classification)
└─ Subtask Estimator → continuous progress in [0,1] (regression, conditioned on predicted stage)
```

**Why two heads?**
- **Stage classifier** provides coarse localization (which phase are we in?)
- **Subtask estimator** refines to continuous progress, using stage embedding as context
- Together: robust to trajectory variability and OOD failure modes

**Architecture details:**
- CLIP ViT-Base frozen (no finetuning) → robustness
- Transformer backbone: 8 layers, 12 heads, 768 dims (60M params, optimized for scale)
- Positional embeddings only on first frame (prevent temporal leakage per ReWiND)
- Input: 9 frames from one episode (first frame + 8 consecutive frames at 30-frame intervals)
- Rewind augmentation: append reversed early frames (handles recovery/failure modes)

### 3. Reward-Aligned Behavior Cloning (RA-BC)

Standard BC averages loss uniformly over all demonstrations:
```
L_BC(θ) = (1/N) Σ ℓ(π_θ(o_i), a_i)
```

**RA-BC reweights based on predicted progress:**

For each data point i, compute a **progress delta** (does this action advance the task?):
```
progress_delta_i = reward_model(observation_{t+Δ}) - reward_model(observation_t)
                 ∈ [-1, 1]  (negative = regression, positive = progress)
```

Map this to a sample weight w_i ∈ [0,1]:
```
w_i = soft_weight_from_running_stats(progress_delta_i)
      with thresholded hard cutoff: if progress_delta > κ, then w_i = 1
```

**Weighted objective:**
```
L_RA-BC(θ) = Σ w_i × ℓ(π_θ(o_i), a_i) / (Σ w_i + ε)
```

**Result:** RA-BC **softly filters high-quality segments** while preserving training stability.

---

## Why It Works

### Robustness to Demonstration Variability
- Semantic labeling handles variable trajectory lengths
- Stage classification catches OOD recovery attempts (robot misgrasps, back-and-forth motions)
- Rewind augmentation teaches model to stay calm during failures

### Data Quality Filtering Without Manual Labels
- Reward model automatically learns which frames show progress
- RA-BC down-weights stuck/regressing segments without explicit labeling
- No need to manually classify demos as "good" or "bad"

### Long-Horizon Performance
- Two-stage architecture (coarse + fine) handles multi-stage uncertainty
- RA-BC acts as an online bootstrapping mechanism (each training epoch re-evaluates data quality)

---

## Evaluation

### Reward Model Benchmarks (T-shirt folding)

**Baselines:** LIV, VLC, GVL, VICtoR, REDS, ReWiND (all VLM-based or stage-aware approaches)

| Metric | Demo Loss ↓ | Rollout Classification ↑ |
|--------|-----------|--------------------------|
| **SARM** | **0.009** | **0.94** (94% correct) |
| ReWiND | 0.019 | 0.50 |
| REDS | 0.036 | 0.16 |
| LIV | 0.021 | 0.33 |

- 50% relative improvement over ReWiND on human demos
- 80% improvement on real robot rollouts
- SARM correctly classifies SE (success) / PSE (partial success) / FE (failure) 11–12/12 times

### Policy Training Results (RA-BC on π0 foundation model)

**Task: T-shirt folding, 200-hour dataset from GELLO teleoperation**

Fine-tuned from π0 (foundation model) using different reweighting strategies:

| Task | BC-All | BC-2min | RA-BC-ReWiND | **RA-BC-SARM** |
|------|--------|---------|--------------|----------------|
| **Simple** (pick+place) | 12/12 | 12/12 | 12/12 | 12/12 |
| **Medium** (fold from flat) @ 40k steps | 1/12 | 7/12 | 6/12 | **10/12** (83%) |
| **Hard** (fold from crumpled) @ 40k steps | 0/12 | 0/12 | 3/12 | **8/12** (67%) |

**Key insight:** Raw BC on diverse data fails completely (0%). Filtering by duration helps (7/12). But SARM's semantic reward model outperforms both (10/12 medium, 8/12 hard).

### RL Integration (DiffQL + SARM)

SARM also works with RL: trained DiffQL policy with SARM as the reward function on a simulated pick-and-place task. Results in Appendix A.8 show RA-QL converges to higher return than pure BC continuation.

---

## Pros

- **Handles variable-length trajectories** — semantic labeling is robust to trajectory duration variations
- **Filters demonstrations automatically** — no manual classification; reweighting is learned
- **Works on contact-rich deformable object tasks** — designed for T-shirt folding, generalizes to dish unloading
- **Robust to failure modes** — rewind augmentation helps model stay calm during OOD recovery attempts
- **Improves downstream policy learning significantly** — RA-BC shows 2–6× improvement on hard tasks
- **Foundation model friendly** — works by fine-tuning π0 or other generalist policies with RA-BC
- **Bridges IL and RL** — learned reward signals enable both better BC and downstream RL (DiffQL)

---

## Cons

- **Requires manual annotation protocol** — must define stages and collect subtask timestamps (30–60 min per 200 trajectories)
- **Frozen CLIP backbone limits visual adaptation** — if task domain is far from internet-scale CLIP training, model may struggle
- **Still multi-modal (RGB + joint state)** — increases data collection complexity; wrist cameras were found to add no value
- **Hyperparameter sensitivity** — rewind augmentation strategy, positional embedding choices, frame gaps all affect performance
- **Evaluated on one primary task (T-shirt folding)** — limited to contact-rich deformable objects; generalization to rigid-object assembly unknown
- **Computational cost** — reward model is 60M params; RA-BC adds per-sample computation during training

---

## Key Hyperparameters

| Parameter | Value | Effect |
|-----------|-------|--------|
| Transformer layers | 8 | 60M params; 4 underfit, 12 overfit |
| Frame gap | 30 frames (1 sec) | Small gaps (15f) = redundancy; large gaps (60f) = miss events |
| Num observation steps | 8 | Temporal span ~8 sec; 4 underfit, 12 = redundancy |
| RA-BC threshold κ | 0.01 | Top 5% demos by progress/duration; demos above get w=1 |
| Rewind frames | 4 | Critical for OOD failure mode robustness |

---

## Related Work & Distinctions

### vs. ReWiND (Zhang et al., 2025)
- **ReWiND:** Direct regression (no stage classification), uses rewind augmentation
- **SARM:** Dual-head (stage + subtask), semantic rather than frame-based labeling
- **Result:** SARM more stable on long-horizon tasks; 80% improvement on rollout classification

### vs. REDS (Kim et al., 2025)
- **REDS:** Also stage-aware but learns semi-sparse, step-shaped reward with monotonicity regularization
- **SARM:** Continuous dense reward, better for variable-speed trajectories
- **Result:** SARM generalizes better across trajectory speeds

### vs. VLM-based reward models (LIV, VLC, GVL, VICtoR)
- **VLM approaches:** Direct prompting of pretrained VLMs (e.g., GPT-4V)
- **SARM:** Task-specific finetuning of CLIP + learned stage/subtask heads
- **Result:** SARM faster, more controllable, better scaling

---

## In This Wiki

SARM represents a **data-quality-focused approach to IL** that bridges:
- [[imitation-learning]] — core IL methods, but addresses data quality systematically
- [[grasping-and-manipulation]] — contact-rich deformable object handling
- [[reinforcement-learning]] — learned reward signals enable RL fine-tuning (DiffQL)
- [[hybrid-il-rl]] — RA-BC + downstream RL is a hybrid approach

**Key contribution to the field:**
The most important insight from SARM is that **demonstration quality matters more than quantity**. Scaling data helps little without addressing per-sample quality. This challenges the "data scale is everything" narrative in foundation model robotics.

---

## Experimental Takeaway for Your Project

If you're working on **long-horizon IL tasks with diverse demonstrations**, SARM's lesson is:
1. **Semantic task decomposition** > frame-based labeling
2. **Automatic filtering via learned rewards** > manual dataset curation
3. **Multi-stage progress modeling** > single end-state regression
4. **RA-BC reweighting** can 2–6× improve policy performance at same data volume

For SO-100 pick-and-place (simpler, rigid objects, shorter horizon), this may be overkill. But if you move to deformable objects or longer tasks, reward modeling becomes critical.
