// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfNullValueTest);
    defineReflectiveTests(UncheckedUseOfNullableValueTest);
    defineReflectiveTests(UncheckedUseOfNullableValueInsideExtensionTest);
  });
}

@reflectiveTest
class InvalidUseOfNullValueTest extends PubPackageResolutionTest
    with WithNullSafetyMixin {
  test_as() async {
    await assertNoErrorsInCode(r'''
m() {
  Null x;
  x as int; // ignore: unnecessary_cast
}
''');
  }

  test_await() async {
    await assertNoErrorsInCode(r'''
m() async {
  Null x;
  await x;
}
''');
  }

  test_cascade() async {
    await assertNoErrorsInCode(r'''
m() {
  Null x;
  x..toString;
}
''');
  }

  test_eq() async {
    await assertNoErrorsInCode(r'''
m() {
  Null x;
  x == null;
}
''');
  }

  test_forLoop() async {
    await assertErrorsInCode(r'''
m() {
  Null x;
  for (var y in x) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 27, 1),
      error(CompileTimeErrorCode.INVALID_USE_OF_NULL_VALUE, 32, 1),
    ]);
  }

  test_is() async {
    await assertNoErrorsInCode(r'''
m() {
  Null x;
  x is int;
}
''');
  }

  test_member() async {
    await assertNoErrorsInCode(r'''
m() {
  Null x;
  x.runtimeType;
}
''');
  }

  test_method() async {
    await assertNoErrorsInCode(r'''
m() {
  Null x;
  x.toString();
}
''');
  }

  test_notEq() async {
    await assertNoErrorsInCode(r'''
m() {
  Null x;
  x != null;
}
''');
  }

  test_ternary_lhs() async {
    await assertNoErrorsInCode(r'''
m(bool cond) {
  Null x;
  cond ? x : 1;
}
''');
  }

  test_ternary_rhs() async {
    await assertNoErrorsInCode(r'''
m(bool cond) {
  Null x;
  cond ? 0 : x;
}
''');
  }
}

@reflectiveTest
class UncheckedUseOfNullableValueInsideExtensionTest
    extends PubPackageResolutionTest with WithNullSafetyMixin {
  test_indexExpression_nonNullable() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;

  operator[]=(int index, int value) {}
}

extension E on A {
  void bar() {
    this[0];

    this[0] = 0;
  }
}
''');
  }

  test_indexExpression_nullable() async {
    await assertErrorsInCode(r'''
class A {
  int operator[](int index) => 0;

  operator[]=(int index, int value) {}
}

extension E on A? {
  void bar() {
    this[0];
    this?[0];

    this[0] = 0;
    this?[0] = 0;
  }
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 126, 4),
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 154, 4),
    ]);
  }

  test_methodInvocation_nonNullable() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
}

extension E on A {
  void bar() {
    foo();
    this.foo();

    bar();
    this.bar();
  }
}
''');
  }

  test_methodInvocation_nullable() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}

extension E on A? {
  void bar() {
    foo();
    this.foo();
    this?.foo();

    bar();
    this.bar();
    this?.bar();
  }
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 68, 3),
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 79, 4),
    ]);
  }

  test_prefixExpression_minus_nonNullable() async {
    await assertNoErrorsInCode(r'''
class A {
  A operator-() => this;
}

extension E on A {
  void bar() {
    -this;
  }
}
''');
  }

  test_prefixExpression_minus_nullable() async {
    await assertErrorsInCode(r'''
class A {
  A operator-() => this;
}

extension E on A? {
  void bar() {
    -this;
  }
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 78, 4),
    ]);
  }

  test_propertyAccess_getter_nonNullable() async {
    await assertNoErrorsInCode(r'''
class A {
  int get foo => 0;
}

extension E on A {
  int get bar => 0;

  void baz() {
    foo;
    this.foo;

    bar;
    this.bar;
  }
}
''');
  }

  test_propertyAccess_getter_nullable() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}

extension E on A? {
  int get bar => 0;

  void baz() {
    foo;
    this.foo;
    this?.foo;

    bar;
    this.bar;
    this?.bar;
  }
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 93, 3),
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 102, 4),
    ]);
  }

  test_propertyAccess_setter_nonNullable() async {
    await assertNoErrorsInCode(r'''
class A {
  set foo(int _) {}
}

extension E on A {
  set bar(int _) {}

  void baz() {
    foo = 0;
    this.foo = 0;

    bar = 0;
    this.bar = 0;
  }
}
''');
  }

  test_propertyAccess_setter_nullable() async {
    await assertErrorsInCode(r'''
class A {
  set foo(int _) {}
}

extension E on A? {
  set bar(int _) {}

  void baz() {
    foo = 0;
    this.foo = 0;
    this?.foo = 0;

    bar = 0;
    this.bar = 0;
    this?.bar = 0;
  }
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 93, 3),
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 106, 4),
    ]);
  }
}

@reflectiveTest
class UncheckedUseOfNullableValueTest extends PubPackageResolutionTest
    with WithNullSafetyMixin {
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 22, 1),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 26, 1),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 100, 3),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 109, 5),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 101, 3),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 31, 1),
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

  test_cascade_nullable_indexed_assignment() async {
    await assertErrorsInCode(r'''
m() {
  List<int>? x;
  x..[0] = 1;
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 24, 1),
    ]);
  }

  test_cascade_nullable_indexed_assignment_null_aware() async {
    await assertNoErrorsInCode(r'''
m() {
  List<int>? x;
  x?..[0] = 1;
}
''');
  }

  test_cascade_nullable_method_invocation() async {
    await assertErrorsInCode(r'''
m() {
  int? x;
  x..abs();
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 18, 1),
    ]);
  }

  test_cascade_nullable_method_invocation_null_aware() async {
    await assertNoErrorsInCode(r'''
m() {
  int? x;
  x?..abs();
}
''');
  }

  test_cascade_nullable_property_access() async {
    await assertErrorsInCode(r'''
m() {
  int? x;
  x..isEven;
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 18, 1),
    ]);
  }

  test_cascade_nullable_property_access_null_aware() async {
    await assertNoErrorsInCode(r'''
m() {
  int? x;
  x?..isEven;
}
''');
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
    await assertErrorsInCode(r'''
m() {
  List x = [];
  for (var y in x) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 32, 1),
    ]);
  }

  test_forLoop_nullable() async {
    await assertErrorsInCode(r'''
m() {
  List? x;
  for (var y in x) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 28, 1),
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 33, 1),
    ]);
  }

  test_getter_nullable_nonNullableExtension() async {
    await assertErrorsInCode(r'''
extension E on int {
  int get foo => 0;
}

m(int? x) {
  x.foo;
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 58, 1),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 23, 1),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 19, 1),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 23, 1),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 25, 1),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 18, 1),
    ]);
    assertSimpleIdentifier(
      findNode.simple('isEven'),
      readElement: intElement.getGetter('isEven'),
      writeElement: null,
      type: 'bool',
    );
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 18, 3),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 27, 1),
    ]);
  }

  test_member_potentiallyNullable_called() async {
    await assertErrorsInCode(r'''
m<T extends Function>(List<T?> x) {
  x.first();
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 38, 7),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 18, 1),
    ]);
  }

  test_method_nullable_notNullableExtension() async {
    await assertErrorsInCode(r'''
extension E on int {
  void foo() {}
}

m(int? x) {
  x.foo();
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 54, 1),
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

  test_methodInvocation_call_nonNullable() async {
    await assertNoErrorsInCode(r'''
m(Function x) {
  x.call();
}
''');
  }

  test_methodInvocation_call_nullable() async {
    await assertErrorsInCode(r'''
m(Function? x) {
  x.call();
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 19, 1),
    ]);
  }

  test_minusEq_nonNullable() async {
    await assertErrorsInCode(r'''
m() {
  int x = 0;
  x -= 1;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 12, 1),
    ]);
  }

  test_minusEq_nullable() async {
    await assertErrorsInCode(r'''
m() {
  int? x;
  x -= 1;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 13, 1),
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 18, 1),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 23, 1),
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

  test_nullable_dotQ_propertyAccess_dot_methodInvocation() async {
    await assertNoErrorsInCode(r'''
class A {
  int get foo => 0;
}

void f(A? a) {
  a?.foo.abs();
}
''');
    assertType(findNode.propertyAccess('.foo'), 'int');
    assertType(findNode.methodInvocation('.abs()'), 'int?');
  }

  test_nullable_dotQ_propertyAccess_dot_propertyAccess() async {
    await assertNoErrorsInCode(r'''
class A {
  int get foo => 0;
}

void f(A? a) {
  a?.foo.isEven;
}
''');
    assertType(findNode.propertyAccess('.foo'), 'int');
    assertType(findNode.propertyAccess('.isEven'), 'bool?');
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 18, 1),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 18, 1),
    ]);
  }

  test_operatorPostfixDec_nonNullable() async {
    await assertErrorsInCode(r'''
m() {
  int x = 0;
  x--;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 12, 1),
    ]);
  }

  test_operatorPostfixDec_nullable() async {
    await assertErrorsInCode(r'''
m() {
  int? x;
  x--;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 13, 1),
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 18, 1),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 14, 1),
    ]);
  }

  test_operatorPostfixInc_nullable_nonNullableExtension() async {
    await assertErrorsInCode(r'''
class A {}

extension E on A {
  A operator +(int _) => this;
}

m(A? x) {
  x++;
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 77, 1),
    ]);
  }

  test_operatorPrefixDec_nonNullable() async {
    await assertErrorsInCode(r'''
m() {
  int x = 0;
  --x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 12, 1),
    ]);
  }

  test_operatorPrefixDec_nullable() async {
    await assertErrorsInCode(r'''
m() {
  int? x;
  --x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 13, 1),
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 20, 1),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 16, 1),
    ]);
  }

  test_operatorUnaryMinus_nonNullable() async {
    await assertErrorsInCode(r'''
m() {
  int x = 0;
  -x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 12, 1),
    ]);
  }

  test_operatorUnaryMinus_nullable() async {
    await assertErrorsInCode(r'''
m() {
  int? x;
  -x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 13, 1),
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 19, 1),
    ]);
  }

  test_operatorUnaryMinus_nullable_nonNullableExtension() async {
    await assertErrorsInCode(r'''
class A {}

extension E on A {
  A operator -() => this;
}

m(A? x) {
  -x;
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 73, 1),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 22, 1),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 14, 1),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 66, 1),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 101, 3),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 101, 1),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 142, 5),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 148, 3),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 26, 4),
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
      error(CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE, 19, 1),
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
