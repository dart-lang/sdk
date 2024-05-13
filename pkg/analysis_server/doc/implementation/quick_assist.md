# Writing a quick assist

This document describes what a quick assist is and outlines the basic steps for
writing a quick assist.

## Overview

A quick assist is an automated [code edit](code_edits.md) that is both
[local in scope](code_edits.md#scope) and doesn't require any user input. If a
code edit requires user input, might depend on knowledge from outside the local
library, or could make changes outside the local library, then it should be
implemented using a refactoring.

Unlike quick fixes, quick assists are displayed even when there are no
diagnostics being reported against the code. They are not intended to fix
problems that are being reported, but are used to perform common and
straightforward code transformations.

In this document we'll use a simple example of writing an assist to convert a
decimal representation of an integer into a hexadecimal representation. While
this wouldn't be a good assist to offer, it's simple enough that the details of
the implementation won't mask the general process used to implement an assist.

## Design considerations

Because quick assists are computed on demand, they need to be computed quickly.
(Some clients request quick assists every time the user repositions the cursor.)
That places a performance requirement on quick assists, one that requires that
the code to compute a quick assist can't perform any potentially lengthy
computations such as searching all of the user's code or accessing the network.
That, in turn, generally means that assists can only support localized changes.
They can add or remove text in the local library, but generally can't do more
than that.

Unlike quick fixes, there is no signal to indicate which assists might apply at
a given location in the code. That means that we have to test every assist to
see whether it's appropriate, which puts a practical limit on the number of
assists that we can implement. (Even if each assist only takes 100 milliseconds
to determine whether it applies, if we have 100 assists it will take 10 seconds
to return the list of assists to the user, which is too slow.) That means that
we need to be discerning about which assists are implemented and work to make
assists return quickly if they are not appropriate.

## Describing the assist

Each assist has an instance of the class `AssistKind` associated with it. The
existing assists for Dart are defined in the class `DartAssistKind`. An
assist kind has an identifier, a priority, and a message.

The identifier is used by some LSP-based clients to provide user-defined
shortcuts. It's a hierarchical dot-separated identifier and should follow the
pattern seen in the existing assist kinds.

The priority is used to order the list of assists when presented to the user.
The larger the value the closer to the top of the list it will appear. If you're
implementing an assist for Dart files, you should use one of the constants
defined in `DartAssistKindPriority` (typically
`DartAssistKindPriority.DEFAULT`), or add a new constant if there's a need for
it.

The message is what will be displayed to the user by the client. This should be
a sentence fragment (no terminating period) that would be appropriate as a label
in a menu or on a button. It should describe the change that will be made to the
user's code.

Create a static field whose value is an `AssistKind` describing the assist
you're implementing. For our example you might define a new constant in
`DartAssistKind` like this:

```dart
static const CONVERT_TO_HEX = AssistKind(
  'dart.assist.convert.toHex',
  DartAssistKindPriority.DEFAULT,
  "Convert to hexadecimal",
);
```

## Implementing the assist, part 1

To implement the assist you'll create a subclass of `CorrectionProducer`. Most
of the existing correction producers are in the directory
`analysis_server/lib/src/services/correction/dart`, so we'll start by creating
a file named `convert_to_hex.dart` in that directory that contains the following
(with the year updated appropriately):

```dart
// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToHex extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_HEX;

  @override
  Future<void> compute(ChangeBuilder builder) async {
  }
}
```

The `compute` method is where the assist will be built. We'll come back to it in
"Implementing the assist, part 2".

The `assistKind` getter is how you associate the assist kind we created earlier
with the assist produced by the `compute` method.

There's another getter you might need to override. The message associated with
the assist kind is actually a template that can be filled in at runtime. The
placeholders in the message are denoted by integers inside curly braces (such as
`{0}`). The integers are indexes into a list of replacement values (hence, zero
based), and the getter `assistArguments` returns the list of replacement values.
The message we used above doesn't have any placeholders, but if we'd written the
message as `"Convert to '{0}'"`, then we could return the replacement values by
implementing:

```dart
String _hexRepresentation = '';

@override
List<Object> get assistArguments => [_hexRepresentation];
```

and assigning the replacement string to the field inside the `compute` method.

If you don't implement this getter, then the inherited getter will return an
empty list. The number of elements in the list must match the largest index used
in the message. If it doesn't, an exception will be thrown at runtime.

## Testing the assist

Before we look at implementing the `compute` method, we should probably write
some tests. Even if you don't normally use a test-driven approach to coding, we
recommend it in this case because writing the tests can help you think of corner
cases that the implementation will need to handle. The corresponding tests are
in the directory `analysis_server/test/src/services/correction/assist`, so we'll
create a file named `convert_to_hex_test.dart` that contains the following:

```dart
// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToHexTest);
  });
}

@reflectiveTest
class ConvertToHexTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_TO_HEX;
}
```

This getter tells the test framework to expect an assist of the returned kind.

The test can then be written in a method that looks something like this:

```dart
Future<void> test_positive() async {
  await resolveTestCode('''
var c = /*caret*/42;
''');
  await assertHasAssist('''
var c = 0x2a;
''');
}
```

The test framework will look for the marker `/*caret*/`, remember it's offset,
create a file containing the first piece of code with the marker removed, run
the assist over the code, use our correction producer to build an edit, apply
the edit to the file, and textually compare the results with the second piece of
code.

## Registering the assist

Before we can run the test, we need to register the correction producer so that
it can be run.

The list of assists is computed by the `AssistProcessor`, which has two static
lists named `generators` and `multiGenerators` that contain the correction
producers used to compute the assists.

Actually, the lists contain functions used to create the producers. We do that
so that producers can't accidentally carry state over from one use to the next.
These functions are usually a tear-off of the correction producer's constructor.

The last step is to add your correction producer to the list named `generators`.
We'll talk about the other list in "Multi-assist producers".

At this point you should be able to run the test and see it failing.

## Implementing the assist, part 2

We're now at a point where we can finish the implementation of the assist by
implementing the `compute` method.

The correction producer has access to most of the information you should need in
order to write the assist. The change builder passed to `compute` is how you
construct the edit that will be sent back to the client.

The first step in the implementation of any assist is to find the location in
the AST where the cursor is positioned and verify that all the conditions on
which the assist is predicated are valid. For example, for our assist we'll need
to ensure that the cursor is on an integer literal, that the literal consists of
decimal digits, and that the value is a valid integer.

Finding the AST node is easy because it's done for you by the assist processor
before `compute` is invoked. All you have to do is use the getter `node` to find
the node at the cursor.

```dart
@override
Future<void> compute(ChangeBuilder builder) async {
  final node = this.node;
}
```

Then we need to verify that this node is an integer literal:

```dart
@override
Future<void> compute(ChangeBuilder builder) async {
  final node = this.node;
  if (node is! IntegerLiteral) {
    return;
  }
}
```

If it isn't, then we'll return. Because we haven't used the builder to create a
assist, returning now means that no assist from this producer will be sent to
the client.

We'll also check that the integer has the right form and is valid:

```dart
@override
Future<void> compute(ChangeBuilder builder) async {
  final node = this.node;
  if (node is! IntegerLiteral) {
    return;
  }
  var value = node.value;
  if (value == null) {
    return;
  }
  if (node.literal.lexeme.contains(RegExp('[^0-9]'))) {
    return;
  }
}
```

After all those checks we now know that we have a decimal integer that we can
convert. Note that we check for a `null` value before checking for non-decimal
digits because it's a faster check and we want the assist to fail as quickly as
possible.

We're now ready to create the edit. To do that we're going to use the
`ChangeBuilder` passed to the `compute` method. In the example below we'll
introduce a couple of the methods on `ChangeBuilder`, but for more information
you can read [Creating `SourceChange`s](https://github.com/dart-lang/sdk/blob/main/pkg/analyzer_plugin/doc/tutorial/creating_edits.md).

```dart
@override
Future<void> compute(ChangeBuilder builder) async {
  final node = this.node;
  if (node is! IntegerLiteral) {
    return;
  }
  var value = node.value;
  if (value == null) {
    return;
  }
  if (node.literal.lexeme.contains(RegExp('[^0-9]'))) {
    return;
  }
  await builder.addDartFileEdit(file, (builder) {
    var hexDigits = value.toRadixString(16);
    builder.addSimpleReplacement(range.node(node), '0x$hexDigits');
  });
}
```

We're using `addDartFileEdit` to create an edit in a `.dart` file. In this case
the edit is simple: we're just replacing one representation of the integer
literal with a representation of the same value in a different base. The getter
`range` returns a `RangeFactory`, a utility class with lots of methods to make
it easier to create `SourceRange`s.

We're missing several test cases. Minimally we should test that the assist works
correctly with negative values (it doesn't), and that it will not produce an
edit if the integer literal isn't valid. We'll leave adding such tests as an
exercise for the reader.

In this example we're just making a simple replacement, so we're avoiding any
need to worry about formatting. As a general principle we don't attempt to
format the code after it's been modified, but we do make an effort to leave the
code in a reasonably readable state. There's a getter (`eol`) that you can use
to get the end-of-line marker that should be used in the file, and there's
another getter (`utils`) that will return an object with several utility methods
that help with things like getting the right indentation for nested code.

## Multi-assist producers

We skipped over the list named `multiGenerators` earlier, promising that we'd
return to it later. You'll probably never have a need for it, but in case you do
this section will hopefully tell you what you need to know.

There's a subclass of `CorrectionProducer` named `MultiCorrectionProducer` and
this list is how you register one of them. That class exists for rare cases
where you need to use a single correction producer to produce multiple assists.
This is generally only needed when you can't know in advance the maximum number
of assists that might need to be produced. For example, there's a set of assists
to wrap a Flutter `Widget` in another widget, but the set of widgets that can
wrap a given widget depends on the widget being wrapped.

If you are able to enumerate the possible assists ahead of time, then you're
probably better off to create one subclass of `CorrectionProducer` for each of
the assists.
