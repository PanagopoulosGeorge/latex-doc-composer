---
name: academic-writing
description: Principles for drafting and revising academic text (theses, papers, reports) - document structure, chapter roles, argument and evidence, claim calibration, paragraphs, style, figures, citations. Use when drafting or editing prose in a thesis/paper, restructuring chapters, writing an abstract/introduction/conclusion, or responding to supervisor feedback.
---
# Academic writing

The reader is a busy expert, often an examiner, looking for gaps. Good academic writing makes the argument easy to check.

## The argument comes first
A thesis is one argument: **problem → question → approach → evidence → answer**. Every chapter has a job in it (see `references/structure.md`). Before editing prose, check:
1. Can you state the research question in one sentence?
2. Does every contribution listed in the introduction have evidence in the evaluation, and get revisited in the conclusion?
3. Does each chapter say at its start what it does and how it connects to the previous one?

If any answer is no, fix the structure first. Polishing sentences in a chapter that shouldn't exist is wasted effort.

## Claim calibration (the most common examiner complaint)
Classify each claim by its support, and phrase it to match:

| Support | Wording |
|---|---|
| Measured (your experiment, reported in a table/figure) | "X improves Y by 12% (Table 5.2)" |
| Analytic (follows from a definition or proof) | "By construction, X guarantees Y" |
| Anecdotal (one example, an observation) | "In the cases we inspected, X tended to..." |
| Cited | "Prior work reports X [12]". Check that [12] actually says it |
| Unsupported | Remove it, or turn it into an explicit hypothesis or future work |

- Words that need strong evidence: *always, never, all, none, significantly* (that word implies a statistical test), *proves, solves, state-of-the-art, first*.
- A claim covering "all models" or "both datasets" must hold for **every row** it covers. Check the table.
- Report what you measured, not what you hoped. Negative and partial results stated clearly are worth more than overclaimed ones.

## Paragraphs
- One idea per paragraph. The **first sentence states it**, and the rest supports it. A reader skimming first sentences should follow the whole argument.
- Old → new: start a sentence with something already known and end with the new information.
- Signpost transitions: *However*, *As a result*, *In contrast*. Don't let readers guess how two paragraphs relate.

## Sentences and style
- Concrete subject + active verb: "We evaluate X on Y" rather than "An evaluation of X was performed on Y". The passive voice is fine when the actor doesn't matter.
- "We" is normal in CS and engineering theses, even with a single author. Follow your institution's convention and be consistent.
- Cut filler: *in order to* → *to*; *it is important to note that* → (delete); *a number of* → *several*/the actual number; *utilize* → *use*.
- **One term per concept.** Don't alternate "rule", "definition" and "specification" for the same thing. Readers assume different words mean different things. Define a term once and put it in `macros.tex` if it's a name.
- Define every acronym at first use in the main text, even if it's in the list of acronyms.
- Tense: present for what the thesis does and for established facts ("Chapter 4 presents"). Past for what you did in experiments ("We ran..."). Present for what the results show ("Table 3 shows").
- Numbers: give units, a consistent number of decimals, and the same value everywhere it appears (abstract, text, tables, slides).

## Figures and tables
- A caption should make sense on its own: what is shown, what to notice, and what the metric/axes mean.
- Every figure and table is referenced in the text **before** it appears, and the text says what to conclude from it.
- Tables: use `booktabs` (no vertical lines), right-align numbers, bold the best value, and mark the metric direction (↑/↓).
- Plots: label axes with units, use a readable font size, and choose colours that survive grayscale and colour-blindness.

## Citations
- Cite the primary source for definitions and claims, not a survey that mentions it.
- Read what you cite, at least the relevant section. Don't attribute claims a paper doesn't make.
- Citations support sentences; they aren't nouns: "Smith et al. [3] show..." or "...as shown previously [3]", not "[3] shows".
- Don't invent references. If you (the agent) aren't sure a paper exists and says what you claim, mark it `\todo{verify citation}` and tell the user.

## Revising
Work top-down:
1. **Structure**: chapter jobs, contribution ↔ evidence ↔ conclusion links.
2. **Paragraphs**: topic sentences, one idea each.
3. **Sentences**: clarity, consistent terms.
4. **Mechanics**: typos, references, number consistency.

Use `references/checklist.md` before any version goes to a supervisor or examiner.

When editing someone's thesis as an agent:
- Keep their voice. Propose bigger restructurings rather than doing them silently.
- Never change a number, result or claim's meaning without asking.
- Release a version (`scripts/release.sh`) before large edits, so the user can review them with `scripts/diff.sh`.
