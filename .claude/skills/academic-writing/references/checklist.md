# Pre-submission checklist

## Argument
- [ ] Research question stated in one sentence in the introduction, and answered plainly in the conclusions.
- [ ] Every contribution has a presentation (method), evidence (evaluation), and revisit (conclusions).
- [ ] No claim is stronger than its evidence (see the calibration table in SKILL.md).
- [ ] Limitations are specific; future work follows from them.

## Consistency
- [ ] Every number appears with the same value everywhere: abstract, text, tables, captions, slides.
- [ ] Each concept has one name, used consistently. Acronyms are defined at first use.
- [ ] Notation matches the background chapter throughout.
- [ ] Summary statements ("all", "both", "none") hold for every case they cover.

## LaTeX hygiene
- [ ] `grep -rn '\\todo{' .` finds nothing.
- [ ] The build has no undefined references or citations (`scripts/build.sh` prints them).
- [ ] No overfull boxes over ~5pt (`grep 'Overfull' build/*.log`).
- [ ] Every figure and table is referenced in the text, and its caption makes sense on its own.
- [ ] Every bibliography entry is complete (authors, title, venue, year; DOI if available). No "et al." inside the .bib author field.
- [ ] Every appendix is referenced from the main text.

## Front matter
- [ ] Metadata (title, names, degree, date) is correct on the title, copyright, signature and declaration pages.
- [ ] The abstract contains the main result and no citations.

## Versions
- [ ] Committed and released: `scripts/release.sh <doc> <version>`.
- [ ] If this is a revision after feedback: diff generated (`scripts/diff.sh <doc> <previous-tag>`) and each feedback point mapped to a change.
