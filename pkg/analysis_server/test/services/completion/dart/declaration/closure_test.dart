// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:linter/src/lint_names.dart';
import 'package:linter/src/rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClosureTest);
  });
}

@reflectiveTest
class ClosureTest extends AbstractCompletionDriverTest with ClosureTestCases {}

mixin ClosureTestCases on AbstractCompletionDriverTest {
  @override
  bool get includeClosures => true;

  @override
  bool get includeKeywords => false;

  @override
  Future<void> setUp() async {
    await super.setUp();
    printerConfiguration.withDisplayText = true;
  }

  Future<void> test_argumentList_named() async {
    await computeSuggestions('''
void f({void Function(int a, String b) closure}) {}

void g() {
  f(closure: ^);
}
''');
    assertResponse('''
suggestions
  (a, b) => ^,
    kind: invocation
    displayText: (a, b) =>
  (a, b) {
    ^
  },
    kind: invocation
    displayText: (a, b) {}
''');
  }

  Future<void> test_argumentList_named_hasComma() async {
    await computeSuggestions('''
void f({void Function(int a, String b) closure}) {}

void g() {
  f(
    closure: ^,
  );
}
''');
    assertResponse('''
suggestions
  |(a, b) => |
    kind: invocation
    displayText: (a, b) =>
  (a, b) {
      ^
    }
    kind: invocation
    displayText: (a, b) {}
''');
  }

  Future<void> test_argumentList_positional() async {
    await computeSuggestions('''
void f(void Function(int a, int b) closure) {}

void g() {
  f(^);
}
''');
    assertResponse('''
suggestions
  (a, b) => ^,
    kind: invocation
    displayText: (a, b) =>
  (a, b) {
    ^
  },
    kind: invocation
    displayText: (a, b) {}
''');
  }

  Future<void> test_argumentList_positional_hasComma() async {
    await computeSuggestions('''
void f(void Function(int a, int b) closure) {}

void g() {
  f(^,);
}
''');
    assertResponse('''
suggestions
  |(a, b) => |
    kind: invocation
    displayText: (a, b) =>
  (a, b) {
    ^
  }
    kind: invocation
    displayText: (a, b) {}
''');
  }

  Future<void> test_lint_alwaysSpecifyTypes() async {
    registerLintRules();
    writeTestPackageAnalysisOptionsFile(
      analysisOptionsContent(rules: [LintNames.always_specify_types]),
    );

    await computeSuggestions('''
void Function(List<int> a, Object? b, [dynamic c]) v = ^;
''');
    assertResponse('''
suggestions
  |(List<int> a, Object? b, [dynamic c]) => |
    kind: invocation
    displayText: (a, b, [c]) =>
  (List<int> a, Object? b, [dynamic c]) {
  ^
}
    kind: invocation
    displayText: (a, b, [c]) {}
''');
  }

  Future<void> test_parameters_optionalNamed() async {
    await computeSuggestions('''
void f({void Function(int a, {int b, int c}) closure}) {}

void g() {
  f(closure: ^);
}
''');
    assertResponse('''
suggestions
  (a, {b, c}) => ^,
    kind: invocation
    displayText: (a, {b, c}) =>
  (a, {b, c}) {
    ^
  },
    kind: invocation
    displayText: (a, {b, c}) {}
''');
  }

  Future<void> test_parameters_optionalPositional() async {
    await computeSuggestions('''
void f({void Function(int a, [int b, int c]) closure]) {}

void g() {
  f(closure: ^);
}
''');
    assertResponse('''
suggestions
  (a, [b, c]) => ^,
    kind: invocation
    displayText: (a, [b, c]) =>
  (a, [b, c]) {
    ^
  },
    kind: invocation
    displayText: (a, [b, c]) {}
''');
  }

  Future<void> test_parameters_requiredNamed() async {
    await computeSuggestions('''
void f({void Function(int a, {int b, required int c}) closure}) {}

void g() {
  f(closure: ^);
}
''');
    assertResponse('''
suggestions
  (a, {b, required c}) => ^,
    kind: invocation
    displayText: (a, {b, c}) =>
  (a, {b, required c}) {
    ^
  },
    kind: invocation
    displayText: (a, {b, c}) {}
''');
  }

  Future<void> test_variableInitializer() async {
    await computeSuggestions('''
void Function(int a, int b) v = ^;
''');
    assertResponse('''
suggestions
  |(a, b) => |
    kind: invocation
    displayText: (a, b) =>
  (a, b) {
  ^
}
    kind: invocation
    displayText: (a, b) {}
''');
  }
}
