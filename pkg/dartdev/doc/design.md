# Design Principles

The purpose of this document is to capture the design principles that should be
followed when designing new commands or updating existing ones. The goal is to
ensure that the dartdev tool provides a consistent UX.

## Status

This is a work in progress. At the moment we are just capturing the ideas that
are coming out of discussions. They will need to be organized and more fully
documented at some point.

## Command Arguments

### Default Target

If the command cannot have side effects (such as analyze) then the argument for
what to operate on should default to the CWD, but if the command can have side
effects (such as format or fix) then the argument for what to operate on should
be required.
