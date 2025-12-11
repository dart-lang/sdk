// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SimplifyVariablePatternTest);
  });
}

@reflectiveTest
class SimplifyVariablePatternTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.simplify_variable_pattern;

  Future<void> test_noPatternField() async {
    await assertNoDiagnostics('''
void f(Object o) {
  if (o case int i) {}
}
''');
  }

  Future<void> test_patternField_explicit() async {
    await assertDiagnostics(
      '''
void f(Object o) {
  if (o case int(isEven:var isEven)) {}
}
''',
      [lint(36, 6)],
    );
  }

  Future<void> test_patternField_function() async {
    await assertDiagnostics(
      '''
void f(Object o) {
  if (o case Function(call:var call)) {}
}
''',
      [lint(41, 4)],
    );
  }

  Future<void> test_patternField_implicit() async {
    await assertNoDiagnostics('''
void f(Object o) {
  if (o case int(:var isEven)) {}
}
''');
  }

  Future<void> test_patternField_otherName() async {
    await assertNoDiagnostics('''
void f(Object o) {
  if (o case int(isEven:var other)) {}
}
''');
  }

  Future<void> test_patternField_unnexistingProperty() async {
    await assertDiagnostics(
      '''
void f(Object o) {
  if (o case int(isEvenn:var isEvenn) when isEvenn) {}
}
''',
      [error(diag.undefinedGetter, 36, 7)],
    );
  }

  Future<void> test_recordDestructuring() async {
    await assertDiagnostics(
      '''
void f((int, {String name}) record) {
  var (x, name: name) = record;
}
''',
      [lint(48, 4)],
    );
  }

  Future<void> test_recordDestructuring_unnexistingField() async {
    await assertDiagnostics(
      '''
void f((int, {String name}) record) {
  var (x, namee: namee) = record;
  print(namee);
}
''',
      [error(diag.patternTypeMismatchInIrrefutableContext, 44, 17)],
    );
  }
}
