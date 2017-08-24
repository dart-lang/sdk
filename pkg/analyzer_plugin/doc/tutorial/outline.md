# Providing Outlines

Outline information is used by clients to allow users to see the structure of
their code.

## Implementation details

Outline information is available through a subscription. If the server has
subscribed for outline information in some set of files, then the plugin should
send the information in an `analysis.outline` notification whenever the
information needs to be updated.

When a notification needs to be sent, the method`sendOutlineNotification` will
be invoked. This method is responsible for sending the notification.

The easiest way to add support for this notification is by adding the classes
`OutlineMixin` and `DartOutlineMixin` (from
`package:analyzer_plugin/plugin/outline_mixin.dart`) to the list of mixins
for your subclass of `ServerPlugin`. This will leave you with one abstract
method that you need to implement: `getOutlineContributors`. That method is
responsible for returning a list of `OutlineContributor`s. It is the outline
contributors that produce the actual outline information. (Most plugins will
only need a single outline contributor.)

To write an outline contributor, create a class that implements
`OutlineContributor`. The interface defines a single method named
`computeOutline`. The method has two arguments: an `OutlineRequest` that
describes the file for which outline information is being requested and an
`OutlineCollector` through which outline information is to be added.

If you mix in the class `DartOutlineMixin`, then the request will be an instance
of `DartOutlineRequest`, which also has analysis results.

## Example

Start by creating a class that implements `OutlineContributor`, then
implement the method `computeOutline`. This method is typically implemented
by creating a visitor (such as an AstVisitor) that can visit the results of the
analysis (such as a CompilationUnit) and extract the outline information from
the analysis result.

For example, your contributor might look something like the following:

```dart
class MyOutlineContributor implements OutlineContributor {
  @override
  void computeOutline(
      OutlineRequest request, OutlineCollector collector) {
    if (request is DartOutlineRequest) {
      OutlineVisitor visitor = new OutlineVisitor(collector);
      request.result.unit.accept(visitor);
    }
  }
}

class OutlineVisitor extends RecursiveAstVisitor {
  final OutlineCollector collector;

  OutlineVisitor(this.collector);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // ...
  }
}
```

Given a contributor like the one above, you can implement your plugin similar to
the following:

```dart
class MyPlugin extends ServerPlugin with OutlineMixin, DartOutlineMixin {
  // ...

  @override
  List<OutlineContributor> getOutlineContributors(String path) {
    return <OutlineContributor>[new MyOutlineContributor()];
  }
}
```
