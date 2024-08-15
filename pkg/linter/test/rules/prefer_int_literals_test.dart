// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/analyzer_error_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferIntLiteralsTest);
  });
}

@reflectiveTest
class PreferIntLiteralsTest extends LintRuleTest {
  @override
  List<AnalyzerErrorCode> get ignoredErrorCodes => [
        WarningCode.UNUSED_ELEMENT,
        WarningCode.UNUSED_FIELD,
        WarningCode.UNUSED_LOCAL_VARIABLE,
      ];

  @override
  String get lintRule => 'prefer_int_literals';

  test_argumentPassedToTypeVariableParameter_explicitlyTypedDouble_integer() async {
    await assertDiagnostics(r'''
import 'dart:math';
f(double d) {
  double x = max(d, 7.0);
}
''', [
      lint(54, 3),
    ]);
  }

  test_argumentPassedToTypeVariableParameter_inferredType_integer() async {
    await assertDiagnostics(r'''
import 'dart:math';
f(double d) {
  var a = max(d, 7.0);
}
''', [
      lint(51, 3),
    ]);
  }

  test_argumentToNamedParameter_implicitlyTyped() async {
    await assertNoDiagnostics(r'''
void f({d}) {
  f(d: 1.0);
}
''');
  }

  test_argumentToNamedParameter_withDefaultValue_explicitlyTypedDouble() async {
    await assertDiagnostics(r'''
void f({double d = 0.0}) {
  f(d: 1.0);
}
''', [
      lint(34, 3),
    ]);
  }

  test_argumentToNamedParameter_withDefaultValue_implicitlyTyped() async {
    await assertNoDiagnostics(r'''
void f({d = 0.0}) {
  f(d: 1.0);
}
''');
  }

  test_argumentToPositionalParameter_explicitlyTypedDouble() async {
    await assertDiagnostics(r'''
void f(double d) {
  f(1.0);
}
''', [
      lint(23, 3),
    ]);
  }

  test_argumentToSuperParameter_decimal() async {
    await assertNoDiagnostics(r'''
class A {
  A(double x);
}
class B extends A {
  B() : super(1.7);
}
''');
  }

  test_argumentToSuperParameter_int() async {
    await assertNoDiagnostics(r'''
class A {
  A(double x);
}
class B extends A {
  B() : super(1);
}
''');
  }

  test_argumentToSuperParameter_integer() async {
    await assertDiagnostics(r'''
class A {
  A(double x);
}
class B extends A {
  B() : super(1.0);
}
''', [
      lint(61, 3),
    ]);
  }

  test_binaryExpression_multipliedByInt_explicitlyTypedDouble() async {
    // TODO(danrubel): Consider if this can be converted to an int literal.
    await assertNoDiagnostics(r'''
void f(int i) {
  double a = 360.0 * i;
}
''');
  }

  test_binaryExpression_multipliedByInt_inferredType() async {
    await assertNoDiagnostics(r'''
void f(int i) {
  var a = 360.0 * i;
}
''');
  }

  test_binaryExpression_multipliedByLargeInt2_implicitlyTyped() async {
    await assertNoDiagnostics(r'''
void f() {
  int i = 1 << 61 + 1;
  var j = i * 360.0;
}
''');
  }

  test_binaryExpression_multipliedByLargeInt_implicitlyTyped() async {
    await assertNoDiagnostics(r'''
void f() {
  int i = 1 << 61 + 1;
  var j = i * 360.0;
}
''');
  }

  test_canBeInt_explicitlyTypedDouble_decimalWithExponent() async {
    await assertDiagnostics(r'''
double a = 7.1e2;
''', [
      lint(11, 5),
    ]);
  }

  test_cannotBeInt_explicitlyTypedDouble_decimalWithExponent() async {
    await assertNoDiagnostics(r'''
double a = 7.576e2;
''');
  }

  test_explicitTypeDouble_decimal() async {
    await assertNoDiagnostics(r'''
double a = 7.3;
''');
  }

  test_explicitTypeDouble_decimalWithSeparators() async {
    await assertNoDiagnostics(r'''
double a = 1_234.567_8;
''');
  }

  test_explicitTypeDouble_integer() async {
    await assertDiagnostics(r'''
double a = 8.0;
''', [
      lint(11, 3),
    ]);
  }

  test_explicitTypeDouble_integer_negative() async {
    await assertDiagnostics(r'''
double a = -8.0;
''', [
      lint(12, 3),
    ]);
  }

  test_explicitTypeDouble_integerWithExponent() async {
    await assertDiagnostics(r'''
double a = 7.0e2;
''', [
      lint(11, 5),
    ]);
  }

  test_explicitTypeDouble_integerWithExponentAndSeparators() async {
    await assertDiagnostics(r'''
double a = 7_000.0e2;
''', [
      lint(11, 9),
    ]);
  }

  test_explicitTypeDouble_integerWithSeparators() async {
    await assertDiagnostics(r'''
double a = 8_000.000_0;
''', [
      lint(11, 11),
    ]);
  }

  test_explicitTypeDynamic_integer() async {
    await assertNoDiagnostics(r'''
dynamic a = 8.0;
''');
  }

  test_explicitTypeObject_integer() async {
    await assertNoDiagnostics(r'''
Object a = 8.0;
''');
  }

  test_functionExpressionBody_explicitlyTypedDouble() async {
    await assertDiagnostics(r'''
void f() {
  double g() => 6.0;
}
''', [
      lint(27, 3),
    ]);
  }

  test_functionExpressionBody_implicitlyTypedDynamic() async {
    await assertNoDiagnostics(r'''
void f() {
  g() => 6.0;
}
''');
  }

  test_functionExpressionBody_method_explicitlyTypedDouble() async {
    await assertDiagnostics(r'''
class C {
  double f() => 6.0;
}
''', [
      lint(26, 3),
    ]);
  }

  test_inBinaryExpression_explicitlyTypedInt_integer() async {
    await assertNoDiagnostics(r'''
final a = 8.0 + 7.0;
''');
  }

  test_inBinaryExpression_explicitTypeDouble_integer() async {
    // TODO(danrubel): Consider linting these as well
    await assertNoDiagnostics(r'''
double a = 8.0 + 7.0;
''');
  }

  test_inferredType_integer() async {
    await assertNoDiagnostics(r'''
var a = 8.0;
''');
  }

  test_inferredType_integerWithExponent() async {
    await assertNoDiagnostics(r'''
var a = 7.0e2;
''');
  }

  test_inListLiteral_explicitTypeDouble_integer() async {
    await assertDiagnostics(r'''
var a = <double>[50.0];
''', [
      lint(17, 4),
    ]);
  }

  test_inListLiteral_inferredType_integer() async {
    await assertNoDiagnostics(r'''
var a = [50.0];
''');
  }

  test_returnExpression_explicitlyTypedDouble() async {
    await assertDiagnostics(r'''
double f() {
  return 6.0;
}
''', [
      lint(22, 3),
    ]);
  }

  test_returnExpression_implicitlyTypedDynamic() async {
    await assertNoDiagnostics(r'''
f() {
  return 6.0;
}
''');
  }

  test_returnExpression_method_explicitlyTypedDouble() async {
    await assertDiagnostics(r'''
class C {
  double f() {
    return 6.0;
  }
}
''', [
      lint(36, 3),
    ]);
  }
}
