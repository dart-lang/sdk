# Providing Quick Fixes

A quick fix is used by clients to provide a set of possible changes to code that
are based on diagnostics reported against the code. Quick fixes are intended to
help users resolve the issue being reported.

If your plugin generates any diagnostics then you should consider providing
support for automatically fixing those diagnostics. There is often more than one
potential way of fixing a given problem, so it is possible for your plugin to
provide multiple fixes for a single problem.

For example, if an undefined identifier is used in the code, you might return
a fix to create an appropriate definition for the identifier. If there is a
similar identifier that is already defined, you might also return a second fix
to replace the undefined identifier with the defined identifier.

The latter example illustrates that fixes can be conditionally returned. You
will produce a better UX if only those fixes that actually make sense in the
given context are returned. If a lot of work is required to determine which
fixes make sense, it is possible to improve performance by generating different
diagnostics for the same issue, depending on the context in which the issue
occurs.

In addition, fixes have a priority associated with them. The priority allows the
client to display the fixes that are most likely to be of use closer to the top
of the list when there are multiple fixes available.

## Implementation details

When appropriate, the analysis server will send your plugin an `edit.getFixes`
request. The request includes the `file` and `offset` associated with the
diagnostics for which fixes should be generated. Fixes are typically produced
for all of the diagnostics on a given line of code. Your plugin should only
return fixes associated with the errors that it produced earlier.

When an `edit.getFixes` request is received, the method `handleEditGetFixes`
will be invoked. This method is responsible for returning a response that
contains the available fixes.

The easiest way to implement this method is by adding the classes `FixesMixin`
and `DartFixesMixin` (from `package:analyzer_plugin/plugin/fix_mixin.dart`) to
the list of mixins for your subclass of `ServerPlugin`. This will leave you with
one abstract method that you need to implement: `getFixContributors`. That
method is responsible for returning a list of `FixContributor`s. It is the fix
contributors that produce the actual fixes. (Most plugins will only need a
single fix contributor.)

To write a fix contributor, create a class that implements `FixContributor`. The
interface defines a single method named `computeFixes`. The method has two
arguments: a `FixesRequest` that describes the errors that should be fixed and a
`FixCollector` through which fixes are to be added.

If you mix in the class `DartFixesMixin`, then the list of errors available
through the request object will only include the errors for which fixes should
be returned and the request will be an instance of `DartFixesRequest`, which
also has analysis results.

The class `FixContributorMixin` defines a simple implementation of this method
that captures the two arguments in fields, iterates through the errors, and
invokes a method named `computeFixesForError` for each of the errors for which
fixes are to be computed.

## Example

Start by creating a class that implements `FixContributor` and that mixes in the
class `FixContributorMixin`, then implement the method `computeFixesForError`.
This method is typically implemented by a series of `if` statements that test
the error code and invoke individual methods that compute the actual fixes to be
proposed. (In addition to keeping the method `computeFixesForError` shorter,
this also allows some fixes to be used for multiple error codes.)

To learn about the support available for creating the edits, see
[Creating Edits][creatingEdits].

For example, your contributor might look something like the following:

```dart
class MyFixContributor extends Object
    with FixContributorMixin
    implements FixContributor {
  static FixKind defineComponent =
      new FixKind('defineComponent', 100, "Define a component named {0}");

  AnalysisSession get session => request.result.session;

  @override
  void computeFixesForError(AnalysisError error) {
    ErrorCode code = error.errorCode;
    if (code == MyErrorCode.undefinedComponent) {
      _defineComponent(error);
      _useExistingComponent(error);
    }
  }

  void _defineComponent(AnalysisError error) {
    // TODO Get the name from the source code.
    String componentName = null;
    ChangeBuilder builder = new DartChangeBuilder(session);
    // TODO Build the edit to insert the definition of the component.
    addFix(error, defineComponent, builder, args: [componentName]);
  }

  void _useExistingComponent(AnalysisError error) {
    // ...
  }
}
```

Given a contributor like the one above, you can implement your plugin similar to
the following:

```dart
class MyPlugin extends ServerPlugin with FixesMixin, DartFixesMixin {
  // ...

  @override
  List<FixContributor> getFixContributors(
      AnalysisDriverGeneric driver) {
    return <FixContributor>[new MyFixContributor()];
  }
}
```

[creatingEdits]: creating_edits.md
