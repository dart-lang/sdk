# The lint lifecycle

Every lint rule implemented in `pkg/linter` has a state that
describes its maturity and whether it's publicly visible.
A lint's current state is set in its implementation, and
its full state history is recorded in `pkg/linter/messages.yaml`.

Before being implemented, a lint also moves through
a proposal process that isn't recorded as a state.

## Before implementation

### Proposed

A lint begins its life as a proposal,
which is pending until accepted by the Dart developer experience team.

### Accepted

After discussion and sufficient agreement within the team,
a proposed lint becomes accepted and is ready for implementation.

A change that lands a new, publicly available, lint should have
a corresponding `CHANGELOG` entry.

## Public states

Lints in these states are publicly available and documented.

### Experimental

Experimental lints are available for public use,
but they are subject to removal or changes without notice.

Reasons a lint might be experimental include the lint:

- Being tentatively introduced.
- Having unknown value.
- Having incomplete semantics.
- Having outstanding but fixable false positives.
- Being known to be temporary.

Experimental lints should aspire to become stable.
An experimental lint is a candidate for the stable state when it has:

- Complete semantics.
- A complete implementation with no known false positives.
- Established long-term value, potentially illustrated by
  a core lint set considering it for inclusion.

### Stable

Stable lints are publicly available,
generally well tested and documented,
and are less likely to be removed or changed without notice.

A stable lint's semantics and implementation are considered complete.
False positives are bugs unless they're known and documented limitations,
and fixing them should be prioritized.
False negatives might be bugs or enhancements,
depending on the lint's semantics.

Stable lints might be included in core rule sets.
A stable lint generally should be deprecated before it's removed,
unless it's no longer relevant or valid in any supported language version.

### Deprecated

Deprecated lints are planned for removal in a future release of the SDK.

Reasons for deprecating a lint include:

- Semantics that don't make sense with
  current language semantics, such as after null safety.
- Stale advice.
- Poor performance.
- Poor developer experience, such as too many false positives.
- Insufficient usage or value across the ecosystem.

Deprecating a lint that's in a common lint set,
such as one in [`package:lints`](https://github.com/dart-lang/lints),
can be impactful, so it should be done with care.

Deprecated lints remain publicly visible and documented so that
users can learn why a lint was deprecated and what to use instead.

A change that deprecates an existing lint should have
a corresponding `CHANGELOG` entry.

### Removed

Removed lints are no longer implemented or supported.

This state is intended for lints that were previously publicly available.
Lints that were only internal or only used for testing
don't need to be moved to the removed state.

In general, removal is preceded by a period of deprecation.
A change that removes a publically available lint should have
a corresponding `CHANGELOG` entry.

## Private states

Lints in these states shouldn't be
offered as completions in user-facing tooling or documented publicly.

### Internal

Internal lints are intended for use within the Dart SDK only.

When removed, internal lints don't need to move to the removed state.
Their code and supporting documentation can be deleted.

### Testing

Testing lints are temporary lints used for internal testing.
Their use isn't limited to the Dart SDK, but
they have no stability guarantees and
aren't intended for public use.

Lints shouldn't stay in the testing state indefinitely.
After testing of the lint is completed,
lints should be removed or graduated to another state.

When removed, testing lints don't need to move to the removed state.
Their code and supporting documentation can be deleted.
