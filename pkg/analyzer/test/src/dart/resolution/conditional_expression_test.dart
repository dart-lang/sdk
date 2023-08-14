// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConditionalExpressionResolutionTest);
    defineReflectiveTests(
        ConditionalExpressionResolutionTest_WithoutNullSafety);
  });
}

@reflectiveTest
class ConditionalExpressionResolutionTest extends PubPackageResolutionTest
    with ConditionalExpressionTestCases {
  test_condition_super() async {
    await assertErrorsInCode('''
class A {
  void f() {
    super ? 0 : 1;
  }
}
''', [
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 27, 5),
    ]);

    final node = findNode.singleConditionalExpression;
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

    final node = findNode.singleMethodInvocation;
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: a
    staticElement: self::@function::a
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
    await assertErrorsInCode('''
class A {
  void f(bool c) {
    c ? 0 : super;
  }
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 41, 5),
    ]);

    final node = findNode.singleConditionalExpression;
    assertResolvedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: c
    staticElement: self::@class::A::@method::f::@parameter::c
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

  test_issue49692() async {
    await assertErrorsInCode('''
T f<T>(T t, bool b) {
  if (t is int) {
    final u = b ? t : null;
    return u;
  } else {
    return t;
  }
}
''', [
      error(CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 79, 1),
    ]);

    final node = findNode.conditionalExpression('b ?');
    assertResolvedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: b
    staticElement: self::@function::f::@parameter::b
    staticType: bool
  question: ?
  thenExpression: SimpleIdentifier
    token: t
    staticElement: self::@function::f::@parameter::t
    staticType: T & int
  colon: :
  elseExpression: NullLiteral
    literal: null
    staticType: Null
  staticType: (T & int)?
''');
  }

  test_recordType_differentShape() async {
    await assertNoErrorsInCode('''
void f(bool b, (int, String) r1, ({int a}) r2) {
  b ? r1 : r2;
}
''');

    final node = findNode.conditionalExpression('b ?');
    assertResolvedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: b
    staticElement: self::@function::f::@parameter::b
    staticType: bool
  question: ?
  thenExpression: SimpleIdentifier
    token: r1
    staticElement: self::@function::f::@parameter::r1
    staticType: (int, String)
  colon: :
  elseExpression: SimpleIdentifier
    token: r2
    staticElement: self::@function::f::@parameter::r2
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

    final node = findNode.conditionalExpression('b ?');
    assertResolvedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: b
    staticElement: self::@function::f::@parameter::b
    staticType: bool
  question: ?
  thenExpression: SimpleIdentifier
    token: r1
    staticElement: self::@function::f::@parameter::r1
    staticType: ({int a})
  colon: :
  elseExpression: SimpleIdentifier
    token: r2
    staticElement: self::@function::f::@parameter::r2
    staticType: ({double a})
  staticType: ({num a})
''');
  }

  test_then_super() async {
    await assertErrorsInCode('''
class A {
  void f(bool c) {
    c ? super : 0;
  }
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 37, 5),
    ]);

    final node = findNode.singleConditionalExpression;
    assertResolvedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: c
    staticElement: self::@class::A::@method::f::@parameter::c
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

    final node = findNode.singleConditionalExpression;
    assertResolvedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: b
    staticElement: self::@function::f::@parameter::b
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

    final node = findNode.singleConditionalExpression;
    assertResolvedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: b
    staticElement: self::@function::f::@parameter::b
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
}

@reflectiveTest
class ConditionalExpressionResolutionTest_WithoutNullSafety
    extends PubPackageResolutionTest
    with ConditionalExpressionTestCases, WithoutNullSafetyMixin {}

mixin ConditionalExpressionTestCases on PubPackageResolutionTest {
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
