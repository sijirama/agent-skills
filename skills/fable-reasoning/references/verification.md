# Verification Methodology

Verification is where claimed competence becomes actual competence. The failure mode it prevents is specific and common: code that *looks* correct, typechecks, and matches the pattern of correct code — but doesn't do the right thing. No amount of careful writing substitutes for observing the behavior.

## The Hierarchy of Evidence

From weakest to strongest. Know which level you're at, and report at that level:

1. **It reads correctly** — you re-read the code and believe it. (Necessary, never sufficient.)
2. **It parses/typechecks/lints** — the change is syntactically coherent. Catches typos, not logic.
3. **It builds** — the module graph is intact. Still says nothing about behavior.
4. **Unit tests pass** — the tested paths behave as the tests expect. Only as strong as the tests; new behavior needs *new* tests to be covered at all.
5. **The changed behavior was exercised directly** — you ran the actual flow (hit the endpoint, clicked the flow, ran the script on real input) and observed the correct output. **This is the minimum bar for claiming "it works."**
6. **The original failure case now passes AND the surrounding cases still pass** — for bug fixes, the gold standard.

When you report status, your words must match your level: "typechecks, but I couldn't run it in this environment" is honest and useful. "Works now" backed by level 2 evidence is the cardinal sin.

## Verifying a Bug Fix

1. **Re-run the original reproduction** — the exact failing input/steps captured before the fix. Watch it pass. If you never had a reproduction, you cannot actually verify the fix; say so.
2. **Run the neighbors** — the cases adjacent to the fix (the other branch of the condition you changed, the boundary values around the one that failed). Fixes regularly break the case right next to the one they fix.
3. **Check for regression in the blast radius** — run the tests/flows of every caller you identified when planning the change.
4. **Confirm the mechanism, not just the outcome.** If the symptom vanished but you can't explain why your change fixed it, treat the bug as NOT fixed — you likely disturbed the timing or masked it. This is how bugs come back in production.

## Verifying New Functionality

Exercise it end to end, through the real entry point — not just the inner function in isolation:

- Happy path with realistic (not toy) input.
- The most likely failure input (empty, malformed, unauthorized) — confirm it fails the way you designed, with the intended error surface, not a crash.
- One boundary case from the edge-case taxonomy that applies.
- Integration seams: does the data actually arrive in the DB / the email actually contain the right fields / the UI actually re-render? The unit can be perfect while the wiring is wrong; most real-world breakage lives at seams.

If the environment permits it, drive the real app (dev server + request, script run on live data path). If it doesn't, state exactly what you could and could not verify.

## Designing Tests That Discriminate

A test is valuable in proportion to its ability to fail when the code is wrong.

- **Write the assertion for the behavior, not the implementation.** Asserting a mock was called with certain arguments verifies wiring, not correctness; prefer asserting on the observable output/state.
- **The best first test for a bug fix is one that fails before the fix and passes after.** If you can, actually run it against the pre-fix code (stash the fix, run, unstash) — a "regression test" that passes both ways is decoration.
- Test names should state the expected behavior ("returns empty list when user has no enrollments"), so a failure reads as a specification violation.
- One behavior per test. A test asserting five things reports failure as "something in here broke."
- Don't over-mock. Every mock is an assumption that the real dependency behaves as the mock does — the exact class of assumption verification exists to eliminate. Mock only true boundaries (network, clock, randomness).
- Match the project's existing test idiom and runner; check how sibling features are tested before inventing structure. If the project has no test framework, verification shifts to direct exercise (level 5) — don't bolt on a framework as a side effect of a small change.

## Reviewing Your Own Diff — the Adversarial Pass

Do this immediately before declaring done. Read the raw diff (`git diff`), not your memory of it, in reviewer mode:

- **Per hunk:** does this hunk serve the stated goal? (Stray edits, leftover debug code, accidental formatting churn — remove.) Is anything in it there because "it seemed safer" without a reason you can articulate?
- **Classic-bug sweep per hunk:** inverted condition, off-by-one, `==`/`===`, missing `await`, error swallowed by a broad catch, early return skipping cleanup, mutated shared object, stale closure over a changed variable, resource opened but not closed on the error path.
- **The absence check:** what does this diff *assume* stayed the same? (A caller, a config value, a DB column, an env var, ordering of operations.) Verify the top one or two assumptions instead of trusting them.
- **The second-instance check:** if this was a bug, grep for the same pattern elsewhere. Bugs are rarely unique.
- **Trace one concrete input** through the final version of the changed path, line by line, including one edge input. Concrete tracing catches what pattern-level reading glosses over.

## Proving a Negative ("nothing else broke")

You can't prove it absolutely; you can bound it honestly:

- Run the project's own gates: test suite, typecheck, lint, build. Report actual results, including pre-existing failures you didn't cause (note them as pre-existing — verify by checking they fail on the base branch too).
- Exercise the highest-traffic flow that shares code with your change, even if "unrelated."
- State the bound explicitly: "Tests, typecheck, and a manual pass through checkout all pass; I did not exercise the admin flows."

## Reporting Results

- Lead with the verdict and its evidence level: "Fixed and verified — the original failing request now returns 200 and the webhook test passes."
- Failures verbatim: paste the actual failing output, not a paraphrase. Never soften a failure into "mostly working."
- Distinguish three buckets explicitly when relevant: verified ✓ / believed but unverified / known not done.
- If you hit the limits of the environment (no DB access, can't send real email), name the residual risk and the one command or check the user should run to close it.

The habit that ties all of this together: **never let your certainty outrun your evidence, and never end a task at evidence level 1–3 while claiming level 5.**
