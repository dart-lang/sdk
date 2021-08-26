# Writing a quick fix

This document outlines the basic steps for writing a quick fix.

## Overview

A quick fix is an automated code edit that's associated with a diagnostic. The
intent is to automate the work required to fix the issue being reported. When
the client asks for quick fixes, server computes the relevant diagnostics based
on the cursor location. Then, for each diagnostic, it computes one or more
fixes. The list of computed fixes is then returned to the client.

Through most of this document we'll use a simple example. We'll assume you wrote
a new lint named `could_be_final` that flags fields that could be marked final
but aren't, and that you're adding a fix for it. The fix will simply add the
keyword `final` to the field declaration.

## Describing the fix

Each fix has an instance of the class `FixKind` associated with it. The existing
fixes for Dart diagnostics are defined in the class `DartFixKind`, fixes for the
analysis options file are defined in the class `AnalysisOptionsFixKind`, and
fixes for the pubspec file are in the class `PubspecFixKind`. A fix kind has an
identifier, a priority, and a message.

The identifier is used by some LSP-based clients to provide user-defined
shortcuts. It's a hierarchical dot-separated identifier and should follow the
pattern seen in the existing fix kinds.

The priority is used to order the list of fixes when presented to the user. The
larger the value the closer to the top of the list it will appear. You should
use one of the constants defined in `DartFixKindPriority` (typically
`DartFixKindPriority.DEFAULT`), or add a new constant if there's a need for it.

The message is what will be displayed to the user by the client. This should be
a sentence fragment (no terminating period) that would be appropriate as a label
in a menu or on a button. It should describe the change that will be made to the
user's code.

Create a static field, in the appropriate class, whose value is a `FixKind`
describing the fix you're implementing. For our example you might define a new
constant in `DartFixKind` like this:

```dart
static const ADD_FINAL = FixKind(
  'dart.fix.add.final',
  DartFixKindPriority.DEFAULT,
  "Add 'final' modifier",
);
```

## Implementing the fix, part 1

To implement the fix you'll create a subclass of `CorrectionProducer`. The
existing correction producers are in the directory
`analysis_server/lib/src/services/correction/dart`, so we'll start by creating
a file named `add_final.dart` in that directory that contains the following:

```dart
// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddFinal extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.ADD_FINAL;

  @override
  Future<void> compute(ChangeBuilder builder) async {
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static AddFinal newInstance() => AddFinal();
}
```

The `compute` method is where the fix will be built. We'll come back to it in
"Implementing the fix, part 2".

The `fixKind` getter is how you associate the fix kind we created earlier with
the fix produced by the `compute` method.

The static `newInstance` method will be used later in "Registering the fix".

## Testing the fix

Before we look at implementing the `compute` method, we should probably write
some tests. Even if you don't normally use a test-driven approach to coding, we
recommend it in this case because writing the tests can help you think of corner
cases that the implementation will need to handle. The corresponding tests are
in the directory `analysis_server/test/src/services/correction/fix`, so we'll
create a file named `add_final_test.dart` that contains the following:

```dart
// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddFinalTest);
  });
}

@reflectiveTest
class AddFinalTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_FINAL;

  @override
  String get lintCode => LintNames.could_be_final;
}
```

These two getters tell the test framework to enable the lint being fixed and to
expect a fix of the expected kind.

The test can then be written in a method that looks something like this:

```dart
Future<void> test_withType() async {
  await resolveTestCode('''
class C {
  String name;

  C(this.name);
}
''');
  await assertHasFix('''
class C {
  final String name;

  C(this.name);
}
''');
}
```

The test framework will create a file containing the first piece of code, run
the lint over the code, use our correction producer to build a fix, apply the
fix to the file, and textually compare the results with the second piece of
code.

## Registering the fix

Before we can run the test, we need to register the correction producer so that
it can be run.

The list of fixes is computed by a `FixProcessor`. For each diagnostic passed
to it, it will look up the diagnostic in a table to get a list of the correction
producers it can use to produce fixes. There are three tables:

- The `lintProducerMap` is used for fixes related to lint rules. The table is
  keyed by the name of the lint to which the fix applies.

- The `nonLintProducerMap` is used for all other fixes. The table is keyed by
  the `ErrorCode` associated with the diagnostic.

- The `nonLintMultiProducerMap` is used for multi-producers, which are
  described below in "Multi-fix producers".

Actually, the tables contain lists of functions used to create the producers. We
do that so that producers can't accidentally carry state over from one use to
the next. These functions are usually a tear-off of the static method you
defined in "Implementing the fix, part 1".

The last step is to add your correction producer to the appropriate map. If
you're adding a fix for a lint, then you'd add an entry like

```dart
LintNames.could_be_final: [
  AddFinal.newInstance,
],
```

At this point you should be able to run the test and see it failing.

## Implementing the fix, part 2

We're now at a point where we can finish the implementation of the fix by
implementing the `compute` method.

The correction producer has access to most of the information you should need in
order to write the fix. The change builder passed to `compute` is how you
construct the fix that will be sent back to the client.

The first step in the implementation of any fix is to find the location in the
AST where the diagnostic was reported and verify that all of the conditions on
which the fix is predicated are valid. Assuming that the lint has been written
and tested correctly, there's no need to test that the conditions that caused
the lint rule to generate a diagnostic are still true. However, sometimes there
are additional constraints that need to be satisfied before the fix can safely
be applied. For example, for our fix, where we're only going to add a keyword,
we'll need to ensure that there's only one field that would be impacted by the
change, otherwise we might introduce more problems than there were before the
fix.

Of course, sometimes you'll end up duplicating some of the work done by the lint
in the course of getting the information you need from the AST. While that's
less than optimal, there isn't any mechanism for passing information from the
diagnostic to the fix, so sometimes it just can't be avoided.

For this example we're going to assume that the lint highlights the name of the
field that could have been final. Finding the AST node is easy because it's done
for you by the fix processor before `compute` is invoked. All you have to do is
use the getter `node` to find the node at the offset of the lint's highlight
region. We're expecting it to be the name of a field, so that's how we'll name
the variable:

```dart
@override
Future<void> compute(ChangeBuilder builder) async {
  var fieldName = node;
}
```

Then we need to verify that this node really is an identifier as expected:

```dart
@override
Future<void> compute(ChangeBuilder builder) async {
  var fieldName = node;
  if (fieldName is! SimpleIdentifier) {
    return;
  }
}
```

If it isn't, then we'll return. Because we haven't used the builder to create a
fix, returning now means that no fix from this producer will be sent to the
client.

Simple identifiers appear in lots of places, so to be extra sure we have what
we're looking for we'll also make sure that
- the identifier is the name being declared by a variable declaration,
- the variable declaration is in a list of variables in a field declaration, and
- there's only one field being declared.

```dart
@override
Future<void> compute(ChangeBuilder builder) async {
  var fieldName = node;
  if (fieldName is! SimpleIdentifier) {
    return;
  }
  var field = fieldName.parent;
  if (field is! VariableDeclaration || field.name != fieldName) {
    return;
  }
  var fieldList = field.parent;
  if (fieldList is! VariableDeclarationList ||
          fieldList.variables.length > 1 ||
          fieldList.parent is! FieldDeclaration) {
    return;
  }
}
```

After all those checks we now know that the `fieldName` really is the name of a
field and that there are no other fields that would be impacted by marking the
list of fields with `final`.

We're now ready to create the actual fix. To do that we're going to use the
`ChangeBuilder` passed to the `compute` method. In the example below we'll
introduce a couple of the methods on `ChangeBuilder`, but for more information
you can read [Creating `SourceChange`s](https://github.com/dart-lang/sdk/blob/master/pkg/analyzer_plugin/doc/tutorial/creating_edits.md).

Fields can be declared with either `final`, `const`, `var`, or a type
annotation, and the change that needs to be made depends on how the field was
declared. To figure that out we'll make use of the fact that the first three
tokens are all accessible from the AST by using the getter `keyword`. If there
is no keyword, then we can safely insert `final `, but if `var` was used then it
has to be replaced. And, of course, if it's already `final` or `const` then we
shouldn't do anything (and presumably the lint rule wouldn't have produced a
lint).

```dart
@override
Future<void> compute(ChangeBuilder builder) async {
  var fieldName = node;
  if (fieldName is! SimpleIdentifier) {
    return;
  }
  var field = fieldName.parent;
  if (field is! VariableDeclaration || field.name != fieldName) {
    return;
  }
  var fieldList = field.parent;
  if (fieldList is! VariableDeclarationList ||
          fieldList.variables.length > 1 ||
          fieldList.parent is! FieldDeclaration) {
    return;
  }
  var keyword = fieldList.keyword;
  if (keyword == null) {
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(fieldList.offset, 'final ');
    });
  } else if (keyword.type == Keyword.VAR) {
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.token(keyword), 'final');
    });
  }
}
```

In both cases we're using `addDartFileEdit` to create an edit in a `.dart` file.
If we only need to insert the keyword, then we'll use `addSimpleInsertion` to do
the insertion, but if we need to replace the existing keyword, then we'll use
`addSimpleReplacement` to do the replacement.

We don't have a test case for the branch where the keyword `var` is used. We'll
leave adding such a test as an exercise for the reader.

In this example we're just adding a single keyword, so we're avoiding any need
to worry about formatting. As a general principle we don't attempt to format the
code after it's been modified, but we do make an effort to leave the code in a
reasonably readable state. There's a getter (`eol`) that you can use to get the
end-of-line marker that should be used in the file, and there's another getter
(`utils`) that will return an object with several utility methods that help with
things like getting the right indentation for nested code.

If we were adding a fix for a non-lint diagnostic, then there would be a couple
of minor differences. First, we'd register the correction producer using the
diagnostic's error code. Second, the test class would be a subclass of
`FixProcessorTest` and wouldn't specify the name of the lint.

## Multi-fix producers

We skipped over the map named `nonLintMultiProducerMap` earlier, promising that
we'd return to it later. You'll probably never have a need for it, but in case
you do this section will hopefully tell you what you need to know.

There's a subclass of `CorrectionProducer` named `MultiCorrectionProducer` and
this map is how you register one of them. That class exists for rare cases where
you need to use a single correction producer to produce multiple fixes. This is
generally only needed when you can't know in advance the maximum number of
fixes that might need to be produced. For example, if there is an undefined
identifier and it might be possible to add an import to fix the problem, there's
no way to know in advance how many different libraries might define the name.

If you are able to enumerate the possible fixes ahead of time, then you're
better off to create one subclass of `CorrectionProducer` for each of the fixes.
For example, taking the case of an undefined identifier again, another way to
fix the problem is to add a declaration of the name. There are a finite number
of kinds of declarations a user might want: class, mixin, variable, etc. Even
though some of the declarations might not make sense because of how the
identifier is being used, it's better to have a separate correction producer for
each kind of declaration and have each one determine whether to generate a fix.

And, we don't currently have support for associating a `MultiCorrectionProducer`
with a lint, so if you're writing fixes for a lint then this option isn't
available to you.
