# Triage Priorities for Dart Migration tool

This document describes the relative priorities for bugs filed under the
`area-migration` tag in GitHub as in
[this search](https://github.com/dart-lang/sdk/issues?q=is%3Aopen+is%3Aissue+label%3Aarea-migration).
While there are always exceptions to any rule, in general try to align our
priorities with these definitions.

To triage bugs, search for `area-migration`
[bugs that are not currently triaged](https://github.com/dart-lang/sdk/issues?q=is%3Aopen+is%3Aissue+label%3Aarea-migration+-label%3AP0+-label%3AP1+-label%3AP2+-label%3AP3+-label%3AP4)
and for each bug, mark priority based on how closely it matches with the below
constraints.

## Migration tool triage priorities

Descriptions here use [terms and definitions](#terms-and-definitions) from the
end of this document.  If your bug doesn't precisely match one of these,
consider how impactful it is compared to examples given here and pick a priority
reflecting that.

### P0

* Crashes that can't be worked around by `--ignore-exceptions`, typical impact or widespread.
* Crashes that can be worked around by `--ignore-exceptions`, widespread.

### P1

* Crashes that can be worked around by `--ignore-exceptions`, typical impact.
* An enhancement required for critical milestones for key users, or that has
  significant evidence gathered indicating a positive impact if implemented.
* A problem that is significantly impairing a key user's ability to migrate
  their code.

### P2

* Crashes, edge case.
* An enhancement with typical impact that doesn't fit the criteria above but
  would still be significantly beneficial to users (i.e. more than just a "would
  be nice" feature).
* A problem with typical impact that doesn't fit the criteria above, but impairs
  users' ability to migrate their code.

### P3

* Crashes, theoretical.
* An enhancement that doesn't fit the criteria above.
* A problem that doesn't fit the criteria above, but impairs users' ability to
  migrate their code.

## Terms and definitions

### Terms describing impact

* "widespread" - Impact endemic throughout the ecosystem, or at least far
  enough that this is impacting multiple key users.
* "typical impact" - Known to impact a key user, or likely to impact a
  significant percentage of all users.  Issues are assumed to have typical
  impact unless we have evidence otherwise.
* "edge cases" - Impacting only small parts of the ecosystem.  For example, one
  package, or one key user with a workaround.  Note this is an edge case from
  the perspective of the ecosystem vs. language definition.  Note that since the
  migration tool is still in an early adoption phase, if a bug has only been
  reported by one user, that's not sufficient evidence that it's an edge case.
  To be considered an edge case, we need to have a concrete reason to suspect
  that the bug is caused by an unusual pattern in the user's source code, or
  unusual user behavior.
* "theoretical" - Something that we think is unlikely to happen in the wild
  and there's no evidence for it happening in the wild.

### Other terms

* "key users" - Flutter, Pub, Fuchsia, Dart, Google3, 1P
