// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnrelatedTypeEqualityChecksTest);
  });
}

@reflectiveTest
class UnrelatedTypeEqualityChecksTest extends LintRuleTest {
  @override
  bool get addFixnumPackageDep => true;

  @override
  String get lintRule => LintNames.unrelated_type_equality_checks;

  test_assignment_ok() async {
    await assertNoDiagnostics(r'''
void m(int? a1, num a2) {
  var b1 = a1 == a2;
  var b2 = a2 == a1;
}
''');
  }

  test_dynamic_andInt() async {
    await assertNoDiagnostics(r'''
void f(dynamic x) {
  if (x == 0) {}
}
''');
  }

  test_fixnum_int32_leftSide() async {
    await assertNoDiagnostics(r'''
import 'package:fixnum/fixnum.dart';

void f(Int32 p) {
  if (p == 0) {}
}
''');
  }

  test_fixnum_int32_rightSide() async {
    await assertDiagnostics(r'''
import 'package:fixnum/fixnum.dart';

void f(Int32 p) {
  if (0 == p) {}
}
''', [
      lint(64, 2),
    ]);
  }

  test_fixnum_int64_leftSide() async {
    await assertNoDiagnostics(r'''
import 'package:fixnum/fixnum.dart';

void f(Int64 p) {
  if (p == 0) {}
}
''');
  }

  test_fixnum_int64_rightSide() async {
    await assertDiagnostics(r'''
import 'package:fixnum/fixnum.dart';

void f(Int64 p) {
  if (0 == p) {}
}
''', [
      lint(64, 2),
    ]);
  }

  test_futureOfDynamic_andFutureOfVoid() async {
    await assertNoDiagnostics(r'''
void f(Future<dynamic> x, Future<void> y) {
  if (x == y) {}
}
''');
  }

  test_int_andInt() async {
    await assertNoDiagnostics(r'''
void f() {
  if (1 == 0) {}
}
''');
  }

  test_mixin_andTypeImplementingMixin() async {
    await assertNoDiagnostics(r'''
void f(M x, C y) {
  if (x == y) {}
}
mixin M {}
class C implements M {}
''');
  }

  test_mixin_andTypeWithMixin() async {
    await assertNoDiagnostics(r'''
void f(M x, C y) {
  if (x == y) {}
}
mixin M {}
class C with M {}
''');
  }

  test_object_andArbitraryType() async {
    await assertNoDiagnostics(r'''
void f(Object x, C y) {
  if (x == y) {}
}
class C {}
''');
  }

  test_object_andDynamic() async {
    await assertNoDiagnostics(r'''
void f(Object x, dynamic y) {
  if (x == y) {}
}
''');
  }

  test_oneEnum_andSameEnum() async {
    await assertNoDiagnostics(r'''
void f(E x, E y) {
  if (x == y) {}
}
enum E { one, two; }
''');
  }

  test_oneEnum_andUnrelatedEnum() async {
    await assertDiagnostics(r'''
void f(E x, F y) {
  if (x == y) {}
}
enum E { one, two; }
enum F { three, four; }
''', [
      lint(27, 2),
    ]);
  }

  test_oneType_andSubtype() async {
    await assertNoDiagnostics(r'''
void f(C x, D y) {
  if (x == y) {}
}
class C {}
class D extends C {}
''');
  }

  test_oneTypeVariable_andOneSubtypeTypeVariable() async {
    await assertNoDiagnostics(r'''
void f<A, B extends A>(A a, B b) {
  if (a == b) {}
}
''');
  }

  test_recordAndInterfaceType_unrelated() async {
    await assertDiagnostics(r'''
bool f((int, int) a, String b) => a == b;
''', [
      lint(36, 2),
    ]);
  }

  test_records_related() async {
    await assertNoDiagnostics(r'''
bool f((int, int) a, (num, num) b) => a == b;
''');
  }

  test_records_unrelated() async {
    await assertDiagnostics(r'''
bool f((int, int) a, (String, String) b) => a == b;
''', [
      lint(46, 2),
    ]);
  }

  test_recordsWithNamed_related() async {
    await assertNoDiagnostics(r'''
bool f(({int one, int two}) a, ({num two, num one}) b) => a == b;
''');
  }

  test_recordsWithNamed_unrelated() async {
    await assertDiagnostics(r'''
bool f(({int one, int two}) a, ({String one, String two}) b) => a == b;
''', [
      lint(66, 2),
    ]);
  }

  test_recordsWithNamedAndPositional_related() async {
    await assertNoDiagnostics(r'''
bool f((int, {int two}) a, (num one, {num two}) b) => a == b;
''');
  }

  test_recordsWithNamedAndPositional_unrelated() async {
    await assertDiagnostics(r'''
bool f((int, {int two}) a, (String one, {String two}) b) => a == b;
''', [
      lint(62, 2),
    ]);
  }

  test_string_andInt() async {
    await assertDiagnostics(r'''
void f() {
  if ('foo' == 1) {}
}
''', [
      lint(23, 2),
    ]);
  }

  test_string_andNull() async {
    await assertDiagnostics(r'''
void f() {
  if ('foo' == null) {}
}
''', [
      // No lint.
      error(WarningCode.UNNECESSARY_NULL_COMPARISON_NEVER_NULL_FALSE, 23, 7),
    ]);
  }

  test_string_andString() async {
    await assertNoDiagnostics(r'''
void f() {
  if ('foo' == 'bar') {}
}
''');
  }

  test_switchExpression() async {
    await assertDiagnostics(r'''
const space = 32;

String f(int char) {
  return switch (char) {
    == 'space' => 'space',
  };
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_EXPRESSION, 49, 6),
      lint(69, 10),
    ]);
  }

  test_switchExpression_lessEq_ok() async {
    await assertDiagnostics(r'''
String f(int i) {
  return switch (i) {
    <= 1 => 'one',
  };
}
''', [
      // No lint.
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_EXPRESSION, 27, 6)
    ]);
  }

  test_switchExpression_notEq() async {
    await assertDiagnostics(r'''
const space = 32;

String f(int char) {
  return switch (char) {
    != 'space' => 'space',
  };
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_EXPRESSION, 49, 6),
      lint(69, 10),
    ]);
  }

  test_switchExpression_ok() async {
    await assertDiagnostics(r'''
String f(String char) {
  return switch (char) {
    == 'space' => 'space',
  };
}
''', [
      // No lint.
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_EXPRESSION, 33, 6),
    ]);
  }

  test_twoListsOfTypeVariables_unrelatedBounds() async {
    await assertDiagnostics(r'''
void f<A extends int, B extends bool>(List<A> a, List<B> b) {
  if (a == b) {}
}
''', [
      lint(70, 2),
    ]);
  }

  test_twoListsOfUnrelatedTypeVariables() async {
    await assertNoDiagnostics(r'''
void f<A, B>(List<A> a, List<B> b) {
  if (a == b) {}
}
''');
  }

  test_twoMapsOfUnrelatedTypeVariableKeys() async {
    await assertNoDiagnostics(r'''
void f<A, B>(Map<A, int> a, Map<B, int> b) {
  if (a == b) {}
}
''');
  }

  test_twoMapsOfUnrelatedTypeVariableValues() async {
    await assertNoDiagnostics(r'''
void f<A, B>(Map<int, A> a, Map<int, B> b) {
  if (a == b) {}
}
''');
  }

  test_twoSubtypesOfSharedDistantSupertype() async {
    await assertDiagnostics(r'''
void f(D2 x, E2 y) {
  if (x == y) {}
}
class C {}
class D1 extends C {}
class E1 extends C {}
class D2 extends D1 {}
class E2 extends E1 {}
''', [
      lint(29, 2),
    ]);
  }

  test_twoSubtypesOfSharedSupertype() async {
    await assertNoDiagnostics(r'''
void f(D x, E y) {
  if (x == y) {}
}
class C {}
class D extends C {}
class E extends C {}
''');
  }

  test_twoTypeVariables_sameBounds() async {
    await assertNoDiagnostics(r'''
void f<A extends int, B extends int>(A a, B b) {
  if (a == b) {}
}
''');
  }

  test_twoTypeVariables_unrelatedBounds() async {
    await assertDiagnostics(r'''
void f<A extends int, B extends bool>(A a, B b) {
  if (a == b) {}
}
''', [
      lint(58, 2),
    ]);
  }

  test_twoUnrelatedTypeVariables() async {
    await assertNoDiagnostics(r'''
void f<A, B>(A a, B b) {
  if (a == b) {}
}
''');
  }
}
