# Code completion

This document describes how code completion is implemented and how to fix bugs
and extend it.

## Basic operation

Code completion begins with the receipt of either a `completion.getSuggestions2`
request (from the legacy protocol) or a `textDocument/completion` request (from
LSP). When the request is received the appropriate handler is invoked. The
handler will compute a list of completion suggestions and will then translate
the suggestions into the form required by the protocol.

Code completion is supported in `.dart` files as well as in the `pubspec.yaml`,
`analysis_options.yaml`, and `fix_data.yaml` files.

Dart completion suggestions are computed using the `DartCompletionManager` by
invoking either the method `computeSuggestions` (for the legacy protocol) or
`computeFinalizedCandidateSuggestions`. (The legacy protocol will be changed to
use `computeFinalizedCandidateSuggestions` in the near future.)

The completion manager computes suggestions in two "passes".

- The `InScopeCompletionPass` computes suggestions for every appropriate element
  whose name is visible in the name scope surrounding the completion location.

- The `NotImportedCompletionPass` computes suggestions for elements that are not
  yet visible in the name scope surrounding the completion location. This pass
  is skipped if there isn't time left in the `budget` or if there are already
  enough suggestions that the not-yet-imported elements wouldn't be sent anyway.

## Maintaining and improving

The easiest way to fix bugs or add support for new features is to start by
writing a test in the directory `test/services/completion/dart/location`. These
tests are grouped based on the location in the grammar at which completion is
being requested.

When you have a test that's failing, add a breakpoint to
`InScopeCompletionPass.computeSuggestions`. When the debugger stops at the
breakpoint, hover over `_completionNode` to see what kind of node will be
visited. Add a breakpoint in the corresponding visit method and resume
execution. (If the visit method if it doesn't already exist, then add it and
restart the debugger).

## New language features

If a new language feature is being introduced that adds new syntax, then code
completion support will need to be updated. If the changes are limited to
updating an existing node then you should be able to use the method above to
update the corresponding visit method. If the changes required the addition of
some new subclasses of `AstNode`, then you'll likely need to add a new visit
method for the added nodes.
