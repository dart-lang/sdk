# Providing Highlighting Information

Highlighting information is used by clients to help users identify different
syntactic and semantic regions of their code.

Syntactic highlighting is highlighting that is based completely on the syntax of
the code. For example, editors will often provide unique colors for comments,
string literals, and numeric literals.

Semantic highlighting is highlighting that is based on semantic information. For
example, an editor could highlight references to fields differently than
references to local variables. Editors could also highlight references to
deprecated elements differently.

## Implementation details

Highlighting information is available through a subscription. If the server has
subscribed for highlighting information in some set of files, then the plugin
should send the information in an `analysis.highlights` notification whenever
the information needs to be updated.

When a notification needs to be sent, the method `sendHighlightsNotification`
will be invoked. This method is responsible for sending the notification.

The easiest way to add support for this notification is by adding the classes
`HighlightsMixin` and `DartHighlightsMixin` (from
`package:analyzer_plugin/plugin/highlights_mixin.dart`) to the list of mixins
for your subclass of `ServerPlugin`. This will leave you with one abstract
method that you need to implement: `getHighlightsContributors`. That method is
responsible for returning a list of `HighlightsContributor`s. It is the
highlights contributors that produce the actual highlighting information. (Most
plugins will only need a single highlights contributor.)

To write a highlights contributor, create a class that implements
`HighlightsContributor`. The interface defines a single method named
`computeHighlights`. The method has two arguments: an `HighlightsRequest` that
describes the file for which highlighting information is being requested and an
`HighlightsCollector` through which highlighting information is to be added.

If you mix in the class `DartHighlightsMixin`, then the request will be an
instance of `DartHighlightsRequest`, which also has analysis results.

## Example

Start by creating a class that implements `HighlightsContributor`, then
implement the method `computeHighlights`. This method is typically implemented
by creating a visitor (such as an AstVisitor) that can visit the results of the
analysis (such as a CompilationUnit) and extract the highlighting information
from the analysis result.

For example, your contributor might look something like the following:

```dart
class MyHighlightsContributor implements HighlightsContributor {
  @override
  void computeHighlights(
      HighlightsRequest request, HighlightsCollector collector) {
    if (request is DartHighlightsRequest) {
      HighlightsVisitor visitor = new HighlightsVisitor(collector);
      request.result.unit.accept(visitor);
    }
  }
}

class HighlightsVisitor extends RecursiveAstVisitor {
  final HighlightsCollector collector;

  HighlightsVisitor(this.collector);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // ...
  }
}
```

Given a contributor like the one above, you can implement your plugin similar to
the following:

```dart
class MyPlugin extends ServerPlugin with HighlightsMixin, DartHighlightsMixin {
  // ...

  @override
  List<HighlightsContributor> getHighlightsContributors(String path) {
    return <HighlightsContributor>[new MyHighlightsContributor()];
  }
}
```
