# Providing Navigation

Navigation information is used by clients to allow users to navigate to the
location at which an identifier is defined.

## Implementation details

Navigation information can be requested both by an `analysis.getNavigation`
request and by a subscription. If the server has subscribed for navigation
information in some set of files, the the plugin should send the information in
an `analysis.navigation` notification whenever the information needs to be
updated.

When an `analysis.getNavigation` request is received, the method
`handleAnalysisGetNavigation` will be invoked. This method is responsible for
returning a response that contains the available navigation information.

The easiest way to implement the method `handleAnalysisGetNavigation` is by
adding the classes `NavigationMixin` and `DartNavigationMixin` (from
`package:analyzer_plugin/plugin/navigation_mixin.dart`) to the list of mixins
for your subclass of `ServerPlugin`. This will leave you with one abstract
method that you need to implement: `getNavigationContributors`. That method is
responsible for returning a list of `NavigationContributor`s. It is the
navigation contributors that produce the actual navigation information. (Most
plugins will only need a single navigation contributor.)

To write a navigation contributor, create a class that implements
`NavigationContributor`. The interface defines a single method named
`computeNavigation`. The method has two arguments: a `NavigationRequest` that
describes the region of the file for which navigation is being requested and a
`NavigationCollector` through which navigation information is to be added.

If you mix in the class `DartNavigationMixin`, then the request will be an
instance of `DartNavigationRequest`, which also has analysis results.

## Example

Start by creating a class that implements `NavigationContributor`, then
implement the method `computeNavigation`. This method is typically implemented
by creating a visitor (such as an AstVisitor) that can visit the results of the
analysis (such as a CompilationUnit) and extract the navigation information from
the analysis result.

For example, your contributor might look something like the following:

```dart
class MyNavigationContributor implements NavigationContributor {
  @override
  void computeNavigation(
      NavigationRequest request, NavigationCollector collector) {
    if (request is DartNavigationRequest) {
      NavigationVisitor visitor = new NavigationVisitor(collector);
      request.result.unit.accept(visitor);
    }
  }
}

class NavigationVisitor extends RecursiveAstVisitor {
  final NavigationCollector collector;

  NavigationVisitor(this.collector);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // ...
  }
}
```

Given a contributor like the one above, you can implement your plugin similar to
the following:

```dart
class MyPlugin extends ServerPlugin with NavigationMixin, DartNavigationMixin {
  // ...

  @override
  List<NavigationContributor> getNavigationContributors(String path) {
    return <NavigationContributor>[new MyNavigationContributor()];
  }
}
```
