// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConditionalExpressionResolutionTest);
    defineReflectiveTests(InferenceUpdate3Test);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ConditionalExpressionResolutionTest extends PubPackageResolutionTest {
  test_condition_super() async {
    await assertErrorsInCode(
      '''
class A {
  void f() {
    super ? 0 : 1;
  }
}
''',
      [error(CompileTimeErrorCode.nonBoolCondition, 27, 5)],
    );

    var node = findNode.singleConditionalExpression;
    assertResolvedNodeText(node, r'''
ConditionalExpression
  condition: SuperExpression
    superKeyword: super
    staticType: A
  question: ?
  thenExpression: IntegerLiteral
    literal: 0
    staticType: int
  colon: :
  elseExpression: IntegerLiteral
    literal: 1
    staticType: int
  staticType: int
''');
  }

  test_downward_condition() async {
    await resolveTestCode('''
void f(int b, int c) {
  a() ? b : c;
}

T a<T>() => throw '';
''');

    var node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::a
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: bool Function()
  staticType: bool
  typeArgumentTypes
    bool
''');
  }

  test_else_super() async {
    await assertErrorsInCode(
      '''
class A {
  void f(bool c) {
    c ? 0 : super;
  }
}
''',
      [error(ParserErrorCode.missingAssignableSelector, 41, 5)],
    );

    var node = findNode.singleConditionalExpression;
    assertResolvedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: c
    element: <testLibrary>::@class::A::@method::f::@formalParameter::c
    staticType: bool
  question: ?
  thenExpression: IntegerLiteral
    literal: 0
    staticType: int
  colon: :
  elseExpression: SuperExpression
    superKeyword: super
    staticType: A
  staticType: Object
''');
  }

  test_ifNull_lubUsedEvenIfItDoesNotSatisfyContext() async {
    await assertNoErrorsInCode('''
// @dart=3.3
class A {}
class B1 extends A {}
class B2 extends A {}
class C1 implements B1, B2 {}
class C2 implements B1, B2 {}
f(bool b, C1 c1, C2 c2, Object? o) {
  if (o is B1) {
    o = b ? c1 : c2;
  }
}
''');

    assertResolvedNodeText(findNode.conditionalExpression('b ? c1 : c2'), r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool
  question: ?
  thenExpression: SimpleIdentifier
    token: c1
    element: <testLibrary>::@function::f::@formalParameter::c1
    staticType: C1
  colon: :
  elseExpression: SimpleIdentifier
    token: c2
    element: <testLibrary>::@function::f::@formalParameter::c2
    staticType: C2
  correspondingParameter: <null>
  staticType: A
''');
  }

  test_issue49692() async {
    await assertErrorsInCode(
      '''
T f<T>(T t, bool b) {
  if (t is int) {
    final u = b ? t : null;
    return u;
  } else {
    return t;
  }
}
''',
      [error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 79, 1)],
    );

    var node = findNode.conditionalExpression('b ?');
    assertResolvedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool
  question: ?
  thenExpression: SimpleIdentifier
    token: t
    element: <testLibrary>::@function::f::@formalParameter::t
    staticType: T & int
  colon: :
  elseExpression: NullLiteral
    literal: null
    staticType: Null
  staticType: int?
''');
  }

  test_recordType_differentShape() async {
    await assertNoErrorsInCode('''
void f(bool b, (int, String) r1, ({int a}) r2) {
  b ? r1 : r2;
}
''');

    var node = findNode.conditionalExpression('b ?');
    assertResolvedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool
  question: ?
  thenExpression: SimpleIdentifier
    token: r1
    element: <testLibrary>::@function::f::@formalParameter::r1
    staticType: (int, String)
  colon: :
  elseExpression: SimpleIdentifier
    token: r2
    element: <testLibrary>::@function::f::@formalParameter::r2
    staticType: ({int a})
  staticType: Record
''');
  }

  test_recordType_sameShape_named() async {
    await assertNoErrorsInCode('''
void f(bool b, ({int a}) r1, ({double a}) r2) {
  b ? r1 : r2;
}
''');

    var node = findNode.conditionalExpression('b ?');
    assertResolvedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool
  question: ?
  thenExpression: SimpleIdentifier
    token: r1
    element: <testLibrary>::@function::f::@formalParameter::r1
    staticType: ({int a})
  colon: :
  elseExpression: SimpleIdentifier
    token: r2
    element: <testLibrary>::@function::f::@formalParameter::r2
    staticType: ({double a})
  staticType: ({num a})
''');
  }

  test_then_super() async {
    await assertErrorsInCode(
      '''
class A {
  void f(bool c) {
    c ? super : 0;
  }
}
''',
      [error(ParserErrorCode.missingAssignableSelector, 37, 5)],
    );

    var node = findNode.singleConditionalExpression;
    assertResolvedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: c
    element: <testLibrary>::@class::A::@method::f::@formalParameter::c
    staticType: bool
  question: ?
  thenExpression: SuperExpression
    superKeyword: super
    staticType: A
  colon: :
  elseExpression: IntegerLiteral
    literal: 0
    staticType: int
  staticType: Object
''');
  }

  test_type_int_double() async {
    await assertNoErrorsInCode('''
void f(bool b) {
  b ? 0 : 1.2;
}
''');

    var node = findNode.singleConditionalExpression;
    assertResolvedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool
  question: ?
  thenExpression: IntegerLiteral
    literal: 0
    staticType: int
  colon: :
  elseExpression: DoubleLiteral
    literal: 1.2
    staticType: double
  staticType: num
''');
  }

  test_type_int_null() async {
    await assertNoErrorsInCode('''
void f(bool b) {
  b ? 42 : null;
}
''');

    var node = findNode.singleConditionalExpression;
    assertResolvedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool
  question: ?
  thenExpression: IntegerLiteral
    literal: 42
    staticType: int
  colon: :
  elseExpression: NullLiteral
    literal: null
    staticType: Null
  staticType: int?
''');
  }

  test_upward() async {
    await resolveTestCode('''
void f(bool a, int b, int c) {
  var d = a ? b : c;
  print(d);
}
''');
    assertType(findNode.simple('d)'), 'int');
  }
}

@reflectiveTest
class InferenceUpdate3Test extends PubPackageResolutionTest {
  test_contextIsConvertedToATypeUsingGreatestClosure() async {
    await assertNoErrorsInCode('''
class A {}
class B1<T> extends A {}
class B2<T> extends A {}
class C1<T> implements B1<T>, B2<T> {}
class C2<T> implements B1<T>, B2<T> {}
void contextB1<T>(B1<T> b1) {}
f(bool b, C1<int> c1, C2<double> c2) {
  contextB1(b ? c1 : c2);
}
''');

    assertResolvedNodeText(
      findNode.conditionalExpression('b ? c1 : c2'),
      r'''ConditionalExpression
  condition: SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool
  question: ?
  thenExpression: SimpleIdentifier
    token: c1
    element: <testLibrary>::@function::f::@formalParameter::c1
    staticType: C1<int>
  colon: :
  elseExpression: SimpleIdentifier
    token: c2
    element: <testLibrary>::@function::f::@formalParameter::c2
    staticType: C2<double>
  correspondingParameter: ParameterMember
    baseElement: <testLibrary>::@function::contextB1::@formalParameter::b1
    substitution: {T: Object?}
  staticType: B1<Object?>
''',
    );
  }

  test_contextNotUsedIfLhsDoesNotSatisfyContext() async {
    await assertNoErrorsInCode('''
class A {}
class B1 extends A {}
class B2 extends A {}
class C1 implements B1, B2 {}
class C2 implements B1, B2 {}
f(bool b, B2 b2, C1 c1, Object? o) {
  if (o is B1) {
    o = b ? b2 : c1;
  }
}
''');

    assertResolvedNodeText(
      findNode.conditionalExpression('b ? b2 : c1'),
      r'''ConditionalExpression
  condition: SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool
  question: ?
  thenExpression: SimpleIdentifier
    token: b2
    element: <testLibrary>::@function::f::@formalParameter::b2
    staticType: B2
  colon: :
  elseExpression: SimpleIdentifier
    token: c1
    element: <testLibrary>::@function::f::@formalParameter::c1
    staticType: C1
  correspondingParameter: <null>
  staticType: B2
''',
    );
  }

  test_contextNotUsedIfRhsDoesNotSatisfyContext() async {
    await assertNoErrorsInCode('''
class A {}
class B1 extends A {}
class B2 extends A {}
class C1 implements B1, B2 {}
class C2 implements B1, B2 {}
f(bool b, C1 c1, B2 b2, Object? o) {
  if (o is B1) {
    o = b ? c1 : b2;
  }
}
''');

    assertResolvedNodeText(
      findNode.conditionalExpression('b ? c1 : b2'),
      r'''ConditionalExpression
  condition: SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool
  question: ?
  thenExpression: SimpleIdentifier
    token: c1
    element: <testLibrary>::@function::f::@formalParameter::c1
    staticType: C1
  colon: :
  elseExpression: SimpleIdentifier
    token: b2
    element: <testLibrary>::@function::f::@formalParameter::b2
    staticType: B2
  correspondingParameter: <null>
  staticType: B2
''',
    );
  }

  test_contextUsedInsteadOfLubIfLubDoesNotSatisfyContext() async {
    await assertNoErrorsInCode('''
class A {}
class B1 extends A {}
class B2 extends A {}
class C1 implements B1, B2 {}
class C2 implements B1, B2 {}
B1 f(bool b, C1 c1, C2 c2) => b ? c1 : c2;
''');

    assertResolvedNodeText(findNode.conditionalExpression('b ? c1 : c2'), r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: b
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool
  question: ?
  thenExpression: SimpleIdentifier
    token: c1
    element: <testLibrary>::@function::f::@formalParameter::c1
    staticType: C1
  colon: :
  elseExpression: SimpleIdentifier
    token: c2
    element: <testLibrary>::@function::f::@formalParameter::c2
    staticType: C2
  staticType: B1
''');
  }
}
