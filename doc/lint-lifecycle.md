# The Life of a Lint

## Lint States

### Proposed

A lint begins its life as a **proposal** which is _pending_ until _accepted_.

### Accepted

After discussion and sufficient agreement within the team, a proposed lint becomes **accepted**.

An accepted lint is ready for implementation.

### Experimental

Lints can be marked experimental. 

Reasons a lint might be marked experimental include a lint

* being tentatively introduced
* having unknown value
* having incomplete semantics
* having outstanding (fixable) false positives or
* that might be known to be temporary.

### Stable

Stable lints are lints whose semantics and implementation are considered complete. False
positives (that are not known, accepted and documentted limitations of lint semantics) are
considered bugs and fixing them should be prioritized. False negatives may be bugs or
enhancements (depending on semantics).

### Deprecated

Deprecated lints are lints that we plan to remove.

Reasons for deprecation include:

* semantics that don't make sense with current language semantics (e.g., null-safety)
* stale advice
* poor performance or
* poor user experience (e.g., too many false positives).

### Removed

Lints we no longer support are removed.

In general removal is preceded by a period of deprecation.

## State Transitions

### Deprecation

Implemented lints can be deprecated.

Deprecating lints that are in common lint sets (e.g., in [package:lints](https://github.com/dart-lang/lints)
can be impactful so should be done with care.

### Marking Stable

Experimental lints should aspire to be stable. An experimental lint is a candidate for stable when it has

* complete semantics
* complete implementation (with no false-positives)
* established long-term value (e.g., inclusion in a recommended lint set)
