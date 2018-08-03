# Providing Code Completions

A code completion is used by clients to provide a set of possible completions to
partially entered code. Completions are intended to address two use cases: to
help users enter code with less effort and to help users discover the behavior
of an object.

For example, if the user has typed `o.toSt` and then requested completions, one
suggestion might be `toString`.

That said, the completion suggestions that your plugin returns should include
all of the options that would be valid if the partial identifier did not exist.
The reason is that most clients are implemented such that they send a single
request for completions when the dialog with the user begins and cannot send any
subsequent requests. If the user presses the backspace key during the dialog the
client needs to have already received the expanded list of options that now
match the prefix (or all options if the prefix has completely been deleted).
Clients will filter the list of suggestions displayed as appropriate.

Hence, in the example above, plugins should return suggestions as if the user
had requested completions after typing `o.`;

## Implementation details

When appropriate, the analysis server will send your plugin a
`completion.getSuggestions` request. The request includes the `file` and
`offset` at which completions are being requested.

When a `completion.getSuggestions` request is received, the method
`handleCompletionGetSuggestions` will be invoked. This method is responsible for
returning a response that contains the available suggestions.

The easiest way to implement this method is by adding the classes
`CompletionMixin` and `DartCompletionMixin` (from
`package:analyzer_plugin/plugin/completion_mixin.dart`) to the list of mixins
for your subclass of `ServerPlugin`. This will leave you with one abstract
method that you need to implement: `getCompletionContributors`. That method is
responsible for returning a list of `CompletionContributor`s. It is the
completion contributors that produce the actual completion suggestions. (Most
plugins will only need a single completion contributor.)

To write a completion contributor, create a class that implements
`CompletionContributor`. The interface defines a single method named
`computeSuggestions`. The method has two arguments: a `CompletionRequest` that
describes the where completions are being requested and a `CompletionCollector`
through which suggestions are to be added.

If you mix in the class `DartCompletionMixin`, then the request will be an
instance of `DartCompletionRequest`, which also has analysis results.

## Example

Start by creating a class that implements `CompletionContributor`, then
implement the method `computeSuggestions`. Your contributor should invoke the
method `checkAborted`, defined on the `CompletionRequest` object, before
starting any slow work. This allows the computation of completion suggestions
to be preempted if the client no longer needs the results.

For example, your contributor might look something like the following:

```dart
class MyCompletionContributor implements CompletionContributor {
  @override
  Future<Null> computeSuggestions(DartCompletionRequest request,
      CompletionCollector collector) async {
    // ...
  }
}
```

Given a contributor like the one above, you can implement your plugin similar to
the following:

```dart
class MyPlugin extends ServerPlugin with CompletionMixin, DartCompletionMixin {
  // ...

  @override
  List<CompletionContributor> getCompletionContributors(
      AnalysisDriverGeneric driver) {
    return <CompletionContributor>[new MyCompletionContributor()];
  }
}
```
