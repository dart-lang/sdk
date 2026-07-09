# Code completion

    LSP:    [textDocument/completion][] request
    Legacy: `completion.getSuggestions2` request

Code completion supports two significant functions. The first is to make it
faster and easier for the user to enter code by predicting the code they might
be trying to type and suggesting the possibilities. The second is to help the
user understand the API of the objects referenced in their code.

The design of the feature is largely dictated by the need to support both of
these functions as well as by the protocol.

The quality of the completion suggestions is dependent on two factors:

- The choice of identifiers being suggested
- The order in which the suggestions are presented

## The process

TBD (how the protocol works)

## Choosing what to suggest

This section describes the choices we make when deciding what to suggest.

### What we suggest

We generally suggest every identifier that is in scope and every keyword that is
valid at the point where completion was requested.

As a result, we often suggest identifiers that are not particularly likely to be
the one the user is trying to type. Several ideas have been proposed for ways to
reduce the number of suggestions. The most common proposal is to only suggest
identifiers that are valid initial tokens for the static type of the expression
being completed. That's an attractive idea, but we don't have an efficient way
to determine the set of types that could be returned by an expression starting
with a given token, so the proposal isn't practical.

If time allows, we also suggest identifiers that are not in scope but could be
added to the scope by adding an import.

### What we don't suggest

There are a couple of things that we don't suggest. Each is discussed in a
section below.

#### Operators

We generally don't suggest operators for the following reasons:

- Most operators are a single character, so it doesn't really save time to find
and insert them via completion.

- There's no automatic trigger for completions where an operator would be valid,
and we suspect that most users don't think to request completion when they want
an operator (in part because doing so wouldn't buy them much, and in part
because users are probably trained to expect completion to be triggered
automatically).

Not suggesting operators does impact the ability of users to find operators
defined in the API, but most of the operators should only be included in an API
when it's already obvious that they should exist.

#### Multi-token completions

There are a couple of exceptions, but we generally don't suggest multi-token
completions. We prefer to leave that to AI.

If we're going to suggest a name that is imported using a prefix, then we will
include the prefix and period in the completion.

If we're going to suggest a static member, then we will include the name of the
class and the period in the completion.

### Filtering

As the completion suggestions are computed, they are filtered based on the
prefix of the identifier being completed that has already been typed. The
filtering is done in the analysis server in order to reduce the number of
suggestions sent to the client, and it is done on the client when the client has
a complete set of suggestions.

### Phases

The process of generating completion suggestions is divided into two phases. The
first phase computes the identifiers that are in scope and the keywords. The
second phase computes identifiers that are not in scope but could be added to
the scope by adding an import.

The primary reason for having two phases is to allow the completion engine to
more easily return earlier if it's necessary to do so in order to meet the
response time goal.

## Ordering the suggestions

The goal of ordering the suggestions is to move the suggestion for the thing the
user is trying to type to the top of the list. Of course, there's no way to know
what the user is trying to type, but we can use some heuristics to improve the
quality of the ordering.

### An important limitation

There is one significant limitation that we face: clients often re-order the
suggestions returned by the server before displaying them to the user. That
re-ordering is often only partial, so we still make an effort to optimize the
order of the suggestions, but there's a limit to the amount of value we can
bring in some cases.

### The relevance score

The order of suggestions is based on a _relevance_ score, which is computed for
each suggestion. The relevance score is computed as a weighted average of
several _feature_ scores. The features are intended to capture the most
important factors that influence the user's choice of suggestion. The use of
these features is designed to make the ordering more comprehensible (to us) and
maintainable by making it more deterministic.

The set of features used for a given suggestion is dependent on the kind of
suggestion. For example, one of the features is only used for local variables.

The feature scores are combined by the `[RelevanceComputer][]`.

### The features

While the features themselves are heuristic in nature, the set of features that
are used isn't. The features are evaluated independently to determine whether
their inclusion improves the ranking of the suggestions. This evaluation is done
during the development of a new feature, not in the deployed server. The
evaluation is done using the [Completion Metrics tool][].

The feature scores are computed by the `[FeatureComputer][]`.

[textDocument/completion]: https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_completion
[FeatureComputer]: https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/lib/src/services/completion/dart/feature_computer.dart#L131
[RelevanceComputer]: https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/lib/src/services/completion/dart/relevance_computer.dart#L18
[Completion Metrics tool]: https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/tool/code_completion/completion_metrics.dart