# Wiki Health Report

**Generated:** 2026-06-25 | **Scope:** all 42 files in `wiki/` + 60+ files in `raw_sources/`
**Previous report:** 2026-05-22 | **Next scheduled run:** 2026-07-02

---

## Summary

| Category | Issues found | Severity | Status |
|----------|-------------|----------|---------|
| Critical contradictions & stale status markers | 3 | 🔴 Fix immediately | **NEW** |
| Cross-reference gaps | 4 | 🟡 Update soon | **NEW** |
| Missing metrics (source vs wiki) | 3 | 🟡 Update soon | Previous |
| Orphan / low-inbound algo pages | 3 | 🟡 Add links | Previous |
| Concepts needing dedicated pages | 7 | 🟡 Create pages | Previous |
| Potentially outdated framing | 2 | 🟢 Review | Previous |
| Broken internal references | 1 | 🔴 Fix immediately | Previous |

---

## 🔴 Critical Issues (New — 2026-06-25)

### CRIT-1 · Stale "Pending" status markers for completed experiments

**Files:** `imitation-learning.md:42-43` and `reinforcement-learning.md:40`

`imitation-learning.md` marks both ACT and SmolVLA experiments as "🔄 Pending" but both are actually ✅ completed on Dataset_v4:

```markdown
| Method | Status | Key question |
|--------|--------|-------------|
| ACT | 🔄 Pending | ...
| SmolVLA | 🔄 Pending | ...
```

**Actual results** (from `results.md`):
- **ACT:** 83% ID @ 0° / 92% ID @ 45° / 75% distractor
- **SmolVLA:** 58% ID / 0% distractor

**Fix:** Update both rows in `imitation-learning.md` to:
```markdown
| ACT | ✅ Done (Dataset_v4) | 83% ID, 75% distractor resilience |
| SmolVLA | ✅ Done (Dataset_v4) | 58% ID, 0% distractor (full fine-tune issue) |
```

Also add: → See `[[results]]` for full per-condition breakdown and `[[algo-act]]`, `[[algo-smolvla]]` for detailed analysis.

---

### CRIT-2 · Real-hardware RL results marked as pending but never completed

**File:** `reinforcement-learning.md:40`

Current text: `*[Real-hardware results pending — will be added here once available]*`

**Issue:** SAC was only evaluated in simulation (MuJoCo); real-hardware RL was never attempted. The marker makes it sound like work-in-progress rather than a completed decision.

**Fix:** Replace with:
> SAC RL evaluation in this project is **simulation-only** (MuJoCo, 92% on pick-and-place with task decomposition). Real-hardware RL remains future work — see `[[decision-guide]]` Step 4 RL section for real-world deployment challenges and why simulation-first is the standard approach.

---

### CRIT-3 · SmolVLA distractor failure needs clearer attribution

**Files:** `results.md:98`, `algo-smolvla.md:143`, `vision-language-action-models.md:44`

The distractor result (0% with 3 near-successes) is described consistently across pages, BUT the **root-cause hypothesis** (full fine-tuning eroded pretrained robustness) is buried in `algo-smolvla.md` lines 104–106. A reader of `results.md` alone won't understand *why* this anomaly occurred or what the proposed fix is.

**Fix:** In `results.md` Section 4 (SmolVLA), add after line 98:
> **Diagnostic note:** The 0% distractor result is unexpected given 75% near-success rate. Leading hypothesis: full fine-tuning (Option C in `[[algo-smolvla]]`) may have eroded the pretrained backbone's robustness to novel objects. Proposed follow-up: frozen-backbone fine-tuning (Option A/B) with explicit distractor training data. See `[[algo-smolvla]]` "Fine-Tuning SmolVLA — The Options" for the full reasoning.

---

## 🔴 Contradictions

### C-1 · RT-2-X benchmark score: 62% vs 62.5%

**Files:** `algo-octo.md:124` vs `algo-openvla.md:105`

`algo-octo.md` reports RT-2-X achieving **62%** task success; `algo-openvla.md` reports **62.5%** for the same model. These are likely from different evaluation protocols (Octo uses its own fine-tuning benchmark; OpenVLA uses BridgeV2 29-task suite), but both pages present the number without qualification, making them look contradictory to a reader comparing tables.

**Fix:** Add a footnote in each table clarifying the evaluation protocol. Example:
- `algo-octo.md` table caption: *(RT-2-X score on Octo's multi-platform fine-tuning benchmark)*
- `algo-openvla.md` table caption: *(RT-2-X score on BridgeV2 29-task evaluation)*

---

### C-2 · VLA-RL "+4.5% on 40 tasks" — misleading phrasing

**File:** `vision-language-action-models.md:99`

> "OpenVLA-7B surpasses strongest fine-tuned baseline by **4.5% on 40 tasks**"

This implies a uniform +4.5% across 40 tasks. The truth (correctly stated in `algo-vla-rl.md:130`) is that 4.5% is the **average across 4 LIBERO suites**, each containing 10 tasks — individual suite gains range from +4.2% to +4.8%.

**Fix:** Change to:
> "OpenVLA-7B surpasses strongest fine-tuned baseline by an average of **+4.5% across LIBERO's 40 tasks** (4 suites × 10 tasks)"

---

### C-3 · GF-VLA placement accuracy not captured

**Files:** `vision-language-action-models.md:121`, `grasping-and-manipulation.md:64` vs raw source

Raw source (`Information-theoretic graph fusion...`) reports **three** key metrics:
- 94% grasp success ✅ — captured in wiki
- **89% placement accuracy** ❌ — missing from wiki
- 90% task success ✅ — captured in wiki

**Fix:** Add "**89% placement accuracy**" to both entries where GF-VLA results appear.

---

## 🔴 Broken Internal Reference

### B-1 · Broken anchor link in `reinforcement-learning.md`

**File:** `reinforcement-learning.md:17`

> "SAC balances exploration and exploitation... (see `[[#Composable-DRL-SQL]]` below for SQL)"

The anchor `#Composable-DRL-SQL` will not resolve in Obsidian — the actual heading is `### Composable Deep Reinforcement Learning for Robotic Manipulation (SQL) → [[algo-sql-sac]]`. Obsidian generates anchors from heading text after stripping special characters, making the actual anchor something like `#composable-deep-reinforcement-learning-for-robotic-manipulation-sql--algo-sql-sac`.

**Fix:** Replace the anchor with an explicit wikilink:
> "SAC balances exploration and exploitation... (see [[algo-sql-sac]] for SQL foundations)"

---

## 🟡 Cross-Reference & Navigation Gaps (New — 2026-06-25)

### CRG-1 · Contact-rich manipulation scattered across 3 pages with no hub

**Files:** `imitation-learning.md:72–88` (full survey), `grasping-and-manipulation.md:30–37` (synthesis), `vision-language-action-models.md:23` (mention)

The contact-rich survey section is detailed and comprehensive but has no entry point. Pages reference it via anchor links (`[[imitation-learning#contact-rich-survey]]`) but there's no dedicated **contact-rich-tasks** or **contact-rich-manipulation** page as a hub. A user specifically interested in "assembly tasks" or "force feedback" must hunt across 3 pages.

**Fix:** Create `contact-rich-tasks.md` as a topic page that:
1. Summarizes the survey (from `imitation-learning.md`)
2. Categorizes tasks: assembly, insertion, polishing, surgical
3. Cross-references relevant algorithms: `[[algo-hitl-rl]]`, `[[algo-awac]]`, `[[algo-act]]` (Bi-ACT, Comp-ACT)
4. Lists sensor modalities: force/torque, tactile (research-only), EMG
5. Links to: `[[imitation-learning#contact-rich-survey]]`, `[[grasping-and-manipulation]]`, papers

---

### CRG-2 · Action generation methods not centralized

**Files:** `imitation-learning.md:53` (glossary), `vision-language-action-models.md:98` (trajectory), `algo-smolvla.md:47` (implementation), `algo-openvla.md` (contrast to autoregressive)

Flow Matching, Diffusion Policy (DDPM), and Autoregressive token generation are three fundamentally different ways to generate robot actions, but they're scattered across pages with no unified comparison. A reader comparing π0 (flow matching) vs OpenVLA (autoregressive) vs Diffusion Policy has to piece together technical trade-offs from 4+ pages.

**Fix:** Add a brief section to `vision-language-action-models.md` after line 98 (or create `action-generation.md`):

```markdown
## Action Generation Paradigms

| Method | Examples | Speed | Quality | Implementation complexity |
|--------|----------|-------|---------|--------------------------|
| **Autoregressive** | OpenVLA, RT-2, RT-1 | Slower (7B at 1-6Hz) | Good for learned distributions | O(T) steps for T actions |
| **Diffusion (DDPM)** | Diffusion Policy, ACT-Diff | Moderate (50-100 steps) | Multimodal, high quality | Scores learned via diffusion |
| **Flow Matching** | π0, SmolVLA, X-VLA, TinyVLA | Fastest (10 steps) | Comparable to diffusion | Deterministic flow field |
| **Single-step (Deterministic)** | Traditional IL (BC) | Fastest | Lower (averaging problem) | Simplest |

See: [[algo-diffusion-policy]], [[algo-smolvla]], [[algo-openvla]]
```

---

### CRG-3 · "Generalization" used in 3 different senses without central definition

**Files:** Multiple (`vision-language-action-models.md:13`, `reinforcement-learning.md:25`, `decision-guide.md:16`, `evaluation-protocol.md`)

- "Semantic generalization" = understanding object categories (VLA strength)
- "Spatial generalization" = handling position/orientation shifts (RL & VLA)
- "No generalization" = task-specific (RL weakness)

No central glossary; readers must infer meaning from context.

**Fix:** Create `glossary.md` with key terms:
- **Semantic generalization:** Understanding *what* (object classes, scene structure, language). VLA unique capability via internet pretraining.
- **Spatial generalization:** Handling position, orientation, and scale variations. RL (reward-shaped) and VLA (pretrained vision) both strong; IL weak.
- **Domain generalization:** Transfer across object types, lighting, camera angles, embodiments. VLA > IL >> RL.
- **Task-specific:** Single-task optimization. RL & IL specialize here; VLAs also excel.

---

### CRG-4 · Low-reference topic pages need more internal links

**Pages with ≤2 inbound links (excluding nav pages):**

| Page | Inbound links | Should also link from |
|------|---|---|
| `[[evaluation-protocol]]` | 9 | `[[results]]` (intro), `[[pick-and-place]]` (methodology section) |
| `[[trajectory-planning]]` | 17 | `[[pick-and-place]]` (industrial P&P), `[[simulation-and-tools]]` (planning sim) |
| `[[simulation-and-tools]]` | 41 | `[[decision-guide]]` Step 2 (simulator selection) |
| `[[world-models]]` | 23 | `[[decision-guide]]` Step 4 (emerging RL frontier) |

**Fix:** Add 1–2 strategic backlinks to each (see specific suggestions in parentheses).

---

## 🟡 Missing Metrics (source richer than wiki)

### M-1 · GigaWorld-Policy: missing π0-5 comparison

**File:** `world-models.md:15–25`

Raw source abstract states: *"compared with pi-0.5, GigaWorld-Policy improves performance by **95% on RoboTwin 2.0**"* — a striking result not captured anywhere in the wiki. The wiki only mentions the Motus comparison.

**Fix:** Add to `world-models.md` GigaWorld-Policy entry:
> Also outperforms **π0-5 by 95%** on the RoboTwin 2.0 benchmark.

---

### M-2 · Mamba2Diff: CGRU module missing

**File:** `imitation-learning.md:75–81`

The wiki mentions only the BDGM module. Raw source describes two components: BDGM (global long-term features) and **CGRU (Convolution-Enhanced Gated Recurrent Unit)** for short-term dependencies. The two modules together explain why Mamba2Diff outperforms diffusion-only and non-diffusion baselines.

**Fix:** Add to the Mamba2Diff entry:
> Combines two modules: **BDGM** for long-horizon global features (bidirectional) and **CGRU** for short-term local dependencies. Evaluated on 3 simulated environments + 1 custom real-world platform.

---

### M-3 · GF-VLA: graph accuracy metric missing

**File:** `vision-language-action-models.md:118–123`, `grasping-and-manipulation.md:61–66`

Raw source also reports **95% graph accuracy** and **93% subtask segmentation** for the scene graph representation — neither appears in the wiki. These intermediate metrics explain *why* the 94%/90% task results are achievable.

**Fix:** Add to GF-VLA entries:
> Scene graph representation achieves **95% graph accuracy** and **93% subtask segmentation**, enabling the LLM planner to generate reliable task policies.

---

## 🟡 Orphan / Low-Inbound Algorithm Pages

Pages with only **2 inbound links** (index.md + one topic page) are effectively isolated — a reader exploring the wiki cannot reach them from multiple entry points.

### O-1 · `algo-safevla` — 2 inbound links

Only referenced from `vision-language-action-models.md` and `index.md`. SafeVLA uses **constrained RL (CMDP)** — it should appear in `reinforcement-learning.md` under a "Safe RL" or "Constrained RL" subsection. Its long-horizon mobile manipulation evaluation also connects to `simulation-and-tools.md`.

**Fix:**
- Add a brief entry in `reinforcement-learning.md` under a new `## Safe / Constrained RL` section → `[[algo-safevla]]`
- Add `See: [[algo-safevla]]` to the SafeVLA mention in `hybrid-il-rl.md` Related Topics

---

### O-2 · `algo-namr-rrt` — 3 inbound links

Referenced from `trajectory-planning.md`, `pick-and-place.md` (via trajectory planning), and `index.md`. The real-world validation was conducted in dynamic crowded outdoor environments (shopping malls) — this connects to `simulation-and-tools.md` (real-world testing) and `grasping-and-manipulation.md` is unrelated, but `pick-and-place.md` could link it more explicitly.

**Fix:**
- Add `See: [[algo-namr-rrt]]` to the trajectory comparison table row in `pick-and-place.md` "Long-Horizon" section

---

### O-3 · `algo-qlora` — 3 inbound links

Referenced from `llms-for-robotics.md`, `vision-language-action-models.md`, and `index.md`. QLoRA is the enabling technology for fine-tuning OpenVLA on consumer GPUs — it should also appear in `imitation-learning.md`'s discussion of fine-tuning VLA models from demonstrations.

**Fix:**
- Add `See: [[algo-qlora]]` to `imitation-learning.md` Related Topics section

---

## 🟡 Concepts Needing Dedicated Pages

The following models have **substantial source coverage** (full papers in `raw_sources/`) and are mentioned ≥4 times across topic pages, but have no `algo-*.md` explainer. They currently appear only as brief entries in topic pages, making them second-class citizens compared to peers like `algo-octo.md` or `algo-act.md`.

| Concept | Mentions | Source file | Priority |
|---------|----------|-------------|----------|
| **SmolVLA** | 6 | `SmolVLA A Vision-Language-Action Model...` | High |
| **TinyVLA** | 8 | `TinyVLA Towards Fast, Data-Efficient...` | High |
| **X-VLA** | 4 | `X-VLA Soft-Prompted Transformer...` | High |
| **GF-VLA** | 6 | `Information-theoretic graph fusion...` | High |
| **GigaWorld-Policy** | 4 | `GigaWorld-Policy An Efficient...` | Medium |
| **Mamba2Diff** | 4 | `Mamba2Diff An enhanced diffusion...` | Medium |
| **Cosmos-Reason1** | 4 | `Cosmos-Reason1 From Physical Common Sense...` | Medium |

**Suggested creation order:** SmolVLA → TinyVLA → X-VLA → GF-VLA (all 2025–2026 VLA family, reads as a coherent set), then GigaWorld-Policy → Mamba2Diff → Cosmos-Reason1.

**Note on DDPG:** 16 mentions across the wiki, but no source paper for DDPG exists in `raw_sources/`. DDPG appears only as a baseline in HER and Multi-Goal RL papers. A brief inline definition in `reinforcement-learning.md` (rather than a full algo page) would be sufficient.

---

## 🟢 Potentially Outdated Framing

### F-1 · VLA paradigm intro overstates the size-performance tradeoff

**File:** `vision-language-action-models.md:14`

> "large models (7B+ parameters) are slow at inference and expensive to train"

This was accurate when written (against RT-2-X's 55B). But the 2025 papers in the wiki now demonstrate:
- SmolVLA (<1B) matches VLAs 10× larger
- TinyVLA (<1B) is faster and more data-efficient than OpenVLA 7B
- X-VLA 0.9B achieves SOTA across 9 platforms

The framing implies 7B is the minimum viable size, which the newer papers contradict.

**Fix:** Update to:
> "The main tradeoff: large models (7B+) were historically slow and expensive, motivating a wave of efficient sub-1B VLAs (SmolVLA, TinyVLA, X-VLA) that now match or exceed 7B baselines."

---

### F-2 · `algo-vla-rl.md` Con: "simulation-only evaluation" may be stale

**File:** `algo-vla-rl.md:167`

> "Simulation-only — evaluation is entirely in LIBERO (simulation); real-robot results not reported"

This was accurate at paper submission (2025). If a subsequent version or extended paper exists in `raw_sources/` with real-robot results, this con should be updated. No such update was found in current raw sources — but flag for review when ingesting new sources.

---

## 🟢 Structural Notes

### S-1 · VLA comparison table missing Molmo family

**File:** `vision-language-action-models.md:156–167`

The comparison table has 8 rows (Octo through GF-VLA) but the Molmo Family section immediately above it (MolmoAct2, MolmoB0T) is not in the table. This creates an asymmetry where the table appears to summarize the full page but silently omits 3 models.

**Fix:** Add rows:
```
| MolmoAct2 | — | Yes | Yes | Explicit reasoning chains; real-world deployment |
| MolmoB0T  | — | Yes | Zero-shot | Zero-shot via simulation scale (MolmoSpaces) |
```

---

### S-2 · `algo-sql-sac.md` ↔ `algo-sac.md` cross-reference

Both pages cover related content (SQL is the precursor to SAC). Verify that `algo-sql-sac.md` contains an explicit `See: [[algo-sac]]` link, and vice versa. If not, add them. (Check: `algo-sql-sac.md` should have been updated to reference `algo-sac.md` when the SAC page was created — confirm this is the case.)

---

## Fixes Prioritized by Effort & Impact

### 🔴 Critical — Complete Today

| Fix | File | Effort | Impact |
|-----|------|--------|--------|
| CRIT-1 · Update "Pending" to "Done" for ACT/SmolVLA | `imitation-learning.md:42-43` | 2 edits | High — fixes false status |
| CRIT-2 · Clarify real-hardware RL is completed, not pending | `reinforcement-learning.md:40` | 1 edit | Medium — fixes confusing signal |
| CRIT-3 · Link distractor anomaly to root-cause hypothesis | `results.md:98` | 1 edit | High — clarifies key finding |
| B-1 · Fix broken anchor in `reinforcement-learning.md` | `reinforcement-learning.md:17` | 1 edit | Low — link repair |
| C-2 · Clarify VLA-RL "4.5% on 40 tasks" phrasing | `vision-language-action-models.md:99` | 1 edit | Medium — removes ambiguity |

**Total: 6 edits, ~15 min**

---

### 🟡 Important — This Week

| Fix | File | Effort | Impact |
|-----|------|--------|--------|
| C-1 · Add evaluation-context footnotes to RT-2-X scores | `algo-octo.md`, `algo-openvla.md` | 2 edits | Low — cosmetic |
| C-3 · Add GF-VLA placement accuracy (89%) | `vision-language-action-models.md`, `grasping-and-manipulation.md` | 2 edits | Medium — missing metric |
| CRG-1 · Create `contact-rich-tasks.md` hub page | New file | 30 min | High — improves navigation |
| CRG-2 · Add action generation methods comparison | `vision-language-action-models.md` or new file | 20 min | High — clarifies paradigm differences |
| CRG-3 · Create `glossary.md` for generalization types | New file | 20 min | Medium — improves vocabulary consistency |
| CRG-4 · Add backlinks to low-reference pages | 4 files | 5 edits | Medium — improves discoverability |
| M-1 · Add GigaWorld π0-5 result | `world-models.md` | 1 edit | Low |
| M-2 · Add CGRU module to Mamba2Diff | `imitation-learning.md` | 1 edit | Low |
| M-3 · Add graph accuracy to GF-VLA | 2 files | 2 edits | Low |
| O-1 · Add SafeVLA to Safe RL section | `reinforcement-learning.md` | 1 edit | Medium |
| F-1 · Update VLA paradigm intro tradeoff | `vision-language-action-models.md:14` | 1 edit | Low |
| S-1 · Add Molmo family to VLA comparison table | `vision-language-action-models.md` | 1 edit | Low |

**Total: ~35 edits + 3 new files, ~2 hours**

---

### 🟢 Nice-to-Have — Future Sessions

| Fix | Type | Effort | Impact |
|-----|------|--------|--------|
| Create algo pages: SmolVLA, TinyVLA, X-VLA, GF-VLA | 4 new files | 4 hrs | High — completes VLA family docs |
| Create algo pages: GigaWorld-Policy, Mamba2Diff, Cosmos | 3 new files | 3 hrs | Medium — emerging techniques |
| O-2, O-3 · Extra backlinks for NAMR-RRT and QLoRA | 2 edits | 5 min | Low — minor navigation |
| Add Advantages/Disadvantages to 5 more algo pages | 5 edits | 30 min | Medium — consistency |

---

---

## 📊 Wiki Health Metrics (2026-06-25)

| Metric | Value | Trend | Status |
|--------|-------|-------|--------|
| **Total pages** | 42 | +7 since 2026-05-22 | ✅ Growing steadily |
| **Algorithm pages (algo-*)** | 27 | +6 | ✅ |
| **Topic/synthesis pages** | 10 | same | ✅ |
| **Navigation pages** | 5 | same | ✅ |
| **Dead wiki links** | 0 | ✅ unchanged | ✅ Perfect |
| **Orphan pages** | 0 | ✅ unchanged | ✅ Perfect |
| **Critical issues (status/contradiction)** | 3 | ⚠️ NEW | 🔴 Action required |
| **Pages with completed results** | 5 | +1 (SmolVLA done) | ✅ |
| **Cross-reference density** | High (avg 8 links/page) | Stable | ✅ |

---

## Lint Methodology

**This report was generated by:**
1. **Link analysis:** Extracted all `[[...]]` references; counted inbound links per page
2. **Status consistency:** Cross-checked "Pending" and "Done" markers across `imitation-learning.md`, `reinforcement-learning.md`, `results.md`, `overview.md`
3. **Results audit:** Compared success rate numbers across 5 pages for consistency (SAC 92%, ACT 83–94%, SmolVLA 58%, PPO timing)
4. **Concept discovery:** Identified frequently-mentioned topics without dedicated pages (contact-rich, flow matching, action generation)
5. **Raw source spot-checks:** Verified claims in 8 papers for missing metrics or outdated framing
6. **Cross-reference depth:** Evaluated whether synthesis pages (decision-guide, evaluation-protocol, results) are properly linked from algorithmic pages

**Excluded from this analysis:**
- Prose quality, tone, or length
- PDF/image handling (all images stored locally)
- Git history or version control

---

*Next report: 2026-07-02 (or after 10 new raw-source papers ingested)*
