// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UncheckedUseOfNullableValueTest);
  });
}

@reflectiveTest
class UncheckedUseOfNullableValueTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..enabledExperiments = [EnableString.non_nullable];

  @override
  bool get typeToStringWithNullability => true;

  test_and_nonNullable() async {
    await assertNoErrorsInCode(r'''
m() {
  bool x = true;
  if(x && true) {}
}
''');
  }

  test_and_nullable() async {
    await assertErrorsInCode(r'''
m() {
  bool? x;
  if(x && true) {}
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 22, 1),
    ]);
  }

  test_as_nullable() async {
    await assertNoErrorsInCode(r'''
m() {
  num? x;
  x as int;
}
''');
  }

  test_assert_nonNullable() async {
    await assertNoErrorsInCode(r'''
m() {
  bool x = true;
  assert(x);
}
''');
  }

  test_assert_nullable() async {
    await assertErrorsInCode(r'''
m() {
  bool? x;
  assert(x);
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 26, 1),
    ]);
  }

  test_assignment_eq_propertyAccess3_short1() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A(this.x);
}

class B {
  final A? a;
  B(this.a);
}

m(B b) {
  b.a?.x = 1;
  b.a.x = 2;
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 100, 3),
    ]);
    var assignment1 = findNode.assignment('b.a?.x = 1');
    var assignment2 = findNode.assignment('b.a.x = 2');
    assertType(assignment1.leftHandSide, 'int');
    assertType(assignment2.leftHandSide, 'int');
    assertType(assignment1, 'int?');
    assertType(assignment2, 'int');
  }

  test_assignment_eq_simpleIdentifier() async {
    await assertNoErrorsInCode(r'''
m(int x, int? y) {
  x = 0;
  y = 0;
}
''');
    var assignment1 = findNode.assignment('x =');
    var assignment2 = findNode.assignment('y =');
    assertType(assignment1.leftHandSide, 'int');
    assertType(assignment2.leftHandSide, 'int?');
    assertType(assignment1, 'int');
    assertType(assignment2, 'int');
  }

  test_assignment_plusEq_propertyAccess3() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  int? y;
  A(this.x);
}

class B {
  final A a;
  B(this.a);
}

m(B b) {
  b.a.x += 0;
  b.a.y += 0;
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 109, 5),
    ]);
    var assignment1 = findNode.assignment('b.a.x +=');
    var assignment2 = findNode.assignment('b.a.y +=');
    assertType(assignment1.leftHandSide, 'int');
    assertType(assignment2.leftHandSide, 'int?');
    assertType(assignment1, 'int');
    assertType(assignment2, 'int');
  }

  test_assignment_plusEq_propertyAccess3_short1() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A(this.x);
}

class B {
  final A? a;
  B(this.a);
}

m(B b) {
  b.a?.x += 1;
  b.a.x += 2;
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 101, 3),
    ]);
    var assignment1 = findNode.assignment('b.a?.x += 1');
    var assignment2 = findNode.assignment('b.a.x += 2');
    assertType(assignment1.leftHandSide, 'int');
    assertType(assignment2.leftHandSide, 'int');
    assertType(assignment1, 'int?');
    assertType(assignment2, 'int');
  }

  test_assignment_plusEq_simpleIdentifier() async {
    await assertErrorsInCode(r'''
m(int x, int? y) {
  x += 0;
  y += 0;
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 31, 1),
    ]);
    var assignment1 = findNode.assignment('x +=');
    var assignment2 = findNode.assignment('y +=');
    assertType(assignment1.leftHandSide, 'int');
    assertType(assignment2.leftHandSide, 'int?');
    assertType(assignment1, 'int');
    assertType(assignment2, 'int');
  }

  test_await_nonNullable() async {
    await assertNoErrorsInCode(r'''
m() async {
  Future x = Future.value(null);
  await x;
}
''');
  }

  test_await_nullable() async {
    await assertNoErrorsInCode(r'''
m() async {
  Future? x;
  await x;
}
''');
  }

  test_cascade_nonNullable() async {
    await assertNoErrorsInCode(r'''
m() {
  int x = 0;
  x..isEven;
}
''');
  }

  test_cascade_nullable() async {
    await assertErrorsInCode(r'''
m() {
  int? x;
  x..isEven;
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 18, 1),
    ]);
  }

  test_eqEq_nullable() async {
    await assertNoErrorsInCode(r'''
m() {
  int? x;
  x == null;
}
''');
  }

  test_forLoop_nonNullable() async {
    await assertNoErrorsInCode(r'''
m() {
  List x = [];
  for (var y in x) {}
}
''');
  }

  test_forLoop_nullable() async {
    await assertErrorsInCode(r'''
m() {
  List? x;
  for (var y in x) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 28, 1),
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 33, 1),
    ]);
  }

  test_if_nonNullable() async {
    await assertNoErrorsInCode(r'''
m() {
  bool x = true;
  if (x) {}
}
''');
  }

  test_if_nullable() async {
    await assertErrorsInCode(r'''
m() {
  bool? x;
  if (x) {}
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 23, 1),
    ]);
  }

  test_index_nonNullable() async {
    await assertNoErrorsInCode(r'''
m() {
  List x = [1];
  x[0];
}
''');
  }

  test_index_nullable() async {
    await assertErrorsInCode(r'''
m() {
  List? x;
  x[0];
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 19, 1),
    ]);
  }

  test_invoke_dynamicFunctionType_nonNullable() async {
    await assertNoErrorsInCode(r'''
m() {
  Function x = () {};
  x();
}
''');
  }

  test_invoke_dynamicFunctionType_nullable() async {
    await assertErrorsInCode(r'''
m() {
  Function? x;
  x();
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 23, 1),
    ]);
  }

  test_invoke_nonNullable() async {
    await assertNoErrorsInCode(r'''
m() {
  Function() x = () {};
  x();
}
''');
  }

  test_invoke_nullable() async {
    await assertErrorsInCode(r'''
m() {
  Function()? x;
  x();
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 25, 1),
    ]);
  }

  test_invoke_parenthesized_nonNullable() async {
    await assertNoErrorsInCode(r'''
m() {
  Function x = () {};
  (x)();
}
''');
  }

  test_is_nullable() async {
    await assertNoErrorsInCode(r'''
m() {
  int? x;
  x is int;
}
''');
  }

  test_member_dynamic_nullable() async {
    await assertNoErrorsInCode(r'''
m() {
  dynamic x;
  x.foo;
}
''');
  }

  test_member_hashCode_nullable() async {
    await assertNoErrorsInCode(r'''
m() {
  int? x;
  x.hashCode;
}
''');
  }

  test_member_nonNullable() async {
    await assertNoErrorsInCode(r'''
m() {
  int x = 0;
  x.isEven;
}
''');
  }

  test_member_nullable() async {
    await assertErrorsInCode(r'''
m() {
  int? x;
  x.isEven;
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 18, 1),
    ]);
  }

  test_member_parenthesized_hashCode_nullable() async {
    await assertNoErrorsInCode(r'''
m() {
  int? x;
  (x).hashCode;
}
''');
  }

  test_member_parenthesized_nullable() async {
    await assertErrorsInCode(r'''
m() {
  int? x;
  (x).isEven;
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 18, 3),
    ]);
  }

  test_member_parenthesized_runtimeType_nullable() async {
    await assertNoErrorsInCode(r'''
m() {
  int? x;
  (x).runtimeType;
}
''');
  }

  test_member_potentiallyNullable() async {
    await assertErrorsInCode(r'''
m<T extends int?>(T x) {
  x.isEven;
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 27, 1),
    ]);
  }

  test_member_potentiallyNullable_called() async {
    await assertErrorsInCode(r'''
m<T extends Function>(List<T?> x) {
  x.first();
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 40, 5),
    ]);
  }

  test_member_questionDot_nullable() async {
    await assertNoErrorsInCode(r'''
m() {
  int? x;
  x?.isEven;
}
''');
  }

  test_member_runtimeType_nullable() async {
    await assertNoErrorsInCode(r'''
m() {
  int? x;
  x.runtimeType;
}
''');
  }

  test_method_nonNullable() async {
    await assertNoErrorsInCode(r'''
m() {
  int x = 0;
  x.round();
}
''');
  }

  test_method_noSuchMethod_nullable() async {
    await assertNoErrorsInCode(r'''
m(int x) {
  x.noSuchMethod(throw '');
}
''');
  }

  test_method_nullable() async {
    await assertErrorsInCode(r'''
m() {
  int? x;
  x.round();
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 18, 1),
    ]);
  }

  test_method_questionDot_nullable() async {
    await assertNoErrorsInCode(r'''
m() {
  int? x;
  x?.round();
}
''');
  }

  test_method_toString_nullable() async {
    await assertNoErrorsInCode(r'''
m(int x) {
  x.toString();
}
''');
  }

  test_minusEq_nonNullable() async {
    await assertNoErrorsInCode(r'''
m() {
  int x = 0;
  x -= 1;
}
''');
  }

  test_minusEq_nullable() async {
    await assertErrorsInCode(r'''
m() {
  int? x;
  x -= 1;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 13, 1),
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 18, 1),
    ]);
  }

  test_not_nonNullable() async {
    await assertNoErrorsInCode(r'''
m() {
  bool x = true;
  if(!x) {}
}
''');
  }

  test_not_nullable() async {
    await assertErrorsInCode(r'''
m() {
  bool? x;
  if(!x) {}
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 23, 1),
    ]);
  }

  test_notEq_nullable() async {
    await assertNoErrorsInCode(r'''
m() {
  int? x;
  x != null;
}
''');
  }

  test_operatorMinus_nonNullable() async {
    await assertNoErrorsInCode(r'''
m() {
  int x = 0;
  x - 3;
}
''');
  }

  test_operatorMinus_nullable() async {
    await assertErrorsInCode(r'''
m() {
  int? x;
  x - 3;
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 18, 1),
    ]);
  }

  test_operatorPlus_nonNullable() async {
    await assertNoErrorsInCode(r'''
m() {
  int x = 0;
  x + 3;
}
''');
  }

  test_operatorPlus_nullable() async {
    await assertErrorsInCode(r'''
m() {
  int? x;
  x + 3;
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 18, 1),
    ]);
  }

  test_operatorPostfixDec_nonNullable() async {
    await assertNoErrorsInCode(r'''
m() {
  int x = 0;
  x--;
}
''');
  }

  test_operatorPostfixDec_nullable() async {
    await assertErrorsInCode(r'''
m() {
  int? x;
  x--;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 13, 1),
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 18, 1),
    ]);
  }

  test_operatorPostfixInc_nonNullable() async {
    await assertNoErrorsInCode(r'''
m(int x) {
  x++;
}
''');
  }

  test_operatorPostfixInc_nullable() async {
    await assertErrorsInCode(r'''
m(int? x) {
  x++;
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 14, 1),
    ]);
  }

  test_operatorPrefixDec_nonNullable() async {
    await assertNoErrorsInCode(r'''
m() {
  int x = 0;
  --x;
}
''');
  }

  test_operatorPrefixDec_nullable() async {
    await assertErrorsInCode(r'''
m() {
  int? x;
  --x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 13, 1),
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 20, 1),
    ]);
  }

  test_operatorPrefixInc_nonNullable() async {
    await assertNoErrorsInCode(r'''
m(int x) {
  ++x;
}
''');
  }

  test_operatorPrefixInc_nullable() async {
    await assertErrorsInCode(r'''
m(int? x) {
  ++x;
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 16, 1),
    ]);
  }

  test_operatorUnaryMinus_nonNullable() async {
    await assertNoErrorsInCode(r'''
m() {
  int x = 0;
  -x;
}
''');
  }

  test_operatorUnaryMinus_nullable() async {
    await assertErrorsInCode(r'''
m() {
  int? x;
  -x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 13, 1),
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 19, 1),
    ]);
  }

  test_or_nonNullable() async {
    await assertNoErrorsInCode(r'''
m() {
  bool x = true;
  if(x || false) {}
}
''');
  }

  test_or_nullable() async {
    await assertErrorsInCode(r'''
m() {
  bool? x;
  if(x || false) {}
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 22, 1),
    ]);
  }

  test_plusEq_nonNullable() async {
    await assertNoErrorsInCode(r'''
m(int x) {
  x += 1;
}
''');
  }

  test_plusEq_nullable() async {
    await assertErrorsInCode(r'''
m(int? x) {
  x += 1;
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 14, 1),
    ]);
  }

  test_read_propertyAccess2_short1() async {
    await assertErrorsInCode(r'''
class A {
  final int x;
  A(this.x);
}

m(A? a) {
  a?.x; // 1
  a.x; // 2
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 66, 1),
    ]);
    var propertyAccess1 = findNode.propertyAccess('a?.x; // 1');
    var propertyAccess2 = findNode.prefixed('a.x; // 2');
    assertType(propertyAccess1.target, 'A?');
    assertType(propertyAccess2.prefix, 'A?');

    assertType(propertyAccess1.propertyName, 'int');
    assertType(propertyAccess2.identifier, 'int');

    assertType(propertyAccess1, 'int?');
    assertType(propertyAccess2, 'int');
  }

  test_read_propertyAccess3_short1() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A(this.x);
}

class B {
  final A? a;
  B(this.a);
}

m(B b) {
  b.a?.x; // 1
  b.a.x; // 2
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 101, 3),
    ]);
    var propertyAccess1 = findNode.propertyAccess('b.a?.x; // 1');
    var propertyAccess2 = findNode.propertyAccess('b.a.x; // 2');
    assertType(propertyAccess1.target, 'A?');
    assertType(propertyAccess2.target, 'A?');

    assertType(propertyAccess1.propertyName, 'int');
    assertType(propertyAccess2.propertyName, 'int');

    assertType(propertyAccess1, 'int?');
    assertType(propertyAccess2, 'int');
  }

  test_read_propertyAccess3_short2() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A(this.x);
}

class B {
  final A a;
  B(this.a);
}

m(B? b) {
  b?.a.x; // 1
  b.a.x; // 2
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 101, 1),
    ]);
    var propertyAccess1 = findNode.propertyAccess('x; // 1');
    var propertyAccess2 = findNode.propertyAccess('x; // 2');
    assertType(propertyAccess1.target, 'A');
    assertType(propertyAccess2.target, 'A');

    assertType(propertyAccess1.propertyName, 'int');
    assertType(propertyAccess2.propertyName, 'int');

    assertType(propertyAccess1, 'int?');
    assertType(propertyAccess2, 'int');
  }

  test_read_propertyAccess4_short1() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A(this.x);
}

class B {
  final A? a;
  B(this.a);
}

class C {
  final B b;
  C(this.b);
}

m(C c) {
  c.b.a?.x; // 1
  c.b.a.x; // 2
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 142, 5),
    ]);
    var propertyAccess1 = findNode.propertyAccess('x; // 1');
    var propertyAccess2 = findNode.propertyAccess('x; // 2');
    assertType(propertyAccess1.target, 'A?');
    assertType(propertyAccess2.target, 'A?');

    assertType(propertyAccess1.propertyName, 'int');
    assertType(propertyAccess2.propertyName, 'int');

    assertType(propertyAccess1, 'int?');
    assertType(propertyAccess2, 'int');
  }

  test_read_propertyAccess4_short2() async {
    await assertErrorsInCode(r'''
class A {
  final int x;
  A(this.x);
}

class B {
  final A a;
  B(this.a);
}

class C {
  final B? b;
  C(this.b);
}

m(C c) {
  c.b?.a.x; // 1
  c.b.a.x; // 2
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 148, 3),
    ]);
    var propertyAccess1 = findNode.propertyAccess('x; // 1');
    var propertyAccess2 = findNode.propertyAccess('x; // 2');
    PropertyAccess propertyAccess1t = propertyAccess1.target;
    PropertyAccess propertyAccess2t = propertyAccess1.target;
    assertType(propertyAccess1t.target, 'B?');
    assertType(propertyAccess2t.target, 'B?');
    assertType(propertyAccess1t, 'A');
    assertType(propertyAccess2t, 'A');

    assertType(propertyAccess1.propertyName, 'int');
    assertType(propertyAccess2.propertyName, 'int');

    assertType(propertyAccess1, 'int?');
    assertType(propertyAccess2, 'int');
  }

  test_spread_nonNullable() async {
    await assertNoErrorsInCode(r'''
m() {
  var list = [];
  [...list];
}
''');
  }

  test_spread_nullable() async {
    await assertErrorsInCode(r'''
m() {
  List? list;
  [...list];
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 26, 4),
    ]);
  }

  test_spread_nullable_question() async {
    await assertNoErrorsInCode(r'''
m() {
  List? list;
  [...?list];
}
''');
  }

  test_ternary_condition_nullable() async {
    await assertErrorsInCode(r'''
m() {
  bool? x;
  x ? 0 : 1;
}
''', [
      error(StaticWarningCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 19, 1),
    ]);
  }

  test_ternary_lhs_nullable() async {
    await assertNoErrorsInCode(r'''
m(bool cond) {
  int? x;
  cond ? x : 1;
}
''');
  }

  test_ternary_rhs_nullable() async {
    await assertNoErrorsInCode(r'''
m(bool cond) {
  int? x;
  cond ? 0 : x;
}
''');
  }
}
