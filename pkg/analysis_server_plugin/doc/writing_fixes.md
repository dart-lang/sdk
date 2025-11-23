# Writing fixes

This package gives analyzer plugin authors the ability to write "quick fixes"
targeted at specific diagnostics, that can fix source code from a developer's
IDE. This document describes briefly how to write such a fix, and how to
register it in an analyzer plugin.

## The analysis rule

A quick fix must be associated with a diagnostic in order to be presented to a
developer in their IDE. (There is a separate feature calls "assists" which do
not need to be associated with diagnostics; see the
[writing assists][] doc.)

For this guide, we will be using the "MyRule" rule from the [writing rules][]
guide.


## The ResolvedCorrectionProducer class

A quick fix is specified by subclassing the ResolvedCorrectionProducer class.
Here is our example:

```dart
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/dart/dart_fix_kind_priority.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveAwait extends ResolvedCorrectionProducer {
  static const _removeAwaitKind = FixKind(
      'dart.fix.removeAwait',
      DartFixKindPriority.standard,
      "Remove the 'await' keyword");

  RemoveAwait({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _removeAwaitKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var awaitExpression = node;
    if (awaitExpression is AwaitExpression) {
      var awaitToken = awaitExpression.awaitKeyword;
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.startStart(awaitToken, awaitToken.next!));
      });
    }
  }
}
```

Let's look at each declaration individually:

* `class RemoveAwait` - A quick fix is a class that extends
  `ResolvedCorrectionProducer`. The name of the base class indicates that an
  instance of this class can produce "corrections" (a set of edits) for a
  resolved library.
* `static const _removeAwaitKind = FixKind(...)` - Each quick fix must have an
  associated `FixKind` which has a unique `id`
  (`'dart.fix.removeAwait'`), a priority (`DartFixKindPriority.standard` is a
  fine default), and a message which is displayed in the IDE
  (`"Remove the 'await' keyword"`).
* `RemoveAwait({required super.context});` - A standard constructor that accepts
  a `CorrectionProducerContext` and passes it up to the super-constructor.
* `CorrectionApplicability get applicability =>` - the applicability field
  describes how widely a fix can be applied safely and sensibly. Currently,
  fixes registered in plugins cannot be applied in bulk, so only
  `CorrectionApplicability.singleLocation` and
  `CorrectionApplicability.acrossSingleFile` should be used.
* `FixKind get fixKind => _removeAwaitKind;` - each instance of this class can
  refer to the static field for it's `fixKind`.
* `Future<void> compute(ChangeBuilder builder)` - This method is called when an
  associated diagnostic (lint or warning) has been reported, and we want a
  possible correction from this correction producer. This is the code that
  looks at the error node (the `node` field) and surrounding code and
  determines what correction to offer, if any.

  * `await builder.addDartFileEdit(...)` - Once we have determined that we want
    to offer a fix, we call this method, and specify code deletions,
    insertions, and/or replacements inside the callback function. If there are
    cases where this correction producer will not offer any quick fixes (such
    as the source code having certain properties), then those cases should be
    checked so that we don't call this method in such cases.
  * `builder.addDeletion(...)` - For this fix (removing an `await` keyword), we
    can use `addDeletion` to specify a range of source code text to delete. The
    `DartFileEditBuilder` class has many utilities for adding various edits.

  Writing a quick fix can be non-trivial, even for changes which are
  conceptually simple. It may be helpful to see examples that are similar to a
  desired fix. See the [fixes that are offered by Dart Analysis
  Server][existing-fixes] for hundreds of examples.

Instances of the correction producer class are short-lived, and they can contain
state related to the specific reported diagnostic and code-under-analysis.
Indeed, the `CorrectionProducerContext`, which is passed into the constructor,
and available as a field in the super-class, contains information specific to
the code-under-analysis and the diagnostic.

## Registering a quick fix

In order for a quick fix to be used in an analyzer plugin, it must be
registered. Register the quick fix's constructor inside a plugin's
`register` method:

```dart
import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

final plugin = SimplePlugin();

class SimplePlugin extends Plugin {
  @override
  String get name => 'Simple plugin';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(MyRule());
    registry.registerFixForRule(MyRule.code, RemoveAwait.new);
  }
}
```

Here, the warning (`MyRule.code`) is associated with the fix (the constructor
for the`RemoveAwait` class), in `registry.registerFixForRule`. Instances of
correction producers contain state related to the specific reported diagnostic
and the code-under-analysis, which is why the constructor is given here,
instead of a long-lived instance.

See [writing a plugin][] for information about the `Plugin` class.

[writing rules]: https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_rules.md
[writing assists]: https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_assists.md
[existing-fixes]: https://github.com/dart-lang/sdk/tree/main/pkg/analysis_server/lib/src/services/correction/dart
[writing a plugin]: https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_rules.md
