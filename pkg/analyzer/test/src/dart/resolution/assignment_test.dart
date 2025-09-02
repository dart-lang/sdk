// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentExpressionResolutionTest);
    defineReflectiveTests(InferenceUpdate3Test);
    defineReflectiveTests(UpdateNodeTextExpectations);
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

    var node = findNode.assignment('+= f()');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::g::@formalParameter::a
    staticType: null
  operator: +=
  rightHandSide: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      element: <testLibrary>::@function::f
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticInvokeType: int Function()
    staticType: int
    typeArgumentTypes
      int
  readElement2: <testLibrary>::@function::g::@formalParameter::a
  readType: int
  writeElement2: <testLibrary>::@function::g::@formalParameter::a
  writeType: int
  element: dart:core::@class::num::@method::+
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

    var node = findNode.assignment('+= f()');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::g::@formalParameter::a
      staticType: List<int>
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: ParameterMember
        baseElement: dart:core::@class::List::@method::[]=::@formalParameter::index
        substitution: {E: int}
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      element: <testLibrary>::@function::f
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticInvokeType: int Function()
    staticType: int
    typeArgumentTypes
      int
  readElement2: MethodMember
    baseElement: dart:core::@class::List::@method::[]
    substitution: {E: int}
  readType: int
  writeElement2: MethodMember
    baseElement: dart:core::@class::List::@method::[]=
    substitution: {E: int}
  writeType: int
  element: dart:core::@class::num::@method::+
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

    var node = findNode.assignment('+= f()');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::g::@formalParameter::a
    staticType: null
  operator: +=
  rightHandSide: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      element: <testLibrary>::@function::f
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticInvokeType: int Function()
    staticType: int
    typeArgumentTypes
      int
  readElement2: <testLibrary>::@function::g::@formalParameter::a
  readType: int
  writeElement2: <testLibrary>::@function::g::@formalParameter::a
  writeType: num
  element: dart:core::@class::num::@method::+
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

    var node = findNode.assignment('+=');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::g::@formalParameter::a
    staticType: null
  operator: +=
  rightHandSide: ConditionalExpression
    condition: SimpleIdentifier
      token: b
      element: <testLibrary>::@function::g::@formalParameter::b
      staticType: bool
    question: ?
    thenExpression: MethodInvocation
      methodName: SimpleIdentifier
        token: f
        element: <testLibrary>::@function::f
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
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: num
  readElement2: <testLibrary>::@function::g::@formalParameter::a
  readType: int
  writeElement2: <testLibrary>::@function::g::@formalParameter::a
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: num
''');

    assertResolvedNodeText(findNode.simple('a;'), r'''
SimpleIdentifier
  token: a
  element: <testLibrary>::@function::g::@formalParameter::a
  staticType: num
''');
  }

  test_dynamicIdentifier_compound() async {
    await assertNoErrorsInCode(r'''
void f(dynamic a) {
  a += 0;
}
''');

    var node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement2: <testLibrary>::@function::f::@formalParameter::a
  readType: dynamic
  writeElement2: <testLibrary>::@function::f::@formalParameter::a
  writeType: dynamic
  element: <null>
  staticType: dynamic
''');
  }

  test_dynamicIdentifier_identifier_compound() async {
    await assertNoErrorsInCode(r'''
void f(dynamic a) {
  a.foo += 0;
}
''');

    var node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: dynamic
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: dynamic
  writeElement2: <null>
  writeType: dynamic
  element: <null>
  staticType: dynamic
''');
  }

  test_dynamicIdentifier_identifier_identifier_compound() async {
    await assertNoErrorsInCode(r'''
void f(dynamic a) {
  a.foo.bar += 0;
}
''');

    var node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: dynamic
      period: .
      identifier: SimpleIdentifier
        token: foo
        element: <null>
        staticType: dynamic
      element: <null>
      staticType: dynamic
    operator: .
    propertyName: SimpleIdentifier
      token: bar
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: dynamic
  writeElement2: <null>
  writeType: dynamic
  element: <null>
  staticType: dynamic
''');
  }

  test_ifNull_lubUsedEvenIfItDoesNotSatisfyContext() async {
    await assertNoErrorsInCode('''
// @dart=3.3
f(Object? o1, Object? o2, List<num> listNum) {
  if (o1 is Iterable<int>? && o2 is Iterable<num>) {
    o2 = (o1 ??= listNum);
  }
}
''');

    assertResolvedNodeText(findNode.assignment('o1 ??= listNum'), r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: o1
    element: <testLibrary>::@function::f::@formalParameter::o1
    staticType: null
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: listNum
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::listNum
    staticType: List<num>
  readElement2: <testLibrary>::@function::f::@formalParameter::o1
  readType: Iterable<int>?
  writeElement2: <testLibrary>::@function::f::@formalParameter::o1
  writeType: Object?
  element: <null>
  staticType: Object
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

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: v
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: package:test/a.dart::@setter::v::@formalParameter::value
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: package:test/a.dart::@setter::v
  writeType: int
  element: <null>
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
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement2: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_indexExpression_dynamicTarget_compound() async {
    await assertNoErrorsInCode(r'''
void f(dynamic a) {
  a[0] += 1;
}
''');

    var node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: dynamic
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <null>
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: dynamic
  writeElement2: <null>
  writeType: dynamic
  element: <null>
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
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement2: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
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
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: DoubleLiteral
    literal: 2.0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: double
  readElement2: <testLibrary>::@class::A::@method::[]
  readType: num
  writeElement2: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
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
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement2: <testLibrary>::@class::A::@method::[]
  readType: int?
  writeElement2: <testLibrary>::@class::A::@method::[]=
  writeType: num?
  element: <null>
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
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::_
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_indexExpression_nullShorting_assignable() async {
    await assertNoErrorsInCode('''
abstract class A {
  B get b;
}
abstract class B {
  operator []=(String s, int i);
}
test(A? a, String s) {
  a?.b[s] = 0;
}
''');

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: PropertyAccess
      target: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::test::@formalParameter::a
        staticType: A?
      operator: ?.
      propertyName: SimpleIdentifier
        token: b
        element: <testLibrary>::@class::A::@getter::b
        staticType: B
      staticType: B
    leftBracket: [
    index: SimpleIdentifier
      token: s
      correspondingParameter: <testLibrary>::@class::B::@method::[]=::@formalParameter::s
      element: <testLibrary>::@function::test::@formalParameter::s
      staticType: String
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::B::@method::[]=::@formalParameter::i
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::B::@method::[]=
  writeType: int
  element: <null>
  staticType: int?
''');
  }

  test_indexExpression_nullShorting_notAssignable() async {
    await assertErrorsInCode(
      '''
abstract class A {
  B get b;
}
abstract class B {
  operator []=(String s, int i);
}
test(A? a, String s) {
  a?.b[s] = null;
}
''',
      [error(CompileTimeErrorCode.invalidAssignment, 121, 4)],
    );

    var node = findNode.assignment('= null');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: PropertyAccess
      target: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::test::@formalParameter::a
        staticType: A?
      operator: ?.
      propertyName: SimpleIdentifier
        token: b
        element: <testLibrary>::@class::A::@getter::b
        staticType: B
      staticType: B
    leftBracket: [
    index: SimpleIdentifier
      token: s
      correspondingParameter: <testLibrary>::@class::B::@method::[]=::@formalParameter::s
      element: <testLibrary>::@function::test::@formalParameter::s
      staticType: String
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: NullLiteral
    literal: null
    correspondingParameter: <testLibrary>::@class::B::@method::[]=::@formalParameter::i
    staticType: Null
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::B::@method::[]=
  writeType: int
  element: <null>
  staticType: Null
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
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement2: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
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
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement2: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_indexExpression_unresolved1_simple() async {
    await assertErrorsInCode(
      r'''
void f(int c) {
  a[b] = c;
}
''',
      [
        error(CompileTimeErrorCode.undefinedIdentifier, 18, 1),
        error(CompileTimeErrorCode.undefinedIdentifier, 20, 1),
      ],
    );

    var assignment = findNode.assignment('a[b] = c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <null>
      staticType: InvalidType
    leftBracket: [
    index: SimpleIdentifier
      token: b
      correspondingParameter: <null>
      element: <null>
      staticType: InvalidType
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_indexExpression_unresolved2_simple() async {
    await assertErrorsInCode(
      r'''
void f(int a, int c) {
  a[b] = c;
}
''',
      [
        error(CompileTimeErrorCode.undefinedOperator, 26, 3),
        error(CompileTimeErrorCode.undefinedIdentifier, 27, 1),
      ],
    );

    var assignment = findNode.assignment('a[b] = c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: int
    leftBracket: [
    index: SimpleIdentifier
      token: b
      correspondingParameter: <null>
      element: <null>
      staticType: InvalidType
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_indexExpression_unresolved3_simple() async {
    await assertErrorsInCode(
      r'''
class A {
  operator[]=(int index, num _) {}
}

void f(A a, int c) {
  a[b] = c;
}
''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 73, 1)],
    );

    var assignment = findNode.assignment('a[b] = c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    leftBracket: [
    index: SimpleIdentifier
      token: b
      correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::index
      element: <null>
      staticType: InvalidType
    rightBracket: ]
    element: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    correspondingParameter: <testLibrary>::@class::A::@method::[]=::@formalParameter::_
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_indexExpression_unresolved_missing_type_parameter_name() async {
    await assertErrorsInCode(
      r'''
abstract class A {
   void b< extends int>();
}
void f(A a) {
  a.b[0] = 0;
}
''',
      [
        error(ParserErrorCode.missingIdentifier, 30, 7),
        error(CompileTimeErrorCode.undefinedOperator, 67, 3),
      ],
    );
  }

  test_indexExpression_unresolvedTarget_compound() async {
    await assertErrorsInCode(
      r'''
void f() {
  a[0] += 1;
}
''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 13, 1)],
    );

    var node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      element: <null>
      staticType: InvalidType
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      correspondingParameter: <null>
      staticType: int
    rightBracket: ]
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_left_super() async {
    await assertErrorsInCode(
      r'''
class A {
  void f() {
    super = 0;
  }
}
''',
      [
        error(ParserErrorCode.missingAssignableSelector, 27, 5),
        error(ParserErrorCode.illegalAssignmentToNonAssignable, 27, 5),
      ],
    );

    var node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SuperExpression
    superKeyword: super
    staticType: A
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notLValue_binaryExpression_compound() async {
    await assertErrorsInCode(
      r'''
void f(int a, int b, double c) {
  a + b += c;
}
''',
      [
        error(ParserErrorCode.illegalAssignmentToNonAssignable, 35, 5),
        error(ParserErrorCode.missingAssignableSelector, 35, 5),
      ],
    );

    var assignment = findNode.assignment('= c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: BinaryExpression
    leftOperand: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: int
    operator: +
    rightOperand: SimpleIdentifier
      token: b
      correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
      element: <testLibrary>::@function::f::@formalParameter::b
      staticType: int
    element: dart:core::@class::num::@method::+
    staticInvokeType: num Function(num)
    staticType: int
  operator: +=
  rightHandSide: SimpleIdentifier
    token: c
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: double
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notLValue_parenthesized_compound() async {
    await assertErrorsInCode(
      r'''
void f(int a, int b, double c) {
  (a + b) += c;
}
''',
      [
        error(ParserErrorCode.illegalAssignmentToNonAssignable, 35, 7),
        error(ParserErrorCode.missingAssignableSelector, 35, 7),
      ],
    );

    var assignment = findNode.assignment('= c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: ParenthesizedExpression
    leftParenthesis: (
    expression: BinaryExpression
      leftOperand: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: int
      operator: +
      rightOperand: SimpleIdentifier
        token: b
        correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: int
      element: dart:core::@class::num::@method::+
      staticInvokeType: num Function(num)
      staticType: int
    rightParenthesis: )
    staticType: int
  operator: +=
  rightHandSide: SimpleIdentifier
    token: c
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: double
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notLValue_parenthesized_simple() async {
    await assertErrorsInCode(
      r'''
void f(int a, double b) {
  (a + 0) = b;
}
''',
      [
        error(
          CompileTimeErrorCode.patternTypeMismatchInIrrefutableContext,
          29,
          1,
        ),
        error(ParserErrorCode.expectedToken, 31, 1),
      ],
    );

    var node = findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: AssignedVariablePattern
      name: a
      element2: <testLibrary>::@function::f::@formalParameter::a
      matchedValueType: double
    rightParenthesis: )
    matchedValueType: double
  equals: =
  expression: SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: double
  patternTypeSchema: int
  staticType: double
''');
  }

  test_notLValue_parenthesized_simple_language219() async {
    await assertErrorsInCode(
      r'''
// @dart = 2.19
void f(int a, double b) {
  (a + 0) = b;
}
''',
      [
        error(ParserErrorCode.illegalAssignmentToNonAssignable, 44, 7),
        error(ParserErrorCode.missingAssignableSelector, 44, 7),
      ],
    );

    var node = findNode.assignment('= b');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: ParenthesizedExpression
    leftParenthesis: (
    expression: BinaryExpression
      leftOperand: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: int
      operator: +
      rightOperand: IntegerLiteral
        literal: 0
        correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
        staticType: int
      element: dart:core::@class::num::@method::+
      staticInvokeType: num Function(num)
      staticType: int
    rightParenthesis: )
    staticType: int
  operator: =
  rightHandSide: SimpleIdentifier
    token: b
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: double
  readElement2: <null>
  readType: null
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: double
''');
  }

  test_notLValue_postfixIncrement_compound() async {
    await assertErrorsInCode(
      '''
void f(num x, int y) {
  x++ += y;
}
''',
      [
        error(ParserErrorCode.illegalAssignmentToNonAssignable, 25, 3),
        error(ParserErrorCode.missingAssignableSelector, 25, 3),
      ],
    );

    var assignment = findNode.assignment('= y');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PostfixExpression
    operand: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: null
    operator: ++
    readElement2: <testLibrary>::@function::f::@formalParameter::x
    readType: num
    writeElement2: <testLibrary>::@function::f::@formalParameter::x
    writeType: num
    element: dart:core::@class::num::@method::+
    staticType: num
  operator: +=
  rightHandSide: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notLValue_postfixIncrement_compound_ifNull() async {
    await assertErrorsInCode(
      '''
void f(num x, int y) {
  x++ ??= y;
}
''',
      [
        error(ParserErrorCode.illegalAssignmentToNonAssignable, 25, 3),
        error(ParserErrorCode.missingAssignableSelector, 25, 3),
      ],
    );

    var assignment = findNode.assignment('= y');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PostfixExpression
    operand: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: null
    operator: ++
    readElement2: <testLibrary>::@function::f::@formalParameter::x
    readType: num
    writeElement2: <testLibrary>::@function::f::@formalParameter::x
    writeType: num
    element: dart:core::@class::num::@method::+
    staticType: num
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notLValue_postfixIncrement_simple() async {
    await assertErrorsInCode(
      '''
void f(num x, int y) {
  x++ = y;
}
''',
      [
        error(ParserErrorCode.illegalAssignmentToNonAssignable, 25, 3),
        error(ParserErrorCode.missingAssignableSelector, 25, 3),
      ],
    );

    var assignment = findNode.assignment('= y');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PostfixExpression
    operand: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: null
    operator: ++
    readElement2: <testLibrary>::@function::f::@formalParameter::x
    readType: num
    writeElement2: <testLibrary>::@function::f::@formalParameter::x
    writeType: num
    element: dart:core::@class::num::@method::+
    staticType: num
  operator: =
  rightHandSide: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notLValue_prefixIncrement_compound() async {
    await assertErrorsInCode(
      '''
void f(num x, int y) {
  ++x += y;
}
''',
      [
        error(ParserErrorCode.illegalAssignmentToNonAssignable, 25, 3),
        error(ParserErrorCode.missingAssignableSelector, 25, 3),
      ],
    );

    var assignment = findNode.assignment('= y');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixExpression
    operator: ++
    operand: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: null
    readElement2: <testLibrary>::@function::f::@formalParameter::x
    readType: num
    writeElement2: <testLibrary>::@function::f::@formalParameter::x
    writeType: num
    element: dart:core::@class::num::@method::+
    staticType: num
  operator: +=
  rightHandSide: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notLValue_prefixIncrement_compound_ifNull() async {
    await assertErrorsInCode(
      '''
void f(num x, int y) {
  ++x ??= y;
}
''',
      [
        error(ParserErrorCode.illegalAssignmentToNonAssignable, 25, 3),
        error(ParserErrorCode.missingAssignableSelector, 25, 3),
      ],
    );

    var assignment = findNode.assignment('= y');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixExpression
    operator: ++
    operand: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: null
    readElement2: <testLibrary>::@function::f::@formalParameter::x
    readType: num
    writeElement2: <testLibrary>::@function::f::@formalParameter::x
    writeType: num
    element: dart:core::@class::num::@method::+
    staticType: num
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notLValue_prefixIncrement_simple() async {
    await assertErrorsInCode(
      '''
void f(num x, int y) {
  ++x = y;
}
''',
      [
        error(ParserErrorCode.illegalAssignmentToNonAssignable, 25, 3),
        error(ParserErrorCode.missingAssignableSelector, 25, 3),
      ],
    );

    var assignment = findNode.assignment('= y');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixExpression
    operator: ++
    operand: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: null
    readElement2: <testLibrary>::@function::f::@formalParameter::x
    readType: num
    writeElement2: <testLibrary>::@function::f::@formalParameter::x
    writeType: num
    element: dart:core::@class::num::@method::+
    staticType: num
  operator: =
  rightHandSide: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notLValue_typeLiteral_class_ambiguous_simple() async {
    newFile('$testPackageLibPath/a.dart', 'class C {}');
    newFile('$testPackageLibPath/b.dart', 'class C {}');
    await assertErrorsInCode(
      '''
import 'a.dart';
import 'b.dart';
void f() {
  C = 0;
}
''',
      [error(CompileTimeErrorCode.ambiguousImport, 47, 1)],
    );

    var assignment = findNode.assignment('C = 0');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: C
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: multiplyDefinedElement
    package:test/a.dart::@class::C
    package:test/b.dart::@class::C
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notLValue_typeLiteral_class_simple() async {
    await assertErrorsInCode(
      '''
class C {}

void f() {
  C = 0;
}
''',
      [error(CompileTimeErrorCode.assignmentToType, 25, 1)],
    );

    var assignment = findNode.assignment('C = 0');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: C
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::C
  writeType: InvalidType
  element: <null>
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

    var node = findNode.assignment('??= f()');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::g::@formalParameter::a
    staticType: null
  operator: ??=
  rightHandSide: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      element: <testLibrary>::@function::f
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    correspondingParameter: <null>
    staticInvokeType: int? Function()
    staticType: int?
    typeArgumentTypes
      int?
  readElement2: <testLibrary>::@function::g::@formalParameter::a
  readType: int?
  writeElement2: <testLibrary>::@function::g::@formalParameter::a
  writeType: int?
  element: <null>
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
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement2: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
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
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement2: <testLibrary>::@class::A::@getter::x
  readType: int?
  writeElement2: <testLibrary>::@class::A::@setter::x
  writeType: num?
  element: <null>
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
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::_
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_instanceGetter_simple() async {
    await assertErrorsInCode(
      r'''
class A {
  int get x => 0;
}

void f(A a) {
  a.x = 2;
}
''',
      [error(CompileTimeErrorCode.assignmentToFinalNoSetter, 49, 1)],
    );

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::A::@getter::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_prefixedIdentifier_ofClass_getterAugmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  int get foo => 0;
}
''');

    await assertErrorsInCode(
      r'''
part 'a.dart';

class A {}

void f(A a) {
  a.foo = 0;
}
''',
      [error(CompileTimeErrorCode.assignmentToFinalNoSetter, 46, 3)],
    );

    var node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@getter::foo
  writeElement2: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@getter::foo#element
  writeType: InvalidType
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_prefixedIdentifier_ofClass_setterAugmentationAugments() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  augment set foo(int _) {}
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

class A {
  set foo(int _) {}
}

void f(A a) {
  a.foo = 0;
}
''');

    var node = findNode.singleAssignmentExpression;
    // TODO(scheglov): implement augmentation
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <testLibraryFragment>::@class::A::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@setterAugmentation::foo
  writeElement2: <testLibraryFragment>::@class::A::@setter::foo#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_prefixedIdentifier_ofClass_setterAugmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  set foo(int _) {}
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

class A {}

void f(A a) {
  a.foo = 0;
}
''');

    var node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@setter::foo
  writeElement2: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@setter::foo#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_prefixedIdentifier_ofClassName_getterAugmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  static int get foo => 0;
}
''');

    await assertErrorsInCode(
      r'''
part 'a.dart';

class A {}

void f() {
  A.foo = 0;
}
''',
      [error(CompileTimeErrorCode.assignmentToFinalNoSetter, 43, 3)],
    );

    var node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@getter::foo
  writeElement2: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@getter::foo#element
  writeType: InvalidType
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_prefixedIdentifier_ofClassName_setterAugmentationAugments() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  augment static set foo(int _) {}
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

class A {
  static set foo(int _) {}
}

void f() {
  A.foo = 0;
}
''');

    var node = findNode.singleAssignmentExpression;
    // TODO(scheglov): implement augmentation
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <testLibraryFragment>::@class::A::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@setterAugmentation::foo
  writeElement2: <testLibraryFragment>::@class::A::@setter::foo#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_prefixedIdentifier_ofClassName_setterAugmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  static set foo(int _) {}
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

class A {}

void f() {
  A.foo = 0;
}
''');

    var node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@setter::foo
  writeElement2: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@setter::foo#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_prefixedIdentifier_ofExtensionName_augmentationAugments() async {
    await assertNoErrorsInCode(r'''
extension A on int {
  static set foo(int _) {}
}

augment extension A {
  augment static set foo(int _) {}
}

void f() {
  A.foo = 0;
}
''');

    var node = findNode.singleAssignmentExpression;
    // TODO(scheglov): implement augmentation
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: <testLibraryFragment>::@extension::A
      element: <testLibrary>::@extension::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <testLibraryFragment>::@extension::A::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@extensionAugmentation::A::@setterAugmentation::foo
  writeElement2: <testLibraryFragment>::@extension::A::@setter::foo#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_prefixedIdentifier_ofExtensionName_augmentationDeclares() async {
    await assertNoErrorsInCode(r'''
extension A on int {}

augment extension A {
  static set foo(int _) {}
}

void f() {
  A.foo = 0;
}
''');

    var node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: <testLibraryFragment>::@extension::A
      element: <testLibrary>::@extension::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <testLibraryFragment>::@extensionAugmentation::A::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@extensionAugmentation::A::@setter::foo
  writeElement2: <testLibraryFragment>::@extensionAugmentation::A::@setter::foo#element
  writeType: int
  staticElement: <null>
  element: <null>
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
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::_
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_staticGetter_simple() async {
    await assertErrorsInCode(
      r'''
class A {
  static int get x => 0;
}

void f() {
  A.x = 2;
}
''',
      [error(CompileTimeErrorCode.assignmentToFinalNoSetter, 53, 1)],
    );

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::A::@getter::x
  writeType: InvalidType
  element: <null>
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
      element: <testLibraryFragment>::@prefix2::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: package:test/a.dart::@getter::x
  readType: int
  writeElement2: package:test/a.dart::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
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
      element: <testLibrary>::@typeAlias::B
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement2: <testLibrary>::@class::A::@setter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_prefixedIdentifier_unresolved1_simple() async {
    await assertErrorsInCode(
      r'''
void f(int c) {
  a.b = c;
}
''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 18, 1)],
    );

    var assignment = findNode.assignment('a.b = c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <null>
      staticType: InvalidType
    period: .
    identifier: SimpleIdentifier
      token: b
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_unresolved2_compound() async {
    await assertErrorsInCode(
      r'''
void f(int a, int c) {
  a.b += c;
}
''',
      [
        error(CompileTimeErrorCode.undefinedGetter, 27, 1),
        error(CompileTimeErrorCode.undefinedSetter, 27, 1),
      ],
    );

    var assignment = findNode.assignment('a.b += c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: int
    period: .
    identifier: SimpleIdentifier
      token: b
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: SimpleIdentifier
    token: c
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
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
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement2: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
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
          element2: <testLibrary>::@class::B
          type: B
        element: <testLibrary>::@class::B::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: B
    operator: .
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
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::A::@setter::x
  writeType: int
  element: <null>
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
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
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
  readElement2: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement2: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
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
        element: <testLibrary>::@function::f::@formalParameter::c
        staticType: C
      rightParenthesis: )
      staticType: C
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
  readElement2: <testLibrary>::@mixin::M2::@getter::x
  readType: int
  writeElement2: <testLibrary>::@mixin::M2::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
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
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement2: <testLibrary>::@class::A::@getter::x
  readType: int?
  writeElement2: <testLibrary>::@class::A::@setter::x
  writeType: num?
  element: <null>
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
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::_
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_propertyAccess_nullShorting_assignable() async {
    await assertNoErrorsInCode('''
abstract class A {
  B get b;
}
abstract class B {
  set setter(int i);
}
test(A? a) {
  a?.b.setter = 0;
}
''');

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: PropertyAccess
      target: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::test::@formalParameter::a
        staticType: A?
      operator: ?.
      propertyName: SimpleIdentifier
        token: b
        element: <testLibrary>::@class::A::@getter::b
        staticType: B
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: setter
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::B::@setter::setter::@formalParameter::i
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::B::@setter::setter
  writeType: int
  element: <null>
  staticType: int?
''');
  }

  test_propertyAccess_nullShorting_notAssignable() async {
    await assertErrorsInCode(
      '''
abstract class A {
  B get b;
}
abstract class B {
  set setter(int i);
}
test(A? a) {
  a?.b.setter = null;
}
''',
      [error(CompileTimeErrorCode.invalidAssignment, 103, 4)],
    );

    var node = findNode.assignment('= null');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: PropertyAccess
      target: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::test::@formalParameter::a
        staticType: A?
      operator: ?.
      propertyName: SimpleIdentifier
        token: b
        element: <testLibrary>::@class::A::@getter::b
        staticType: B
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: setter
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: NullLiteral
    literal: null
    correspondingParameter: <testLibrary>::@class::B::@setter::setter::@formalParameter::i
    staticType: Null
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::B::@setter::setter
  writeType: int
  element: <null>
  staticType: Null
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_propertyAccess_ofClass_setterAugmentationAugments() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  augment set foo(int _) {}
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

class A {
  set foo(int _) {}
}

void f(A a) {
  (a).foo = 0;
}
''');

    var node = findNode.singleAssignmentExpression;
    // TODO(scheglov): implement augmentation
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        staticElement: <testLibraryFragment>::@function::f::@parameter::a
        element: <testLibraryFragment>::@function::f::@parameter::a#element
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <testLibraryFragment>::@class::A::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@setterAugmentation::foo
  writeElement2: <testLibraryFragment>::@class::A::@setter::foo#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_propertyAccess_ofClass_setterAugmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  set foo(int _) {}
}
''');
    await assertNoErrorsInCode(r'''
part 'a.dart';

class A {}

void f(A a) {
  (a).foo = 0;
}
''');

    var node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        staticElement: <testLibraryFragment>::@function::f::@parameter::a
        element: <testLibraryFragment>::@function::f::@parameter::a#element
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@setter::foo
  writeElement2: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@setter::foo#element
  writeType: int
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  /// Has record getter:    false
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_FFFF_compound() async {
    await assertErrorsInCode(
      r'''
void f(({int bar}) r) {
  r.foo += 0;
}
''',
      [
        error(CompileTimeErrorCode.undefinedGetter, 28, 3),
        error(CompileTimeErrorCode.undefinedSetter, 28, 3),
      ],
    );

    var node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  /// Has record getter:    false
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_FFFF_simple() async {
    await assertErrorsInCode(
      r'''
void f(({int bar}) r) {
  r.foo = 0;
}
''',
      [error(CompileTimeErrorCode.undefinedSetter, 28, 3)],
    );

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  /// Has record getter:    false
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_named_FFFT_compound() async {
    await assertErrorsInCode(
      r'''
extension E on ({int bar}) {
  set foo(int _) {}
}

void f(({int bar}) r) {
  r.foo += 0;
}
''',
      [error(CompileTimeErrorCode.undefinedGetter, 80, 3)],
    );

    var node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement2: <testLibrary>::@extension::E::@setter::foo
  readType: InvalidType
  writeElement2: <testLibrary>::@extension::E::@setter::foo
  writeType: int
  element: <null>
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

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@extension::E::@setter::foo::@formalParameter::_
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@extension::E::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  /// Has record getter:    false
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_FTFF_compound() async {
    await assertErrorsInCode(
      r'''
extension E on ({int bar}) {
  int get foo => 0;
}

void f(({int bar}) r) {
  r.foo += 0;
}
''',
      [error(CompileTimeErrorCode.assignmentToFinalNoSetter, 80, 3)],
    );

    var node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <testLibrary>::@extension::E::@getter::foo
  readType: int
  writeElement2: <testLibrary>::@extension::E::@getter::foo
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    false
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_FTFF_simple() async {
    await assertErrorsInCode(
      r'''
extension E on ({int bar}) {
  int get foo => 0;
}

void f(({int bar}) r) {
  r.foo = 0;
}
''',
      [error(CompileTimeErrorCode.assignmentToFinalNoSetter, 80, 3)],
    );

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@extension::E::@getter::foo
  writeType: InvalidType
  element: <null>
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

    var node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <testLibrary>::@extension::E::@getter::foo
  readType: int
  writeElement2: <testLibrary>::@extension::E::@setter::foo
  writeType: int
  element: dart:core::@class::num::@method::+
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

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@extension::E::@setter::foo::@formalParameter::_
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@extension::E::@setter::foo
  writeType: int
  element: <null>
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_TFFF_compound() async {
    await assertErrorsInCode(
      r'''
void f(({int foo, String bar}) r) {
  r.foo += 0;
}
''',
      [error(CompileTimeErrorCode.undefinedSetter, 40, 3)],
    );

    var node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <null>
  readType: int
  writeElement2: <null>
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_TFFF_simple() async {
    await assertErrorsInCode(
      r'''
void f(({int foo, String bar}) r) {
  r.foo = 0;
}
''',
      [error(CompileTimeErrorCode.undefinedSetter, 40, 3)],
    );

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_named_TFFT_compound() async {
    await assertErrorsInCode(
      r'''
extension E on ({int foo, String bar}) {
  set foo(int _) {}
}

void f(({int foo, String bar}) r) {
  r.foo += 0;
}
''',
      [error(CompileTimeErrorCode.undefinedSetter, 104, 3)],
    );

    var node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <null>
  readType: int
  writeElement2: <null>
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_named_TFFT_simple() async {
    await assertErrorsInCode(
      r'''
extension E on ({int foo, String bar}) {
  set foo(int _) {}
}

void f(({int foo, String bar}) r) {
  r.foo = 0;
}
''',
      [error(CompileTimeErrorCode.undefinedSetter, 104, 3)],
    );

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_TTFF_compound() async {
    await assertErrorsInCode(
      r'''
extension E on ({int foo, String bar}) {
  int get foo => 0;
}

void f(({int foo, String bar}) r) {
  r.foo += 0;
}
''',
      [error(CompileTimeErrorCode.undefinedSetter, 104, 3)],
    );

    var node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <null>
  readType: int
  writeElement2: <null>
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_TTFF_simple() async {
    await assertErrorsInCode(
      r'''
extension E on ({int foo, String bar}) {
  int get foo => 0;
}

void f(({int foo, String bar}) r) {
  r.foo = 0;
}
''',
      [error(CompileTimeErrorCode.undefinedSetter, 104, 3)],
    );

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_named_TTFT_compound() async {
    await assertErrorsInCode(
      r'''
extension E on ({int foo, String bar}) {
  int get foo => 0;
  set foo(int _) {}
}

void f(({int foo, String bar}) r) {
  r.foo += 0;
}
''',
      [error(CompileTimeErrorCode.undefinedSetter, 124, 3)],
    );

    var node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <null>
  readType: int
  writeElement2: <null>
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_named_TTFT_simple() async {
    await assertErrorsInCode(
      r'''
extension E on ({int foo, String bar}) {
  int get foo => 0;
  set foo(int _) {}
}

void f(({int foo, String bar}) r) {
  r.foo = 0;
}
''',
      [error(CompileTimeErrorCode.undefinedSetter, 124, 3)],
    );

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  /// Has record getter:    false
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_positional_FFFF_compound() async {
    await assertErrorsInCode(
      r'''
void f((int, String) r) {
  r.$4 += 0;
}
''',
      [
        error(CompileTimeErrorCode.undefinedGetter, 30, 2),
        error(CompileTimeErrorCode.undefinedSetter, 30, 2),
      ],
    );

    var node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $4
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  /// Has record getter:    false
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_positional_FFFF_simple() async {
    await assertErrorsInCode(
      r'''
void f((int, String) r) {
  r.$4 = 0;
}
''',
      [error(CompileTimeErrorCode.undefinedSetter, 30, 2)],
    );

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $4
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  /// Has record getter:    false
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_positional_FTFF_compound() async {
    await assertErrorsInCode(
      r'''
extension E on (int, String) {
  int get $3 => 0;
}

void f((int, String) r) {
  r.$3 += 0;
}
''',
      [error(CompileTimeErrorCode.assignmentToFinalNoSetter, 83, 2)],
    );

    var node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $3
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <testLibrary>::@extension::E::@getter::$3
  readType: int
  writeElement2: <testLibrary>::@extension::E::@getter::$3
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    false
  /// Has extension getter: true
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_positional_FTFF_simple() async {
    await assertErrorsInCode(
      r'''
extension E on (int, String) {
  int get $3 => 0;
}

void f((int, String) r) {
  r.$3 = 0;
}
''',
      [error(CompileTimeErrorCode.assignmentToFinalNoSetter, 83, 2)],
    );

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $3
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@extension::E::@getter::$3
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_positional_TFFF_compound() async {
    await assertErrorsInCode(
      r'''
void f((int, String) r) {
  r.$1 += 0;
}
''',
      [error(CompileTimeErrorCode.undefinedSetter, 30, 2)],
    );

    var node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $1
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <null>
  readType: int
  writeElement2: <null>
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_positional_TFFF_simple() async {
    await assertErrorsInCode(
      r'''
void f((int, String) r) {
  r.$1 = 0;
}
''',
      [error(CompileTimeErrorCode.undefinedSetter, 30, 2)],
    );

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $1
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_positional_TFFT_compound() async {
    await assertErrorsInCode(
      r'''
extension E on (int, String) {
  set $1(int _) {}
}

void f((int, String) r) {
  r.$1 += 0;
}
''',
      [error(CompileTimeErrorCode.undefinedSetter, 83, 2)],
    );

    var node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $1
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <null>
  readType: int
  writeElement2: <null>
  writeType: InvalidType
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  /// Has record getter:    true
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: true
  test_propertyAccess_recordTypeField_positional_TFFT_simple() async {
    await assertErrorsInCode(
      r'''
extension E on (int, String) {
  set $1(int _) {}
}

void f((int, String) r) {
  r.$1 = 0;
}
''',
      [error(CompileTimeErrorCode.undefinedSetter, 83, 2)],
    );

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      element: <testLibrary>::@function::f::@formalParameter::r
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $1
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
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
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement2: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
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
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement2: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_propertyAccess_unresolved1_simple() async {
    await assertErrorsInCode(
      r'''
void f(int c) {
  (a).b = c;
}
''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 19, 1)],
    );

    var assignment = findNode.assignment('(a).b = c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <null>
        staticType: InvalidType
      rightParenthesis: )
      staticType: InvalidType
    operator: .
    propertyName: SimpleIdentifier
      token: b
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_propertyAccess_unresolved2_simple() async {
    await assertErrorsInCode(
      r'''
void f(int a, int c) {
  (a).b = c;
}
''',
      [error(CompileTimeErrorCode.undefinedSetter, 29, 1)],
    );

    var assignment = findNode.assignment('(a).b = c');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: int
      rightParenthesis: )
      staticType: int
    operator: .
    propertyName: SimpleIdentifier
      token: b
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_right_super() async {
    await assertErrorsInCode(
      r'''
class A {
  void f(Object a) {
    a = super;
  }
}
''',
      [error(ParserErrorCode.missingAssignableSelector, 39, 5)],
    );

    var node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    element: <testLibrary>::@class::A::@method::f::@formalParameter::a
    staticType: null
  operator: =
  rightHandSide: SuperExpression
    superKeyword: super
    staticType: A
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::A::@method::f::@formalParameter::a
  writeType: Object
  element: <null>
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
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::C::@setter::x::@formalParameter::value
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::C::@setter::x
  writeType: num
  element: <null>
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
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::C::@setter::x::@formalParameter::value
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::C::@setter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_getterInstance_simple() async {
    await assertErrorsInCode(
      '''
class C {
  num get x => 0;

  void f() {
    x = 2;
  }
}
''',
      [error(CompileTimeErrorCode.assignmentToFinalNoSetter, 46, 1)],
    );

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::C::@getter::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_getterStatic_simple() async {
    await assertErrorsInCode(
      '''
class C {
  static num get x => 0;

  void f() {
    x = 2;
  }
}
''',
      [error(CompileTimeErrorCode.assignmentToFinalNoSetter, 53, 1)],
    );

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::C::@getter::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_getterTopLevel_simple() async {
    await assertErrorsInCode(
      '''
int get x => 0;

void f() {
  x = 2;
}
''',
      [error(CompileTimeErrorCode.assignmentToFinal, 30, 1)],
    );

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@getter::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_importPrefix_hasSuperSetter_simple() async {
    await assertErrorsInCode(
      '''
import 'dart:math' as x;

class A {
  var x;
}

class B extends A {
  void f() {
    x = 2;
  }
}
''',
      [error(CompileTimeErrorCode.prefixIdentifierNotFollowedByDot, 85, 1)],
    );

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibraryFragment>::@prefix2::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_importPrefix_simple() async {
    await assertErrorsInCode(
      '''
import 'dart:math' as x;

main() {
  x = 2;
}
''',
      [error(CompileTimeErrorCode.prefixIdentifierNotFollowedByDot, 37, 1)],
    );

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibraryFragment>::@prefix2::x
  writeType: InvalidType
  element: <null>
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
    element: x@51
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 3
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: x@51
  readType: num
  writeElement2: x@51
  writeType: num
  element: dart:core::@class::num::@method::+
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
    element: x@51
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: x@51
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_localVariableConst_simple() async {
    await assertErrorsInCode(
      '''
void f() {
  // ignore:unused_local_variable
  const num x = 1;
  x = 2;
}
''',
      [error(CompileTimeErrorCode.assignmentToConst, 66, 1)],
    );

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: x@57
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: x@57
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_localVariableFinal_simple() async {
    await assertErrorsInCode(
      '''
void f() {
  // ignore:unused_local_variable
  final num x = 1;
  x = 2;
}
''',
      [error(CompileTimeErrorCode.assignmentToFinalLocal, 66, 1)],
    );

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: x@57
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: x@57
  writeType: num
  element: <null>
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
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement2: <testLibrary>::@function::f::@formalParameter::x
  readType: num?
  writeElement2: <testLibrary>::@function::f::@formalParameter::x
  writeType: num?
  element: <null>
  staticType: num
''');
  }

  test_simpleIdentifier_parameter_compound_ifNull2() async {
    await assertErrorsInCode(
      '''
class A {}
class B extends A {}
class C extends A {}

void f(B? x) {
  x ??= C();
}
''',
      [error(CompileTimeErrorCode.invalidAssignment, 77, 3)],
    );

    var assignment = findNode.assignment('x ??=');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: ??=
  rightHandSide: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: C
        element2: <testLibrary>::@class::C
        type: C
      element: <testLibrary>::@class::C::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    correspondingParameter: <null>
    staticType: C
  readElement2: <testLibrary>::@function::f::@formalParameter::x
  readType: B?
  writeElement2: <testLibrary>::@function::f::@formalParameter::x
  writeType: B?
  element: <null>
  staticType: A
''');
  }

  test_simpleIdentifier_parameter_compound_ifNull_notAssignableType() async {
    await assertErrorsInCode(
      '''
void f(double? a, int b) {
  a ??= b;
}
''',
      [error(CompileTimeErrorCode.invalidAssignment, 35, 1)],
    );

    var assignment = findNode.assignment('a ??=');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: null
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: b
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: int
  readElement2: <testLibrary>::@function::f::@formalParameter::a
  readType: double?
  writeElement2: <testLibrary>::@function::f::@formalParameter::a
  writeType: double?
  element: <null>
  staticType: num
''');
  }

  test_simpleIdentifier_parameter_compound_refineType_int_double() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  x += 1.2;
  x -= 1.2;
  x *= 1.2;
  x %= 1.2;
}
''',
      [
        error(CompileTimeErrorCode.invalidAssignment, 23, 3),
        error(CompileTimeErrorCode.invalidAssignment, 35, 3),
        error(CompileTimeErrorCode.invalidAssignment, 47, 3),
        error(CompileTimeErrorCode.invalidAssignment, 59, 3),
      ],
    );
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
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@function::f::@formalParameter::x
  writeType: num
  element: <null>
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
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: double
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@function::f::@formalParameter::x
  writeType: Object
  element: <null>
  staticType: double
''');
  }

  test_simpleIdentifier_parameter_simple_notAssignableType() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  x = true;
}
''',
      [error(CompileTimeErrorCode.invalidAssignment, 22, 4)],
    );

    var assignment = findNode.assignment('x = true');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: =
  rightHandSide: BooleanLiteral
    literal: true
    correspondingParameter: <null>
    staticType: bool
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@function::f::@formalParameter::x
  writeType: int
  element: <null>
  staticType: bool
''');
  }

  test_simpleIdentifier_parameterFinal_simple() async {
    await assertErrorsInCode(
      '''
void f(final int x) {
  x = 2;
}
''',
      [error(CompileTimeErrorCode.assignmentToFinalLocal, 24, 1)],
    );

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@function::f::@formalParameter::x
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_staticGetter_superSetter_simple() async {
    await assertErrorsInCode(
      '''
class A {
  set x(num _) {}
}

class B extends A {
  static int get x => 1;

  void f() {
    x = 2;
  }
}
''',
      [
        error(CompileTimeErrorCode.conflictingStaticAndInstance, 68, 1),
        error(CompileTimeErrorCode.assignmentToFinalNoSetter, 94, 1),
      ],
    );

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::B::@getter::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_staticMethod_superSetter_simple() async {
    await assertErrorsInCode(
      '''
class A {
  set x(num _) {}
}

class B extends A {
  static void x() {}

  void f() {
    x = 2;
  }
}
''',
      [
        error(CompileTimeErrorCode.conflictingStaticAndInstance, 65, 1),
        error(CompileTimeErrorCode.assignmentToMethod, 90, 1),
      ],
    );

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::B::@method::x
  writeType: InvalidType
  element: <null>
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
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::_
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_synthetic_simple() async {
    await assertErrorsInCode(
      '''
void f(int y) {
  = y;
}
''',
      [error(ParserErrorCode.missingIdentifier, 18, 1)],
    );

    var assignment = findNode.assignment('= y');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: <empty> <synthetic>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
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
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@class::A::@setter::x::@formalParameter::value
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@class::A::@setter::x
  writeType: int
  element: <null>
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
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <testLibrary>::@class::C::@getter::x
  readType: int
  writeElement2: <testLibrary>::@class::C::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
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
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <testLibrary>::@mixin::M2::@getter::x
  readType: int
  writeElement2: <testLibrary>::@mixin::M2::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
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
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement2: <testLibrary>::@class::C::@getter::x
  readType: int?
  writeElement2: <testLibrary>::@class::C::@setter::x
  writeType: num?
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_topGetter_superSetter_simple() async {
    await assertErrorsInCode(
      '''
class A {
  set x(num _) {}
}

int get x => 1;

class B extends A {

  void f() {
    x = 2;
  }
}
''',
      [error(CompileTimeErrorCode.assignmentToFinal, 86, 1)],
    );

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@getter::x
  writeType: InvalidType
  element: <null>
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
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <testLibrary>::@getter::x
  readType: int
  writeElement2: <testLibrary>::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_simpleIdentifier_topGetter_topSetter_compound_ifNull2() async {
    await assertErrorsInCode(
      '''
void f() {
  x ??= C();
}

class A {}
class B extends A {}
class C extends A {}

B? get x => B();
set x(B? _) {}
''',
      [error(CompileTimeErrorCode.invalidAssignment, 19, 3)],
    );

    var assignment = findNode.assignment('x ??=');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: C
        element2: <testLibrary>::@class::C
        type: C
      element: <testLibrary>::@class::C::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    correspondingParameter: <null>
    staticType: C
  readElement2: <testLibrary>::@getter::x
  readType: B?
  writeElement2: <testLibrary>::@setter::x
  writeType: B?
  element: <null>
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
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  readElement2: <testLibrary>::@getter::x
  readType: int
  writeElement2: <testLibrary>::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
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
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <testLibrary>::@setter::x::@formalParameter::value
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@setter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_topLevelVariable_simple_notAssignableType() async {
    await assertErrorsInCode(
      r'''
int x = 0;

void f() {
  x = true;
}
''',
      [error(CompileTimeErrorCode.invalidAssignment, 29, 4)],
    );

    var assignment = findNode.assignment('x = true');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: BooleanLiteral
    literal: true
    correspondingParameter: <testLibrary>::@setter::x::@formalParameter::value
    staticType: bool
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@setter::x
  writeType: int
  element: <null>
  staticType: bool
''');
  }

  test_simpleIdentifier_topLevelVariableFinal_simple() async {
    await assertErrorsInCode(
      r'''
final num x = 0;

void f() {
  x = 2;
}
''',
      [error(CompileTimeErrorCode.assignmentToFinal, 31, 1)],
    );

    var assignment = findNode.assignment('x = 2');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <testLibrary>::@getter::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_typeLiteral_compound() async {
    await assertErrorsInCode(
      r'''
void f() {
  int += 3;
}
''',
      [error(CompileTimeErrorCode.assignmentToType, 13, 3)],
    );

    var assignment = findNode.assignment('int += 3');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: int
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 3
    correspondingParameter: <null>
    staticType: int
  readElement2: dart:core::@class::int
  readType: InvalidType
  writeElement2: dart:core::@class::int
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_simpleIdentifier_typeLiteral_simple() async {
    await assertErrorsInCode(
      r'''
void f() {
  int = 0;
}
''',
      [error(CompileTimeErrorCode.assignmentToType, 13, 3)],
    );

    var assignment = findNode.assignment('int = 0');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: int
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: dart:core::@class::int
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_unresolved_compound() async {
    await assertErrorsInCode(
      r'''
void f() {
  x += 1;
}
''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 13, 1)],
    );

    var assignment = findNode.assignment('x += 1');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    correspondingParameter: <null>
    staticType: int
  readElement2: <null>
  readType: InvalidType
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_simpleIdentifier_unresolved_simple() async {
    await assertErrorsInCode(
      r'''
void f(int a) {
  x = a;
}
''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 18, 1)],
    );

    var assignment = findNode.assignment('x = a');

    assertResolvedNodeText(assignment, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
    element: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: a
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  readElement2: <null>
  readType: null
  writeElement2: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }
}

@reflectiveTest
class InferenceUpdate3Test extends PubPackageResolutionTest {
  test_ifNull_contextIsConvertedToATypeUsingGreatestClosure() async {
    await assertNoErrorsInCode('''
class A {}
class B1<T> extends A {}
class B2<T> extends A {}
class C1<T> implements B1<T>, B2<T> {}
class C2<T> implements B1<T>, B2<T> {}
void contextB1<T>(B1<T> b1) {}
f(Object? o, C2<double> c2) {
  if (o is C1<int>?) {
    contextB1(o ??= c2);
  }
}
''');

    assertResolvedNodeText(
      findNode.assignment('o ??= c2'),
      r'''AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: o
    element: <testLibrary>::@function::f::@formalParameter::o
    staticType: null
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: c2
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c2
    staticType: C2<double>
  correspondingParameter: ParameterMember
    baseElement: <testLibrary>::@function::contextB1::@formalParameter::b1
    substitution: {T: Object?}
  readElement2: <testLibrary>::@function::f::@formalParameter::o
  readType: C1<int>?
  writeElement2: <testLibrary>::@function::f::@formalParameter::o
  writeType: Object?
  element: <null>
  staticType: B1<Object?>
''',
    );
  }

  test_ifNull_contextNotUsedIfLhsDoesNotSatisfyContext() async {
    await assertNoErrorsInCode('''
f(Object? o1, Object? o2, int? i) {
  if (o1 is int? && o2 is double?) {
    o1 = (o2 ??= i);
  }
}
''');

    assertResolvedNodeText(
      findNode.assignment('o2 ??= i'),
      r'''AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: o2
    element: <testLibrary>::@function::f::@formalParameter::o2
    staticType: null
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: i
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::i
    staticType: int?
  readElement2: <testLibrary>::@function::f::@formalParameter::o2
  readType: double?
  writeElement2: <testLibrary>::@function::f::@formalParameter::o2
  writeType: Object?
  element: <null>
  staticType: num?
''',
    );
  }

  test_ifNull_contextUsedInsteadOfLubIfLubDoesNotSatisfyContext() async {
    await assertNoErrorsInCode('''
class A {}
class B1 extends A {}
class B2 extends A {}
class C1 implements B1, B2 {}
class C2 implements B1, B2 {}
void contextB1(B1 b1) {}
f(Object? o, C2 c2) {
  if (o is C1?) {
    contextB1(o ??= c2);
  }
}
''');

    assertResolvedNodeText(findNode.assignment('o ??= c2'), r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: o
    element: <testLibrary>::@function::f::@formalParameter::o
    staticType: null
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: c2
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c2
    staticType: C2
  correspondingParameter: <testLibrary>::@function::contextB1::@formalParameter::b1
  readElement2: <testLibrary>::@function::f::@formalParameter::o
  readType: C1?
  writeElement2: <testLibrary>::@function::f::@formalParameter::o
  writeType: Object?
  element: <null>
  staticType: B1
''');
  }
}
