# Providing Occurrences Information

Occurrences information is used by clients to help users identify all of the
references to a single program element, such as a class, field, or local
variable, within a single file.

## Implementation details

Occurrences information is available through a subscription. If the server has
subscribed for occurrences information in some set of files, then the plugin
should send the information in an `analysis.occurrences` notification whenever
the information needs to be updated.

When a notification needs to be sent, the method `sendOccurrencesNotification`
will be invoked. This method is responsible for sending the notification.

The easiest way to add support for this notification is by adding the classes
`OccurrencesMixin` and `DartOccurrencesMixin` (from
`package:analyzer_plugin/plugin/occurrences_mixin.dart`) to the list of mixins
for your subclass of `ServerPlugin`. This will leave you with one abstract
method that you need to implement: `getOccurrencesContributors`. That method is
responsible for returning a list of `OccurrencesContributor`s. It is the
occurrences contributors that produce the actual occurrences information. (Most
plugins will only need a single occurrences contributor.)

To write an occurrences contributor, create a class that implements
`OccurrencesContributor`. The interface defines a single method named
`computeOccurrences`. The method has two arguments: an `OccurrencesRequest` that
describes the file for which occurrences information is being requested and an
`OccurrencesCollector` through which occurrences information is to be added.

If you mix in the class `DartOccurrencesMixin`, then the request will be an
instance of `DartOccurrencesRequest`, which also has analysis results.

## Example

Start by creating a class that implements `OccurrencesContributor`, then
implement the method `computeOccurrences`. This method is typically implemented
by creating a visitor (such as an AstVisitor) that can visit the results of the
analysis (such as a CompilationUnit) and extract the occurrences information
from the analysis result.

For example, your contributor might look something like the following:

```dart
class MyOccurrencesContributor implements OccurrencesContributor {
  @override
  void computeOccurrences(
      OccurrencesRequest request, OccurrencesCollector collector) {
    if (request is DartOccurrencesRequest) {
      OccurrencesVisitor visitor = new OccurrencesVisitor(collector);
      request.result.unit.accept(visitor);
    }
  }
}

class OccurrencesVisitor extends RecursiveAstVisitor {
  final OccurrencesCollector collector;

  OccurrencesVisitor(this.collector);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // ...
  }
}
```

Given a contributor like the one above, you can implement your plugin similar to
the following:

```dart
class MyPlugin extends ServerPlugin with OccurrencesMixin, DartOccurrencesMixin {
  // ...

  @override
  List<OccurrencesContributor> getOccurrencesContributors(String path) {
    return <OccurrencesContributor>[new MyOccurrencesContributor()];
  }
}
```
