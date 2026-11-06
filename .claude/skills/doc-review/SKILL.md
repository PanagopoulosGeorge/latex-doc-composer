---
name: doc-review
description: Run an independent multi-reviewer critique of a thesis/paper (and its slides) and write REVIEW.md. Use only when the user runs /doc-review.
disable-model-invocation: true
argument-hint: "<doc-dir> [slides-dir] [scope, e.g. chapters/05-evaluation.tex]"
---
Review a document the way a committee would, with independent reviewers and verified findings.

1. Find the document's sources (the main file and every `\input` file) and, if given, the slides.
   If the user passed a scope, restrict the review to it.
2. Build the document first (`scripts/build.sh`) so reviewers can cite the real numbers. Report build errors as findings.
3. In parallel, launch the `consistency-auditor`, `examiner` and `methods-critic` agents.
   Give each one only the file paths and its task, not your own opinions, so the reviews stay independent.
4. Collect every Critical and High finding. For each one, launch a `finding-verifier` agent with the finding and its cited locations.
5. Drop findings marked WRONG; soften OVERSTATED ones.
6. Write `<doc-dir>/REVIEW.md`:
   - findings merged and deduplicated, ordered by severity, each with `file:line`, which reviewer(s) raised it, and a concrete fix;
   - the examiner's likely questions;
   - an "Open questions for the author" section for anything that needs a decision rather than an edit.
7. Don't edit the document. Tell the user where REVIEW.md is and summarise the top three findings.
