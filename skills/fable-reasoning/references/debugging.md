# Debugging Methodology

Debugging is applied epistemology: you hold a wrong belief about the system (that's why the bug surprises you), and the job is to find and correct that belief with the cheapest possible sequence of observations. Everything below serves that.

## Step 1 — Reproduce Before Anything Else

A bug you can't reproduce is a bug you can't verify you've fixed.

- Get the exact failing input, environment, and steps. "Sometimes it fails" → find the conditions that make it *always* fail before theorizing.
- Shrink the reproduction. Every element you remove while the bug persists eliminates hypotheses for free. The minimal repro often *is* the diagnosis.
- If you genuinely can't reproduce it, say so, and shift strategy: instrument the code path so the *next* occurrence yields evidence (structured logging around the suspect region, capturing inputs at the boundary). Don't fix blind.
- Capture the failure output verbatim before changing anything. After your fix, you need to compare against exactly this.

## Step 2 — Read the Error Like It's Evidence, Not Noise

- Read the ENTIRE message, including the middle frames of the stack trace. The topmost frame is where it *crashed*; the frame where the bad value *entered* is usually several levels down.
- Extract every fact: exact type, exact value, exact line, exact time. "Expected string, got undefined" tells you the bug is upstream — something failed to produce a value, and the crash site is just the victim.
- Distinguish the *first* error from *cascade* errors. In long logs, scroll UP: the first anomaly usually causes everything after it. Fixing cascade errors is wasted work.
- If there is no error — silent wrong behavior — the question becomes "where does reality diverge from expectation?" That's a bisection problem (below).

## Step 3 — Build a Hypothesis Tree, Then Bisect It

Enumerate candidate causes across ALL layers before drilling into any one:

- **My code** (most likely): logic error, wrong assumption about input shape, missing case.
- **My understanding of the API/library**: wrong argument order, misread semantics, version mismatch between docs in memory and the installed version. Check the installed version's actual behavior, not your memory of it.
- **State/environment**: stale cache, stale build artifact, env var missing/wrong, wrong database/branch, dirty local state that CI doesn't have.
- **Data**: the input everyone assumed well-formed isn't (nulls, duplicates, encoding, timezone).
- **Timing/concurrency**: order-dependent behavior, race, missing await, callback firing twice.
- **The tooling itself** (least likely — suspect this last, but not never).

Then bisect: choose the observation that most cleanly splits the tree, regardless of which hypothesis you *favor*.

- **Spatial bisection**: is the value correct at point A? At point B? Binary-search along the data path until you find the exact boundary where good data becomes bad. This is the single highest-value debugging move; it converges in log(n) probes.
- **Temporal bisection**: did this ever work? `git bisect` (or manual checkout of older commits) converts "mystery bug" into "what changed in this diff," which is a vastly easier question.
- **Differential diagnosis**: it works in environment A, fails in B → enumerate the differences between A and B; the cause is in that list. Same for "works for input X, fails for Y."

## Step 4 — Instrument Decisively

- Prefer print/log statements that show *values*, not just "got here." `console.log('user', JSON.stringify(user))` beats `console.log('here 3')`. Log at the boundaries where you suspect the divergence.
- One experiment per run, one variable changed per experiment. Write down (or hold explicitly) what each experiment is testing and what each outcome would imply, BEFORE running it. An experiment whose outcome you can't interpret in advance is not an experiment.
- When output contradicts your prediction — that's the gold. Stop, update the model, re-rank the tree. Don't rationalize it away.
- Remove all instrumentation when done.

## Step 5 — Confirm the Causal Chain, Then Fix

You have found the bug when you can narrate: *"The symptom S occurs because value V is wrong at point P; V is wrong because code C does X under condition Y."* If you can't tell this story, you have a correlation, not a cause — keep going.

- Fix at the point where the invariant is *violated*, not where the symptom appears. Guarding the crash site (`if (x) ...`) while bad data still flows is symptom suppression.
- After fixing, reproduce the ORIGINAL failure case and observe it passing. Then check the bug's siblings: the same mistake pattern usually exists elsewhere in the file — grep for it.
- Ask what allowed this bug to survive until now: missing test, missing validation, misleading name? Fixing that is often in scope; at minimum, mention it.

## Special Cases

**Heisenbugs (disappear under observation):** almost always timing or shared state. Adding a log changed the timing. Suspect races, missing awaits, and reliance on uninitialized values. Use logging that's cheap enough not to change timing (buffered, post-hoc) and reason from the code's concurrency structure rather than pure experimentation.

**Intermittent failures:** run the failing thing in a loop (20–100×) to get a failure *rate*, then test hypotheses by measuring whether the rate moves. A single pass after a "fix" proves nothing for a 10%-failure bug.

**"It works on my machine":** enumerate environmental deltas systematically — versions (runtime, deps, OS), env vars, filesystem state, network access, data, locale/timezone, clean vs. dirty build. Reproduce inside the failing environment rather than theorizing from the working one.

**Multi-cause failures:** if the symptom persists after a correct fix, do NOT revert reflexively — you may have fixed one of two bugs. Re-verify the first fix independently, then hunt the second with the fix in place. Two overlapping bugs are why "obvious" fixes mysteriously don't work.

**After a dependency upgrade:** the answer is in the changelog/migration guide between your two versions, not in general reasoning. Get the exact versions and read what changed.

## Loop Detection — the Meta-Skill

Every time a fix doesn't work, increment a mental counter. At **two** failed fixes for the same symptom, stop editing and declare your model of the problem wrong. Return to the hypothesis tree with all accumulated evidence, and explicitly ask: *"What have I been assuming that I never verified?"* That assumption is usually the bug. The strongest debuggers aren't faster at fixing — they're faster at noticing they're stuck.
