// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfNullValueTest);
    defineReflectiveTests(UncheckedUseOfNullableValueTest);
    defineReflectiveTests(UncheckedUseOfNullableValueInsideExtensionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class InvalidUseOfNullValueTest extends PubPackageResolutionTest {
  test_as() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  Null x;
  x as int;
//^^^^^^^^
// [diag.castFromNullAlwaysFails] This cast always throws an exception because the expression always evaluates to 'null'.
}
''');
  }

  test_await() async {
    await resolveTestCodeWithDiagnostics(r'''
m() async {
  Null x;
  await x;
}
''');
  }

  test_cascade() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  Null x;
  x..toString;
}
''');
  }

  test_eq() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  Null x;
  x == null;
//^^^^
// [diag.unnecessaryNullComparisonAlwaysNullTrue] The operand must be 'null', so the condition is always 'true'.
}
''');
  }

  test_forLoop() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  Null x;
  for (var y in x) {}
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
//              ^
// [diag.invalidUseOfNullValue] An expression whose value is always 'null' can't be dereferenced.
}
''');
  }

  test_is() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  Null x;
  x is int;
}
''');
  }

  test_member() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  Null x;
  x.runtimeType;
}
''');
  }

  test_method() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  Null x;
  x.toString();
}
''');
  }

  test_notEq() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  Null x;
  x != null;
//^^^^
// [diag.unnecessaryNullComparisonAlwaysNullFalse] The operand must be 'null', so the condition is always 'false'.
}
''');
  }

  test_ternary_lhs() async {
    await resolveTestCodeWithDiagnostics(r'''
m(bool cond) {
  Null x;
  cond ? x : 1;
}
''');
  }

  test_ternary_rhs() async {
    await resolveTestCodeWithDiagnostics(r'''
m(bool cond) {
  Null x;
  cond ? 0 : x;
}
''');
  }
}

@reflectiveTest
class UncheckedUseOfNullableValueInsideExtensionTest
    extends PubPackageResolutionTest {
  test_indexExpression_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator[](int index) => 0;

  operator[]=(int index, int value) {}
}

extension E on A? {
  void bar() {
    this[0];
//      ^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '[]' can't be unconditionally invoked because the receiver can be 'null'.
    this?[0];

    this[0] = 0;
//      ^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '[]' can't be unconditionally invoked because the receiver can be 'null'.
    this?[0] = 0;
  }
}
''');
  }

  test_methodInvocation_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}

extension E on A? {
  void bar() {
    foo();
//  ^^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method 'foo' can't be unconditionally invoked because the receiver can be 'null'.
    this.foo();
//       ^^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method 'foo' can't be unconditionally invoked because the receiver can be 'null'.
    this?.foo();

    bar();
    this.bar();
    this?.bar();
  }
}
''');
  }

  test_methodInvocation_nuverNullable_extensionMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
extension<X> on X {
  X m() => this;
}

Future<void> f(Never? x) async {
  (await x).m();
}
''');
  }

  test_prefixExpression_minus_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A operator-() => this;
}

extension E on A? {
  void bar() {
    -this;
//  ^
// [diag.uncheckedMethodInvocationOfNullableValue] The method 'unary-' can't be unconditionally invoked because the receiver can be 'null'.
  }
}
''');
  }

  test_propertyAccess_getter_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}

extension E on A? {
  int get bar => 0;

  void baz() {
    foo;
//  ^^^
// [diag.uncheckedPropertyAccessOfNullableValue] The property 'foo' can't be unconditionally accessed because the receiver can be 'null'.
    this.foo;
//       ^^^
// [diag.uncheckedPropertyAccessOfNullableValue] The property 'foo' can't be unconditionally accessed because the receiver can be 'null'.
    this?.foo;

    bar;
    this.bar;
    this?.bar;
  }
}
''');
  }

  test_propertyAccess_setter_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set foo(int _) {}
}

extension E on A? {
  set bar(int _) {}

  void baz() {
    foo = 0;
//  ^^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method 'foo' can't be unconditionally invoked because the receiver can be 'null'.
    this.foo = 0;
//       ^^^
// [diag.uncheckedPropertyAccessOfNullableValue] The property 'foo' can't be unconditionally accessed because the receiver can be 'null'.
    this?.foo = 0;

    bar = 0;
    this.bar = 0;
    this?.bar = 0;
  }
}
''');
  }
}

@reflectiveTest
class UncheckedUseOfNullableValueTest extends PubPackageResolutionTest {
  test_and_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  bool x = true;
  if(x && true) {}
}
''');
  }

  test_and_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  bool? x;
  if(x && true) {}
//   ^
// [diag.uncheckedUseOfNullableValueAsCondition] A nullable expression can't be used as a condition.
}
''');
  }

  test_as_nullable_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  num? x;
  x as int;
//^
// [diag.castFromNullableAlwaysFails] This cast will always throw an exception because the nullable local variable 'x' is not assigned.
}
''');
  }

  test_as_nullable_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  num? x;
  x as String?;
}
''');
  }

  test_assert_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  bool x = true;
  assert(x);
}
''');
  }

  test_assert_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  bool? x;
  assert(x);
//       ^
// [diag.uncheckedUseOfNullableValueAsCondition] A nullable expression can't be used as a condition.
}
''');
  }

  test_assignment_eq_propertyAccess3_short1() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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
//    ^
// [diag.uncheckedPropertyAccessOfNullableValue] The property 'x' can't be unconditionally accessed because the receiver can be 'null'.
}
''');

    var node1 = result.findNode.assignment('x = 1');
    assertResolvedNodeText(node1, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: b
        element: <testLibrary>::@function::m::@formalParameter::b
        staticType: B
      period: .
      identifier: SimpleIdentifier
        token: a
        element: <testLibrary>::@class::B::@getter::a
        staticType: A?
      element: <testLibrary>::@class::B::@getter::a
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: int
  element: <null>
  staticType: int?
''');

    var node2 = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node2, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: b
        element: <testLibrary>::@function::m::@formalParameter::b
        staticType: B
      period: .
      identifier: SimpleIdentifier
        token: a
        element: <testLibrary>::@class::B::@getter::a
        staticType: A?
      element: <testLibrary>::@class::B::@getter::a
      staticType: A?
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::value
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_assignment_eq_simpleIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
m(int x, int? y) {
  x = 0;
  y = 0;
}
''');

    var node1 = result.findNode.assignment('x =');
    assertResolvedNodeText(node1, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::m::@formalParameter::x
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@function::m::@formalParameter::x
  writeType: int
  element: <null>
  staticType: int
''');

    var node2 = result.findNode.assignment('y =');
    assertResolvedNodeText(node2, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: y
    element: <testLibrary>::@function::m::@formalParameter::y
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@function::m::@formalParameter::y
  writeType: int?
  element: <null>
  staticType: int
''');
  }

  test_assignment_plusEq_propertyAccess3() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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
//      ^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '+' can't be unconditionally invoked because the receiver can be 'null'.
}
''');

    var node1 = result.findNode.assignment('x +=');
    assertResolvedNodeText(node1, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: b
        element: <testLibrary>::@function::m::@formalParameter::b
        staticType: B
      period: .
      identifier: SimpleIdentifier
        token: a
        element: <testLibrary>::@class::B::@getter::a
        staticType: A
      element: <testLibrary>::@class::B::@getter::a
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');

    var node2 = result.findNode.assignment('y +=');
    assertResolvedNodeText(node2, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: b
        element: <testLibrary>::@function::m::@formalParameter::b
        staticType: B
      period: .
      identifier: SimpleIdentifier
        token: a
        element: <testLibrary>::@class::B::@getter::a
        staticType: A
      element: <testLibrary>::@class::B::@getter::a
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: y
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::A::@getter::y
  readType: int?
  writeElement: <testLibrary>::@class::A::@setter::y
  writeType: int?
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_assignment_plusEq_propertyAccess3_short1() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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
//    ^
// [diag.uncheckedPropertyAccessOfNullableValue] The property 'x' can't be unconditionally accessed because the receiver can be 'null'.
}
''');

    var node1 = result.findNode.assignment('x += 1');
    assertResolvedNodeText(node1, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: b
        element: <testLibrary>::@function::m::@formalParameter::b
        staticType: B
      period: .
      identifier: SimpleIdentifier
        token: a
        element: <testLibrary>::@class::B::@getter::a
        staticType: A?
      element: <testLibrary>::@class::B::@getter::a
      staticType: A?
    operator: ?.
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int?
''');

    var node2 = result.findNode.assignment('x += 2');
    assertResolvedNodeText(node2, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: b
        element: <testLibrary>::@function::m::@formalParameter::b
        staticType: B
      period: .
      identifier: SimpleIdentifier
        token: a
        element: <testLibrary>::@class::B::@getter::a
        staticType: A?
      element: <testLibrary>::@class::B::@getter::a
      staticType: A?
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_assignment_plusEq_simpleIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
m(int x, int? y) {
  x += 0;
  y += 0;
//  ^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '+' can't be unconditionally invoked because the receiver can be 'null'.
}
''');

    var node1 = result.findNode.assignment('x +=');
    assertResolvedNodeText(node1, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::m::@formalParameter::x
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@function::m::@formalParameter::x
  readType: int
  writeElement: <testLibrary>::@function::m::@formalParameter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');

    var node2 = result.findNode.assignment('y +=');
    assertResolvedNodeText(node2, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: y
    element: <testLibrary>::@function::m::@formalParameter::y
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement: <testLibrary>::@function::m::@formalParameter::y
  readType: int?
  writeElement: <testLibrary>::@function::m::@formalParameter::y
  writeType: int?
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_await_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() async {
  Future x = Future.value(null);
  await x;
}
''');
  }

  test_await_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() async {
  Future? x;
  await x;
}
''');
  }

  test_cascade_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  int x = 0;
  x..isEven;
}
''');
  }

  test_cascade_nullable_indexed_assignment() async {
    await resolveTestCodeWithDiagnostics(r'''
f(List<int>? x) {
  x..[0] = 1;
//   ^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '[]' can't be unconditionally invoked because the receiver can be 'null'.
}
''');
  }

  test_cascade_nullable_indexed_assignment_null_aware() async {
    await resolveTestCodeWithDiagnostics(r'''
f(List<int>? x) {
  x?..[0] = 1;
}
''');
  }

  test_cascade_nullable_method_invocation() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int? x;
  x..abs();
//   ^^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method 'abs' can't be unconditionally invoked because the receiver can be 'null'.
}
''');
  }

  test_cascade_nullable_method_invocation_null_aware() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int? x) {
  x?..abs();
}
''');
  }

  test_cascade_nullable_property_access() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int? x) {
  x..isEven;
//   ^^^^^^
// [diag.uncheckedPropertyAccessOfNullableValue] The property 'isEven' can't be unconditionally accessed because the receiver can be 'null'.
}
''');
  }

  test_cascade_nullable_property_access_null_aware() async {
    await resolveTestCodeWithDiagnostics(r'''
m(int? x) {
  x?..isEven;
}
''');
  }

  test_eqEq_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int? x;
  x == null;
//^^^^
// [diag.unnecessaryNullComparisonAlwaysNullTrue] The operand must be 'null', so the condition is always 'true'.
}
''');
  }

  test_forLoop_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  List x = [];
  for (var y in x) {}
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
}
''');
  }

  test_forLoop_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  List? x;
  for (var y in x) {}
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
//              ^
// [diag.uncheckedUseOfNullableValueAsIterator] A nullable expression can't be used as an iterator in a for-in loop.
}
''');
  }

  test_forLoop_pattern_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  List? x;
  for (var (y) in x) {}
//          ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
//                ^
// [diag.uncheckedUseOfNullableValueAsIterator] A nullable expression can't be used as an iterator in a for-in loop.
}
''');
  }

  test_getter_nullable_nonNullableExtension() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get foo => 0;
}

m(int? x) {
  x.foo;
//  ^^^
// [diag.uncheckedPropertyAccessOfNullableValue] The property 'foo' can't be unconditionally accessed because the receiver can be 'null'.
}
''');
  }

  test_if_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  bool x = true;
  if (x) {}
}
''');
  }

  test_if_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  bool? x;
  if (x) {}
//    ^
// [diag.uncheckedUseOfNullableValueAsCondition] A nullable expression can't be used as a condition.
}
''');
  }

  test_index_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  List x = [1];
  x[0];
}
''');
  }

  test_index_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  List? x;
  x[0];
// ^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '[]' can't be unconditionally invoked because the receiver can be 'null'.
}
''');
  }

  test_invoke_dynamicFunctionType_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  Function x = () {};
  x();
}
''');
  }

  test_invoke_dynamicFunctionType_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  Function? x;
  x();
//^
// [diag.uncheckedInvocationOfNullableValue] The function can't be unconditionally invoked because it can be 'null'.
}
''');
  }

  test_invoke_dynamicFunctionType_nullable2() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<F extends Function>(List<F?> funcList) {
  funcList[0]();
//^^^^^^^^^^^
// [diag.uncheckedInvocationOfNullableValue] The function can't be unconditionally invoked because it can be 'null'.
}
''');
  }

  test_invoke_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  Function() x = () {};
  x();
}
''');
  }

  test_invoke_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  Function()? x;
  x();
//^
// [diag.uncheckedInvocationOfNullableValue] The function can't be unconditionally invoked because it can be 'null'.
}
''');
  }

  test_invoke_parenthesized_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  Function x = () {};
  (x)();
}
''');
  }

  test_is_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int? x;
  x is int;
}
''');
  }

  test_member_dynamic_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  dynamic x;
  x.foo;
}
''');
  }

  test_member_hashCode_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int? x;
  x.hashCode;
}
''');
  }

  test_member_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int x = 0;
  x.isEven;
}
''');
  }

  test_member_nullable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
m() {
  int? x;
  x.isEven;
//  ^^^^^^
// [diag.uncheckedPropertyAccessOfNullableValue] The property 'isEven' can't be unconditionally accessed because the receiver can be 'null'.
}
''');

    var node = result.findNode.simple('isEven;');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: isEven
  element: dart:core::@class::int::@getter::isEven
  staticType: bool
''');
  }

  test_member_parenthesized_hashCode_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int? x;
  (x).hashCode;
}
''');
  }

  test_member_parenthesized_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int? x;
  (x).isEven;
//    ^^^^^^
// [diag.uncheckedPropertyAccessOfNullableValue] The property 'isEven' can't be unconditionally accessed because the receiver can be 'null'.
}
''');
  }

  test_member_parenthesized_runtimeType_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int? x;
  (x).runtimeType;
}
''');
  }

  test_member_potentiallyNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m<T extends int?>(T x) {
  x.isEven;
//  ^^^^^^
// [diag.uncheckedPropertyAccessOfNullableValue] The property 'isEven' can't be unconditionally accessed because the receiver can be 'null'.
}
''');
  }

  test_member_potentiallyNullable_called() async {
    await resolveTestCodeWithDiagnostics(r'''
m<T extends Function>(List<T?> x) {
  x.first();
//^^^^^^^
// [diag.uncheckedInvocationOfNullableValue] The function can't be unconditionally invoked because it can be 'null'.
}
''');
  }

  test_member_questionDot_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int? x) {
  x?.isEven;
}
''');
  }

  test_member_runtimeType_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int? x;
  x.runtimeType;
}
''');
  }

  test_method_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int x = 0;
  x.round();
}
''');
  }

  test_method_noSuchMethod_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m(int x) {
  x.noSuchMethod(throw '');
}
''');
  }

  test_method_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int? x;
  x.round();
//  ^^^^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method 'round' can't be unconditionally invoked because the receiver can be 'null'.
}
''');
  }

  test_method_nullable_notNullableExtension() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void foo() {}
}

m(int? x) {
  x.foo();
//  ^^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method 'foo' can't be unconditionally invoked because the receiver can be 'null'.
}
''');
  }

  test_method_questionDot_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m(int? x) {
  x?.round();
}
''');
  }

  test_method_toString_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m(int x) {
  x.toString();
}
''');
  }

  test_methodInvocation_call_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m(Function x) {
  x.call();
}
''');
  }

  test_methodInvocation_call_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m(Function? x) {
  x.call();
//  ^^^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method 'call' can't be unconditionally invoked because the receiver can be 'null'.
}
''');
  }

  test_minusEq_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int x = 0;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x -= 1;
}
''');
  }

  test_minusEq_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int? x;
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x -= 1;
//  ^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '-' can't be unconditionally invoked because the receiver can be 'null'.
}
''');
  }

  test_not_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  bool x = true;
  if(!x) {}
//       ^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_not_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  bool? x;
  if(!x) {}
//    ^
// [diag.uncheckedUseOfNullableValueAsCondition] A nullable expression can't be used as a condition.
}
''');
  }

  test_notEq_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int? x;
  x != null;
//^^^^
// [diag.unnecessaryNullComparisonAlwaysNullFalse] The operand must be 'null', so the condition is always 'false'.
}
''');
  }

  test_nullable_dotQ_propertyAccess_dot_methodInvocation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}

void f(A? a) {
  a?.foo.abs();
}
''');
    assertType(result.findNode.propertyAccess('.foo'), 'int');
    assertType(result.findNode.methodInvocation('.abs()'), 'int?');
  }

  test_nullable_dotQ_propertyAccess_dot_propertyAccess() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
}

void f(A? a) {
  a?.foo.isEven;
}
''');
    assertType(result.findNode.propertyAccess('.foo'), 'int');
    assertType(result.findNode.propertyAccess('.isEven'), 'bool?');
  }

  test_operatorMinus_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int x = 0;
  x - 3;
}
''');
  }

  test_operatorMinus_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int? x;
  x - 3;
//  ^
// [diag.uncheckedOperatorInvocationOfNullableValue] The operator '-' can't be unconditionally invoked because the receiver can be 'null'.
}
''');
  }

  test_operatorPlus_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int x = 0;
  x + 3;
}
''');
  }

  test_operatorPlus_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int? x;
  x + 3;
//  ^
// [diag.uncheckedOperatorInvocationOfNullableValue] The operator '+' can't be unconditionally invoked because the receiver can be 'null'.
}
''');
  }

  test_operatorPostfixDec_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int x = 0;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x--;
}
''');
  }

  test_operatorPostfixDec_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int? x;
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  x--;
// ^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '-' can't be unconditionally invoked because the receiver can be 'null'.
}
''');
  }

  test_operatorPostfixInc_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m(int x) {
  x++;
}
''');
  }

  test_operatorPostfixInc_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m(int? x) {
  x++;
// ^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '+' can't be unconditionally invoked because the receiver can be 'null'.
}
''');
  }

  test_operatorPostfixInc_nullable_nonNullableExtension() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

extension E on A {
  A operator +(int _) => this;
}

m(A? x) {
  x++;
// ^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '+' can't be unconditionally invoked because the receiver can be 'null'.
}
''');
  }

  test_operatorPrefixDec_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int x = 0;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  --x;
}
''');
  }

  test_operatorPrefixDec_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int? x;
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  --x;
//^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '-' can't be unconditionally invoked because the receiver can be 'null'.
}
''');
  }

  test_operatorPrefixInc_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m(int x) {
  ++x;
}
''');
  }

  test_operatorPrefixInc_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m(int? x) {
  ++x;
//^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '+' can't be unconditionally invoked because the receiver can be 'null'.
}
''');
  }

  test_operatorUnaryMinus_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int x = 0;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  -x;
}
''');
  }

  test_operatorUnaryMinus_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  int? x;
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
  -x;
//^
// [diag.uncheckedMethodInvocationOfNullableValue] The method 'unary-' can't be unconditionally invoked because the receiver can be 'null'.
}
''');
  }

  test_operatorUnaryMinus_nullable_nonNullableExtension() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

extension E on A {
  A operator -() => this;
}

m(A? x) {
  -x;
//^
// [diag.uncheckedMethodInvocationOfNullableValue] The method 'unary-' can't be unconditionally invoked because the receiver can be 'null'.
}
''');
  }

  test_or_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  bool x = true;
  if(x || false) {}
//     ^^^^^^^^
// [diag.deadCode] Dead code.
}
''');
  }

  test_or_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  bool? x;
  if(x || false) {}
//   ^
// [diag.uncheckedUseOfNullableValueAsCondition] A nullable expression can't be used as a condition.
}
''');
  }

  test_plusEq_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m(int x) {
  x += 1;
}
''');
  }

  test_plusEq_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m(int? x) {
  x += 1;
//  ^^
// [diag.uncheckedMethodInvocationOfNullableValue] The method '+' can't be unconditionally invoked because the receiver can be 'null'.
}
''');
  }

  test_read_propertyAccess2_short1() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x;
  A(this.x);
}

m(A? a) {
  a?.x; // 1
  a.x; // 2
//  ^
// [diag.uncheckedPropertyAccessOfNullableValue] The property 'x' can't be unconditionally accessed because the receiver can be 'null'.
}
''');
    var propertyAccess1 = result.findNode.propertyAccess('a?.x; // 1');
    var propertyAccess2 = result.findNode.prefixed('a.x; // 2');
    assertType(propertyAccess1.target, 'A?');
    assertType(propertyAccess2.prefix, 'A?');

    assertType(propertyAccess1.propertyName, 'int');
    assertType(propertyAccess2.identifier, 'int');

    assertType(propertyAccess1, 'int?');
    assertType(propertyAccess2, 'int');
  }

  test_read_propertyAccess3_short1() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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
//    ^
// [diag.uncheckedPropertyAccessOfNullableValue] The property 'x' can't be unconditionally accessed because the receiver can be 'null'.
}
''');
    var propertyAccess1 = result.findNode.propertyAccess('b.a?.x; // 1');
    var propertyAccess2 = result.findNode.propertyAccess('b.a.x; // 2');
    assertType(propertyAccess1.target, 'A?');
    assertType(propertyAccess2.target, 'A?');

    assertType(propertyAccess1.propertyName, 'int');
    assertType(propertyAccess2.propertyName, 'int');

    assertType(propertyAccess1, 'int?');
    assertType(propertyAccess2, 'int');
  }

  test_read_propertyAccess3_short2() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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
//  ^
// [diag.uncheckedPropertyAccessOfNullableValue] The property 'a' can't be unconditionally accessed because the receiver can be 'null'.
}
''');
    var propertyAccess1 = result.findNode.propertyAccess('x; // 1');
    var propertyAccess2 = result.findNode.propertyAccess('x; // 2');
    assertType(propertyAccess1.target, 'A');
    assertType(propertyAccess2.target, 'A');

    assertType(propertyAccess1.propertyName, 'int');
    assertType(propertyAccess2.propertyName, 'int');

    assertType(propertyAccess1, 'int?');
    assertType(propertyAccess2, 'int');
  }

  test_read_propertyAccess4_short1() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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
//      ^
// [diag.uncheckedPropertyAccessOfNullableValue] The property 'x' can't be unconditionally accessed because the receiver can be 'null'.
}
''');
    var propertyAccess1 = result.findNode.propertyAccess('x; // 1');
    var propertyAccess2 = result.findNode.propertyAccess('x; // 2');
    assertType(propertyAccess1.target, 'A?');
    assertType(propertyAccess2.target, 'A?');

    assertType(propertyAccess1.propertyName, 'int');
    assertType(propertyAccess2.propertyName, 'int');

    assertType(propertyAccess1, 'int?');
    assertType(propertyAccess2, 'int');
  }

  test_read_propertyAccess4_short2() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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
//    ^
// [diag.uncheckedPropertyAccessOfNullableValue] The property 'a' can't be unconditionally accessed because the receiver can be 'null'.
}
''');
    var propertyAccess1 = result.findNode.propertyAccess('x; // 1');
    var propertyAccess2 = result.findNode.propertyAccess('x; // 2');
    var propertyAccess1t = propertyAccess1.target as PropertyAccess;
    var propertyAccess2t = propertyAccess1.target as PropertyAccess;
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
    await resolveTestCodeWithDiagnostics(r'''
m() {
  var list = [];
  [...list];
}
''');
  }

  test_spread_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  List? list;
  [...list];
//    ^^^^
// [diag.uncheckedUseOfNullableValueInSpread] A nullable expression can't be used in a spread.
}
''');
  }

  test_spread_nullable_question() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  List? list;
  [...?list];
}
''');
  }

  test_ternary_condition_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() {
  bool? x;
  x ? 0 : 1;
//^
// [diag.uncheckedUseOfNullableValueAsCondition] A nullable expression can't be used as a condition.
}
''');
  }

  test_ternary_lhs_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m(bool cond) {
  int? x;
  cond ? x : 1;
}
''');
  }

  test_ternary_rhs_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m(bool cond) {
  int? x;
  cond ? 0 : x;
}
''');
  }

  test_tripleShift_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m(String? s) {
  s?.length >>> 2;
//          ^^^
// [diag.uncheckedOperatorInvocationOfNullableValue] The operator '>>>' can't be unconditionally invoked because the receiver can be 'null'.
}
''');
  }

  test_uncheckedOperatorInvocation_relationalPattern() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? x) {
  if (x case > 0) {}
//           ^
// [diag.uncheckedOperatorInvocationOfNullableValue] The operator '>' can't be unconditionally invoked because the receiver can be 'null'.
}
''');
  }

  test_uncheckedOperatorInvocation_relationalPattern_hasExtension() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? x) {
  if (x case > 0) {}
}

extension on int? {
  bool operator >(int other) => true;
}
''');
  }

  test_yieldEach_nonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() sync* {
  List<int> x = [];
  yield* x;
}
''');
  }

  test_yieldEach_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
m() sync* {
  List<int>? x;
  yield* x;
//       ^
// [diag.uncheckedUseOfNullableValueInYieldEach] A nullable expression can't be used in a yield-each statement.
// [diag.yieldEachOfInvalidType] The type 'List<int>?' implied by the 'yield*' expression must be assignable to 'Iterable<dynamic>'.
}
''');
  }
}
