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
invoking the method `computeFinalizedCandidateSuggestions`.

### Completion passes

The completion manager computes suggestions in two "passes".

- The `InScopeCompletionPass` computes suggestions for every appropriate element
  whose name is visible in the name scope surrounding the completion location.

- The `NotImportedCompletionPass` computes suggestions for elements that are not
  yet visible in the name scope surrounding the completion location. This pass
  is skipped if there isn't time left in the `budget` or if there are already
  enough suggestions that the not-yet-imported elements wouldn't be sent anyway.

### The collector

Both passes add `CandidateSuggestion`s to a `SuggestionCollector`. The collector
keeps a list of candidates and uses an insertion sort to keep the list sorted.
The sorting is done based on how well the suggestion matches the completion
prefix (as computed by the `FuzzyMatcher`).

For performance reasons, there is a limit to the number of suggestions that are
passed back to the client. When there are more candidates in the list than what
will be sent back, then any candidates whose match score is less than the score
of any candidates within the window will be dropped from the list.

### Ranking

After the list of candidates has been computed, the candidates are ranked by the
`RelevanceComputer`. They are then re-sorted based on the relevance and
truncated to the maximum number of suggestions to be returned.

The relevance score is computed as follows. First, the `FeatureComputer` is used
to measure certain features related to both the completion location and the
suggestion. The features include such things as whether the type of the
suggestion matches the context type, or how far from the completion location a
local variable declaration is. Each feature is represented as a `double` between
`-1.0` and `1.0` inclusive. The feature values are combined using a weighted
average and then adjusted to be between `0` and `1000` inclusive.

The set of features used are selected based on a statistical analysis of
representative Dart code. It is easy to find specific cases where the existing
ranking algorithm does a poor job, but the requirement is that the ranking
algorithm must be optimized across all use cases, not just one use case. This
sometimes results in relevance scores that seem counter-intuitive. When that
happens, one possible path to explore is to add a new feature to the mix.

Changes to either the set of features or the computation of a specific feature
should only be done if a statistical analysis indicates that the change will
produce a better overall ranking (as measured by the MRR of the suggestion
compared to the actual selection). The tool in
`analysis_server/tool/code_completion/completion_metrics.dart` can be used to
compare the quality of one or more experiments compared to the current
implementation.

## Maintaining and improving

The easiest way to fix bugs or add support for new features is to start by
writing a test in the directory `test/services/completion/dart/location`. These
tests are grouped based on the location in the grammar at which completion is
being requested.

When you have a test that's failing, add a breakpoint to
`InScopeCompletionPass.computeSuggestions`. When the debugger stops at the
breakpoint, hover over `_completionNode` to see what kind of node will be
visited. Add a breakpoint in the corresponding visit method and resume
execution. (If the visit method doesn't already exist, then add it and restart
the debugger).

## New language features

If a new language feature is being introduced that adds new syntax, then code
completion support will need to be updated.

If the changes are limited to updating an existing node then you should be able
to use the method above to update the corresponding visit method. If the changes
required the addition of some new subclasses of `AstNode`, then you'll likely
need to add a new visit method for the added nodes.

If the changes introduce a new kind of element then you might need to add a new
subclass of `CandidateSuggestion` and update the `DeclarationHelper` to produce
the suggestion under the appropriate conditions.

