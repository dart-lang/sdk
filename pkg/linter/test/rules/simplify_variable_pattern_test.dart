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

  Future<void> test_patternField_dynamic() async {
    await assertDiagnosticsFromMarkup('''
void f(Object o) {
  if (o case dynamic([!isEven!]:var isEven)) {}
}
''');
  }

  Future<void> test_patternField_explicit() async {
    await assertDiagnosticsFromMarkup('''
void f(Object o) {
  if (o case int([!isEven!]:var isEven)) {}
}
''');
  }

  Future<void> test_patternField_function() async {
    await assertDiagnosticsFromMarkup('''
void f(Object o) {
  if (o case Function([!call!]:var call)) {}
}
''');
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

  Future<void> test_patternField_parenthesized() async {
    await assertDiagnosticsFromMarkup('''
void f(Object o) {
  if (o case int([!isEven!]:((var isEven)))) {}
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
    await assertDiagnosticsFromMarkup('''
void f((int, {String name}) record) {
  var (x, [!name!]: name) = record;
}
''');
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

  Future<void> test_typedef_if() async {
    await assertDiagnosticsFromMarkup('''
typedef O = Object;

void f(Object o) {
  if (o case O([!hashCode!]: final hashCode)) {}
}
''');
  }

  Future<void> test_typedef_record() async {
    await assertDiagnosticsFromMarkup('''
typedef R = ({int value});

void f(Object o) {
  if (o case R([!value!]: var value)) {}
}
''');
  }

  Future<void> test_typedef_typeParameter() async {
    await assertDiagnosticsFromMarkup('''
typedef O<T extends Object> = T;
void f(O o) {
  if (o case O([!hashCode!]: var hashCode)) {}
}
''');
  }

  Future<void> test_typedef_variableDeclaration() async {
    await assertDiagnosticsFromMarkup('''
typedef O = Object;

void f(Object o) {
  final O([!hashCode!]: hashCode) = o;
}
''');
  }

  Future<void> test_typeParameter() async {
    await assertDiagnosticsFromMarkup('''
void f<T extends Object>(T o) {
  if (o case T([!hashCode!]: var hashCode)) {}
}
''');
  }

  Future<void> test_typeParameter_functionType() async {
    await assertDiagnosticsFromMarkup('''
void f<F extends void Function()>(F o) {
  if (o case F([!call!]: var call)) {}
}
''');
  }

  Future<void> test_typeParameter_record() async {
    await assertDiagnosticsFromMarkup('''
void f<R extends ({int value})>(R o) {
  if (o case R([!value!]: var value)) {}
}
''');
  }

  Future<void> test_typeParameter_typedef_record() async {
    await assertDiagnosticsFromMarkup('''
void f<T extends R>(T o) {
  if (o case T([!value!]: var value)) {}
}

typedef R = ({int value});
''');
  }

  Future<void> test_typeParameter_typeParameterBounded() async {
    await assertDiagnosticsFromMarkup('''
void f<T extends Object, O extends T>(O o) {
  if (o case O([!hashCode!]: var hashCode)) {}
}
''');
  }
}
