---
name: reviewer-mdpi-perspective
description: Simulates an MDPI peer review for an academic paper, producing a complete report in the official MDPI review form. Runs the reviewer skill for the deep technical analysis, then maps its findings onto every MDPI rubric item (recommendations for authors, English quality, editor-only ethics checks, novelty/significance/presentation/soundness/interest/merit ratings, reference check, comments for authors and editors, and the overall recommendation). Use when reviewing a paper for an MDPI journal, preparing to respond to MDPI reviewers, or dry-running an MDPI submission.
---

# MDPI Peer Reviewer

Simulates the official MDPI peer-review report for an academic paper. It reuses the comprehensive analysis from the `reviewer` skill and maps it onto the exact MDPI review form, so the output can be pasted directly into the MDPI reviewer interface (or used to anticipate what MDPI reviewers will ask before submitting).

## When to Use

- You are a reviewer filling in the MDPI review form for a manuscript
- You want to dry-run an MDPI submission to anticipate reviewer questions and ratings
- You are preparing a rebuttal or revision for an MDPI journal
- You need a venue-specific review calibrated to MDPI's rubric (not a generic review)

## How This Skill Works

This skill does **two passes**:

1. **Deep analysis** — invoke the `reviewer` skill (pre-submission reviewer) and run its full 8-dimension analysis on the manuscript. Keep its findings: strengths, weaknesses, critical/major/minor issues, figure audit, writing spot checks, and expected reviewer questions.
2. **MDPI mapping** — translate those findings into the official MDPI review report using the rubric and decision rules below.

> If you have not run `reviewer` yet, run it first (`/skill:reviewer`) with the same manuscript. If the `reviewer` skill is unavailable, perform an equivalent 8-dimension analysis (novelty, clarity, methodological rigor, experimental validity, threats to validity, reproducibility, references, structure/venue fit) before filling the form.

## Input Requirements

1. **Complete manuscript**: all sections, figures, tables, references
2. **The MDPI journal name / section** (e.g., *Molecules*, *Sensors*, *IJERPH*, *Applied Sciences*) to calibrate scope
3. **Author concerns** (optional) and **prior review comments** (if a resubmission)
4. **Reviewer role**: author dry-run (simulate) or actual reviewer (final report)

---

## The MDPI Review Rubric

Reproduce the official MDPI review report structure exactly. Answer every item; do not skip or invent evidence.

### Part 1 — Recommendations for Authors (shown to authors)

*Answers to the following questions do not replace any specific comments made for authors. Give further details in the "Comments and Suggestions for Authors" box.*

| Question | Options |
|----------|---------|
| Does the introduction provide sufficient background and include all relevant references? | Yes / Can be improved / Must be improved / Not applicable |
| Is the research design appropriate? | Yes / Can be improved / Must be improved / Not applicable |
| Are the methods adequately described? | Yes / Can be improved / Must be improved / Not applicable |
| Are the results clearly presented? | Yes / Can be improved / Must be improved / Not applicable |
| Are the conclusions supported by the results? | Yes / Can be improved / Must be improved / Not applicable |
| Are all figures and tables clear and well-presented? | Yes / Can be improved / Must be improved / Not applicable |

### Part 2 — Quality of English Language (shown to authors)

- The English could be improved to more clearly express the research.
- The English is fine and does not require any improvement.

### Part 3 — Recommendations for Editors (NOT shown to authors)

*If you answered "Yes" to any of the following, give details in the "Comments for Editors" box.*

| Question | Options |
|----------|---------|
| Do you have any potential conflicts of interest with regard to this paper? | Yes / No |
| Did you detect plagiarism? | Yes / No |
| Did you detect inappropriate self-citations by authors? | Yes / No |
| Do you have any other ethical concerns about this study? | Yes / No |

### Part 4 — Ratings

| Criterion | Options |
|-----------|---------|
| Originality/Novelty | High / Average / Low / No Answer |
| Significance of Content | High / Average / Low / No Answer |
| Quality of Presentation | High / Average / Low / No Answer |
| Scientific Soundness | High / Average / Low / No Answer |
| Interest to Readers | High / Average / Low / No Answer |
| Overall Merit | High / Average / Low / No Answer |

### Part 5 — References

**Are the references cited in this manuscript appropriate and relevant to this research?** Yes / No

### Part 6 — Comments

- **Comments and Suggestions for Authors** (shown to authors)
- **Comments for Editors** (NOT shown to authors)

### Part 7 — Overall Recommendation

- Accept in present form
- Accept after minor revision (corrections to minor methodological errors and text editing)
- Reconsider after major revision (substantial revisions to text or experimental methods needed)
- Reject (article has serious flaws, additional experiments needed, research not conducted correctly)

### Part 8 — Final Status Notification

**Please confirm whether you would like to be notified about the final status of the paper:** Yes / No

---

## Mapping from `reviewer` Dimensions to the MDPI Form

Use the following mapping to convert the `reviewer` skill output into MDPI answers. The mapping is a guide; use judgment.

| MDPI item | Primary `reviewer` dimension(s) | Scoring rule |
|-----------|--------------------------------|--------------|
| Introduction background & references | Clarity & Presentation (Introduction flow) + References (coverage/recency) | **Yes** = background adequate AND key references present. **Can be improved** = minor gaps (a few missing/irrelevant refs, thin motivation). **Must be improved** = substantial missing background or key citations absent. |
| Research design appropriate | Methodological Rigor (problem formalization, method justification, design choices) | **Yes** = design sound and justified. **Can be improved** = design mostly sound but some choices unjustified or a weak element. **Must be improved** = flawed design that undermines validity. |
| Methods adequately described | Methodological Rigor (implementation detail) + Reproducibility | **Yes** = reproducible detail. **Can be improved** = missing minor details (hyperparameters, settings). **Must be improved** = missing steps that block reproduction. |
| Results clearly presented | Clarity & Presentation + Experimental Validity (statistical rigor) | **Yes** = clear, complete, statistically reported. **Can be improved** = some unclear passages, missing stats/error bars. **Must be improved** = results confusing or key data missing. |
| Conclusions supported by results | Experimental Validity (conclusion validity) + Novelty (overclaiming) | **Yes** = claims match evidence. **Can be improved** = minor overreach. **Must be improved** = conclusions not supported / overclaimed. |
| Figures and tables clear & well-presented | Clarity & Presentation (Figure/Table quality) + the figures/tables audit | **Yes** = all clear. **Can be improved** = some need polish. **Must be improved** = major figures unclear/incorrect. **Not applicable** = no figures/tables. |
| English language quality | Clarity & Presentation (writing quality spot checks) | **Fine** = only trivial typos. **Could be improved** = grammar/wording issues that obscure meaning. |
| Originality/Novelty | Novelty & Contribution | **High** = significant/breakthrough. **Average** = solid/incremental advance. **Low** = marginal or redundant. |
| Significance of Content | Novelty & Contribution (problem significance) | As above, weighted by impact on the field. |
| Quality of Presentation | Clarity & Presentation | **High** = clear, well-organized. **Average** = acceptable. **Low** = poorly written/organized. |
| Scientific Soundness | Methodological Rigor + Experimental Validity + Threats to Validity | **High** = rigorous, valid, few threats. **Average** = sound with some weaknesses. **Low** = flawed methods/validity. |
| Interest to Readers | Novelty & Contribution (significance/broad appeal) | **High** = broad interest. **Average** = niche but valuable. **Low** = narrow/dated. |
| Overall Merit | Weighted average of all dimensions | **High** = strong overall. **Average** = acceptable. **Low** = weak overall. |
| References appropriate & relevant | References (coverage, accuracy, self-citation balance) | **Yes** if coverage adequate, accurate, no excessive self-citation. **No** if key omissions, irrelevant citations, or citation abuse. |

---

## Overall Recommendation Decision Rules

Map the `reviewer` skill's honest recommendation to MDPI's four options:

| `reviewer` outcome | MDPI overall recommendation |
|--------------------|-----------------------------|
| Strong Accept / Accept | **Accept in present form** |
| Weak Accept / Borderline with only minor issues | **Accept after minor revision** (corrections to minor methodological errors and text editing) |
| Borderline with major issues / Weak Reject (fixable) | **Reconsider after major revision** (substantial revisions to text or experimental methods needed) |
| Reject (serious flaws, non-fixable, unethical) | **Reject** (article has serious flaws, additional experiments needed, research not conducted correctly) |

**Consistency rule**: The overall recommendation must be consistent with the Part 1 answers, the ratings, and the comments. If several Part 1 items are "Must be improved" or any rating is "Low", "Accept in present form" is normally unjustified. Flag any inconsistency rather than silently hiding it.

---

## Scoring Guidance Per Part

### Part 1 — Recommendations for Authors

For each item, provide the selected option plus a one-line justification citing the specific section/table/line. Do not answer "Not applicable" unless the manuscript genuinely lacks that element.

- **Introduction background & references**: check the motivation, gap statement, and whether the reference list covers seminal + recent (last 2–3 years) work.
- **Research design appropriate**: check whether the study type (experimental, observational, computational, survey) matches the research question, and whether controls/baselines/comparators are appropriate.
- **Methods adequately described**: check reproducibility — enough detail (materials, protocols, parameters, software, statistics) to replicate.
- **Results clearly presented**: check that results are organized logically, fully reported (not cherry-picked), and include measures of uncertainty where applicable.
- **Conclusions supported by results**: check that every conclusion traces to a reported result; flag overclaiming and unsupported generalization.
- **Figures and tables clear & well-presented**: check legibility, correct units/labels, informative captions, and that they are referenced in the text.

### Part 2 — English Language

- Choose **"The English is fine..."** only if the manuscript has, at most, trivial typos that do not affect comprehension.
- Choose **"The English could be improved..."** if there are grammar, wording, or clarity issues. Then list the most important examples in the comments.

### Part 3 — Recommendations for Editors (ethics)

Answer each Yes/No. These are confidential and must **not** appear in the comments for authors.

- **Conflicts of interest**: answer "Yes" only if the reviewer (or the simulated review) has an actual conflict (e.g., co-author, same institution, competing work). For a dry-run, normally "No".
- **Plagiarism**: "Yes" only with concrete evidence (verbatim overlap, uncredited text). Cite the affected passages in Comments for Editors. If you suspect but cannot confirm, note the suspicion and recommend a similarity check — do not accuse.
- **Inappropriate self-citations**: "Yes" if self-citation appears inflated (e.g., many self-cites not needed to support the work). Quantify (e.g., "N of M references are self-citations").
- **Other ethical concerns**: data fabrication indicators, undisclosed conflicts, ethics-approval gaps (human/animal studies), image manipulation, duplicate submission. Detail in Comments for Editors.

### Part 4 — Ratings

Choose High / Average / Low. Avoid "No Answer" unless information is genuinely missing. Justify each rating briefly in the comments or in the report's rationale section.

### Part 5 — References

- **Yes** — references are appropriate, relevant, reasonably current, and free of abuse.
- **No** — key references missing, irrelevant references cited, or self-citation abuse. List specifics in the comments.

### Part 6 — Comments

- **Comments and Suggestions for Authors** (shown to authors): constructive, specific, prioritized. Use the `reviewer` skill's Critical/Major/Minor issues tables and expected reviewer questions. Structure: (1) summary of the work, (2) major points, (3) minor points, (4) line/section-specific edits. Do not include any ethics concerns or the recommendation-to-reject wording here; keep it professional and actionable.
- **Comments for Editors** (confidential): only ethics findings (Part 3 "Yes" items), a confidential summary of concerns that should not reach authors, and any suspected misconduct. Never duplicate author-facing comments here.

### Part 7 — Overall Recommendation

Pick exactly one option using the decision rules above. Be decisive; MDPI requires a single choice.

### Part 8 — Notification

Recommend **"Yes"** (reviewers are typically notified of the final decision). For a dry-run simulation this field is informational.

---

## Output Format

Emit the review exactly in the MDPI report layout so it can be transcribed/pasted into the MDPI form. Then append an internal rationale (not part of the form) for traceability.

```markdown
# MDPI Review Report
*Manuscript: [Title]*
*Journal/Section: [e.g., Sensors — Section "Intelligent Sensors"]*
*Submission Date: [Date]*
*Prepared by: reviewer-mdpi-perspective (Academic Research Suite)*

---

## Recommendations for Authors (shown to authors)

*Answers to the following questions do not replace any specific comments made for authors. Please give further details in the "Comments and Suggestions for Authors" box below.*

| # | Question | Answer |
|---|----------|--------|
| 1 | Does the introduction provide sufficient background and include all relevant references? | Yes / Can be improved / Must be improved / Not applicable |
| 2 | Is the research design appropriate? | Yes / Can be improved / Must be improved / Not applicable |
| 3 | Are the methods adequately described? | Yes / Can be improved / Must be improved / Not applicable |
| 4 | Are the results clearly presented? | Yes / Can be improved / Must be improved / Not applicable |
| 5 | Are the conclusions supported by the results? | Yes / Can be improved / Must be improved / Not applicable |
| 6 | Are all figures and tables clear and well-presented? | Yes / Can be improved / Must be improved / Not applicable |

### Quality of English Language
- [x] The English could be improved to more clearly express the research.   *(or)*
- [ ] The English is fine and does not require any improvement.

---

## Recommendations for Editors (NOT shown to authors)

*If you answered "Yes" to any of the following, give details in the "Comments for Editors" box below.*

| # | Question | Answer |
|---|----------|--------|
| 1 | Do you have any potential conflicts of interest with regard to this paper? | Yes / No |
| 2 | Did you detect plagiarism? | Yes / No |
| 3 | Did you detect inappropriate self-citations by authors? | Yes / No |
| 4 | Do you have any other ethical concerns about this study? | Yes / No |

---

## Ratings

| Criterion | Rating |
|-----------|--------|
| Originality/Novelty | High / Average / Low / No Answer |
| Significance of Content | High / Average / Low / No Answer |
| Quality of Presentation | High / Average / Low / No Answer |
| Scientific Soundness | High / Average / Low / No Answer |
| Interest to Readers | High / Average / Low / No Answer |
| Overall Merit | High / Average / Low / No Answer |

---

## References

**Are the references cited in this manuscript appropriate and relevant to this research?** Yes / No

---

## Comments

### Comments and Suggestions for Authors
*(shown to authors)*

[Constructive, specific, prioritized comments. Summary → Major points → Minor points → Section-specific edits.]

### Comments for Editors
*(NOT shown to authors)*

[Only ethics findings, confidential concerns, suspected misconduct. "None" if there are no editor-only concerns.]

---

## Overall Recommendation

**Overall Recommendation:** Accept in present form / Accept after minor revision / Reconsider after major revision / Reject

**Would you like to be notified about the final status of the paper?** Yes / No

---

## Anonymity

*To ensure your anonymity throughout the peer-review process, do not include any identifiable information in the review report, including in the comments and metadata of any uploaded files. Comments for authors may be made available to other reviewers, but the identity will remain anonymous.*
*(Confirm the report above contains no identifying information.)*

---

## Internal Rationale (NOT part of the form — do not submit)

*Traceability between this MDPI report and the `reviewer` skill analysis.*

| MDPI item | Answer | Evidence / `reviewer` dimension |
|-----------|--------|---------------------------------|
| 1. Introduction & references | [Answer] | [Section, missing refs, dimension] |
| 2. Research design | [Answer] | [Design issue, dimension] |
| 3. Methods described | [Answer] | [Reproducibility gaps] |
| 4. Results presented | [Answer] | [Clarity/stats issues] |
| 5. Conclusions supported | [Answer] | [Overclaiming evidence] |
| 6. Figures & tables | [Answer] | [Figure audit findings] |
| English quality | [Answer] | [Writing spot-check examples] |
| Ethics (Editors) | [Answers] | [Evidence or "none"] |
| Ratings | [Answers] | [Per-dimension scores → rating] |
| References appropriate | [Answer] | [Coverage/self-citation findings] |
| Overall recommendation | [Answer] | [Decision rule used] |

**Consistency check:** [Confirm recommendation is consistent with Part 1 answers, ratings, and comments; flag any tension.]
```

---

## Review Principles

1. **Be decisive**: MDPI requires a single answer per item and a single overall recommendation — no hedging.
2. **Be specific and evidence-based**: cite section, figure, table, or line for every "Can be improved" / "Must be improved" / "Low" answer. Do not invent evidence.
3. **Separate author-facing from editor-facing content**: ethics and confidential concerns go only in "Comments for Editors", never in "Comments and Suggestions for Authors".
4. **Stay constructive with authors**: even a "Reject" must be accompanied by respectful, actionable feedback.
5. **Preserve anonymity**: no reviewer-identifying information anywhere in the report or file metadata.
6. **Keep consistency**: overall recommendation, ratings, and Part 1 answers must tell the same story.
7. **Use "Not applicable" sparingly**: only when an element genuinely does not exist (e.g., no figures).

## Integration

- **Input from**: `reviewer` (deep 8-dimension analysis) — always run it first.
- **Complements**: `reference-checker` (for the references item), `plagiarism-checker` (for the editors' plagiarism check), `journal-selector` (to confirm MDPI fit).
- **Output to**: `research-manager` (revision planning after the simulated review), or directly to the author/researcher as an MDPI-ready report.
- **Iteration**: review → revise → re-run `reviewer-mdpi-perspective` until the recommendation reaches the desired threshold.
