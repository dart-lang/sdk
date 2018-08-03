# Providing Kythe Data

**Note:** Kythe support is experimental and might be removed or changed without
notice.

[Kythe][kythe] is, in their own words, "A pluggable, (mostly) language-agnostic
ecosystem for building tools that work with code." The analysis server can be
used to produce the data that should be sent to Kythe. In other words, the
analysis server is (almost) a Kythe indexer. (The data needs to be converted
from a Json representation to a protobuf format before being sent to Kythe.)

## Implementation details

When appropriate, the analysis server will send your plugin a
`kythe.getKytheEntries` request. The request includes the `file` for which data
should be generated. The data consists of a list of `KytheEntry`s.

When a `kythe.getKytheEntries` request is received, the method
`handleKytheGetKytheEntries` will be invoked. This method is responsible for
returning a response that contains the entries to be sent to Kythe.

The easiest way to implement this method is by adding the classes `EntryMixin`
and `DartEntryMixin` (from `package:analyzer_plugin/plugin/kythe_mixin.dart`) to
the list of mixins for your subclass of `ServerPlugin`. This will leave you with
one abstract method that you need to implement: `getEntryContributors`. That
method is responsible for returning a list of `EntryContributor`s. It is the
entry contributors that produce the actual entries. (Most plugins will only need
a single entry contributor.)

To write an entry contributor, create a class that implements
`EntryContributor`. The interface defines a single method named
`computeEntries`. The method has two arguments: an `EntryRequest` that describes
the file to be indexed and an `EntryCollector` through which entries are to be
added.

If you mix in the class `DartEntryMixin`, then the request will be an instance
of `DartEntryRequest`, which also has analysis results.

## Example

Start by creating a class that implements `EntryContributor`, then implement the
method `computeEntries`. This method is typically implemented by creating a
visitor (such as an AstVisitor) that can visit the results of the analysis (such
as a CompilationUnit) and extract the navigation information from the analysis
result.

For example, your contributor might look something like the following:

```dart
class MyEntryContributor implements EntryContributor {
  @override
  void computeEntries(EntryRequest request, EntryCollector collector) {
    if (request is DartEntryRequest) {
      EntryVisitor visitor = new EntryVisitor(collector);
      request.result.unit.accept(visitor);
    }
  }
}

class EntryVisitor extends RecursiveAstVisitor {
  final EntryCollector collector;

  EntryVisitor(this.collector);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // ...
  }
}
```

Given a contributor like the one above, you can implement your plugin similar to
the following:

```dart
class MyPlugin extends ServerPlugin with EntryMixin, DartEntryMixin {
  // ...

  @override
  List<EntryContributor> getEntryContributors(String path) {
    return <EntryContributor>[new MyEntryContributor()];
  }
}
```

[kythe]: http://kythe.io/
