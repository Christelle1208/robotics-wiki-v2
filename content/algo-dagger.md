# Algorithm: DAgger — Dataset Aggregation

**Paper:** "A Reduction of Imitation Learning and Structured Prediction to No-Regret Online Learning" — Ross, Gordon, Bagnell (CMU, AISTATS 2011)  
**Category:** Imitation learning — iterative data collection from current policy with expert corrections  
**Related:** [[imitation-learning]], [[algo-act]], [[algo-sarm]], [[reinforcement-learning]], [[hybrid-il-rl]]

---

## The Problem It Solves

**Behavioral Cloning (BC) assumes i.i.d. data** — it trains on expert demonstrations where all states come from the expert's policy distribution. But at test time, the learned policy will reach *different* states than the expert ever visited.

**Distribution shift is catastrophic in sequential prediction:**
- A BC policy with 1% error per step has 1% mistakes on expert-like states
- But on its own induced distribution (after drift), it makes ~T² mistakes over T steps (quadratic growth!)
- Intuition: one mistake → different state → larger next mistake → exponential divergence

**Example:** A BC autonomous driving policy trained on expert human driving may make a small steering error, drifting 1cm left. Now it's in a different region than the expert ever saw. The visual features are novel. It makes a bigger correction, now 5cm off. By minute 5, it's crashed.

**DAgger's solution:** Don't just train on expert trajectories. Iteratively:
1. Run your current learned policy
2. Ask the expert "what should I do in these states?"
3. Add (state, expert-action) pairs to the training set
4. Retrain on the aggregated dataset

Now the policy trains on the actual distribution it will encounter.

---

## How It Works

### The Algorithm

```
Initialize D ← {} (empty dataset)
Initialize π₁ to any policy

For iteration i = 1 to N:
  ├─ Mix current policy with expert: π_i = β_i·π* + (1-β_i)·π̂_i
  │  (on iteration 1, use expert only; later, mostly use learned policy)
  │
  ├─ Run π_i to collect T-step trajectories
  │
  ├─ For each state visited by π_i, ask expert for correct action
  │  D_i ← {(s, π*(s)) for all visited states s}
  │
  ├─ Aggregate: D ← D ∪ D_i
  │
  └─ Train next policy: π̂_{i+1} ← supervised learner trained on D

Return best π̂_i on validation data
```

### The Key Insight: Mixing

At each iteration, DAgger uses a **mixture policy** to collect data:
```
π_i = β_i·π* + (1-β_i)·π̂_i
```

- **Iteration 1 (β₁=1):** Run the expert only → collect expert trajectories
- **Iteration 2-N (β_i < 1):** Run a mix: expert 10% of the time, learned policy 90%
  - This makes the policy visit its own error states early
  - Expert provides corrections at those error states
  - Learned policy learns to recover

**Why mix?** Early iterations of π̂_i are bad and visit garbage states. You don't want expert labels on irrelevant states; you want labels on states the *policy* will actually reach.

### Why It Works

**Traditional BC error bound:** Policy trained on expert data incurs J(π) ≤ J(π*) + εT² where ε is BC error rate.

**DAgger error bound:** Policy trained on aggregated data incurs J(π) ≤ J(π*) + uTε where u is a recovery coefficient (usually O(1)).

**Linear vs quadratic:** DAgger's error grows as T (iterations), not T² (steps). This is a fundamental improvement.

**Intuition from online learning:** DAgger can be viewed as a "Follow-The-Leader" algorithm. At each iteration, you pick the policy that performed best on *all historical data*. This no-regret property guarantees that your sequence of policies converges to good performance under their induced distributions.

---

## Theoretical Guarantees

### Main Result (Theorem 3.1)

If you run N = Õ(T) iterations:
```
E[loss under π̂] ≤ ε_N + O(1/T)
```

Where ε_N is the loss of the best policy when trained on all aggregated data (in hindsight).

**In practice:** If the expert achieves near-zero loss, then DAgger converges to a policy that also achieves near-zero loss, even on its own induced distribution.

### Sample Complexity

Running m trajectories per iteration for N iterations requires O(N·m) environment interactions total.
- With N = O(T²log(1/δ)) iterations and m = O(1) trajectories per iteration
- Total samples needed: Õ(T²)
- Much better than alternative approaches (SMILe needed O(T² log T) iterations)

---

## Advantages

- **Solves distribution shift** — the core pathology of BC
- **Simple to implement** — just iteratively aggregate data + retrain
- **Stationary deterministic policy** — outputs a single policy π̂, not a mixture (unlike SMILe/SEARN)
- **Leverages online learning theory** — no regret guarantees translate to IL performance
- **Works with any supervised learner** — reuse BC on aggregated dataset; compatible with any loss (0-1, hinge, MSE)
- **Linear sample complexity in T** — quadratic→linear is massive improvement
- **No magic hyperparameters** — only requirement is β_i sequence (typically just use β₁=1, β_i=0 for i>1)

---

## Disadvantages

- **Requires expert access at test time** — unlike BC (one-pass training), DAgger needs to query expert N times during training
- **Computationally expensive** — N iterations of data collection + retraining; each iteration runs the full task T steps
- **Expert availability** — assumes you can get instant expert labels on arbitrary states (not feasible for all tasks)
- **Still assumes Markovian recovery** — performance degrades if expert can't easily recover from policy errors (u becomes large)
- **Doesn't handle irreversible mistakes** — if a single policy error leads to an unsalvageable state, no amount of expert correction helps
- **Aggregation bias** — if early learned policies are very bad, early iterations collect useless data; but β₁=1 mitigates this

---

## Evaluation

### Experiments (Alg. 3.1 vs baselines)

**Task 1: Autonomous driving (Super Tux Kart racing game)**
- BC: poor performance after ~5 seconds (crashes due to distribution shift)
- DAgger: converges to near-expert performance after ~5 iterations
- Expert was a human player; policy driven by images

**Task 2: Video game playing (Super Mario Bros.)**
- BC: fails to pass early levels
- DAgger: reaches expert-level progress after N=15 iterations
- Expert actions: 10-minute human gameplay recording

**Task 3: OCR structured prediction** (on benchmark sequence labeling)
- SEARN (prior SOTA): 3.89% error
- **DAgger: 3.27% error** ← outperforms
- Shows generality beyond robotics (applies to any structured prediction)

### Key Finding

DAgger's iterative retraining is **critical**. A one-shot version (collect data from mixed policy once, train once) performs much worse. The aggregation and retraining are what make it work.

---

## In This Wiki

DAgger is foundational to modern IL because it:

1. **Identifies distribution shift as the core problem** — BC is theoretically sound *given* expert data distribution, but that distribution doesn't match test time
2. **Provides a simple, general solution** — applicable to any supervised learning algorithm
3. **Bridges IL and online learning** — shows IL can be reduced to no-regret learning
4. **Enables data-efficient learning** — linear sample complexity (in T) is a big deal

**Relationship to other approaches:**
- [[algo-act|ACT]]: Improves over BC with action chunking and multimodality; still one-pass training
- [[algo-sarm|SARM]]: Also addresses distribution shift, but via learned reward filtering (orthogonal to DAgger's iterative correction)
- [[hybrid-il-rl]]: DAgger can be combined with RL: collect DAgger data, then fine-tune with RL for further improvement

**Modern practice:** DAgger is less commonly used in practice than BC + attention mechanisms (ACT) or Diffusion Policy, mainly because:
- Real-world expert access during training is expensive
- Modern IL methods (action chunking, diffusion) mitigate distribution shift differently
- But the theoretical principle (train on policy's induced distribution) is everywhere

---

## Modern Extensions & Influence

- **SEARN/SMILe:** Earlier structured prediction versions; DAgger is the robotics-friendly simplification
- **No-regret framework:** Any no-regret online learning algorithm can be adapted to IL via the same reduction (Theorem 4 in paper)
- **Interactive learning:** DAgger's iterative expert querying is the ancestor of active learning and human-in-the-loop methods
- **Inverse RL:** Also tries to infer expert preferences from non-expert-distributed trajectories

---

## For Your SO-100 Experiments

If you implemented [[algo-act|ACT]] with clean, expert demonstrations:
- ACT already mitigates distribution shift via action chunking + temporal ensemble
- Adding DAgger iteration on top (run ACT, ask for corrections, retrain) would likely improve robustness
- But with only ~111 demos of consistent expert data (your Dataset_v4), DAgger's value is lower; it shines when you have messy, non-expert data or need to scale beyond expert-provided demos

**Most relevant:** DAgger's principle (train policy on its own induced distribution) is now standard wisdom. SARM applies it differently (reward filtering), but the insight is the same.
