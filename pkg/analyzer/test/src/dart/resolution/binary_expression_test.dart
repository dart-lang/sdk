// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
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
    defineReflectiveTests(BinaryExpressionResolutionTest);
    defineReflectiveTests(InferenceUpdate3Test);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class BinaryExpressionResolutionTest extends PubPackageResolutionTest
    with BinaryExpressionResolutionTestCases {
  test_eqEq_alwaysBool() async {
    await assertNoErrorsInCode(r'''
extension type MyBool(bool it) implements bool {}

class A {
  MyBool operator ==(_) => MyBool(true);
}

void f(A a) {
  a == 0;
}
''');

    var node = findNode.binary('a == 0');
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A
  operator: ==
  rightOperand: IntegerLiteral
    literal: 0
    parameter: self::@class::A::@method::==::@parameter::_
    staticType: int
  staticElement: self::@class::A::@method::==
  staticInvokeType: MyBool Function(Object)
  staticType: bool
''');
  }

  test_eqEq_switchExpression_left() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  (switch (x) {
    _ => 1,
  } == 0);
}
''');

    var node = findNode.binary('== 0');
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SwitchExpression
    switchKeyword: switch
    leftParenthesis: (
    expression: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: Object?
    rightParenthesis: )
    leftBracket: {
    cases
      SwitchExpressionCase
        guardedPattern: GuardedPattern
          pattern: WildcardPattern
            name: _
            matchedValueType: Object?
        arrow: =>
        expression: IntegerLiteral
          literal: 1
          staticType: int
    rightBracket: }
    staticType: int
  operator: ==
  rightOperand: IntegerLiteral
    literal: 0
    parameter: dart:core::@class::num::@method::==::@parameter::other
    staticType: int
  staticElement: dart:core::@class::num::@method::==
  staticInvokeType: bool Function(Object)
  staticType: bool
''');
  }

  test_eqEq_switchExpression_right() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  0 == switch (x) {
    _ => 1,
  };
}
''');

    var node = findNode.binary('0 ==');
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: IntegerLiteral
    literal: 0
    staticType: int
  operator: ==
  rightOperand: SwitchExpression
    switchKeyword: switch
    leftParenthesis: (
    expression: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: Object?
    rightParenthesis: )
    leftBracket: {
    cases
      SwitchExpressionCase
        guardedPattern: GuardedPattern
          pattern: WildcardPattern
            name: _
            matchedValueType: Object?
        arrow: =>
        expression: IntegerLiteral
          literal: 1
          staticType: int
    rightBracket: }
    parameter: dart:core::@class::num::@method::==::@parameter::other
    staticType: int
  staticElement: dart:core::@class::num::@method::==
  staticInvokeType: bool Function(Object)
  staticType: bool
''');
  }

  test_expression_recordType_hasOperator() async {
    await assertNoErrorsInCode(r'''
void f((String,) a) {
  a + 0;
}

extension on (String,) {
  int operator +(int other) => 0;
}
''');

    var node = findNode.binary('+ 0');
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: (String,)
  operator: +
  rightOperand: IntegerLiteral
    literal: 0
    parameter: self::@extension::0::@method::+::@parameter::other
    staticType: int
  staticElement: self::@extension::0::@method::+
  staticInvokeType: int Function(int)
  staticType: int
''');
  }

  test_expression_recordType_noOperator() async {
    await assertErrorsInCode(r'''
void f((String,) a) {
  a + 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_OPERATOR, 26, 1),
    ]);

    var node = findNode.binary('+ 0');
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: (String,)
  operator: +
  rightOperand: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: InvalidType
''');
  }

  test_gtGtGt() async {
    await assertNoErrorsInCode(r'''
class A {
  A operator >>>(int amount) => this;
}

void f(A a) {
  a >>> 3;
}
''');

    var node = findNode.singleBinaryExpression;
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A
  operator: >>>
  rightOperand: IntegerLiteral
    literal: 3
    parameter: self::@class::A::@method::>>>::@parameter::amount
    staticType: int
  staticElement: self::@class::A::@method::>>>
  staticInvokeType: A Function(int)
  staticType: A
''');
  }

  test_ifNull_left_nullableContext() async {
    await assertNoErrorsInCode(r'''
T f<T>(T t) => t;

int g() => f(null) ?? 0;
''');

    assertResolvedNodeText(findNode.binary('?? 0'), r'''
BinaryExpression
  leftOperand: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      staticElement: self::@function::f
      staticType: T Function<T>(T)
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        NullLiteral
          literal: null
          parameter: ParameterMember
            base: self::@function::f::@parameter::t
            substitution: {T: int?}
          staticType: Null
      rightParenthesis: )
    staticInvokeType: int? Function(int?)
    staticType: int?
    typeArgumentTypes
      int?
  operator: ??
  rightOperand: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: int
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
f(C1? c1, C2 c2, Object? o) {
  if (o is B1) {
    o = c1 ?? c2;
  }
}
''');

    assertResolvedNodeText(findNode.binary('c1 ?? c2'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: c1
    staticElement: self::@function::f::@parameter::c1
    staticType: C1?
  operator: ??
  rightOperand: SimpleIdentifier
    token: c2
    parameter: <null>
    staticElement: self::@function::f::@parameter::c2
    staticType: C2
  parameter: <null>
  staticElement: <null>
  staticInvokeType: null
  staticType: A
''');
  }

  test_ifNull_nullableInt_int() async {
    await assertNoErrorsInCode(r'''
void f(int? x, int y) {
  x ?? y;
}
''');

    assertResolvedNodeText(findNode.binary('x ?? y'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: int?
  operator: ??
  rightOperand: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: self::@function::f::@parameter::y
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: int
''');
  }

  test_ifNull_nullableInt_nullableDouble() async {
    await assertNoErrorsInCode(r'''
void f(int? x, double? y) {
  x ?? y;
}
''');

    assertResolvedNodeText(findNode.binary('x ?? y'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: int?
  operator: ??
  rightOperand: SimpleIdentifier
    token: y
    parameter: <null>
    staticElement: self::@function::f::@parameter::y
    staticType: double?
  staticElement: <null>
  staticInvokeType: null
  staticType: num?
''');
  }

  test_ifNull_nullableInt_nullableInt() async {
    await assertNoErrorsInCode(r'''
void f(int? x) {
  x ?? x;
}
''');

    assertResolvedNodeText(findNode.binary('x ?? x'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: int?
  operator: ??
  rightOperand: SimpleIdentifier
    token: x
    parameter: <null>
    staticElement: self::@function::f::@parameter::x
    staticType: int?
  staticElement: <null>
  staticInvokeType: null
  staticType: int?
''');
  }

  test_plus_augmentedExpression_augments_nothing() async {
    await assertErrorsInCode('''
class A {
  int operator+(Object? a) {
    return augmented + 0;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 50, 9),
    ]);

    var node = findNode.singleBinaryExpression;
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: augmented
    staticElement: <null>
    staticType: InvalidType
  operator: +
  rightOperand: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: InvalidType
''');
  }

  test_plus_augmentedExpression_augments_plus() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {
  int operator+(Object? a) => 0;
}
''');

    await assertNoErrorsInCode('''
augment library 'a.dart';

augment class A {
  augment int operator+(Object? a) {
    return augmented + 0;
  }
}
''');

    var node = findNode.singleBinaryExpression;
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: AugmentedExpression
    augmentedKeyword: augmented
    element: self::@class::A::@method::+
    staticType: A
  operator: +
  rightOperand: IntegerLiteral
    literal: 0
    parameter: self::@class::A::@method::+::@parameter::a
    staticType: int
  staticElement: self::@class::A::@method::+
  staticInvokeType: int Function(Object?)
  staticType: int
''');
  }

  test_plus_augmentedExpression_augments_unaryMinus() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {
  int operator-() => 0;
}
''');

    await assertErrorsInCode('''
augment library 'a.dart';

augment class A {
  augment int operator-() {
    return augmented + 0;
  }
}
''', [
      error(CompileTimeErrorCode.AUGMENTED_EXPRESSION_NOT_OPERATOR, 84, 9),
    ]);

    var node = findNode.singleBinaryExpression;
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: AugmentedExpression
    augmentedKeyword: augmented
    element: self::@class::A::@method::unary-
    staticType: A
  operator: +
  rightOperand: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: InvalidType
''');
  }

  test_plus_augmentedExpression_class_field() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {
  num foo = 0;
}
''');

    await assertNoErrorsInCode('''
augment library 'a.dart';

augment class A {
  augment num foo = augmented + 1;
}
''');

    var node = findNode.singleBinaryExpression;
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: AugmentedExpression
    augmentedKeyword: augmented
    element: self::@class::A::@field::foo
    staticType: num
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  staticElement: dart:core::@class::num::@method::+
  staticInvokeType: num Function(num)
  staticType: num
''');
  }

  test_plus_augmentedExpression_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {
  int get foo => 0;
}
''');

    await assertNoErrorsInCode('''
augment library 'a.dart';

augment class A {
  augment int get foo {
    return augmented + 1;
  }
}
''');

    var node = findNode.singleBinaryExpression;
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: AugmentedExpression
    augmentedKeyword: augmented
    element: self::@class::A::@getter::foo
    staticType: int
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  staticElement: dart:core::@class::num::@method::+
  staticInvokeType: num Function(num)
  staticType: int
''');
  }

  test_plus_augmentedExpression_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {
  set foo(int _) {}
}
''');

    await assertErrorsInCode('''
augment library 'a.dart';

augment class A {
  augment set foo(int _) {
    augmented + 1;
  }
}
''', [
      error(CompileTimeErrorCode.AUGMENTED_EXPRESSION_IS_SETTER, 76, 9),
    ]);

    var node = findNode.singleBinaryExpression;
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: AugmentedExpression
    augmentedKeyword: augmented
    element: self::@class::A::@setter::foo
    staticType: InvalidType
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
    parameter: <null>
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: InvalidType
''');
  }

  test_plus_extensionType_int() async {
    await assertNoErrorsInCode('''
extension type Int(int i) implements int {
  Int operator +(int other) {
    return Int(i + other);
  }
}

void f(Int a, int b) {
  a + b;
}
''');

    var node = findNode.binary('a + b');
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: Int
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    parameter: self::@extensionType::Int::@method::+::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: self::@extensionType::Int::@method::+
  staticInvokeType: Int Function(int)
  staticType: Int
''');
  }

  test_plus_int_never() async {
    await assertNoErrorsInCode('''
f(int a, Never b) {
  a + b;
}
''');

    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: Never
  staticElement: dart:core::@class::num::@method::+
  staticInvokeType: num Function(num)
  staticType: num
''');
  }

  test_plus_never_int() async {
    await assertErrorsInCode(r'''
f(Never a, int b) {
  a + b;
}
''', [
      error(WarningCode.RECEIVER_OF_TYPE_NEVER, 22, 1),
      error(WarningCode.DEAD_CODE, 26, 2),
    ]);

    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: Never
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    parameter: <null>
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: Never
''');
  }

  test_plus_switchExpression_left() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  (switch (x) {
    _ => 1,
  } + 0);
}
''');

    var node = findNode.binary('+ 0');
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SwitchExpression
    switchKeyword: switch
    leftParenthesis: (
    expression: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: Object?
    rightParenthesis: )
    leftBracket: {
    cases
      SwitchExpressionCase
        guardedPattern: GuardedPattern
          pattern: WildcardPattern
            name: _
            matchedValueType: Object?
        arrow: =>
        expression: IntegerLiteral
          literal: 1
          staticType: int
    rightBracket: }
    staticType: int
  operator: +
  rightOperand: IntegerLiteral
    literal: 0
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  staticElement: dart:core::@class::num::@method::+
  staticInvokeType: num Function(num)
  staticType: int
''');
  }

  test_plus_switchExpression_right() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  0 + switch (x) {
    _ => 1,
  };
}
''');

    var node = findNode.binary('0 +');
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: IntegerLiteral
    literal: 0
    staticType: int
  operator: +
  rightOperand: SwitchExpression
    switchKeyword: switch
    leftParenthesis: (
    expression: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: Object?
    rightParenthesis: )
    leftBracket: {
    cases
      SwitchExpressionCase
        guardedPattern: GuardedPattern
          pattern: WildcardPattern
            name: _
            matchedValueType: Object?
        arrow: =>
        expression: IntegerLiteral
          literal: 1
          staticType: int
    rightBracket: }
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  staticElement: dart:core::@class::num::@method::+
  staticInvokeType: num Function(num)
  staticType: int
''');
  }

  test_star_syntheticOperand_both() async {
    await assertErrorsInCode(r'''
void f() {
  final v = * ;
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 19, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 23, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 25, 1),
    ]);

    var node = findNode.singleBinaryExpression;
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
    staticElement: <null>
    staticType: InvalidType
  operator: *
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
    parameter: <null>
    staticElement: <null>
    staticType: InvalidType
  staticElement: <null>
  staticInvokeType: null
  staticType: InvalidType
''');
  }

  test_star_syntheticOperand_left() async {
    await assertErrorsInCode(r'''
void f() {
  final v = * 2;
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 19, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 23, 1),
    ]);

    var node = findNode.singleBinaryExpression;
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
    staticElement: <null>
    staticType: InvalidType
  operator: *
  rightOperand: IntegerLiteral
    literal: 2
    parameter: <null>
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: InvalidType
''');
  }

  test_star_syntheticOperand_right() async {
    await assertErrorsInCode(r'''
void f() {
  final v = 2 * ;
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 19, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 27, 1),
    ]);

    var node = findNode.singleBinaryExpression;
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: IntegerLiteral
    literal: 2
    staticType: int
  operator: *
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
    parameter: dart:core::@class::num::@method::*::@parameter::other
    staticElement: <null>
    staticType: InvalidType
  staticElement: dart:core::@class::num::@method::*
  staticInvokeType: num Function(num)
  staticType: double
''');
  }

  test_superQualifier_plus() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator +(int other) => 0;
}

class B extends A {
  int operator +(int other) => 0;

  void f() {
    super + 0;
  }
}
''');

    var node = findNode.binary('+ 0');
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SuperExpression
    superKeyword: super
    staticType: B
  operator: +
  rightOperand: IntegerLiteral
    literal: 0
    parameter: self::@class::A::@method::+::@parameter::other
    staticType: int
  staticElement: self::@class::A::@method::+
  staticInvokeType: int Function(int)
  staticType: int
''');
  }

  test_thisExpression_plus() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator +(int other) => 0;

  void f() {
    this + 0;
  }
}
''');

    var node = findNode.binary('+ 0');
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: ThisExpression
    thisKeyword: this
    staticType: A
  operator: +
  rightOperand: IntegerLiteral
    literal: 0
    parameter: self::@class::A::@method::+::@parameter::other
    staticType: int
  staticElement: self::@class::A::@method::+
  staticInvokeType: int Function(int)
  staticType: int
''');
  }
}

mixin BinaryExpressionResolutionTestCases on PubPackageResolutionTest {
  test_bangEq() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a != b;
}
''');

    assertResolvedNodeText(findNode.binary('a != b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: !=
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::==::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: dart:core::@class::num::@method::==
  staticInvokeType: bool Function(Object)
  staticType: bool
''');
  }

  test_bangEq_extensionOverride_left() async {
    await assertErrorsInCode(r'''
extension E on int {}

void f(int a) {
  E(a) != 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR, 46, 2),
    ]);

    assertResolvedNodeText(findNode.binary('!= 0'), r'''
BinaryExpression
  leftOperand: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: int
      rightParenthesis: )
    element: self::@extension::E
    extendedType: int
    staticType: null
  operator: !=
  rightOperand: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: InvalidType
''');
  }

  test_bangEqEq() async {
    await assertErrorsInCode(r'''
f(int a, int b) {
  a !== b;
}
''', [
      error(ScannerErrorCode.UNSUPPORTED_OPERATOR, 22, 1),
    ]);

    assertResolvedNodeText(findNode.binary('a !== b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: !==
  rightOperand: SimpleIdentifier
    token: b
    parameter: <null>
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: InvalidType
''');
  }

  test_eqEq_dynamic_int() async {
    await assertNoErrorsInCode(r'''
f(dynamic a) {
  a == 0;
}
''');

    var node = findNode.binary('a == 0');
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: dynamic
  operator: ==
  rightOperand: IntegerLiteral
    literal: 0
    parameter: dart:core::@class::Object::@method::==::@parameter::other
    staticType: int
  staticElement: dart:core::@class::Object::@method::==
  staticInvokeType: bool Function(Object)
  staticType: bool
''');
  }

  test_eqEq_extensionOverride_left() async {
    await assertErrorsInCode(r'''
extension E on int {}

void f(int a) {
  E(a) == 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR, 46, 2),
    ]);

    assertResolvedNodeText(findNode.binary('== 0'), r'''
BinaryExpression
  leftOperand: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: int
      rightParenthesis: )
    element: self::@extension::E
    extendedType: int
    staticType: null
  operator: ==
  rightOperand: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: bool
''');
  }

  test_eqEq_int_int() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a == b;
}
''');

    var node = findNode.binary('a == b');
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: ==
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::==::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: dart:core::@class::num::@method::==
  staticInvokeType: bool Function(Object)
  staticType: bool
''');
  }

  test_eqEq_invalidType_int() async {
    await assertErrorsInCode(r'''
void f(A a) {
  a == 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 7, 1),
    ]);

    var node = findNode.binary('a == 0');
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: InvalidType
  operator: ==
  rightOperand: IntegerLiteral
    literal: 0
    parameter: dart:core::@class::Object::@method::==::@parameter::other
    staticType: int
  staticElement: dart:core::@class::Object::@method::==
  staticInvokeType: bool Function(Object)
  staticType: bool
''');
  }

  test_eqEqEq() async {
    await assertErrorsInCode(r'''
f(int a, int b) {
  a === b;
}
''', [
      error(ScannerErrorCode.UNSUPPORTED_OPERATOR, 22, 1),
    ]);

    assertResolvedNodeText(findNode.binary('a === b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: ===
  rightOperand: SimpleIdentifier
    token: b
    parameter: <null>
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: InvalidType
''');
  }

  test_ifNull() async {
    await assertNoErrorsInCode('''
f(int? a, double b) {
  a ?? b;
}
''');

    assertResolvedNodeText(findNode.binary('a ?? b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int?
  operator: ??
  rightOperand: SimpleIdentifier
    token: b
    parameter: <null>
    staticElement: self::@function::f::@parameter::b
    staticType: double
  staticElement: <null>
  staticInvokeType: null
  staticType: num
''');
  }

  test_logicalAnd() async {
    await assertNoErrorsInCode(r'''
f(bool a, bool b) {
  a && b;
}
''');

    assertResolvedNodeText(findNode.binary('a && b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: bool
  operator: &&
  rightOperand: SimpleIdentifier
    token: b
    parameter: <null>
    staticElement: self::@function::f::@parameter::b
    staticType: bool
  staticElement: <null>
  staticInvokeType: null
  staticType: bool
''');
  }

  test_logicalOr() async {
    await assertNoErrorsInCode(r'''
f(bool a, bool b) {
  a || b;
}
''');

    assertResolvedNodeText(findNode.binary('a || b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: bool
  operator: ||
  rightOperand: SimpleIdentifier
    token: b
    parameter: <null>
    staticElement: self::@function::f::@parameter::b
    staticType: bool
  staticElement: <null>
  staticInvokeType: null
  staticType: bool
''');
  }

  test_minus_int_context_int() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a - f());
}
h(int x) {}
''');

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: dart:core::@class::num::@method::-::@parameter::other
  staticInvokeType: int Function()
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_minus_int_double() async {
    await assertNoErrorsInCode(r'''
f(int a, double b) {
  a - b;
}
''');

    assertResolvedNodeText(findNode.binary('a - b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: -
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::-::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: double
  staticElement: dart:core::@class::num::@method::-
  staticInvokeType: num Function(num)
  staticType: double
''');
  }

  test_minus_int_int() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a - b;
}
''');

    assertResolvedNodeText(findNode.binary('a - b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: -
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::-::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: dart:core::@class::num::@method::-
  staticInvokeType: num Function(num)
  staticType: int
''');
  }

  test_mod_int_context_int() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a % f());
}
h(int x) {}
''');

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: dart:core::@class::num::@method::%::@parameter::other
  staticInvokeType: int Function()
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_mod_int_double() async {
    await assertNoErrorsInCode(r'''
f(int a, double b) {
  a % b;
}
''');

    assertResolvedNodeText(findNode.binary('a % b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: %
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::%::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: double
  staticElement: dart:core::@class::num::@method::%
  staticInvokeType: num Function(num)
  staticType: double
''');
  }

  test_mod_int_int() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a % b;
}
''');

    assertResolvedNodeText(findNode.binary('a % b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: %
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::%::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: dart:core::@class::num::@method::%
  staticInvokeType: num Function(num)
  staticType: int
''');
  }

  test_plus_double_context_double() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(double a) {
  h(a + f());
}
h(double x) {}
''');

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: dart:core::@class::double::@method::+::@parameter::other
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_plus_double_context_int() async {
    await assertErrorsInCode('''
T f<T>() => throw Error();
g(double a) {
  h(a + f());
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 45, 7),
    ]);

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: dart:core::@class::double::@method::+::@parameter::other
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_plus_double_context_none() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(double a) {
  a + f();
}
''');

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: dart:core::@class::double::@method::+::@parameter::other
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_plus_double_dynamic() async {
    await assertNoErrorsInCode(r'''
f(double a, dynamic b) {
  a + b;
}
''');

    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: double
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::double::@method::+::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: dynamic
  staticElement: dart:core::@class::double::@method::+
  staticInvokeType: double Function(num)
  staticType: double
''');
  }

  test_plus_int_context_double() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a + f());
}
h(double x) {}
''');

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: dart:core::@class::num::@method::+::@parameter::other
  staticInvokeType: double Function()
  staticType: double
  typeArgumentTypes
    double
''');
  }

  test_plus_int_context_int() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a + f());
}
h(int x) {}
''');

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
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
''');
  }

  test_plus_int_context_int_target_rewritten() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int Function() a) {
  h(a() + f());
}
h(int x) {}
''');

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
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
''');
  }

  test_plus_int_context_int_via_extension_explicit() async {
    await assertErrorsInCode('''
extension E on int {
  String operator+(num x) => '';
}
T f<T>() => throw Error();
g(int a) {
  h(E(a) + f());
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 98, 10),
    ]);

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: self::@extension::E::@method::+::@parameter::x
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_plus_int_context_none() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  a + f();
}
''');

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: dart:core::@class::num::@method::+::@parameter::other
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_plus_int_double() async {
    await assertNoErrorsInCode(r'''
f(int a, double b) {
  a + b;
}
''');

    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: double
  staticElement: dart:core::@class::num::@method::+
  staticInvokeType: num Function(num)
  staticType: double
''');
  }

  test_plus_int_dynamic() async {
    await assertNoErrorsInCode(r'''
f(int a, dynamic b) {
  a + b;
}
''');

    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: dynamic
  staticElement: dart:core::@class::num::@method::+
  staticInvokeType: num Function(num)
  staticType: num
''');
  }

  test_plus_int_int() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a + b;
}
''');

    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
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
''');
  }

  test_plus_int_int_target_rewritten() async {
    await assertNoErrorsInCode('''
f(int Function() a, int b) {
  a() + b;
}
''');

    assertResolvedNodeText(findNode.binary('a() + b'), r'''
BinaryExpression
  leftOperand: FunctionExpressionInvocation
    function: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: int Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticElement: <null>
    staticInvokeType: int Function()
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
''');
  }

  test_plus_int_int_via_extension_explicit() async {
    await assertNoErrorsInCode('''
extension E on int {
  String operator+(int other) => '';
}
f(int a, int b) {
  E(a) + b;
}
''');

    assertResolvedNodeText(findNode.binary('E(a) + b'), r'''
BinaryExpression
  leftOperand: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: int
      rightParenthesis: )
    element: self::@extension::E
    extendedType: int
    staticType: null
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    parameter: self::@extension::E::@method::+::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: self::@extension::E::@method::+
  staticInvokeType: String Function(int)
  staticType: String
''');
  }

  test_plus_int_num() async {
    await assertNoErrorsInCode(r'''
f(int a, num b) {
  a + b;
}
''');

    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: num
  staticElement: dart:core::@class::num::@method::+
  staticInvokeType: num Function(num)
  staticType: num
''');
  }

  test_plus_invalidType_int() async {
    await assertErrorsInCode(r'''
void f() {
  x + 0;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 13, 1),
    ]);

    var node = findNode.binary('x + 0');
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
    staticElement: <null>
    staticType: InvalidType
  operator: +
  rightOperand: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: InvalidType
''');
  }

  test_plus_num_context_int() async {
    await assertErrorsInCode('''
T f<T>() => throw Error();
g(num a) {
  h(a + f());
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 42, 7),
    ]);

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: dart:core::@class::num::@method::+::@parameter::other
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_plus_other_context_int() async {
    await assertErrorsInCode('''
abstract class A {
  num operator+(String x);
}
T f<T>() => throw Error();
g(A a) {
  h(a + f());
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 88, 7),
    ]);

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: self::@class::A::@method::+::@parameter::x
  staticInvokeType: String Function()
  staticType: String
  typeArgumentTypes
    String
''');
  }

  test_plus_other_context_int_via_extension_explicit() async {
    await assertErrorsInCode('''
class A {}
extension E on A {
  String operator+(num x) => '';
}
T f<T>() => throw Error();
g(A a) {
  h(E(a) + f());
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 105, 10),
    ]);

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: self::@extension::E::@method::+::@parameter::x
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_plus_other_context_int_via_extension_implicit() async {
    await assertErrorsInCode('''
class A {}
extension E on A {
  String operator+(num x) => '';
}
T f<T>() => throw Error();
g(A a) {
  h(a + f());
}
h(int x) {}
''', [
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 105, 7),
    ]);

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: self::@extension::E::@method::+::@parameter::x
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_plus_other_double() async {
    await assertNoErrorsInCode('''
abstract class A {
  String operator+(double other);
}
f(A a, double b) {
  a + b;
}
''');

    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    parameter: self::@class::A::@method::+::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: double
  staticElement: self::@class::A::@method::+
  staticInvokeType: String Function(double)
  staticType: String
''');
  }

  test_plus_other_int_via_extension_explicit() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  String operator+(int other) => '';
}
f(A a, int b) {
  E(a) + b;
}
''');

    assertResolvedNodeText(findNode.binary('E(a) + b'), r'''
BinaryExpression
  leftOperand: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          parameter: <null>
          staticElement: self::@function::f::@parameter::a
          staticType: A
      rightParenthesis: )
    element: self::@extension::E
    extendedType: A
    staticType: null
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    parameter: self::@extension::E::@method::+::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: self::@extension::E::@method::+
  staticInvokeType: String Function(int)
  staticType: String
''');
  }

  test_plus_other_int_via_extension_implicit() async {
    await assertNoErrorsInCode('''
class A {}
extension E on A {
  String operator+(int other) => '';
}
f(A a, int b) {
  a + b;
}
''');

    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: A
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    parameter: self::@extension::E::@method::+::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: self::@extension::E::@method::+
  staticInvokeType: String Function(int)
  staticType: String
''');
  }

  test_receiverTypeParameter_bound_dynamic() async {
    await assertNoErrorsInCode(r'''
f<T extends dynamic>(T a) {
  a + 0;
}
''');

    assertResolvedNodeText(findNode.binary('a + 0'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: T
  operator: +
  rightOperand: IntegerLiteral
    literal: 0
    parameter: <null>
    staticType: int
  staticElement: <null>
  staticInvokeType: null
  staticType: dynamic
''');
  }

  test_receiverTypeParameter_bound_num() async {
    await assertNoErrorsInCode(r'''
f<T extends num>(T a) {
  a + 0;
}
''');

    assertResolvedNodeText(findNode.binary('a + 0'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: T
  operator: +
  rightOperand: IntegerLiteral
    literal: 0
    parameter: dart:core::@class::num::@method::+::@parameter::other
    staticType: int
  staticElement: dart:core::@class::num::@method::+
  staticInvokeType: num Function(num)
  staticType: num
''');
  }

  test_slash() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a / b;
}
''');

    assertResolvedNodeText(findNode.binary('a / b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: /
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::/::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: dart:core::@class::num::@method::/
  staticInvokeType: double Function(num)
  staticType: double
''');
  }

  test_star_int_context_int() async {
    await assertNoErrorsInCode('''
T f<T>() => throw Error();
g(int a) {
  h(a * f());
}
h(int x) {}
''');

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    staticElement: self::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  parameter: dart:core::@class::num::@method::*::@parameter::other
  staticInvokeType: int Function()
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_star_int_double() async {
    await assertNoErrorsInCode(r'''
f(int a, double b) {
  a * b;
}
''');

    assertResolvedNodeText(findNode.binary('a * b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: *
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::*::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: double
  staticElement: dart:core::@class::num::@method::*
  staticInvokeType: num Function(num)
  staticType: double
''');
  }

  test_star_int_int() async {
    await assertNoErrorsInCode(r'''
f(int a, int b) {
  a * b;
}
''');

    assertResolvedNodeText(findNode.binary('a * b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: int
  operator: *
  rightOperand: SimpleIdentifier
    token: b
    parameter: dart:core::@class::num::@method::*::@parameter::other
    staticElement: self::@function::f::@parameter::b
    staticType: int
  staticElement: dart:core::@class::num::@method::*
  staticInvokeType: num Function(num)
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
f(C1<int>? c1, C2<double> c2) {
  contextB1(c1 ?? c2);
}
''');

    assertResolvedNodeText(findNode.binary('c1 ?? c2'), r'''BinaryExpression
  leftOperand: SimpleIdentifier
    token: c1
    staticElement: self::@function::f::@parameter::c1
    staticType: C1<int>?
  operator: ??
  rightOperand: SimpleIdentifier
    token: c2
    parameter: <null>
    staticElement: self::@function::f::@parameter::c2
    staticType: C2<double>
  parameter: ParameterMember
    base: self::@function::contextB1::@parameter::b1
    substitution: {T: Object?}
  staticElement: <null>
  staticInvokeType: null
  staticType: B1<Object?>
''');
  }

  test_ifNull_contextNotUsedIfLhsDoesNotSatisfyContext() async {
    await assertNoErrorsInCode('''
class A {}
class B1 extends A {}
class B2 extends A {}
class C1 implements B1, B2 {}
class C2 implements B1, B2 {}
f(B2? b2, C1 c1, Object? o) {
  if (o is B1) {
    o = b2 ?? c1;
  }
}
''');

    assertResolvedNodeText(findNode.binary('b2 ?? c1'), r'''BinaryExpression
  leftOperand: SimpleIdentifier
    token: b2
    staticElement: self::@function::f::@parameter::b2
    staticType: B2?
  operator: ??
  rightOperand: SimpleIdentifier
    token: c1
    parameter: <null>
    staticElement: self::@function::f::@parameter::c1
    staticType: C1
  parameter: <null>
  staticElement: <null>
  staticInvokeType: null
  staticType: B2
''');
  }

  test_ifNull_contextNotUsedIfRhsDoesNotSatisfyContext() async {
    await assertNoErrorsInCode('''
class A {}
class B1 extends A {}
class B2 extends A {}
class C1 implements B1, B2 {}
class C2 implements B1, B2 {}
f(C1? c1, B2 b2, Object? o) {
  if (o is B1) {
    o = c1 ?? b2;
  }
}
''');

    assertResolvedNodeText(findNode.binary('c1 ?? b2'), r'''BinaryExpression
  leftOperand: SimpleIdentifier
    token: c1
    staticElement: self::@function::f::@parameter::c1
    staticType: C1?
  operator: ??
  rightOperand: SimpleIdentifier
    token: b2
    parameter: <null>
    staticElement: self::@function::f::@parameter::b2
    staticType: B2
  parameter: <null>
  staticElement: <null>
  staticInvokeType: null
  staticType: B2
''');
  }

  test_ifNull_contextUsedInsteadOfLubIfLubDoesNotSatisfyContext() async {
    await assertNoErrorsInCode('''
class A {}
class B1 extends A {}
class B2 extends A {}
class C1 implements B1, B2 {}
class C2 implements B1, B2 {}
B1 f(C1? c1, C2 c2) => c1 ?? c2;
''');

    assertResolvedNodeText(findNode.binary('c1 ?? c2'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: c1
    staticElement: self::@function::f::@parameter::c1
    staticType: C1?
  operator: ??
  rightOperand: SimpleIdentifier
    token: c2
    parameter: <null>
    staticElement: self::@function::f::@parameter::c2
    staticType: C2
  staticElement: <null>
  staticInvokeType: null
  staticType: B1
''');
  }
}
