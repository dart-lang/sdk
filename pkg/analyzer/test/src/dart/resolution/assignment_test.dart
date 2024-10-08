// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
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
    staticElement: <testLibraryFragment>::@function::g::@parameter::a
    element: <testLibraryFragment>::@function::g::@parameter::a#element
    staticType: null
  operator: +=
  rightHandSide: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      staticElement: <testLibraryFragment>::@function::f
      element: <testLibraryFragment>::@function::f#element
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticInvokeType: int Function()
    staticType: int
    typeArgumentTypes
      int
  readElement: <testLibraryFragment>::@function::g::@parameter::a
  readElement2: <testLibraryFragment>::@function::g::@parameter::a#element
  readType: int
  writeElement: <testLibraryFragment>::@function::g::@parameter::a
  writeElement2: <testLibraryFragment>::@function::g::@parameter::a#element
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
      staticElement: <testLibraryFragment>::@function::g::@parameter::a
      element: <testLibraryFragment>::@function::g::@parameter::a#element
      staticType: List<int>
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: ParameterMember
        base: dart:core::<fragment>::@class::List::@method::[]=::@parameter::index
        substitution: {E: int}
      staticType: int
    rightBracket: ]
    staticElement: <null>
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      staticElement: <testLibraryFragment>::@function::f
      element: <testLibraryFragment>::@function::f#element
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticInvokeType: int Function()
    staticType: int
    typeArgumentTypes
      int
  readElement: MethodMember
    base: dart:core::<fragment>::@class::List::@method::[]
    substitution: {E: int}
  readElement2: dart:core::<fragment>::@class::List::@method::[]#element
  readType: int
  writeElement: MethodMember
    base: dart:core::<fragment>::@class::List::@method::[]=
    substitution: {E: int}
  writeElement2: dart:core::<fragment>::@class::List::@method::[]=#element
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
    staticElement: <testLibraryFragment>::@function::g::@parameter::a
    element: <testLibraryFragment>::@function::g::@parameter::a#element
    staticType: null
  operator: +=
  rightHandSide: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      staticElement: <testLibraryFragment>::@function::f
      element: <testLibraryFragment>::@function::f#element
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticInvokeType: int Function()
    staticType: int
    typeArgumentTypes
      int
  readElement: <testLibraryFragment>::@function::g::@parameter::a
  readElement2: <testLibraryFragment>::@function::g::@parameter::a#element
  readType: int
  writeElement: <testLibraryFragment>::@function::g::@parameter::a
  writeElement2: <testLibraryFragment>::@function::g::@parameter::a#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
    staticElement: <testLibraryFragment>::@function::g::@parameter::a
    element: <testLibraryFragment>::@function::g::@parameter::a#element
    staticType: null
  operator: +=
  rightHandSide: ConditionalExpression
    condition: SimpleIdentifier
      token: b
      staticElement: <testLibraryFragment>::@function::g::@parameter::b
      element: <testLibraryFragment>::@function::g::@parameter::b#element
      staticType: bool
    question: ?
    thenExpression: MethodInvocation
      methodName: SimpleIdentifier
        token: f
        staticElement: <testLibraryFragment>::@function::f
        element: <testLibraryFragment>::@function::f#element
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
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: num
  readElement: <testLibraryFragment>::@function::g::@parameter::a
  readElement2: <testLibraryFragment>::@function::g::@parameter::a#element
  readType: int
  writeElement: <testLibraryFragment>::@function::g::@parameter::a
  writeElement2: <testLibraryFragment>::@function::g::@parameter::a#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
  staticType: num
''');

    assertResolvedNodeText(findNode.simple('a;'), r'''
SimpleIdentifier
  token: a
  staticElement: <testLibraryFragment>::@function::g::@parameter::a
  element: <testLibraryFragment>::@function::g::@parameter::a#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <testLibraryFragment>::@function::f::@parameter::a
  readElement2: <testLibraryFragment>::@function::f::@parameter::a#element
  readType: dynamic
  writeElement: <testLibraryFragment>::@function::f::@parameter::a
  writeElement2: <testLibraryFragment>::@function::f::@parameter::a#element
  writeType: dynamic
  staticElement: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: dynamic
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: dynamic
  writeElement: <null>
  writeElement2: <null>
  writeType: dynamic
  staticElement: <null>
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
        staticElement: <testLibraryFragment>::@function::f::@parameter::a
        element: <testLibraryFragment>::@function::f::@parameter::a#element
        staticType: dynamic
      period: .
      identifier: SimpleIdentifier
        token: foo
        staticElement: <null>
        element: <null>
        staticType: dynamic
      staticElement: <null>
      element: <null>
      staticType: dynamic
    operator: .
    propertyName: SimpleIdentifier
      token: bar
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: dynamic
  writeElement: <null>
  writeElement2: <null>
  writeType: dynamic
  staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::o1
    element: <testLibraryFragment>::@function::f::@parameter::o1#element
    staticType: null
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: listNum
    parameter: <null>
    staticElement: <testLibraryFragment>::@function::f::@parameter::listNum
    element: <testLibraryFragment>::@function::f::@parameter::listNum#element
    staticType: List<num>
  readElement: <testLibraryFragment>::@function::f::@parameter::o1
  readElement2: <testLibraryFragment>::@function::f::@parameter::o1#element
  readType: Iterable<int>?
  writeElement: <testLibraryFragment>::@function::f::@parameter::o1
  writeElement2: <testLibraryFragment>::@function::f::@parameter::o1#element
  writeType: Object?
  staticElement: <null>
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
      staticElement: <testLibraryFragment>::@prefix::prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: v
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: package:test/a.dart::<fragment>::@setter::v::@parameter::_v
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: package:test/a.dart::<fragment>::@setter::v
  writeElement2: package:test/a.dart::<fragment>::@setter::v#element
  writeType: int
  staticElement: <null>
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
      parameter: <testLibraryFragment>::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <testLibraryFragment>::@class::A::@method::[]
  readElement2: <testLibraryFragment>::@class::A::@method::[]#element
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@method::[]=
  writeElement2: <testLibraryFragment>::@class::A::@method::[]=#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: dynamic
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: <null>
      staticType: int
    rightBracket: ]
    staticElement: <null>
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: dynamic
  writeElement: <null>
  writeElement2: <null>
  writeType: dynamic
  staticElement: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: <testLibraryFragment>::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <testLibraryFragment>::@class::A::@method::[]
  readElement2: <testLibraryFragment>::@class::A::@method::[]#element
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@method::[]=
  writeElement2: <testLibraryFragment>::@class::A::@method::[]=#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: <testLibraryFragment>::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: DoubleLiteral
    literal: 2.0
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: double
  readElement: <testLibraryFragment>::@class::A::@method::[]
  readElement2: <testLibraryFragment>::@class::A::@method::[]#element
  readType: num
  writeElement: <testLibraryFragment>::@class::A::@method::[]=
  writeElement2: <testLibraryFragment>::@class::A::@method::[]=#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: <testLibraryFragment>::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <testLibraryFragment>::@class::A::@method::[]
  readElement2: <testLibraryFragment>::@class::A::@method::[]#element
  readType: int?
  writeElement: <testLibraryFragment>::@class::A::@method::[]=
  writeElement2: <testLibraryFragment>::@class::A::@method::[]=#element
  writeType: num?
  staticElement: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: <testLibraryFragment>::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <testLibraryFragment>::@class::A::@method::[]=::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@class::A::@method::[]=
  writeElement2: <testLibraryFragment>::@class::A::@method::[]=#element
  writeType: num
  staticElement: <null>
  element: <null>
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
      parameter: <testLibraryFragment>::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <testLibraryFragment>::@class::A::@method::[]
  readElement2: <testLibraryFragment>::@class::A::@method::[]#element
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@method::[]=
  writeElement2: <testLibraryFragment>::@class::A::@method::[]=#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
      parameter: <testLibraryFragment>::@class::A::@method::[]=::@parameter::index
      staticType: int
    rightBracket: ]
    staticElement: <null>
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <testLibraryFragment>::@class::A::@method::[]
  readElement2: <testLibraryFragment>::@class::A::@method::[]#element
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@method::[]=
  writeElement2: <testLibraryFragment>::@class::A::@method::[]=#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
      element: <null>
      staticType: InvalidType
    leftBracket: [
    index: SimpleIdentifier
      token: b
      parameter: <null>
      staticElement: <null>
      element: <null>
      staticType: InvalidType
    rightBracket: ]
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: int
    leftBracket: [
    index: SimpleIdentifier
      token: b
      parameter: <null>
      staticElement: <null>
      element: <null>
      staticType: InvalidType
    rightBracket: ]
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    leftBracket: [
    index: SimpleIdentifier
      token: b
      parameter: <testLibraryFragment>::@class::A::@method::[]=::@parameter::index
      staticElement: <null>
      element: <null>
      staticType: InvalidType
    rightBracket: ]
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <testLibraryFragment>::@class::A::@method::[]=::@parameter::_
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@class::A::@method::[]=
  writeElement2: <testLibraryFragment>::@class::A::@method::[]=#element
  writeType: num
  staticElement: <null>
  element: <null>
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

    var node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: a
      staticElement: <null>
      element: <null>
      staticType: InvalidType
    leftBracket: [
    index: IntegerLiteral
      literal: 0
      parameter: <null>
      staticType: int
    rightBracket: ]
    staticElement: <null>
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: InvalidType
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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

    var node = findNode.singleAssignmentExpression;
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
  readElement2: <null>
  readType: null
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: int
    operator: +
    rightOperand: SimpleIdentifier
      token: b
      parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
      staticElement: <testLibraryFragment>::@function::f::@parameter::b
      element: <testLibraryFragment>::@function::f::@parameter::b#element
      staticType: int
    staticElement: dart:core::<fragment>::@class::num::@method::+
    element: dart:core::<fragment>::@class::num::@method::+#element
    staticInvokeType: num Function(num)
    staticType: int
  operator: +=
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: double
  readElement: <null>
  readElement2: <null>
  readType: InvalidType
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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
        staticElement: <testLibraryFragment>::@function::f::@parameter::a
        element: <testLibraryFragment>::@function::f::@parameter::a#element
        staticType: int
      operator: +
      rightOperand: SimpleIdentifier
        token: b
        parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
        staticType: int
      staticElement: dart:core::<fragment>::@class::num::@method::+
      element: dart:core::<fragment>::@class::num::@method::+#element
      staticInvokeType: num Function(num)
      staticType: int
    rightParenthesis: )
    staticType: int
  operator: +=
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: double
  readElement: <null>
  readElement2: <null>
  readType: InvalidType
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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
      element: <testLibraryFragment>::@function::f::@parameter::a
      element2: <testLibraryFragment>::@function::f::@parameter::a#element
      matchedValueType: double
    rightParenthesis: )
    matchedValueType: double
  equals: =
  expression: SimpleIdentifier
    token: b
    staticElement: <testLibraryFragment>::@function::f::@parameter::b
    element: <testLibraryFragment>::@function::f::@parameter::b#element
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
        staticElement: <testLibraryFragment>::@function::f::@parameter::a
        element: <testLibraryFragment>::@function::f::@parameter::a#element
        staticType: int
      operator: +
      rightOperand: IntegerLiteral
        literal: 0
        parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
        staticType: int
      staticElement: dart:core::<fragment>::@class::num::@method::+
      element: dart:core::<fragment>::@class::num::@method::+#element
      staticInvokeType: num Function(num)
      staticType: int
    rightParenthesis: )
    staticType: int
  operator: =
  rightHandSide: SimpleIdentifier
    token: b
    parameter: <null>
    staticElement: <testLibraryFragment>::@function::f::@parameter::b
    element: <testLibraryFragment>::@function::f::@parameter::b#element
    staticType: double
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: null
    operator: ++
    readElement: <testLibraryFragment>::@function::f::@parameter::x
    readElement2: <testLibraryFragment>::@function::f::@parameter::x#element
    readType: num
    writeElement: <testLibraryFragment>::@function::f::@parameter::x
    writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
    writeType: num
    staticElement: dart:core::<fragment>::@class::num::@method::+
    element: dart:core::<fragment>::@class::num::@method::+#element
    staticType: num
  operator: +=
  rightHandSide: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: <testLibraryFragment>::@function::f::@parameter::y
    element: <testLibraryFragment>::@function::f::@parameter::y#element
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: InvalidType
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: null
    operator: ++
    readElement: <testLibraryFragment>::@function::f::@parameter::x
    readElement2: <testLibraryFragment>::@function::f::@parameter::x#element
    readType: num
    writeElement: <testLibraryFragment>::@function::f::@parameter::x
    writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
    writeType: num
    staticElement: dart:core::<fragment>::@class::num::@method::+
    element: dart:core::<fragment>::@class::num::@method::+#element
    staticType: num
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: <testLibraryFragment>::@function::f::@parameter::y
    element: <testLibraryFragment>::@function::f::@parameter::y#element
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: InvalidType
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: null
    operator: ++
    readElement: <testLibraryFragment>::@function::f::@parameter::x
    readElement2: <testLibraryFragment>::@function::f::@parameter::x#element
    readType: num
    writeElement: <testLibraryFragment>::@function::f::@parameter::x
    writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
    writeType: num
    staticElement: dart:core::<fragment>::@class::num::@method::+
    element: dart:core::<fragment>::@class::num::@method::+#element
    staticType: num
  operator: =
  rightHandSide: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: <testLibraryFragment>::@function::f::@parameter::y
    element: <testLibraryFragment>::@function::f::@parameter::y#element
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: null
    readElement: <testLibraryFragment>::@function::f::@parameter::x
    readElement2: <testLibraryFragment>::@function::f::@parameter::x#element
    readType: num
    writeElement: <testLibraryFragment>::@function::f::@parameter::x
    writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
    writeType: num
    staticElement: dart:core::<fragment>::@class::num::@method::+
    element: dart:core::<fragment>::@class::num::@method::+#element
    staticType: num
  operator: +=
  rightHandSide: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: <testLibraryFragment>::@function::f::@parameter::y
    element: <testLibraryFragment>::@function::f::@parameter::y#element
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: InvalidType
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: null
    readElement: <testLibraryFragment>::@function::f::@parameter::x
    readElement2: <testLibraryFragment>::@function::f::@parameter::x#element
    readType: num
    writeElement: <testLibraryFragment>::@function::f::@parameter::x
    writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
    writeType: num
    staticElement: dart:core::<fragment>::@class::num::@method::+
    element: dart:core::<fragment>::@class::num::@method::+#element
    staticType: num
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: <testLibraryFragment>::@function::f::@parameter::y
    element: <testLibraryFragment>::@function::f::@parameter::y#element
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: InvalidType
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: null
    readElement: <testLibraryFragment>::@function::f::@parameter::x
    readElement2: <testLibraryFragment>::@function::f::@parameter::x#element
    readType: num
    writeElement: <testLibraryFragment>::@function::f::@parameter::x
    writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
    writeType: num
    staticElement: dart:core::<fragment>::@class::num::@method::+
    element: dart:core::<fragment>::@class::num::@method::+#element
    staticType: num
  operator: =
  rightHandSide: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: <testLibraryFragment>::@function::f::@parameter::y
    element: <testLibraryFragment>::@function::f::@parameter::y#element
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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
  writeElement: <testLibraryFragment>::@class::C
  writeElement2: <testLibraryFragment>::@class::C#element
  writeType: InvalidType
  staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::g::@parameter::a
    element: <testLibraryFragment>::@function::g::@parameter::a#element
    staticType: null
  operator: ??=
  rightHandSide: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      staticElement: <testLibraryFragment>::@function::f
      element: <testLibraryFragment>::@function::f#element
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    parameter: <null>
    staticInvokeType: int? Function()
    staticType: int?
    typeArgumentTypes
      int?
  readElement: <testLibraryFragment>::@function::g::@parameter::a
  readElement2: <testLibraryFragment>::@function::g::@parameter::a#element
  readType: int?
  writeElement: <testLibraryFragment>::@function::g::@parameter::a
  writeElement2: <testLibraryFragment>::@function::g::@parameter::a#element
  writeType: int?
  staticElement: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <testLibraryFragment>::@class::A::@getter::x
  readElement2: <testLibraryFragment>::@class::A::@getter::x#element
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <testLibraryFragment>::@class::A::@getter::x
  readElement2: <testLibraryFragment>::@class::A::@getter::x#element
  readType: int?
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: num?
  staticElement: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <testLibraryFragment>::@class::A::@setter::x::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: num
  staticElement: <null>
  element: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: A
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@class::A::@getter::x
  writeElement2: <testLibraryFragment>::@class::A::@getter::x#element
  writeType: InvalidType
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

  test_prefixedIdentifier_ofClass_getterAugmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  int get foo => 0;
}
''');

    await assertErrorsInCode(r'''
part 'a.dart';

class A {}

void f(A a) {
  a.foo = 0;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 46, 3),
    ]);

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
    parameter: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@setterAugmentation::foo::@parameter::_
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

  test_prefixedIdentifier_ofClassName_getterAugmentationDeclares() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart'

augment class A {
  static int get foo => 0;
}
''');

    await assertErrorsInCode(r'''
part 'a.dart';

class A {}

void f() {
  A.foo = 0;
}
''', [
      error(CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER, 43, 3),
    ]);

    var node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
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
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
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
    parameter: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@setterAugmentation::foo::@parameter::_
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
      element: <testLibraryFragment>::@class::A#element
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
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      staticElement: <testLibraryFragment>::@extension::A
      element: <testLibraryFragment>::@extension::A#element
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
    parameter: <testLibraryFragment>::@extensionAugmentation::A::@setterAugmentation::foo::@parameter::_
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
      element: <testLibraryFragment>::@extension::A#element
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
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <testLibraryFragment>::@class::A::@setter::x::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: num
  staticElement: <null>
  element: <null>
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
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@class::A::@getter::x
  writeElement2: <testLibraryFragment>::@class::A::@getter::x#element
  writeType: InvalidType
  staticElement: <null>
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
      staticElement: <testLibraryFragment>::@prefix::p
      element: <testLibraryFragment>::@prefix2::p
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: package:test/a.dart::<fragment>::@getter::x
  readElement2: package:test/a.dart::<fragment>::@getter::x#element
  readType: int
  writeElement: package:test/a.dart::<fragment>::@setter::x
  writeElement2: package:test/a.dart::<fragment>::@setter::x#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
      staticElement: <testLibraryFragment>::@typeAlias::B
      element: <testLibraryFragment>::@typeAlias::B#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: x
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <testLibraryFragment>::@class::A::@getter::x
  readElement2: <testLibraryFragment>::@class::A::@getter::x#element
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
      element: <null>
      staticType: InvalidType
    period: .
    identifier: SimpleIdentifier
      token: b
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: int
    period: .
    identifier: SimpleIdentifier
      token: b
      staticElement: <null>
      element: <null>
      staticType: null
    staticElement: <null>
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: InvalidType
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
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
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <testLibraryFragment>::@class::A::@getter::x
  readElement2: <testLibraryFragment>::@class::A::@getter::x#element
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
          element: <testLibraryFragment>::@class::B
          element2: <testLibraryFragment>::@class::B#element
          type: B
        staticElement: <testLibraryFragment>::@class::B::@constructor::new
        element: <testLibraryFragment>::@class::B::@constructor::new#element
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticType: B
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: <testLibraryFragment>::@class::A::@setter::x::@parameter::_x
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: int
  staticElement: <null>
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
        staticElement: <testLibraryFragment>::@function::f::@parameter::a
        element: <testLibraryFragment>::@function::f::@parameter::a#element
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <testLibraryFragment>::@class::A::@getter::x
  readElement2: <testLibraryFragment>::@class::A::@getter::x#element
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
        staticElement: <testLibraryFragment>::@function::f::@parameter::c
        element: <testLibraryFragment>::@function::f::@parameter::c#element
        staticType: C
      rightParenthesis: )
      staticType: C
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <testLibraryFragment>::@mixin::M2::@getter::x
  readElement2: <testLibraryFragment>::@mixin::M2::@getter::x#element
  readType: int
  writeElement: <testLibraryFragment>::@mixin::M2::@setter::x
  writeElement2: <testLibraryFragment>::@mixin::M2::@setter::x#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
        staticElement: <testLibraryFragment>::@function::f::@parameter::a
        element: <testLibraryFragment>::@function::f::@parameter::a#element
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <testLibraryFragment>::@class::A::@getter::x
  readElement2: <testLibraryFragment>::@class::A::@getter::x#element
  readType: int?
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: num?
  staticElement: <null>
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
        staticElement: <testLibraryFragment>::@function::f::@parameter::a
        element: <testLibraryFragment>::@function::f::@parameter::a#element
        staticType: A
      rightParenthesis: )
      staticType: A
    operator: .
    propertyName: SimpleIdentifier
      token: x
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <testLibraryFragment>::@class::A::@setter::x::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: num
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }

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
    parameter: <testLibrary>::@fragment::package:test/a.dart::@classAugmentation::A::@setterAugmentation::foo::@parameter::_
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
    await assertErrorsInCode(r'''
void f(({int bar}) r) {
  r.foo += 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 28, 3),
      error(CompileTimeErrorCode.UNDEFINED_SETTER, 28, 3),
    ]);

    var node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: InvalidType
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: ({int bar})
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
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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

    var node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <testLibraryFragment>::@extension::E::@setter::foo
  readElement2: <testLibraryFragment>::@extension::E::@setter::foo#element
  readType: InvalidType
  writeElement: <testLibraryFragment>::@extension::E::@setter::foo
  writeElement2: <testLibraryFragment>::@extension::E::@setter::foo#element
  writeType: int
  staticElement: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: ({int bar})
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
    parameter: <testLibraryFragment>::@extension::E::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@extension::E::@setter::foo
  writeElement2: <testLibraryFragment>::@extension::E::@setter::foo#element
  writeType: int
  staticElement: <null>
  element: <null>
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

    var node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <testLibraryFragment>::@extension::E::@getter::foo
  readElement2: <testLibraryFragment>::@extension::E::@getter::foo#element
  readType: int
  writeElement: <testLibraryFragment>::@extension::E::@getter::foo
  writeElement2: <testLibraryFragment>::@extension::E::@getter::foo#element
  writeType: InvalidType
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: ({int bar})
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
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@extension::E::@getter::foo
  writeElement2: <testLibraryFragment>::@extension::E::@getter::foo#element
  writeType: InvalidType
  staticElement: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: ({int bar})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <testLibraryFragment>::@extension::E::@getter::foo
  readElement2: <testLibraryFragment>::@extension::E::@getter::foo#element
  readType: int
  writeElement: <testLibraryFragment>::@extension::E::@setter::foo
  writeElement2: <testLibraryFragment>::@extension::E::@setter::foo#element
  writeType: int
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: ({int bar})
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
    parameter: <testLibraryFragment>::@extension::E::@setter::foo::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@extension::E::@setter::foo
  writeElement2: <testLibraryFragment>::@extension::E::@setter::foo#element
  writeType: int
  staticElement: <null>
  element: <null>
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

    var node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: int
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: ({String bar, int foo})
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
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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

    var node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: int
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: ({String bar, int foo})
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
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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

    var node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: int
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: ({String bar, int foo})
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
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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

    var node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: ({String bar, int foo})
    operator: .
    propertyName: SimpleIdentifier
      token: foo
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: int
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: ({String bar, int foo})
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
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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

    var node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $4
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: InvalidType
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $4
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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

    var node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $3
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <testLibraryFragment>::@extension::E::@getter::$3
  readElement2: <testLibraryFragment>::@extension::E::@getter::$3#element
  readType: int
  writeElement: <testLibraryFragment>::@extension::E::@getter::$3
  writeElement2: <testLibraryFragment>::@extension::E::@getter::$3#element
  writeType: InvalidType
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $3
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@extension::E::@getter::$3
  writeElement2: <testLibraryFragment>::@extension::E::@getter::$3#element
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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

    var node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $1
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: int
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $1
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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

    var node = findNode.assignment('+= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $1
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: int
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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

    var node = findNode.assignment('= 0');
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SimpleIdentifier
      token: r
      staticElement: <testLibraryFragment>::@function::f::@parameter::r
      element: <testLibraryFragment>::@function::f::@parameter::r#element
      staticType: (int, String)
    operator: .
    propertyName: SimpleIdentifier
      token: $1
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
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
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <testLibraryFragment>::@class::A::@getter::x
  readElement2: <testLibraryFragment>::@class::A::@getter::x#element
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
      element: <null>
      staticType: null
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <testLibraryFragment>::@class::A::@getter::x
  readElement2: <testLibraryFragment>::@class::A::@getter::x#element
  readType: int
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
        element: <null>
        staticType: InvalidType
      rightParenthesis: )
      staticType: InvalidType
    operator: .
    propertyName: SimpleIdentifier
      token: b
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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
        staticElement: <testLibraryFragment>::@function::f::@parameter::a
        element: <testLibraryFragment>::@function::f::@parameter::a#element
        staticType: int
      rightParenthesis: )
      staticType: int
    operator: .
    propertyName: SimpleIdentifier
      token: b
      staticElement: <null>
      element: <null>
      staticType: null
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: c
    parameter: <null>
    staticElement: <testLibraryFragment>::@function::f::@parameter::c
    element: <testLibraryFragment>::@function::f::@parameter::c#element
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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

    var node = findNode.singleAssignmentExpression;
    assertResolvedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@class::A::@method::f::@parameter::a
    element: <testLibraryFragment>::@class::A::@method::f::@parameter::a#element
    staticType: null
  operator: =
  rightHandSide: SuperExpression
    superKeyword: super
    staticType: A
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@class::A::@method::f::@parameter::a
  writeElement2: <testLibraryFragment>::@class::A::@method::f::@parameter::a#element
  writeType: Object
  staticElement: <null>
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
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <testLibraryFragment>::@class::C::@setter::x::@parameter::_x
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@class::C::@setter::x
  writeElement2: <testLibraryFragment>::@class::C::@setter::x#element
  writeType: num
  staticElement: <null>
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
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <testLibraryFragment>::@class::C::@setter::x::@parameter::_x
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@class::C::@setter::x
  writeElement2: <testLibraryFragment>::@class::C::@setter::x#element
  writeType: num
  staticElement: <null>
  element: <null>
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
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@class::C::@getter::x
  writeElement2: <testLibraryFragment>::@class::C::@getter::x#element
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@class::C::@getter::x
  writeElement2: <testLibraryFragment>::@class::C::@getter::x#element
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@getter::x
  writeElement2: <testLibraryFragment>::@getter::x#element
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@prefix::x
  writeElement2: <testLibraryFragment>::@prefix2::x
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@prefix::x
  writeElement2: <testLibraryFragment>::@prefix2::x
  writeType: InvalidType
  staticElement: <null>
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
    staticElement: x@51
    element: x@51
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 3
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: x@51
  readElement2: x@51
  readType: num
  writeElement: x@51
  writeElement2: x@51
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
    element: x@51
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: x@51
  writeElement2: x@51
  writeType: num
  staticElement: <null>
  element: <null>
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
    element: x@57
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: x@57
  writeElement2: x@57
  writeType: num
  staticElement: <null>
  element: <null>
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
    element: x@57
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: x@57
  writeElement2: x@57
  writeType: num
  staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  readElement: <testLibraryFragment>::@function::f::@parameter::x
  readElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  readType: num?
  writeElement: <testLibraryFragment>::@function::f::@parameter::x
  writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  writeType: num?
  staticElement: <null>
  element: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: null
  operator: ??=
  rightHandSide: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: C
        element: <testLibraryFragment>::@class::C
        element2: <testLibraryFragment>::@class::C#element
        type: C
      staticElement: <testLibraryFragment>::@class::C::@constructor::new
      element: <testLibraryFragment>::@class::C::@constructor::new#element
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    parameter: <null>
    staticType: C
  readElement: <testLibraryFragment>::@function::f::@parameter::x
  readElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  readType: B?
  writeElement: <testLibraryFragment>::@function::f::@parameter::x
  writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  writeType: B?
  staticElement: <null>
  element: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: null
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: b
    parameter: <null>
    staticElement: <testLibraryFragment>::@function::f::@parameter::b
    element: <testLibraryFragment>::@function::f::@parameter::b#element
    staticType: int
  readElement: <testLibraryFragment>::@function::f::@parameter::a
  readElement2: <testLibraryFragment>::@function::f::@parameter::a#element
  readType: double?
  writeElement: <testLibraryFragment>::@function::f::@parameter::a
  writeElement2: <testLibraryFragment>::@function::f::@parameter::a#element
  writeType: double?
  staticElement: <null>
  element: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@function::f::@parameter::x
  writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  writeType: num
  staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: <null>
    staticType: double
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@function::f::@parameter::x
  writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  writeType: Object
  staticElement: <null>
  element: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: null
  operator: =
  rightHandSide: BooleanLiteral
    literal: true
    parameter: <null>
    staticType: bool
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@function::f::@parameter::x
  writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  writeType: int
  staticElement: <null>
  element: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@function::f::@parameter::x
  writeElement2: <testLibraryFragment>::@function::f::@parameter::x#element
  writeType: int
  staticElement: <null>
  element: <null>
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
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@class::B::@getter::x
  writeElement2: <testLibraryFragment>::@class::B::@getter::x#element
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@class::B::@method::x
  writeElement2: <testLibraryFragment>::@class::B::@method::x#element
  writeType: InvalidType
  staticElement: <null>
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
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <testLibraryFragment>::@class::A::@setter::x::@parameter::_
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: num
  staticElement: <null>
  element: <null>
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
    element: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: <testLibraryFragment>::@function::f::@parameter::y
    element: <testLibraryFragment>::@function::f::@parameter::y#element
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
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
    staticElement: <null>
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <testLibraryFragment>::@class::A::@setter::x::@parameter::_x
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@class::A::@setter::x
  writeElement2: <testLibraryFragment>::@class::A::@setter::x#element
  writeType: int
  staticElement: <null>
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
    staticElement: <null>
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <testLibraryFragment>::@class::C::@getter::x
  readElement2: <testLibraryFragment>::@class::C::@getter::x#element
  readType: int
  writeElement: <testLibraryFragment>::@class::C::@setter::x
  writeElement2: <testLibraryFragment>::@class::C::@setter::x#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <testLibraryFragment>::@mixin::M2::@getter::x
  readElement2: <testLibraryFragment>::@mixin::M2::@getter::x#element
  readType: int
  writeElement: <testLibraryFragment>::@mixin::M2::@setter::x
  writeElement2: <testLibraryFragment>::@mixin::M2::@setter::x#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <testLibraryFragment>::@class::C::@getter::x
  readElement2: <testLibraryFragment>::@class::C::@getter::x#element
  readType: int?
  writeElement: <testLibraryFragment>::@class::C::@setter::x
  writeElement2: <testLibraryFragment>::@class::C::@setter::x#element
  writeType: num?
  staticElement: <null>
  element: <null>
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
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@getter::x
  writeElement2: <testLibraryFragment>::@getter::x#element
  writeType: InvalidType
  staticElement: <null>
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
    staticElement: <null>
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <testLibraryFragment>::@getter::x
  readElement2: <testLibraryFragment>::@getter::x#element
  readType: int
  writeElement: <testLibraryFragment>::@setter::x
  writeElement2: <testLibraryFragment>::@setter::x#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
    element: <null>
    staticType: null
  operator: ??=
  rightHandSide: InstanceCreationExpression
    constructorName: ConstructorName
      type: NamedType
        name: C
        element: <testLibraryFragment>::@class::C
        element2: <testLibraryFragment>::@class::C#element
        type: C
      staticElement: <testLibraryFragment>::@class::C::@constructor::new
      element: <testLibraryFragment>::@class::C::@constructor::new#element
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    parameter: <null>
    staticType: C
  readElement: <testLibraryFragment>::@getter::x
  readElement2: <testLibraryFragment>::@getter::x#element
  readType: B?
  writeElement: <testLibraryFragment>::@setter::x
  writeElement2: <testLibraryFragment>::@setter::x#element
  writeType: B?
  staticElement: <null>
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
    staticElement: <null>
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: dart:core::<fragment>::@class::num::@method::+::@parameter::other
    staticType: int
  readElement: <testLibraryFragment>::@getter::x
  readElement2: <testLibraryFragment>::@getter::x#element
  readType: int
  writeElement: <testLibraryFragment>::@setter::x
  writeElement2: <testLibraryFragment>::@setter::x#element
  writeType: num
  staticElement: dart:core::<fragment>::@class::num::@method::+
  element: dart:core::<fragment>::@class::num::@method::+#element
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
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <testLibraryFragment>::@setter::x::@parameter::_x
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@setter::x
  writeElement2: <testLibraryFragment>::@setter::x#element
  writeType: num
  staticElement: <null>
  element: <null>
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
    element: <null>
    staticType: null
  operator: =
  rightHandSide: BooleanLiteral
    literal: true
    parameter: <testLibraryFragment>::@setter::x::@parameter::_x
    staticType: bool
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@setter::x
  writeElement2: <testLibraryFragment>::@setter::x#element
  writeType: int
  staticElement: <null>
  element: <null>
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
    element: <null>
    staticType: null
  operator: =
  rightHandSide: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <testLibraryFragment>::@getter::x
  writeElement2: <testLibraryFragment>::@getter::x#element
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 3
    parameter: <null>
    staticType: int
  readElement: dart:core::<fragment>::@class::int
  readElement2: dart:core::<fragment>::@class::int#element
  readType: InvalidType
  writeElement: dart:core::<fragment>::@class::int
  writeElement2: dart:core::<fragment>::@class::int#element
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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
  writeElement: dart:core::<fragment>::@class::int
  writeElement2: dart:core::<fragment>::@class::int#element
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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
    element: <null>
    staticType: null
  operator: +=
  rightHandSide: IntegerLiteral
    literal: 1
    parameter: <null>
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: InvalidType
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
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
    element: <null>
    staticType: null
  operator: =
  rightHandSide: SimpleIdentifier
    token: a
    parameter: <null>
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: int
  readElement: <null>
  readElement2: <null>
  readType: null
  writeElement: <null>
  writeElement2: <null>
  writeType: InvalidType
  staticElement: <null>
  element: <null>
  staticType: int
''');
  }
}

@reflectiveTest
class InferenceUpdate3Test extends PubPackageResolutionTest {
  @override
  List<String> get experiments {
    return [
      ...super.experiments,
      Feature.inference_update_3.enableString,
    ];
  }

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
        findNode.assignment('o ??= c2'), r'''AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: o
    staticElement: <testLibraryFragment>::@function::f::@parameter::o
    element: <testLibraryFragment>::@function::f::@parameter::o#element
    staticType: null
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: c2
    parameter: <null>
    staticElement: <testLibraryFragment>::@function::f::@parameter::c2
    element: <testLibraryFragment>::@function::f::@parameter::c2#element
    staticType: C2<double>
  parameter: ParameterMember
    base: <testLibraryFragment>::@function::contextB1::@parameter::b1
    substitution: {T: Object?}
  readElement: <testLibraryFragment>::@function::f::@parameter::o
  readElement2: <testLibraryFragment>::@function::f::@parameter::o#element
  readType: C1<int>?
  writeElement: <testLibraryFragment>::@function::f::@parameter::o
  writeElement2: <testLibraryFragment>::@function::f::@parameter::o#element
  writeType: Object?
  staticElement: <null>
  element: <null>
  staticType: B1<Object?>
''');
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
        findNode.assignment('o2 ??= i'), r'''AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: o2
    staticElement: <testLibraryFragment>::@function::f::@parameter::o2
    element: <testLibraryFragment>::@function::f::@parameter::o2#element
    staticType: null
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: i
    parameter: <null>
    staticElement: <testLibraryFragment>::@function::f::@parameter::i
    element: <testLibraryFragment>::@function::f::@parameter::i#element
    staticType: int?
  readElement: <testLibraryFragment>::@function::f::@parameter::o2
  readElement2: <testLibraryFragment>::@function::f::@parameter::o2#element
  readType: double?
  writeElement: <testLibraryFragment>::@function::f::@parameter::o2
  writeElement2: <testLibraryFragment>::@function::f::@parameter::o2#element
  writeType: Object?
  staticElement: <null>
  element: <null>
  staticType: num?
''');
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::o
    element: <testLibraryFragment>::@function::f::@parameter::o#element
    staticType: null
  operator: ??=
  rightHandSide: SimpleIdentifier
    token: c2
    parameter: <null>
    staticElement: <testLibraryFragment>::@function::f::@parameter::c2
    element: <testLibraryFragment>::@function::f::@parameter::c2#element
    staticType: C2
  parameter: <testLibraryFragment>::@function::contextB1::@parameter::b1
  readElement: <testLibraryFragment>::@function::f::@parameter::o
  readElement2: <testLibraryFragment>::@function::f::@parameter::o#element
  readType: C1?
  writeElement: <testLibraryFragment>::@function::f::@parameter::o
  writeElement2: <testLibraryFragment>::@function::f::@parameter::o#element
  writeType: Object?
  staticElement: <null>
  element: <null>
  staticType: B1
''');
  }
}
