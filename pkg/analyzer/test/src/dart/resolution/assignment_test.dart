// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentExpressionResolutionTest);
  });
}

@reflectiveTest
class AssignmentExpressionResolutionTest extends PubPackageResolutionTest {
  test_compound_plus_int_context_int() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  a += f();
}
''');

    final node = findNode.assignment('+= f()');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    staticElement: self::@function::g::@parameter::a
    staticType: null
  operator: +=
  rightHandSide: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      staticElement: self::@function::f
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticInvokeType: int Function()
    staticType: int
    typeArgumentTypes
      int
  readElement: self::@function::g::@parameter::a
  readType: int
  writeElement: self::@function::g::@parameter::a
  writeType: int
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_compound_plus_int_context_int_complex() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(List<int> a) {
  a[0] += f();
}
''');

    final node = findNode.assignment('+= f()');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      staticElement: self::@function::g::@parameter::a
      staticType: List<int>
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: ParameterMember
        base: dart:core::@class::List::@method::[]=::@parameter::index
        substitution: {E: int}
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      staticElement: self::@function::f
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticInvokeType: int Function()
    staticType: int
    typeArgumentTypes
      int
  readElement: MethodMember
    base: dart:core::@class::List::@method::[]
    substitution: {E: int}
  readType: int
  writeElement: MethodMember
    base: dart:core::@class::List::@method::[]=
    substitution: {E: int}
  writeType: int
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_compound_plus_int_context_int_promoted() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(num a) {
  if (a is int) {
    a += f();
  }
}
''');

    final node = findNode.assignment('+= f()');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    staticElement: self::@function::g::@parameter::a
    staticType: null
  operator: +=
  rightHandSide: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      staticElement: self::@function::f
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticInvokeType: int Function()
    staticType: int
    typeArgumentTypes
      int
  readElement: self::@function::g::@parameter::a
  readType: int
  writeElement: self::@function::g::@parameter::a
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_compound_plus_int_context_int_promoted_with_subsequent_demotion() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(num a, bool b) {
  if (a is int) {
    a += b ? f() : 1.0;
    a;
  }
}
''');

    final node = findNode.assignment('+=');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    staticElement: self::@function::g::@parameter::a
    staticType: null
  operator: +=
  rightHandSide: ConditionalExpression
    condition: SimpleIdentifier
      token: b
      staticElement: self::@function::g::@parameter::b
      staticType: bool
    question: ?
    thenExpression: MethodInvocation
      methodName: SimpleIdentifier
        token: f
        staticElement: self::@function::f
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: int Function()
      staticType: int
      typeArgumentTypes
        int
    colon: :
    elseExpression: DoubleLiteral
      literal: 1.0
      staticType: double
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: num
  readElement: self::@function::g::@parameter::a
  readType: int
  writeElement: self::@function::g::@parameter::a
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: num
''');

    assertResolvedNodeText(findNode.simple('a;'), r'''
SimpleIdentifier
  token: a
  staticElement: self::@function::g::@parameter::a
  staticType: num
''');
  }

  test_dynamicIdentifier_compound() async {
    await assertNoErrorsInCode(r'''
void f(dynamic a) {
  a += 0;
}
''');

    final node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: self::@function::f::@parameter::a
  readType: dynamic
  writeElement: self::@function::f::@parameter::a
  writeType: dynamic
  staticElement: <null>
  staticType: dynamic
''');
  }

  test_dynamicIdentifier_identifier_compound() async {
    await assertNoErrorsInCode(r'''
void f(dynamic a) {
  a.foo += 0;
}
''');

    final node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: dynamic
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: dynamic
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: dynamic
''');
  }

  test_dynamicIdentifier_identifier_identifier_compound() async {
    await assertNoErrorsInCode(r'''
void f(dynamic a) {
  a.foo.bar += 0;
}
''');

    final node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: a
        staticElement: self::@function::f::@parameter::a
        staticType: dynamic
      period: .
      identifier: SimpleIdentifier
        token: foo
        staticElement: <null>
        staticType: dynamic
      staticElement: <null>
      staticType: dynamic
    operator: .
    propertyName: SimpleIdentifier
      token: bar
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: dynamic
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: dynamic
''');
  }

  test_importPrefix_deferred_topLevelVariable_simple() async {
    newFile('$testPackageLibPath/a.dart', '''
var v = 0;
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' deferred as prefix;

void f() {
  prefix.v = 0;
}
''');

    final node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      staticElement: self::@prefix::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: v
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: package:test/a.dart::@setter::v::@parameter::_v
    staticType: int
  readElement: <null>
  readType: null
  writeElement: package:test/a.dart::@setter::v
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  test_indexExpression_cascade_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

void f(A a) {
  a..[0] += 2;
}
''');

    var assignment = findNode.assignment('[0] += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    period: ..
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: self::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::A::@method::[]
  readType: int
  writeElement: self::@class::A::@method::[]=
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_indexExpression_dynamicTarget_compound() async {
    await assertNoErrorsInCode(r'''
void f(dynamic a) {
  a[0] += 1;
}
''');

    final node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: dynamic
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: <null>
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: dynamic
  writeElement: <null>
  writeType: dynamic
  staticElement: <null>
  staticType: dynamic
''');
  }

  test_indexExpression_instance_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

void f(A a) {
  a[0] += 2;
}
''');

    var assignment = findNode.assignment('[0] += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: self::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::A::@method::[]
  readType: int
  writeElement: self::@class::A::@method::[]=
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_indexExpression_instance_compound_double_num() async {
    await assertNoErrorsInCode(r'''
class A {
  num operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

void f(A a) {
  a[0] += 2.0;
}
''');

    var assignment = findNode.assignment('[0] += 2.0');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: self::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: DoubleLiteral
    literal: 2.0
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: double
  readElement: self::@class::A::@method::[]
  readType: num
  writeElement: self::@class::A::@method::[]=
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: double
''');
  }

  test_indexExpression_instance_ifNull() async {
    await assertNoErrorsInCode(r'''
class A {
  int? operator[](int? index) => 0;
  operator[]=(int? index, num? _) {}
}

void f(A a) {
  a[0] ??= 2;
}
''');

    var assignment = findNode.assignment('[0] ??= 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: self::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: self::@class::A::@method::[]
  readType: int?
  writeElement: self::@class::A::@method::[]=
  writeType: num?
  staticElement: <null>
  staticType: int
''');
  }

  test_indexExpression_instance_simple() async {
    await assertNoErrorsInCode(r'''
class A {
  operator[]=(int index, num _) {}
}

void f(A a) {
  a[0] = 2;
}
''');

    var assignment = findNode.assignment('[0] = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: self::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: self::@class::A::@method::[]=::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@method::[]=
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_indexExpression_super_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

class B extends A {
  void f(A a) {
    super[0] += 2;
  }
}
''');

    var assignment = findNode.assignment('[0] += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SuperExpression
      superKeyword: super
      staticType: B
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: self::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::A::@method::[]
  readType: int
  writeElement: self::@class::A::@method::[]=
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_indexExpression_this_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}

  void f() {
    this[0] += 2;
  }
}
''');

    var assignment = findNode.assignment('[0] += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: ThisExpression
      thisKeyword: this
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: self::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::A::@method::[]
  readType: int
  writeElement: self::@class::A::@method::[]=
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_indexExpression_unresolved1_simple() async {
    await assertErrorsInCode(r'''
void f(int c) {
  a[b] = c;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 18, 1),
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 20, 1),
    ]);

    var assignment = findNode.assignment('a[b] = c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      staticElement: <null>
      staticType: InvalidType
    leftBracket: [
    index: SimpleIdentifier
      token: b
      parameter: <null>
      staticElement: <null>
      staticType: InvalidType
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: self::@function::f::@parameter::c
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_indexExpression_unresolved2_simple() async {
    await assertErrorsInCode(r'''
void f(int a, int c) {
  a[b] = c;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 26, 3),
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 27, 1),
    ]);

    var assignment = findNode.assignment('a[b] = c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: int
    leftBracket: [
    index: SimpleIdentifier
      token: b
      parameter: <null>
      staticElement: <null>
      staticType: InvalidType
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: self::@function::f::@parameter::c
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_indexExpression_unresolved3_simple() async {
    await assertErrorsInCode(r'''
class A {
  operator[]=(int index, num _) {}
}

void f(A a, int c) {
  a[b] = c;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 73, 1),
    ]);

    var assignment = findNode.assignment('a[b] = c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A
    leftBracket: [
    index: SimpleIdentifier
      token: b
      parameter: self::@class::A::@method::[]=::@parameter::index
      staticElement: <null>
      staticType: InvalidType
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    parameter: self::@class::A::@method::[]=::@parameter::_
    staticElement: self::@function::f::@parameter::c
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@method::[]=
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_indexExpression_unresolvedTarget_compound() async {
    await assertErrorsInCode(r'''
void f() {
  a[0] += 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 13, 1),
    ]);

    final node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      staticElement: <null>
      staticType: InvalidType
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: <null>
      staticType: int
    rightBracket: ]
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_left_super() async {
    await assertErrorsInCode(r'''
class A {
  void f() {
    super = 0;
  }
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 27, 5),
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 27, 5),
    ]);

    final node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SuperExpression
    superKeyword: super
    staticType: A
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_notLValue_binaryExpression_compound() async {
    await assertErrorsInCode(r'''
void f(int a, int b, double c) {
  a + b += c;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 35, 5),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 35, 5),
    ]);

    var assignment = findNode.assignment('= c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: BinaryExpression
    leftOperand: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: int
    operator: +
    rightOperand: SimpleIdentifier
      token: b
      parameter: dart:core::@class::num::@method::+::@parameter::other
      staticElement: self::@function::f::@parameter::b
      staticType: int
    staticElement: dart:core::@class::num::@method::+
    staticInvokeType: num Function(num)
    staticType: int
  operator: +=
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: self::@function::f::@parameter::c
    staticType: double
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_notLValue_parenthesized_compound() async {
    await assertErrorsInCode(r'''
void f(int a, int b, double c) {
  (a + b) += c;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 35, 7),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 35, 7),
    ]);

    var assignment = findNode.assignment('= c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: ParenthesizedExpression
    leftParenthesis: (
    expression: BinaryExpression
      leftOperand: SimpleIdentifier
        token: a
        staticElement: self::@function::f::@parameter::a
        staticType: int
      operator: +
      rightOperand: SimpleIdentifier
        token: b
        parameter: dart:core::@class::num::@method::+::@parameter::other
        staticElement: self::@function::f::@parameter::b
        staticType: int
      staticElement: dart:core::@class::num::@method::+
      staticInvokeType: num Function(num)
      staticType: int
    rightParenthesis: )
    staticType: int
  operator: +=
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: self::@function::f::@parameter::c
    staticType: double
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_notLValue_parenthesized_simple() async {
    await assertErrorsInCode(r'''
void f(int a, double b) {
  (a + 0) = b;
}
''', [
      error(CompileTimeErrorCode.PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT,
          29, 1),
      error(ParserErrorCode.EXPECTED_TOKEN, 31, 1),
    ]);

    var node = findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: AssignedVariablePattern
      name: a
      element: self::@function::f::@parameter::a
      matchedValueType: double
    rightParenthesis: )
    matchedValueType: double
  equals: =
  expression: SimpleIdentifier
    token: b
    staticElement: self::@function::f::@parameter::b
    staticType: double
  patternTypeSchema: int
  staticType: double
''');
  }

  test_notLValue_parenthesized_simple_language219() async {
    await assertErrorsInCode(r'''
// @dart = 2.19
void f(int a, double b) {
  (a + 0) = b;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 44, 7),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 44, 7),
    ]);

    var node = findNode.assignment('= b');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: ParenthesizedExpression
    leftParenthesis: (
    expression: BinaryExpression
      leftOperand: SimpleIdentifier
        token: a
        staticElement: self::@function::f::@parameter::a
        staticType: int
      operator: +
      rightOperand: IntegerLiteral
        literal: 0
        parameter: dart:core::@class::num::@method::+::@parameter::other
        staticType: int
      staticElement: dart:core::@class::num::@method::+
      staticInvokeType: num Function(num)
      staticType: int
    rightParenthesis: )
    staticType: int
  operator: =
  rightHandSide: SimpleIdentifier
    token: b
    parameter: <null>
    staticElement: self::@function::f::@parameter::b
    staticType: double
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: double
''');
  }

  test_notLValue_postfixIncrement_compound() async {
    await assertErrorsInCode('''
void f(num x, int y) {
  x++ += y;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 25, 3),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 25, 3),
    ]);

    var assignment = findNode.assignment('= y');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PostfixExpression
    operand: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: null
    operator: ++
    readElement: self::@function::f::@parameter::x
    readType: num
    writeElement: self::@function::f::@parameter::x
    writeType: num
    staticElement: dart:core::@class::num::@method::+
    staticType: num
  operator: +=
  rightHandSide: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: self::@function::f::@parameter::y
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_notLValue_postfixIncrement_compound_ifNull() async {
    await assertErrorsInCode('''
void f(num x, int y) {
  x++ ??= y;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 25, 3),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 25, 3),
    ]);

    var assignment = findNode.assignment('= y');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PostfixExpression
    operand: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: null
    operator: ++
    readElement: self::@function::f::@parameter::x
    readType: num
    writeElement: self::@function::f::@parameter::x
    writeType: num
    staticElement: dart:core::@class::num::@method::+
    staticType: num
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: self::@function::f::@parameter::y
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_notLValue_postfixIncrement_simple() async {
    await assertErrorsInCode('''
void f(num x, int y) {
  x++ = y;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 25, 3),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 25, 3),
    ]);

    var assignment = findNode.assignment('= y');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PostfixExpression
    operand: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: null
    operator: ++
    readElement: self::@function::f::@parameter::x
    readType: num
    writeElement: self::@function::f::@parameter::x
    writeType: num
    staticElement: dart:core::@class::num::@method::+
    staticType: num
  operator: =
  rightHandSide: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: self::@function::f::@parameter::y
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_notLValue_prefixIncrement_compound() async {
    await assertErrorsInCode('''
void f(num x, int y) {
  ++x += y;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 25, 3),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 25, 3),
    ]);

    var assignment = findNode.assignment('= y');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixExpression
    operator: ++
    operand: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: null
    readElement: self::@function::f::@parameter::x
    readType: num
    writeElement: self::@function::f::@parameter::x
    writeType: num
    staticElement: dart:core::@class::num::@method::+
    staticType: num
  operator: +=
  rightHandSide: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: self::@function::f::@parameter::y
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_notLValue_prefixIncrement_compound_ifNull() async {
    await assertErrorsInCode('''
void f(num x, int y) {
  ++x ??= y;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 25, 3),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 25, 3),
    ]);

    var assignment = findNode.assignment('= y');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixExpression
    operator: ++
    operand: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: null
    readElement: self::@function::f::@parameter::x
    readType: num
    writeElement: self::@function::f::@parameter::x
    writeType: num
    staticElement: dart:core::@class::num::@method::+
    staticType: num
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: self::@function::f::@parameter::y
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_notLValue_prefixIncrement_simple() async {
    await assertErrorsInCode('''
void f(num x, int y) {
  ++x = y;
}
''', [
      error(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, 25, 3),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 25, 3),
    ]);

    var assignment = findNode.assignment('= y');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixExpression
    operator: ++
    operand: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: null
    readElement: self::@function::f::@parameter::x
    readType: num
    writeElement: self::@function::f::@parameter::x
    writeType: num
    staticElement: dart:core::@class::num::@method::+
    staticType: num
  operator: =
  rightHandSide: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: self::@function::f::@parameter::y
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_notLValue_typeLiteral_class_ambiguous_simple() async {
    newFile('$testPackageLibPath/a.dart', 'class C {}');
    newFile('$testPackageLibPath/b.dart', 'class C {}');
    await assertErrorsInCode('''
import 'a.dart';
import 'b.dart';
void f() {
  C = 0;
}
''', [
      error(CompileTimeErrorCode.AMBIGUOUS_IMPORT, 47, 1),
    ]);

    var assignment = findNode.assignment('C = 0');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: C
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_notLValue_typeLiteral_class_simple() async {
    await assertErrorsInCode('''
class C {}

void f() {
  C = 0;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_TYPE, 25, 1),
    ]);

    var assignment = findNode.assignment('C = 0');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: C
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::C
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_nullAware_context() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int? a) {
  a ??= f();
}
''');

    final node = findNode.assignment('??= f()');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    staticElement: self::@function::g::@parameter::a
    staticType: null
  operator: ??=
  rightHandSide: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      staticElement: self::@function::f
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    parameter: <null>
    staticInvokeType: int? Function()
    staticType: int?
    typeArgumentTypes
      int?
  readElement: self::@function::g::@parameter::a
  readType: int?
  writeElement: self::@function::g::@parameter::a
  writeType: int?
  staticElement: <null>
  staticType: int?
''');
  }

  test_prefixedIdentifier_instance_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int get x => 0;
  set x(num _) {}
}

void f(A a) {
  a.x += 2;
}
''');

    var assignment = findNode.assignment('x += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::A::@getter::x
  readType: int
  writeElement: self::@class::A::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_prefixedIdentifier_instance_ifNull() async {
    await assertNoErrorsInCode(r'''
class A {
  int? get x => 0;
  set x(num? _) {}
}

void f(A a) {
  a.x ??= 2;
}
''');

    var assignment = findNode.assignment('x ??= 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: self::@class::A::@getter::x
  readType: int?
  writeElement: self::@class::A::@setter::x
  writeType: num?
  staticElement: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_instance_simple() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
}

void f(A a) {
  a.x = 2;
}
''');

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: self::@class::A::@setter::x::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@setter::x
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_instanceGetter_simple() async {
    await assertErrorsInCode(r'''
class A {
  int get x => 0;
}

void f(A a) {
  a.x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 49, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@getter::x
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_ofClass_getterAugmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart'

augment class A {
  int get foo => 0;
}
''');

    await assertErrorsInCode(r'''
import augment 'a.dart';

class A {}

void f(A a) {
  a.foo = 0;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 56, 3),
    ]);

    final node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@augmentation::package:test/a.dart::@classAugmentation::A::@getter::foo
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_ofClass_setterAugmentationAugments() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart'

augment class A {
  augment set foo(int _) {}
}
''');
    await assertNoErrorsInCode(r'''
import augment 'a.dart';

class A {
  set foo(int _) {}
}

void f(A a) {
  a.foo = 0;
}
''');

    final node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: self::@augmentation::package:test/a.dart::@classAugmentation::A::@setterAugmentation::foo::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@augmentation::package:test/a.dart::@classAugmentation::A::@setterAugmentation::foo
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_ofClass_setterAugmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart'

augment class A {
  set foo(int _) {}
}
''');
    await assertNoErrorsInCode(r'''
import augment 'a.dart';

class A {}

void f(A a) {
  a.foo = 0;
}
''');

    final node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: self::@augmentation::package:test/a.dart::@classAugmentation::A::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@augmentation::package:test/a.dart::@classAugmentation::A::@setter::foo
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_ofClassName_getterAugmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart'

augment class A {
  static int get foo => 0;
}
''');

    await assertErrorsInCode(r'''
import augment 'a.dart';

class A {}

void f() {
  A.foo = 0;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 53, 3),
    ]);

    final node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: self::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@augmentation::package:test/a.dart::@classAugmentation::A::@getter::foo
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_ofClassName_setterAugmentationAugments() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart'

augment class A {
  augment static set foo(int _) {}
}
''');
    await assertNoErrorsInCode(r'''
import augment 'a.dart';

class A {
  static set foo(int _) {}
}

void f() {
  A.foo = 0;
}
''');

    final node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: self::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: self::@augmentation::package:test/a.dart::@classAugmentation::A::@setterAugmentation::foo::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@augmentation::package:test/a.dart::@classAugmentation::A::@setterAugmentation::foo
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_ofClassName_setterAugmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart'

augment class A {
  static set foo(int _) {}
}
''');
    await assertNoErrorsInCode(r'''
import augment 'a.dart';

class A {}

void f() {
  A.foo = 0;
}
''');

    final node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: self::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: self::@augmentation::package:test/a.dart::@classAugmentation::A::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@augmentation::package:test/a.dart::@classAugmentation::A::@setter::foo
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_static_simple() async {
    await assertNoErrorsInCode(r'''
class A {
  static set x(num _) {}
}

void f() {
  A.x = 2;
}
''');

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: self::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: self::@class::A::@setter::x::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@setter::x
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_staticGetter_simple() async {
    await assertErrorsInCode(r'''
class A {
  static int get x => 0;
}

void f() {
  A.x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 53, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: self::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@getter::x
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_topLevel_compound() async {
    newFile('$testPackageLibPath/a.dart', r'''
int get x => 0;
set x(num _) {}
''');
    await assertNoErrorsInCode(r'''
import 'a.dart' as p;

void f() {
  p.x += 2;
}
''');

    var assignment = findNode.assignment('x += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      staticElement: self::@prefix::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: package:test/a.dart::@getter::x
  readType: int
  writeElement: package:test/a.dart::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_prefixedIdentifier_typeAlias_static_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  static int get x => 0;
  static set x(int _) {}
}

typedef B = A;

void f() {
  B.x += 2;
}
''');

    var assignment = findNode.assignment('x += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: B
      staticElement: self::@typeAlias::B
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::A::@getter::x
  readType: int
  writeElement: self::@class::A::@setter::x
  writeType: int
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_prefixedIdentifier_unresolved1_simple() async {
    await assertErrorsInCode(r'''
void f(int c) {
  a.b = c;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 18, 1),
    ]);

    var assignment = findNode.assignment('a.b = c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <null>
      staticType: InvalidType
    period: .
    identifier: SimpleIdentifier
      token: b
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: self::@function::f::@parameter::c
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_unresolved2_compound() async {
    await assertErrorsInCode(r'''
void f(int a, int c) {
  a.b += c;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 27, 1),
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 27, 1),
    ]);

    var assignment = findNode.assignment('a.b += c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: int
    period: .
    identifier: SimpleIdentifier
      token: b
      staticElement: <null>
      staticType: null
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: self::@function::f::@parameter::c
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_propertyAccess_cascade_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int get x => 0;
  set x(num _) {}
}

void f(A a) {
  a..x += 2;
}
''');

    var assignment = findNode.assignment('x += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    operator: ..
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::A::@getter::x
  readType: int
  writeElement: self::@class::A::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_propertyAccess_forwardingStub() async {
    await assertNoErrorsInCode(r'''
class A {
  int x = 0;
}
abstract class I<T> {
  T x = throw 0;
}
class B extends A implements I<int> {}
main() {
  new B().x = 1;
}
''');

    var assignment = findNode.assignment('x = 1');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: InstanceCreationExpression
      keyword: new
      constructorName: ConstructorName
        type: NamedType
          name: B
          element: self::@class::B
          type: B
        staticElement: self::@class::B::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: self::@class::A::@setter::x::@parameter::_x
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@setter::x
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  test_propertyAccess_instance_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int get x => 0;
  set x(num _) {}
}

void f(A a) {
  (a).x += 2;
}
''');

    var assignment = findNode.assignment('x += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        staticElement: self::@function::f::@parameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::A::@getter::x
  readType: int
  writeElement: self::@class::A::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_propertyAccess_instance_fromMixins_compound() async {
    await assertNoErrorsInCode('''
mixin M1 {
  int get x => 0;
  set x(num _) {}
}

mixin M2 {
  int get x => 0;
  set x(num _) {}
}

class C with M1, M2 {
}

void f(C c) {
  (c).x += 2;
}
''');

    var assignment = findNode.assignment('x += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: c
        staticElement: self::@function::f::@parameter::c
        staticType: C
      rightParenthesis: )
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@mixin::M2::@getter::x
  readType: int
  writeElement: self::@mixin::M2::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_propertyAccess_instance_ifNull() async {
    await assertNoErrorsInCode(r'''
class A {
  int? get x => 0;
  set x(num? _) {}
}

void f(A a) {
  (a).x ??= 2;
}
''');

    var assignment = findNode.assignment('x ??= 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        staticElement: self::@function::f::@parameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: self::@class::A::@getter::x
  readType: int?
  writeElement: self::@class::A::@setter::x
  writeType: num?
  staticElement: <null>
  staticType: int
''');
  }

  test_propertyAccess_instance_simple() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
}

void f(A a) {
  (a).x = 2;
}
''');

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        staticElement: self::@function::f::@parameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: self::@class::A::@setter::x::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@setter::x
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_propertyAccess_ofClass_setterAugmentationAugments() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart'

augment class A {
  augment set foo(int _) {}
}
''');
    await assertNoErrorsInCode(r'''
import augment 'a.dart';

class A {
  set foo(int _) {}
}

void f(A a) {
  (a).foo = 0;
}
''');

    final node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        staticElement: self::@function::f::@parameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: self::@augmentation::package:test/a.dart::@classAugmentation::A::@setterAugmentation::foo::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@augmentation::package:test/a.dart::@classAugmentation::A::@setterAugmentation::foo
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  test_propertyAccess_ofClass_setterAugmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart'

augment class A {
  set foo(int _) {}
}
''');
    await assertNoErrorsInCode(r'''
import augment 'a.dart';

class A {}

void f(A a) {
  (a).foo = 0;
}
''');

    final node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        staticElement: self::@function::f::@parameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: self::@augmentation::package:test/a.dart::@classAugmentation::A::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@augmentation::package:test/a.dart::@classAugmentation::A::@setter::foo
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  /// Has record getter:    false
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_FFFF_compound() async {
    await assertErrorsInCode(r'''
void f(({int bar}) r) {
  r.foo += 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 28, 3),
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 28, 3),
    ]);

    final node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
  }

  /// Has record getter:    false
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_FFFF_simple() async {
    await assertErrorsInCode(r'''
void f(({int bar}) r) {
  r.foo = 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 28, 3),
    ]);

    final node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  /// Has record getter:    false
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_named_FFFT_compound() async {
    await assertErrorsInCode(r'''
extension E on ({int bar}) {
  set foo(int _) {}
}

void f(({int bar}) r) {
  r.foo += 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 80, 3),
    ]);

    final node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: self::@extension::E::@setter::foo
  readType: InvalidType
  writeElement: self::@extension::E::@setter::foo
  writeType: int
  staticElement: <null>
  staticType: InvalidType
''');
  }

  /// Has record getter:    false
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_named_FFFT_simple() async {
    await assertNoErrorsInCode(r'''
extension E on ({int bar}) {
  set foo(int _) {}
}

void f(({int bar}) r) {
  r.foo = 0;
}
''');

    final node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: self::@extension::E::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@extension::E::@setter::foo
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  /// Has record getter:    false
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_FTFF_compound() async {
    await assertErrorsInCode(r'''
extension E on ({int bar}) {
  int get foo => 0;
}

void f(({int bar}) r) {
  r.foo += 0;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 80, 3),
    ]);

    final node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@extension::E::@getter::foo
  readType: int
  writeElement: self::@extension::E::@getter::foo
  writeType: InvalidType
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    false
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_FTFF_simple() async {
    await assertErrorsInCode(r'''
extension E on ({int bar}) {
  int get foo => 0;
}

void f(({int bar}) r) {
  r.foo = 0;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 80, 3),
    ]);

    final node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@extension::E::@getter::foo
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  /// Has record getter:    false
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_named_FTFT_compound() async {
    await assertNoErrorsInCode(r'''
extension E on ({int bar}) {
  int get foo => 0;
  set foo(int _) {}
}

void f(({int bar}) r) {
  r.foo += 0;
}
''');

    final node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@extension::E::@getter::foo
  readType: int
  writeElement: self::@extension::E::@setter::foo
  writeType: int
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    false
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_named_FTFT_simple() async {
    await assertNoErrorsInCode(r'''
extension E on ({int bar}) {
  int get foo => 0;
  set foo(int _) {}
}

void f(({int bar}) r) {
  r.foo = 0;
}
''');

    final node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: self::@extension::E::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@extension::E::@setter::foo
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_TFFF_compound() async {
    await assertErrorsInCode(r'''
void f(({int foo, String bar}) r) {
  r.foo += 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 40, 3),
    ]);

    final node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <null>
  readType: int
  writeElement: <null>
  writeType: InvalidType
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_TFFF_simple() async {
    await assertErrorsInCode(r'''
void f(({int foo, String bar}) r) {
  r.foo = 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 40, 3),
    ]);

    final node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_named_TFFT_compound() async {
    await assertErrorsInCode(r'''
extension E on ({int foo, String bar}) {
  set foo(int _) {}
}

void f(({int foo, String bar}) r) {
  r.foo += 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 104, 3),
    ]);

    final node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <null>
  readType: int
  writeElement: <null>
  writeType: InvalidType
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_named_TFFT_simple() async {
    await assertErrorsInCode(r'''
extension E on ({int foo, String bar}) {
  set foo(int _) {}
}

void f(({int foo, String bar}) r) {
  r.foo = 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 104, 3),
    ]);

    final node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_TTFF_compound() async {
    await assertErrorsInCode(r'''
extension E on ({int foo, String bar}) {
  int get foo => 0;
}

void f(({int foo, String bar}) r) {
  r.foo += 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 104, 3),
    ]);

    final node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <null>
  readType: int
  writeElement: <null>
  writeType: InvalidType
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_TTFF_simple() async {
    await assertErrorsInCode(r'''
extension E on ({int foo, String bar}) {
  int get foo => 0;
}

void f(({int foo, String bar}) r) {
  r.foo = 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 104, 3),
    ]);

    final node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_named_TTFT_compound() async {
    await assertErrorsInCode(r'''
extension E on ({int foo, String bar}) {
  int get foo => 0;
  set foo(int _) {}
}

void f(({int foo, String bar}) r) {
  r.foo += 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 124, 3),
    ]);

    final node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <null>
  readType: int
  writeElement: <null>
  writeType: InvalidType
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_named_TTFT_simple() async {
    await assertErrorsInCode(r'''
extension E on ({int foo, String bar}) {
  int get foo => 0;
  set foo(int _) {}
}

void f(({int foo, String bar}) r) {
  r.foo = 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 124, 3),
    ]);

    final node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  /// Has record getter:    false
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_positional_FFFF_compound() async {
    await assertErrorsInCode(r'''
void f((int, String) r) {
  r.$4 += 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 30, 2),
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 30, 2),
    ]);

    final node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $4
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
  }

  /// Has record getter:    false
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_positional_FFFF_simple() async {
    await assertErrorsInCode(r'''
void f((int, String) r) {
  r.$4 = 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 30, 2),
    ]);

    final node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $4
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  /// Has record getter:    false
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_positional_FTFF_compound() async {
    await assertErrorsInCode(r'''
extension E on (int, String) {
  int get $3 => 0;
}

void f((int, String) r) {
  r.$3 += 0;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 83, 2),
    ]);

    final node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $3
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@extension::E::@getter::$3
  readType: int
  writeElement: self::@extension::E::@getter::$3
  writeType: InvalidType
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    false
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_positional_FTFF_simple() async {
    await assertErrorsInCode(r'''
extension E on (int, String) {
  int get $3 => 0;
}

void f((int, String) r) {
  r.$3 = 0;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 83, 2),
    ]);

    final node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $3
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@extension::E::@getter::$3
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_positional_TFFF_compound() async {
    await assertErrorsInCode(r'''
void f((int, String) r) {
  r.$1 += 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 30, 2),
    ]);

    final node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $1
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <null>
  readType: int
  writeElement: <null>
  writeType: InvalidType
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_positional_TFFF_simple() async {
    await assertErrorsInCode(r'''
void f((int, String) r) {
  r.$1 = 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 30, 2),
    ]);

    final node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $1
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_positional_TFFT_compound() async {
    await assertErrorsInCode(r'''
extension E on (int, String) {
  set $1(int _) {}
}

void f((int, String) r) {
  r.$1 += 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 83, 2),
    ]);

    final node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $1
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <null>
  readType: int
  writeElement: <null>
  writeType: InvalidType
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_positional_TFFT_simple() async {
    await assertErrorsInCode(r'''
extension E on (int, String) {
  set $1(int _) {}
}

void f((int, String) r) {
  r.$1 = 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 83, 2),
    ]);

    final node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: self::@function::f::@parameter::r
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $1
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_propertyAccess_super_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
  int get x => 0;
}

class B extends A {
  set x(num _) {}
  int get x => 0;

  void f() {
    super.x += 2;
  }
}
''');

    var assignment = findNode.assignment('x += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::A::@getter::x
  readType: int
  writeElement: self::@class::A::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_propertyAccess_this_compound() async {
    await assertNoErrorsInCode(r'''
class A {
  int get x => 0;
  set x(num _) {}

  void f() {
    this.x += 2;
  }
}
''');

    var assignment = findNode.assignment('x += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ThisExpression
      thisKeyword: this
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::A::@getter::x
  readType: int
  writeElement: self::@class::A::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_propertyAccess_unresolved1_simple() async {
    await assertErrorsInCode(r'''
void f(int c) {
  (a).b = c;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 19, 1),
    ]);

    var assignment = findNode.assignment('(a).b = c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        staticElement: <null>
        staticType: InvalidType
      rightParenthesis: )
      staticType: InvalidType
    operator: .
    propertyName: SimpleIdentifier
      token: b
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: self::@function::f::@parameter::c
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_propertyAccess_unresolved2_simple() async {
    await assertErrorsInCode(r'''
void f(int a, int c) {
  (a).b = c;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 29, 1),
    ]);

    var assignment = findNode.assignment('(a).b = c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        staticElement: self::@function::f::@parameter::a
        staticType: int
      rightParenthesis: )
      staticType: int
    operator: .
    propertyName: SimpleIdentifier
      token: b
      staticElement: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: self::@function::f::@parameter::c
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_right_super() async {
    await assertErrorsInCode(r'''
class A {
  void f(Object a) {
    a = super;
  }
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 39, 5),
    ]);

    final node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    staticElement: self::@class::A::@method::f::@parameter::a
    staticType: null
  operator: =
  rightHandSide: SuperExpression
    superKeyword: super
    staticType: A
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@method::f::@parameter::a
  writeType: Object
  staticElement: <null>
  staticType: A
''');
  }

  test_simpleIdentifier_fieldInstance_simple() async {
    await assertNoErrorsInCode(r'''
class C {
  num x = 0;

  void f() {
    x = 2;
  }
}
''');

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: self::@class::C::@setter::x::@parameter::_x
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::C::@setter::x
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_fieldStatic_simple() async {
    await assertNoErrorsInCode(r'''
class C {
  static num x = 0;

  void f() {
    x = 2;
  }
}
''');

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: self::@class::C::@setter::x::@parameter::_x
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::C::@setter::x
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_getterInstance_simple() async {
    await assertErrorsInCode('''
class C {
  num get x => 0;

  void f() {
    x = 2;
  }
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 46, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::C::@getter::x
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_getterStatic_simple() async {
    await assertErrorsInCode('''
class C {
  static num get x => 0;

  void f() {
    x = 2;
  }
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 53, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::C::@getter::x
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_getterTopLevel_simple() async {
    await assertErrorsInCode('''
int get x => 0;

void f() {
  x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 30, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@getter::x
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_importPrefix_hasSuperSetter_simple() async {
    await assertErrorsInCode('''
import 'dart:math' as x;

class A {
  var x;
}

class B extends A {
  void f() {
    x = 2;
  }
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 85, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@prefix::x
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_importPrefix_simple() async {
    await assertErrorsInCode('''
import 'dart:math' as x;

main() {
  x = 2;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 37, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@prefix::x
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_localVariable_compound() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  num x = 0;
  x += 3;
}
''');

    var assignment = findNode.assignment('x += 3');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: x@51
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 3
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: x@51
  readType: num
  writeElement: x@51
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: num
''');
  }

  test_simpleIdentifier_localVariable_simple() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  num x = 0;
  x = 2;
}
''');

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: x@51
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: x@51
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_localVariableConst_simple() async {
    await assertErrorsInCode('''
void f() {
  // ignore:unused_local_variable
  const num x = 1;
  x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_CONST, 66, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: x@57
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: x@57
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_localVariableFinal_simple() async {
    await assertErrorsInCode('''
void f() {
  // ignore:unused_local_variable
  final num x = 1;
  x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL, 66, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: x@57
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: x@57
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_parameter_compound_ifNull() async {
    await assertNoErrorsInCode('''
void f(num? x) {
  x ??= 0;
}
''');

    var assignment = findNode.assignment('x ??=');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: self::@function::f::@parameter::x
  readType: num?
  writeElement: self::@function::f::@parameter::x
  writeType: num?
  staticElement: <null>
  staticType: num
''');
  }

  test_simpleIdentifier_parameter_compound_ifNull2() async {
    await assertErrorsInCode('''
class A {}
class B extends A {}
class C extends A {}

void f(B? x) {
  x ??= C();
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 77, 3),
    ]);

    var assignment = findNode.assignment('x ??=');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  operator: ??=
  rightHandSide: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: C
        element: self::@class::C
        type: C
      staticElement: self::@class::C::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    parameter: <null>
    staticType: C
  readElement: self::@function::f::@parameter::x
  readType: B?
  writeElement: self::@function::f::@parameter::x
  writeType: B?
  staticElement: <null>
  staticType: A
''');
  }

  test_simpleIdentifier_parameter_compound_ifNull_notAssignableType() async {
    await assertErrorsInCode('''
void f(double? a, int b) {
  a ??= b;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 35, 1),
    ]);

    var assignment = findNode.assignment('a ??=');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: null
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: b
    parameter: <null>
    staticElement: self::@function::f::@parameter::b
    staticType: int
  readElement: self::@function::f::@parameter::a
  readType: double?
  writeElement: self::@function::f::@parameter::a
  writeType: double?
  staticElement: <null>
  staticType: num
''');
  }

  test_simpleIdentifier_parameter_compound_refineType_int_double() async {
    await assertErrorsInCode(r'''
void f(int x) {
  x += 1.2;
  x -= 1.2;
  x *= 1.2;
  x %= 1.2;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 23, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 35, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 47, 3),
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 59, 3),
    ]);
    assertType(findNode.assignment('+='), 'double');
    assertType(findNode.assignment('-='), 'double');
    assertType(findNode.assignment('*='), 'double');
    assertType(findNode.assignment('%='), 'double');
  }

  test_simpleIdentifier_parameter_compound_refineType_int_int() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  x += 1;
  x -= 1;
  x *= 1;
  x ~/= 1;
  x %= 1;
}
''');
    assertType(findNode.assignment('+='), 'int');
    assertType(findNode.assignment('-='), 'int');
    assertType(findNode.assignment('*='), 'int');
    assertType(findNode.assignment('~/='), 'int');
    assertType(findNode.assignment('%='), 'int');
  }

  test_simpleIdentifier_parameter_simple() async {
    await assertNoErrorsInCode(r'''
void f(num x) {
  x = 2;
}
''');

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@function::f::@parameter::x
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_parameter_simple_context() async {
    await assertNoErrorsInCode(r'''
void f(Object x) {
  if (x is double) {
    x = 1;
  }
}
''');

    var assignment = findNode.assignment('x = 1');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: <null>
    staticType: double
  readElement: <null>
  readType: null
  writeElement: self::@function::f::@parameter::x
  writeType: Object
  staticElement: <null>
  staticType: double
''');
  }

  test_simpleIdentifier_parameter_simple_notAssignableType() async {
    await assertErrorsInCode(r'''
void f(int x) {
  x = true;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 22, 4),
    ]);

    var assignment = findNode.assignment('x = true');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  operator: =
  rightHandSide: BooleanLiteral
    literal: true
    parameter: <null>
    staticType: bool
  readElement: <null>
  readType: null
  writeElement: self::@function::f::@parameter::x
  writeType: int
  staticElement: <null>
  staticType: bool
''');
  }

  test_simpleIdentifier_parameterFinal_simple() async {
    await assertErrorsInCode('''
void f(final int x) {
  x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL, 24, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@function::f::@parameter::x
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_staticGetter_superSetter_simple() async {
    await assertErrorsInCode('''
class A {
  set x(num _) {}
}

class B extends A {
  static int get x => 1;

  void f() {
    x = 2;
  }
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 68, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 94, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::B::@getter::x
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_staticMethod_superSetter_simple() async {
    await assertErrorsInCode('''
class A {
  set x(num _) {}
}

class B extends A {
  static void x() {}

  void f() {
    x = 2;
  }
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 65, 1),
      error(CompileTimeErrorCode.ASSIGNMENT_TO_METHOD, 90, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::B::@method::x
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_superSetter_simple() async {
    await assertNoErrorsInCode(r'''
class A {
  set x(num _) {}
}

class B extends A {
  void f() {
    x = 2;
  }
}
''');

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: self::@class::A::@setter::x::@parameter::_
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@setter::x
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_synthetic_simple() async {
    await assertErrorsInCode('''
void f(int y) {
  = y;
}
''', [
      error(ParserErrorCode.MISSING_IDENTIFIER, 18, 1),
    ]);

    var assignment = findNode.assignment('= y');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: <empty> <synthetic>
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: self::@function::f::@parameter::y
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_thisGetter_superGetter_simple() async {
    await assertNoErrorsInCode('''
class A {
  int x = 0;
}

class B extends A {
  int get x => 1;

  void f() {
    x = 2;
  }
}
''');

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: self::@class::A::@setter::x::@parameter::_x
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@class::A::@setter::x
  writeType: int
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_thisGetter_thisSetter_compound() async {
    await assertNoErrorsInCode('''
class C {
  int get x => 0;
  set x(num _) {}

  void f() {
    x += 2;
  }
}
''');

    var assignment = findNode.assignment('x += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@class::C::@getter::x
  readType: int
  writeElement: self::@class::C::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_simpleIdentifier_thisGetter_thisSetter_fromMixins_compound() async {
    await assertNoErrorsInCode('''
mixin M1 {
  int get x => 0;
  set x(num _) {}
}

mixin M2 {
  int get x => 0;
  set x(num _) {}
}

class C with M1, M2 {
  void f() {
    x += 2;
  }
}
''');

    var assignment = findNode.assignment('x += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@mixin::M2::@getter::x
  readType: int
  writeElement: self::@mixin::M2::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_simpleIdentifier_thisGetter_thisSetter_ifNull() async {
    await assertNoErrorsInCode('''
class C {
  int? get x => 0;
  set x(num? _) {}

  void f() {
    x ??= 2;
  }
}
''');

    var assignment = findNode.assignment('x ??= 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: self::@class::C::@getter::x
  readType: int?
  writeElement: self::@class::C::@setter::x
  writeType: num?
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_topGetter_superSetter_simple() async {
    await assertErrorsInCode('''
class A {
  set x(num _) {}
}

int get x => 1;

class B extends A {

  void f() {
    x = 2;
  }
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 86, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@getter::x
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_topGetter_topSetter_compound() async {
    await assertNoErrorsInCode('''
int get x => 0;
set x(num _) {}

void f() {
  x += 2;
}
''');

    var assignment = findNode.assignment('x += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@getter::x
  readType: int
  writeElement: self::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_simpleIdentifier_topGetter_topSetter_compound_ifNull2() async {
    await assertErrorsInCode('''
void f() {
  x ??= C();
}

class A {}
class B extends A {}
class C extends A {}

B? get x => B();
set x(B? _) {}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 19, 3),
    ]);

    var assignment = findNode.assignment('x ??=');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: ??=
  rightHandSide: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: C
        element: self::@class::C
        type: C
      staticElement: self::@class::C::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    parameter: <null>
    staticType: C
  readElement: self::@getter::x
  readType: B?
  writeElement: self::@setter::x
  writeType: B?
  staticElement: <null>
  staticType: A
''');
  }

  test_simpleIdentifier_topGetter_topSetter_fromClass_compound() async {
    await assertNoErrorsInCode('''
int get x => 0;
set x(num _) {}

class A {
  void f() {
    x += 2;
  }
}
''');

    var assignment = findNode.assignment('x += 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: self::@getter::x
  readType: int
  writeElement: self::@setter::x
  writeType: num
  staticElement: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_simpleIdentifier_topLevelVariable_simple() async {
    await assertNoErrorsInCode(r'''
num x = 0;

void f() {
  x = 2;
}
''');

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: self::@setter::x::@parameter::_x
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@setter::x
  writeType: num
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_topLevelVariable_simple_notAssignableType() async {
    await assertErrorsInCode(r'''
int x = 0;

void f() {
  x = true;
}
''', [
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 29, 4),
    ]);

    var assignment = findNode.assignment('x = true');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: BooleanLiteral
    literal: true
    parameter: self::@setter::x::@parameter::_x
    staticType: bool
  readElement: <null>
  readType: null
  writeElement: self::@setter::x
  writeType: int
  staticElement: <null>
  staticType: bool
''');
  }

  test_simpleIdentifier_topLevelVariableFinal_simple() async {
    await assertErrorsInCode(r'''
final num x = 0;

void f() {
  x = 2;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL, 31, 1),
    ]);

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: self::@getter::x
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_typeLiteral_compound() async {
    await assertErrorsInCode(r'''
void f() {
  int += 3;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_TYPE, 13, 3),
    ]);

    var assignment = findNode.assignment('int += 3');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: int
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 3
    parameter: <null>
    staticType: int
  readElement: dart:core::@class::int
  readType: InvalidType
  writeElement: dart:core::@class::int
  writeType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_simpleIdentifier_typeLiteral_simple() async {
    await assertErrorsInCode(r'''
void f() {
  int = 0;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_TYPE, 13, 3),
    ]);

    var assignment = findNode.assignment('int = 0');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: int
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: null
  writeElement: dart:core::@class::int
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_unresolved_compound() async {
    await assertErrorsInCode(r'''
void f() {
  x += 1;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 13, 1),
    ]);

    var assignment = findNode.assignment('x += 1');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: <null>
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: InvalidType
''');
  }

  test_simpleIdentifier_unresolved_simple() async {
    await assertErrorsInCode(r'''
void f(int a) {
  x = a;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 18, 1),
    ]);

    var assignment = findNode.assignment('x = a');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: a
    parameter: <null>
    staticElement: self::@function::f::@parameter::a
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  staticElement: <null>
  staticType: int
''');
  }
}
