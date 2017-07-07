# Providing Quick Assists

A quick assist is used by clients to provide a set of possible changes to code
that are based on the structure of the code. Quick assists are intended to help
users safely make local changes to code when those changes do not require any
user interaction. (Modifications that require interaction with users or that
touch multiple files are usually implemented as refactorings.)

For example, if the user has a function whose body consists of a single return
statement in a block, server will provide an assist to convert the function body
from a block to an expression (`=>`).

Assists have a priority associated with them. The priority allows the client to
display the assists that are most likely to be of use closer to the top of the
list when there are multiple assists available.

## Implementation details

When appropriate, the analysis server will send your plugin an `edit.getAssists`
request. The request includes the `file`, `offset` and `length` associated with
the selected region of code.

When an `edit.getAssists` request is received, the method `handleEditGetAssists`
will be invoked. This method is responsible for returning a response that
contains the available assists.

The easiest way to implement this method is by adding the classes `AssistsMixin`
and `DartAssistsMixin` (from `package:analyzer_plugin/plugin/assist_mixin.dart`)
to the list of mixins for your subclass of `ServerPlugin`. This will leave you
with one abstract method that you need to implement: `getAssistContributors`.
That method is responsible for returning a list of `AssistContributor`s. It is
the assist contributors that produce the actual assists. (Most plugins will only
need a single assist contributor.)

To write an assist contributor, create a class that implements
`AssistContributor`. The interface defines a single method named
`computeAssists`. The method has two arguments: an `AssistRequest` that
describes the location at which assists were requested and an `AssistCollector`
through which assists are to be added.

The class `AssistContributorMixin` defines a support method that makes it easier
to implement `computeAssists`.

## Example

Start by creating a class that implements `AssistContributor` and that mixes in
the class `AssistContributorMixin`, then implement the method `computeAssists`.
This method is typically implemented as a sequence of invocations of methods
that check to see whether a given assist is appropriate in the context of the
request 

To learn about the support available for creating the edits, see
[Creating Edits][creatingEdits].

For example, your contributor might look something like the following:

```dart
class MyAssistContributor extends Object
    with AssistContributorMixin
    implements AssistContributor {
  static AssistKind wrapInIf =
      new AssistKind('wrapInIf', 100, "Wrap in an 'if' statement");

  DartAssistRequest request;

  AssistCollector collector;

  AnalysisSession get session => request.result.session;

  @override
  void computeAssists(DartAssistRequest request, AssistCollector collector) {
    this.request = request;
    this.collector = collector;
    _wrapInIf();
    _wrapInWhile();
    // ...
  }

  void _wrapInIf() {
    ChangeBuilder builder = new DartChangeBuilder(session);
    // TODO Build the edit to wrap the selection in a 'if' statement.
    addAssist(wrapInIf, builder);
  }

  void _wrapInWhile() {
    // ...
  }
}
```

Given a contributor like the one above, you can implement your plugin similar to
the following:

```dart
class MyPlugin extends ServerPlugin with AssistsMixin, DartAssistsMixin {
  // ...

  @override
  List<AssistContributor> getAssistContributors(
      covariant AnalysisDriver driver) {
    return <AssistContributor>[new MyAssistContributor()];
  }
}
```

[creatingEdits]: creating_edits.md
