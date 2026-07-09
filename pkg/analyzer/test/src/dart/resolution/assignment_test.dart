// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>() => throw Error();
g(int a) {
  a += f();
}
''');

    var node = result.findNode.assignment('+= f()');
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
  readElement: <testLibrary>::@function::g::@formalParameter::a
  readType: int
  writeElement: <testLibrary>::@function::g::@formalParameter::a
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_compound_plus_int_context_int_complex() async {
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>() => throw Error();
g(List<int> a) {
  a[0] += f();
}
''');

    var node = result.findNode.assignment('+= f()');
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
      correspondingParameter: SubstitutedFormalParameterElementImpl
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
  readElement: SubstitutedMethodElementImpl
    baseElement: dart:core::@class::List::@method::[]
    substitution: {E: int}
  readType: int
  writeElement: SubstitutedMethodElementImpl
    baseElement: dart:core::@class::List::@method::[]=
    substitution: {E: int}
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_compound_plus_int_context_int_promoted() async {
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>() => throw Error();
g(num a) {
  if (a is int) {
    a += f();
  }
}
''');

    var node = result.findNode.assignment('+= f()');
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
  readElement: <testLibrary>::@function::g::@formalParameter::a
  readType: int
  writeElement: <testLibrary>::@function::g::@formalParameter::a
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_compound_plus_int_context_int_promoted_with_subsequent_demotion() async {
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>() => throw Error();
g(num a, bool b) {
  if (a is int) {
    a += b ? f() : 1.0;
    a;
  }
}
''');

    var node = result.findNode.assignment('+=');
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
  readElement: <testLibrary>::@function::g::@formalParameter::a
  readType: int
  writeElement: <testLibrary>::@function::g::@formalParameter::a
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: num
''');

    var node2 = result.findNode.simple('a;');
    assertResolvedNodeText(node2, r'''
SimpleIdentifier
  token: a
  element: <testLibrary>::@function::g::@formalParameter::a
  staticType: num
''');
  }

  test_dynamicIdentifier_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(dynamic a) {
  a += 0;
}
''');

    var node = result.findNode.singleAssignmentExpression;
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
  readElement: <testLibrary>::@function::f::@formalParameter::a
  readType: dynamic
  writeElement: <testLibrary>::@function::f::@formalParameter::a
  writeType: dynamic
  element: <null>
  staticType: dynamic
''');
  }

  test_dynamicIdentifier_identifier_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(dynamic a) {
  a.foo += 0;
}
''');

    var node = result.findNode.singleAssignmentExpression;
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
  readElement: <null>
  readType: dynamic
  writeElement: <null>
  writeType: dynamic
  element: <null>
  staticType: dynamic
''');
  }

  test_dynamicIdentifier_identifier_identifier_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(dynamic a) {
  a.foo.bar += 0;
}
''');

    var node = result.findNode.singleAssignmentExpression;
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
  readElement: <null>
  readType: dynamic
  writeElement: <null>
  writeType: dynamic
  element: <null>
  staticType: dynamic
''');
  }

  test_ifNull_lubUsedEvenIfItDoesNotSatisfyContext() async {
    var result = await resolveTestCodeWithDiagnostics('''
// @dart=3.3
f(Object? o1, Object? o2, List<num> listNum) {
  if (o1 is Iterable<int>? && o2 is Iterable<num>) {
    o2 = (o1 ??= listNum);
  }
}
''');

    var node = result.findNode.assignment('o1 ??= listNum');
    assertResolvedNodeText(node, r'''
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
  readElement: <testLibrary>::@function::f::@formalParameter::o1
  readType: Iterable<int>?
  writeElement: <testLibrary>::@function::f::@formalParameter::o1
  writeType: Object?
  element: <null>
  staticType: Object
''');
  }

  test_importPrefix_deferred_topLevelVariable_simple() async {
    newFile('$testPackageLibPath/a.dart', '''
var v = 0;
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' deferred as prefix;

void f() {
  prefix.v = 0;
}
''');

    var node = result.findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix::prefix
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
  readElement: <null>
  readType: null
  writeElement: package:test/a.dart::@setter::v
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_indexExpression_cascade_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

void f(A a) {
  a..[0] += 2;
}
''');

    var node = result.findNode.assignment('[0] += 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_indexExpression_dynamicTarget_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(dynamic a) {
  a[0] += 1;
}
''');

    var node = result.findNode.singleAssignmentExpression;
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
  readElement: <null>
  readType: dynamic
  writeElement: <null>
  writeType: dynamic
  element: <null>
  staticType: dynamic
''');
  }

  test_indexExpression_instance_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

void f(A a) {
  a[0] += 2;
}
''');

    var node = result.findNode.assignment('[0] += 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_indexExpression_instance_compound_double_num() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  num operator[](int index) => 0;
  operator[]=(int index, num _) {}
}

void f(A a) {
  a[0] += 2.0;
}
''');

    var node = result.findNode.assignment('[0] += 2.0');
    assertResolvedNodeText(node, r'''
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
  readElement: <testLibrary>::@class::A::@method::[]
  readType: num
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: double
''');
  }

  test_indexExpression_instance_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int? operator[](int? index) => 0;
  operator[]=(int? index, num? _) {}
}

void f(A a) {
  a[0] ??= 2;
}
''');

    var node = result.findNode.assignment('[0] ??= 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <testLibrary>::@class::A::@method::[]
  readType: int?
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num?
  element: <null>
  staticType: int
''');
  }

  test_indexExpression_instance_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  operator[]=(int index, num _) {}
}

void f(A a) {
  a[0] = 2;
}
''');

    var node = result.findNode.assignment('[0] = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_indexExpression_nullShorting_assignable() async {
    var result = await resolveTestCodeWithDiagnostics('''
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

    var node = result.findNode.assignment('= 0');
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::B::@method::[]=
  writeType: int
  element: <null>
  staticType: int?
''');
  }

  test_indexExpression_nullShorting_notAssignable() async {
    var result = await resolveTestCodeWithDiagnostics('''
abstract class A {
  B get b;
}
abstract class B {
  operator []=(String s, int i);
}
test(A? a, String s) {
  a?.b[s] = null;
//          ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'int'.
}
''');

    var node = result.findNode.assignment('= null');
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::B::@method::[]=
  writeType: int
  element: <null>
  staticType: Null
''');
  }

  test_indexExpression_super_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.assignment('[0] += 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_indexExpression_this_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int operator[](int index) => 0;
  operator[]=(int index, num _) {}

  void f() {
    this[0] += 2;
  }
}
''');

    var node = result.findNode.assignment('[0] += 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <testLibrary>::@class::A::@method::[]
  readType: int
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_indexExpression_unresolved1_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int c) {
  a[b] = c;
//^
// [diag.undefinedIdentifier] Undefined name 'a'.
//  ^
// [diag.undefinedIdentifier] Undefined name 'b'.
}
''');

    var node = result.findNode.assignment('a[b] = c');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_indexExpression_unresolved2_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int a, int c) {
  a[b] = c;
// ^^^
// [diag.undefinedOperator] The operator '[]=' isn't defined for the type 'int'.
//  ^
// [diag.undefinedIdentifier] Undefined name 'b'.
}
''');

    var node = result.findNode.assignment('a[b] = c');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_indexExpression_unresolved3_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  operator[]=(int index, num _) {}
}

void f(A a, int c) {
  a[b] = c;
//  ^
// [diag.undefinedIdentifier] Undefined name 'b'.
}
''');

    var node = result.findNode.assignment('a[b] = c');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@method::[]=
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_indexExpression_unresolved_missing_type_parameter_name() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
   void b< extends int>();
//         ^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
}
void f(A a) {
  a.b[0] = 0;
//   ^^^
// [diag.undefinedOperator] The operator '[]=' isn't defined for the type 'void Function< extends int>()'.
}
''');
  }

  test_indexExpression_unresolvedTarget_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  a[0] += 1;
//^
// [diag.undefinedIdentifier] Undefined name 'a'.
}
''');

    var node = result.findNode.singleAssignmentExpression;
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
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_left_super() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void f() {
    super = 0;
//  ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
  }
}
''');

    var node = result.findNode.singleAssignmentExpression;
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
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notLValue_binaryExpression_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int a, int b, double c) {
  a + b += c;
//^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');

    var node = result.findNode.assignment('= c');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notLValue_parenthesized_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int a, int b, double c) {
  (a + b) += c;
//^^^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');

    var node = result.findNode.assignment('= c');
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
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notLValue_parenthesized_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int a, double b) {
  (a + 0) = b;
// ^
// [diag.patternTypeMismatchInIrrefutableContext] The matched value of type 'double' isn't assignable to the required type 'int'.
//   ^
// [diag.expectedToken] Expected to find ')'.
}
''');

    var node = result.findNode.singlePatternAssignment;
    assertResolvedNodeText(node, r'''
PatternAssignment
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: AssignedVariablePattern
      name: a
      element: <testLibrary>::@function::f::@formalParameter::a
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
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
void f(int a, double b) {
  (a + 0) = b;
//^^^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');

    var node = result.findNode.assignment('= b');
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
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: double
''');
  }

  test_notLValue_postfixIncrement_compound() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(num x, int y) {
  x++ += y;
//^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');

    var node = result.findNode.assignment('= y');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PostfixExpression
    operand: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: null
    operator: ++
    readElement: <testLibrary>::@function::f::@formalParameter::x
    readType: num
    writeElement: <testLibrary>::@function::f::@formalParameter::x
    writeType: num
    element: dart:core::@class::num::@method::+
    staticType: num
  operator: +=
  rightHandSide: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notLValue_postfixIncrement_compound_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(num x, int y) {
  x++ ??= y;
//^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');

    var node = result.findNode.assignment('= y');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PostfixExpression
    operand: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: null
    operator: ++
    readElement: <testLibrary>::@function::f::@formalParameter::x
    readType: num
    writeElement: <testLibrary>::@function::f::@formalParameter::x
    writeType: num
    element: dart:core::@class::num::@method::+
    staticType: num
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notLValue_postfixIncrement_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(num x, int y) {
  x++ = y;
//^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');

    var node = result.findNode.assignment('= y');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PostfixExpression
    operand: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: null
    operator: ++
    readElement: <testLibrary>::@function::f::@formalParameter::x
    readType: num
    writeElement: <testLibrary>::@function::f::@formalParameter::x
    writeType: num
    element: dart:core::@class::num::@method::+
    staticType: num
  operator: =
  rightHandSide: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notLValue_prefixIncrement_compound() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(num x, int y) {
  ++x += y;
//^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');

    var node = result.findNode.assignment('= y');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixExpression
    operator: ++
    operand: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: null
    readElement: <testLibrary>::@function::f::@formalParameter::x
    readType: num
    writeElement: <testLibrary>::@function::f::@formalParameter::x
    writeType: num
    element: dart:core::@class::num::@method::+
    staticType: num
  operator: +=
  rightHandSide: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notLValue_prefixIncrement_compound_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(num x, int y) {
  ++x ??= y;
//^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');

    var node = result.findNode.assignment('= y');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixExpression
    operator: ++
    operand: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: null
    readElement: <testLibrary>::@function::f::@formalParameter::x
    readType: num
    writeElement: <testLibrary>::@function::f::@formalParameter::x
    writeType: num
    element: dart:core::@class::num::@method::+
    staticType: num
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_notLValue_prefixIncrement_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(num x, int y) {
  ++x = y;
//^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.illegalAssignmentToNonAssignable] Illegal assignment to non-assignable expression.
}
''');

    var node = result.findNode.assignment('= y');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixExpression
    operator: ++
    operand: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: null
    readElement: <testLibrary>::@function::f::@formalParameter::x
    readType: num
    writeElement: <testLibrary>::@function::f::@formalParameter::x
    writeType: num
    element: dart:core::@class::num::@method::+
    staticType: num
  operator: =
  rightHandSide: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notLValue_typeLiteral_class_ambiguous_simple() async {
    newFile('$testPackageLibPath/a.dart', 'class C {}');
    newFile('$testPackageLibPath/b.dart', 'class C {}');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart';
import 'b.dart';
void f() {
  C = 0;
//^
// [diag.ambiguousImport] The name 'C' is defined in the libraries 'package:test/a.dart' and 'package:test/b.dart'.
}
''');

    var node = result.findNode.assignment('C = 0');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: multiplyDefinedElement
    package:test/a.dart::@class::C
    package:test/b.dart::@class::C
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_notLValue_typeLiteral_class_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {}

void f() {
  C = 0;
//^
// [diag.assignmentToType] Types can't be assigned a value.
}
''');

    var node = result.findNode.assignment('C = 0');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_nullAware_context() async {
    var result = await resolveTestCodeWithDiagnostics('''
T f<T>() => throw Error();
g(int? a) {
  a ??= f();
}
''');

    var node = result.findNode.assignment('??= f()');
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
  readElement: <testLibrary>::@function::g::@formalParameter::a
  readType: int?
  writeElement: <testLibrary>::@function::g::@formalParameter::a
  writeType: int?
  element: <null>
  staticType: int?
''');
  }

  test_prefixedIdentifier_instance_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get x => 0;
  set x(num _) {}
}

void f(A a) {
  a.x += 2;
}
''');

    var node = result.findNode.assignment('x += 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_prefixedIdentifier_instance_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int? get x => 0;
  set x(num? _) {}
}

void f(A a) {
  a.x ??= 2;
}
''');

    var node = result.findNode.assignment('x ??= 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int?
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num?
  element: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_instance_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set x(num _) {}
}

void f(A a) {
  a.x = 2;
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_instanceGetter_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get x => 0;
}

void f(A a) {
  a.x = 2;
//  ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'A'.
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@getter::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_static_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  static set x(num _) {}
}

void f() {
  A.x = 2;
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_staticGetter_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get x => 0;
}

void f() {
  A.x = 2;
//  ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'A'.
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@getter::x
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
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as p;

void f() {
  p.x += 2;
}
''');

    var node = result.findNode.assignment('x += 2');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: p
      element: <testLibraryFragment>::@prefix::p
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
  readElement: package:test/a.dart::@getter::x
  readType: int
  writeElement: package:test/a.dart::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_prefixedIdentifier_typeAlias_static_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get x => 0;
  static set x(int _) {}
}

typedef B = A;

void f() {
  B.x += 2;
}
''');

    var node = result.findNode.assignment('x += 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: int
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_prefixedIdentifier_unresolved1_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int c) {
  a.b = c;
//^
// [diag.undefinedIdentifier] Undefined name 'a'.
}
''');

    var node = result.findNode.assignment('a.b = c');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_unresolved2_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int a, int c) {
  a.b += c;
//  ^
// [diag.undefinedGetter] The getter 'b' isn't defined for the type 'int'.
// [diag.undefinedSetter] The setter 'b' isn't defined for the type 'int'.
}
''');

    var node = result.findNode.assignment('a.b += c');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_propertyAccess_cascade_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get x => 0;
  set x(num _) {}
}

void f(A a) {
  a..x += 2;
}
''');

    var node = result.findNode.assignment('x += 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_propertyAccess_forwardingStub() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.assignment('x = 1');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: InstanceCreationExpression
      keyword: new
      constructorName: ConstructorName
        type: NamedType
          name: B
          element: <testLibrary>::@class::B
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_propertyAccess_instance_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get x => 0;
  set x(num _) {}
}

void f(A a) {
  (a).x += 2;
}
''');

    var node = result.findNode.assignment('x += 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_propertyAccess_instance_fromMixins_compound() async {
    var result = await resolveTestCodeWithDiagnostics('''
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

    var node = result.findNode.assignment('x += 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <testLibrary>::@mixin::M2::@getter::x
  readType: int
  writeElement: <testLibrary>::@mixin::M2::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_propertyAccess_instance_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int? get x => 0;
  set x(num? _) {}
}

void f(A a) {
  (a).x ??= 2;
}
''');

    var node = result.findNode.assignment('x ??= 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int?
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num?
  element: <null>
  staticType: int
''');
  }

  test_propertyAccess_instance_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set x(num _) {}
}

void f(A a) {
  (a).x = 2;
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_propertyAccess_nullShorting_assignable() async {
    var result = await resolveTestCodeWithDiagnostics('''
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

    var node = result.findNode.assignment('= 0');
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::B::@setter::setter
  writeType: int
  element: <null>
  staticType: int?
''');
  }

  test_propertyAccess_nullShorting_notAssignable() async {
    var result = await resolveTestCodeWithDiagnostics('''
abstract class A {
  B get b;
}
abstract class B {
  set setter(int i);
}
test(A? a) {
  a?.b.setter = null;
//              ^^^^
// [diag.invalidAssignment] A value of type 'Null' can't be assigned to a variable of type 'int'.
}
''');

    var node = result.findNode.assignment('= null');
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::B::@setter::setter
  writeType: int
  element: <null>
  staticType: Null
''');
  }

  /// Has record getter:    false
  /// Has extension getter: false
  /// Has record setter:    false
  /// Has extension setter: false
  test_propertyAccess_recordTypeField_named_FFFF_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(({int bar}) r) {
  r.foo += 0;
//  ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type '({int bar})'.
// [diag.undefinedSetter] The setter 'foo' isn't defined for the type '({int bar})'.
}
''');

    var node = result.findNode.assignment('+= 0');
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
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(({int bar}) r) {
  r.foo = 0;
//  ^^^
// [diag.undefinedSetter] The setter 'foo' isn't defined for the type '({int bar})'.
}
''');

    var node = result.findNode.assignment('= 0');
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
  readElement: <null>
  readType: null
  writeElement: <null>
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on ({int bar}) {
  set foo(int _) {}
}

void f(({int bar}) r) {
  r.foo += 0;
//  ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type '({int bar})'.
}
''');

    var node = result.findNode.assignment('+= 0');
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
  readElement: <testLibrary>::@extension::E::@setter::foo
  readType: InvalidType
  writeElement: <testLibrary>::@extension::E::@setter::foo
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on ({int bar}) {
  set foo(int _) {}
}

void f(({int bar}) r) {
  r.foo = 0;
}
''');

    var node = result.findNode.assignment('= 0');
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extension::E::@setter::foo
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on ({int bar}) {
  int get foo => 0;
}

void f(({int bar}) r) {
  r.foo += 0;
//  ^^^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'foo' in class 'E'.
}
''');

    var node = result.findNode.assignment('+= 0');
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
  readElement: <testLibrary>::@extension::E::@getter::foo
  readType: int
  writeElement: <testLibrary>::@extension::E::@getter::foo
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on ({int bar}) {
  int get foo => 0;
}

void f(({int bar}) r) {
  r.foo = 0;
//  ^^^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'foo' in class 'E'.
}
''');

    var node = result.findNode.assignment('= 0');
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extension::E::@getter::foo
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on ({int bar}) {
  int get foo => 0;
  set foo(int _) {}
}

void f(({int bar}) r) {
  r.foo += 0;
}
''');

    var node = result.findNode.assignment('+= 0');
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
  readElement: <testLibrary>::@extension::E::@getter::foo
  readType: int
  writeElement: <testLibrary>::@extension::E::@setter::foo
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on ({int bar}) {
  int get foo => 0;
  set foo(int _) {}
}

void f(({int bar}) r) {
  r.foo = 0;
}
''');

    var node = result.findNode.assignment('= 0');
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extension::E::@setter::foo
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(({int foo, String bar}) r) {
  r.foo += 0;
//  ^^^
// [diag.undefinedSetter] The setter 'foo' isn't defined for the type '({String bar, int foo})'.
}
''');

    var node = result.findNode.assignment('+= 0');
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
  readElement: <null>
  readType: int
  writeElement: <null>
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(({int foo, String bar}) r) {
  r.foo = 0;
//  ^^^
// [diag.undefinedSetter] The setter 'foo' isn't defined for the type '({String bar, int foo})'.
}
''');

    var node = result.findNode.assignment('= 0');
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
  readElement: <null>
  readType: null
  writeElement: <null>
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on ({int foo, String bar}) {
  set foo(int _) {}
}

void f(({int foo, String bar}) r) {
  r.foo += 0;
//  ^^^
// [diag.undefinedSetter] The setter 'foo' isn't defined for the type '({String bar, int foo})'.
}
''');

    var node = result.findNode.assignment('+= 0');
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
  readElement: <null>
  readType: int
  writeElement: <null>
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on ({int foo, String bar}) {
  set foo(int _) {}
}

void f(({int foo, String bar}) r) {
  r.foo = 0;
//  ^^^
// [diag.undefinedSetter] The setter 'foo' isn't defined for the type '({String bar, int foo})'.
}
''');

    var node = result.findNode.assignment('= 0');
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
  readElement: <null>
  readType: null
  writeElement: <null>
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on ({int foo, String bar}) {
  int get foo => 0;
}

void f(({int foo, String bar}) r) {
  r.foo += 0;
//  ^^^
// [diag.undefinedSetter] The setter 'foo' isn't defined for the type '({String bar, int foo})'.
}
''');

    var node = result.findNode.assignment('+= 0');
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
  readElement: <null>
  readType: int
  writeElement: <null>
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on ({int foo, String bar}) {
  int get foo => 0;
}

void f(({int foo, String bar}) r) {
  r.foo = 0;
//  ^^^
// [diag.undefinedSetter] The setter 'foo' isn't defined for the type '({String bar, int foo})'.
}
''');

    var node = result.findNode.assignment('= 0');
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
  readElement: <null>
  readType: null
  writeElement: <null>
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on ({int foo, String bar}) {
  int get foo => 0;
  set foo(int _) {}
}

void f(({int foo, String bar}) r) {
  r.foo += 0;
//  ^^^
// [diag.undefinedSetter] The setter 'foo' isn't defined for the type '({String bar, int foo})'.
}
''');

    var node = result.findNode.assignment('+= 0');
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
  readElement: <null>
  readType: int
  writeElement: <null>
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on ({int foo, String bar}) {
  int get foo => 0;
  set foo(int _) {}
}

void f(({int foo, String bar}) r) {
  r.foo = 0;
//  ^^^
// [diag.undefinedSetter] The setter 'foo' isn't defined for the type '({String bar, int foo})'.
}
''');

    var node = result.findNode.assignment('= 0');
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
  readElement: <null>
  readType: null
  writeElement: <null>
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int, String) r) {
  r.$4 += 0;
//  ^^
// [diag.undefinedGetter] The getter '$4' isn't defined for the type '(int, String)'.
// [diag.undefinedSetter] The setter '$4' isn't defined for the type '(int, String)'.
}
''');

    var node = result.findNode.assignment('+= 0');
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
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int, String) r) {
  r.$4 = 0;
//  ^^
// [diag.undefinedSetter] The setter '$4' isn't defined for the type '(int, String)'.
}
''');

    var node = result.findNode.assignment('= 0');
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
  readElement: <null>
  readType: null
  writeElement: <null>
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on (int, String) {
  int get $3 => 0;
}

void f((int, String) r) {
  r.$3 += 0;
//  ^^
// [diag.assignmentToFinalNoSetter] There isn't a setter named '$3' in class 'E'.
}
''');

    var node = result.findNode.assignment('+= 0');
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
  readElement: <testLibrary>::@extension::E::@getter::$3
  readType: int
  writeElement: <testLibrary>::@extension::E::@getter::$3
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on (int, String) {
  int get $3 => 0;
}

void f((int, String) r) {
  r.$3 = 0;
//  ^^
// [diag.assignmentToFinalNoSetter] There isn't a setter named '$3' in class 'E'.
}
''');

    var node = result.findNode.assignment('= 0');
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@extension::E::@getter::$3
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int, String) r) {
  r.$1 += 0;
//  ^^
// [diag.undefinedSetter] The setter '$1' isn't defined for the type '(int, String)'.
}
''');

    var node = result.findNode.assignment('+= 0');
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
  readElement: <null>
  readType: int
  writeElement: <null>
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int, String) r) {
  r.$1 = 0;
//  ^^
// [diag.undefinedSetter] The setter '$1' isn't defined for the type '(int, String)'.
}
''');

    var node = result.findNode.assignment('= 0');
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
  readElement: <null>
  readType: null
  writeElement: <null>
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on (int, String) {
  set $1(int _) {}
}

void f((int, String) r) {
  r.$1 += 0;
//  ^^
// [diag.undefinedSetter] The setter '$1' isn't defined for the type '(int, String)'.
}
''');

    var node = result.findNode.assignment('+= 0');
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
  readElement: <null>
  readType: int
  writeElement: <null>
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on (int, String) {
  set $1(int _) {}
}

void f((int, String) r) {
  r.$1 = 0;
//  ^^
// [diag.undefinedSetter] The setter '$1' isn't defined for the type '(int, String)'.
}
''');

    var node = result.findNode.assignment('= 0');
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
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_propertyAccess_super_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.assignment('x += 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_propertyAccess_this_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  int get x => 0;
  set x(num _) {}

  void f() {
    this.x += 2;
  }
}
''');

    var node = result.findNode.assignment('x += 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <testLibrary>::@class::A::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_propertyAccess_unresolved1_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int c) {
  (a).b = c;
// ^
// [diag.undefinedIdentifier] Undefined name 'a'.
}
''');

    var node = result.findNode.assignment('(a).b = c');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_propertyAccess_unresolved2_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int a, int c) {
  (a).b = c;
//    ^
// [diag.undefinedSetter] The setter 'b' isn't defined for the type 'int'.
}
''');

    var node = result.findNode.assignment('(a).b = c');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_right_super() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void f(Object a) {
    a = super;
//      ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
  }
}
''');

    var node = result.findNode.singleAssignmentExpression;
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@method::f::@formalParameter::a
  writeType: Object
  element: <null>
  staticType: A
''');
  }

  test_simpleIdentifier_fieldInstance_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  num x = 0;

  void f() {
    x = 2;
  }
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@setter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_fieldStatic_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static num x = 0;

  void f() {
    x = 2;
  }
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@setter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_getterInstance_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  num get x => 0;

  void f() {
    x = 2;
//  ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'C'.
  }
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@getter::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_getterStatic_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  static num get x => 0;

  void f() {
    x = 2;
//  ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'C'.
  }
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::C::@getter::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_getterTopLevel_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
int get x => 0;

void f() {
  x = 2;
//^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@getter::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_importPrefix_hasSuperSetter_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:math' as x;

class A {
  var x;
}

class B extends A {
  void f() {
    x = 2;
//  ^
// [diag.prefixIdentifierNotFollowedByDot] The name 'x' refers to an import prefix, so it must be followed by '.'.
  }
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibraryFragment>::@prefix::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_importPrefix_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:math' as x;

main() {
  x = 2;
//^
// [diag.prefixIdentifierNotFollowedByDot] The name 'x' refers to an import prefix, so it must be followed by '.'.
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibraryFragment>::@prefix::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_localVariable_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  num x = 0;
  x += 3;
}
''');

    var node = result.findNode.assignment('x += 3');
    assertResolvedNodeText(node, r'''
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
  readElement: x@51
  readType: num
  writeElement: x@51
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: num
''');
  }

  test_simpleIdentifier_localVariable_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore:unused_local_variable
  num x = 0;
  x = 2;
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: x@51
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_localVariableConst_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  // ignore:unused_local_variable
  const num x = 1;
  x = 2;
//^
// [diag.assignmentToConst] Constant variables can't be assigned a value after initialization.
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: x@57
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_localVariableFinal_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  // ignore:unused_local_variable
  final num x = 1;
  x = 2;
//^
// [diag.assignmentToFinalLocal] The final variable 'x' can only be set once.
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: x@57
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_parameter_compound_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(num? x) {
  x ??= 0;
}
''');

    var node = result.findNode.assignment('x ??=');
    assertResolvedNodeText(node, r'''
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
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: num?
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: num?
  element: <null>
  staticType: num
''');
  }

  test_simpleIdentifier_parameter_compound_ifNull2() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}
class B extends A {}
class C extends A {}

void f(B? x) {
  x ??= C();
//      ^^^
// [diag.invalidAssignment] A value of type 'C' can't be assigned to a variable of type 'B?'.
}
''');

    var node = result.findNode.assignment('x ??=');
    assertResolvedNodeText(node, r'''
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
        element: <testLibrary>::@class::C
        type: C
      element: <testLibrary>::@class::C::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    correspondingParameter: <null>
    staticType: C
  readElement: <testLibrary>::@function::f::@formalParameter::x
  readType: B?
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: B?
  element: <null>
  staticType: A
''');
  }

  test_simpleIdentifier_parameter_compound_ifNull_notAssignableType() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(double? a, int b) {
  a ??= b;
//      ^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'double?'.
}
''');

    var node = result.findNode.assignment('a ??=');
    assertResolvedNodeText(node, r'''
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
  readElement: <testLibrary>::@function::f::@formalParameter::a
  readType: double?
  writeElement: <testLibrary>::@function::f::@formalParameter::a
  writeType: double?
  element: <null>
  staticType: num
''');
  }

  test_simpleIdentifier_parameter_compound_refineType_int_double() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  x += 1.2;
//     ^^^
// [diag.invalidAssignment] A value of type 'double' can't be assigned to a variable of type 'int'.
  x -= 1.2;
//     ^^^
// [diag.invalidAssignment] A value of type 'double' can't be assigned to a variable of type 'int'.
  x *= 1.2;
//     ^^^
// [diag.invalidAssignment] A value of type 'double' can't be assigned to a variable of type 'int'.
  x %= 1.2;
//     ^^^
// [diag.invalidAssignment] A value of type 'double' can't be assigned to a variable of type 'int'.
}
''');
    assertType(result.findNode.assignment('+='), 'double');
    assertType(result.findNode.assignment('-='), 'double');
    assertType(result.findNode.assignment('*='), 'double');
    assertType(result.findNode.assignment('%='), 'double');
  }

  test_simpleIdentifier_parameter_compound_refineType_int_int() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  x += 1;
  x -= 1;
  x *= 1;
  x ~/= 1;
  x %= 1;
}
''');
    assertType(result.findNode.assignment('+='), 'int');
    assertType(result.findNode.assignment('-='), 'int');
    assertType(result.findNode.assignment('*='), 'int');
    assertType(result.findNode.assignment('~/='), 'int');
    assertType(result.findNode.assignment('%='), 'int');
  }

  test_simpleIdentifier_parameter_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(num x) {
  x = 2;
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_parameter_simple_context() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  if (x is double) {
    x = 1;
  }
}
''');

    var node = result.findNode.assignment('x = 1');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: Object
  element: <null>
  staticType: double
''');
  }

  test_simpleIdentifier_parameter_simple_notAssignableType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  x = true;
//    ^^^^
// [diag.invalidAssignment] A value of type 'bool' can't be assigned to a variable of type 'int'.
}
''');

    var node = result.findNode.assignment('x = true');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: int
  element: <null>
  staticType: bool
''');
  }

  test_simpleIdentifier_parameterFinal_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
// @dart = 3.10
void f(final int x) {
  x = 2;
//^
// [diag.assignmentToFinalLocal] The final variable 'x' can only be set once.
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@function::f::@formalParameter::x
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_staticGetter_superSetter_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set x(num _) {}
}

class B extends A {
  static int get x => 1;
//               ^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'x' and have instance member 'A.x' with the same name.

  void f() {
    x = 2;
//  ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'B'.
  }
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::B::@getter::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_staticMethod_superSetter_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set x(num _) {}
}

class B extends A {
  static void x() {}
//            ^
// [diag.conflictingStaticAndInstance] Class 'B' can't define static member 'x' and have instance member 'A.x' with the same name.

  void f() {
    x = 2;
//  ^
// [diag.assignmentToMethod] Methods can't be assigned a value.
  }
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::B::@method::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_superSetter_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  set x(num _) {}
}

class B extends A {
  void f() {
    x = 2;
  }
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_synthetic_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(int y) {
  = y;
//^
// [diag.missingIdentifier] Expected an identifier.
}
''');

    var node = result.findNode.assignment('= y');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_thisGetter_superGetter_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
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

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@class::A::@setter::x
  writeType: int
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_thisGetter_thisSetter_compound() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  int get x => 0;
  set x(num _) {}

  void f() {
    x += 2;
  }
}
''');

    var node = result.findNode.assignment('x += 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <testLibrary>::@class::C::@getter::x
  readType: int
  writeElement: <testLibrary>::@class::C::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_simpleIdentifier_thisGetter_thisSetter_fromMixins_compound() async {
    var result = await resolveTestCodeWithDiagnostics('''
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

    var node = result.findNode.assignment('x += 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <testLibrary>::@mixin::M2::@getter::x
  readType: int
  writeElement: <testLibrary>::@mixin::M2::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_simpleIdentifier_thisGetter_thisSetter_ifNull() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  int? get x => 0;
  set x(num? _) {}

  void f() {
    x ??= 2;
  }
}
''');

    var node = result.findNode.assignment('x ??= 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <testLibrary>::@class::C::@getter::x
  readType: int?
  writeElement: <testLibrary>::@class::C::@setter::x
  writeType: num?
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_topGetter_superSetter_simple() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  set x(num _) {}
}

int get x => 1;

class B extends A {

  void f() {
    x = 2;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  }
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@getter::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_topGetter_topSetter_compound() async {
    var result = await resolveTestCodeWithDiagnostics('''
int get x => 0;
set x(num _) {}

void f() {
  x += 2;
}
''');

    var node = result.findNode.assignment('x += 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <testLibrary>::@getter::x
  readType: int
  writeElement: <testLibrary>::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_simpleIdentifier_topGetter_topSetter_compound_ifNull2() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  x ??= C();
//      ^^^
// [diag.invalidAssignment] A value of type 'C' can't be assigned to a variable of type 'B?'.
}

class A {}
class B extends A {}
class C extends A {}

B? get x => B();
set x(B? _) {}
''');

    var node = result.findNode.assignment('x ??=');
    assertResolvedNodeText(node, r'''
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
        element: <testLibrary>::@class::C
        type: C
      element: <testLibrary>::@class::C::@constructor::new
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    correspondingParameter: <null>
    staticType: C
  readElement: <testLibrary>::@getter::x
  readType: B?
  writeElement: <testLibrary>::@setter::x
  writeType: B?
  element: <null>
  staticType: A
''');
  }

  test_simpleIdentifier_topGetter_topSetter_fromClass_compound() async {
    var result = await resolveTestCodeWithDiagnostics('''
int get x => 0;
set x(num _) {}

class A {
  void f() {
    x += 2;
  }
}
''');

    var node = result.findNode.assignment('x += 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <testLibrary>::@getter::x
  readType: int
  writeElement: <testLibrary>::@setter::x
  writeType: num
  element: dart:core::@class::num::@method::+
  staticType: int
''');
  }

  test_simpleIdentifier_topLevelVariable_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
num x = 0;

void f() {
  x = 2;
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@setter::x
  writeType: num
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_topLevelVariable_simple_notAssignableType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
int x = 0;

void f() {
  x = true;
//    ^^^^
// [diag.invalidAssignment] A value of type 'bool' can't be assigned to a variable of type 'int'.
}
''');

    var node = result.findNode.assignment('x = true');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@setter::x
  writeType: int
  element: <null>
  staticType: bool
''');
  }

  test_simpleIdentifier_topLevelVariableFinal_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final num x = 0;

void f() {
  x = 2;
//^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
}
''');

    var node = result.findNode.assignment('x = 2');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <testLibrary>::@getter::x
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_typeLiteral_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  int += 3;
//^^^
// [diag.assignmentToType] Types can't be assigned a value.
}
''');

    var node = result.findNode.assignment('int += 3');
    assertResolvedNodeText(node, r'''
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
  readElement: dart:core::@class::int
  readType: InvalidType
  writeElement: dart:core::@class::int
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_simpleIdentifier_typeLiteral_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  int = 0;
//^^^
// [diag.assignmentToType] Types can't be assigned a value.
}
''');

    var node = result.findNode.assignment('int = 0');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: dart:core::@class::int
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }

  test_simpleIdentifier_unresolved_compound() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  x += 1;
//^
// [diag.undefinedIdentifier] Undefined name 'x'.
}
''');

    var node = result.findNode.assignment('x += 1');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: InvalidType
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: InvalidType
''');
  }

  test_simpleIdentifier_unresolved_simple() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(int a) {
  x = a;
//^
// [diag.undefinedIdentifier] Undefined name 'x'.
}
''');

    var node = result.findNode.assignment('x = a');
    assertResolvedNodeText(node, r'''
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
  readElement: <null>
  readType: null
  writeElement: <null>
  writeType: InvalidType
  element: <null>
  staticType: int
''');
  }
}

@reflectiveTest
class InferenceUpdate3Test extends PubPackageResolutionTest {
  test_ifNull_contextIsConvertedToATypeUsingGreatestClosure() async {
    var result = await resolveTestCodeWithDiagnostics('''
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

    var node = result.findNode.assignment('o ??= c2');
    assertResolvedNodeText(node, r'''AssignmentExpression
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
  correspondingParameter: SubstitutedFormalParameterElementImpl
    baseElement: <testLibrary>::@function::contextB1::@formalParameter::b1
    substitution: {T: Object?}
  readElement: <testLibrary>::@function::f::@formalParameter::o
  readType: C1<int>?
  writeElement: <testLibrary>::@function::f::@formalParameter::o
  writeType: Object?
  element: <null>
  staticType: B1<Object?>
''');
  }

  test_ifNull_contextNotUsedIfLhsDoesNotSatisfyContext() async {
    var result = await resolveTestCodeWithDiagnostics('''
f(Object? o1, Object? o2, int? i) {
  if (o1 is int? && o2 is double?) {
    o1 = (o2 ??= i);
  }
}
''');

    var node = result.findNode.assignment('o2 ??= i');
    assertResolvedNodeText(node, r'''AssignmentExpression
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
  readElement: <testLibrary>::@function::f::@formalParameter::o2
  readType: double?
  writeElement: <testLibrary>::@function::f::@formalParameter::o2
  writeType: Object?
  element: <null>
  staticType: num?
''');
  }

  test_ifNull_contextUsedInsteadOfLubIfLubDoesNotSatisfyContext() async {
    var result = await resolveTestCodeWithDiagnostics('''
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

    var node = result.findNode.assignment('o ??= c2');
    assertResolvedNodeText(node, r'''
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
  readElement: <testLibrary>::@function::f::@formalParameter::o
  readType: C1?
  writeElement: <testLibrary>::@function::f::@formalParameter::o
  writeType: Object?
  element: <null>
  staticType: B1
''');
  }
}
