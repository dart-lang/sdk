# Providing Folding Information

Folding information is used by clients to allow users to collapse portions of
the code that are not interesting for their current task.

## Implementation details

Folding information is available through a subscription. If the server has
subscribed for folding information in some set of files, then the plugin
should send the information in an `analysis.folding` notification whenever
the information needs to be updated.

When a notification needs to be sent, the method `sendFoldingNotification`
will be invoked. This method is responsible for sending the notification.

The easiest way to add support for this notification is by adding the classes
`FoldingMixin` and `DartFoldingMixin` (from
`package:analyzer_plugin/plugin/folding_mixin.dart`) to the list of mixins
for your subclass of `ServerPlugin`. This will leave you with one abstract
method that you need to implement: `getFoldingContributors`. That method is
responsible for returning a list of `FoldingContributor`s. It is the folding
contributors that produce the actual folding regions. (Most plugins will only
need a single folding contributor.)

To write a folding contributor, create a class that implements
`FoldingContributor`. The interface defines a single method named
`computeFolding`. The method has two arguments: an `FoldingRequest` that
describes the file for which folding information is being requested and an
`FoldingCollector` through which folding regions are to be added.

If you mix in the class `DartFoldingMixin`, then the request will be an
instance of `DartFoldingRequest`, which also has analysis results.

## Example

Start by creating a class that implements `FoldingContributor`, then implement
the method `computeFolding`. This method is typically implemented by creating a
visitor (such as an AstVisitor) that can visit the results of the analysis (such
as a CompilationUnit) and extract the folding regions from the analysis result.

For example, your contributor might look something like the following:

```dart
class MyFoldingContributor implements FoldingContributor {
  @override
  void computeFolding(
      FoldingRequest request, FoldingCollector collector) {
    if (request is DartFoldingRequest) {
      FoldingVisitor visitor = new FoldingVisitor(collector);
      request.result.unit.accept(visitor);
    }
  }
}

class FoldingVisitor extends RecursiveAstVisitor {
  final FoldingCollector collector;

  FoldingVisitor(this.collector);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // ...
  }
}
```

Given a contributor like the one above, you can implement your plugin similar to
the following:

```dart
class MyPlugin extends ServerPlugin with FoldingMixin, DartFoldingMixin {
  // ...

  @override
  List<FoldingContributor> getFoldingContributors(String path) {
    return <FoldingContributor>[new MyFoldingContributor()];
  }
}
```
