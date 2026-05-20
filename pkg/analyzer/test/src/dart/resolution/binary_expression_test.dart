// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    await resolveTestCodeWithDiagnostics(r'''
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
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
  operator: ==
  rightOperand: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@class::A::@method::==::@formalParameter::_
    staticType: int
  element: <testLibrary>::@class::A::@method::==
  staticInvokeType: MyBool Function(Object)
  staticType: bool
''');
  }

  test_eqEq_switchExpression_left() async {
    await resolveTestCodeWithDiagnostics(r'''
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
      element: <testLibrary>::@function::f::@formalParameter::x
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
    correspondingParameter: dart:core::@class::num::@method::==::@formalParameter::other
    staticType: int
  element: dart:core::@class::num::@method::==
  staticInvokeType: bool Function(Object)
  staticType: bool
''');
  }

  test_eqEq_switchExpression_right() async {
    await resolveTestCodeWithDiagnostics(r'''
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
      element: <testLibrary>::@function::f::@formalParameter::x
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
    correspondingParameter: dart:core::@class::num::@method::==::@formalParameter::other
    staticType: int
  element: dart:core::@class::num::@method::==
  staticInvokeType: bool Function(Object)
  staticType: bool
''');
  }

  test_expression_recordType_hasOperator() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: (String,)
  operator: +
  rightOperand: IntegerLiteral
    literal: 0
    correspondingParameter: <testLibrary>::@extension::#0::@method::+::@formalParameter::other
    staticType: int
  element: <testLibrary>::@extension::#0::@method::+
  staticInvokeType: int Function(int)
  staticType: int
''');
  }

  test_expression_recordType_noOperator() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((String,) a) {
  a + 0;
//  ^
// [diag.undefinedOperator] The operator '+' isn't defined for the type '(String,)'.
}
''');
    var node = findNode.binary('+ 0');
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: (String,)
  operator: +
  rightOperand: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  element: <null>
  staticInvokeType: null
  staticType: InvalidType
''');
  }

  test_gtGtGt() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
  operator: >>>
  rightOperand: IntegerLiteral
    literal: 3
    correspondingParameter: <testLibrary>::@class::A::@method::>>>::@formalParameter::amount
    staticType: int
  element: <testLibrary>::@class::A::@method::>>>
  staticInvokeType: A Function(int)
  staticType: A
''');
  }

  test_ifNull_left_nullableContext() async {
    await resolveTestCodeWithDiagnostics(r'''
T f<T>(T t) => t;

int g() => f(null) ?? 0;
''');

    assertResolvedNodeText(findNode.binary('?? 0'), r'''
BinaryExpression
  leftOperand: MethodInvocation
    methodName: SimpleIdentifier
      token: f
      element: <testLibrary>::@function::f
      staticType: T Function<T>(T)
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        NullLiteral
          literal: null
          correspondingParameter: ParameterMember
            baseElement: <testLibrary>::@function::f::@formalParameter::t
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
    correspondingParameter: <null>
    staticType: int
  element: <null>
  staticInvokeType: null
  staticType: int
''');
  }

  test_ifNull_lubUsedEvenIfItDoesNotSatisfyContext() async {
    await resolveTestCodeWithDiagnostics('''
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
    element: <testLibrary>::@function::f::@formalParameter::c1
    staticType: C1?
  operator: ??
  rightOperand: SimpleIdentifier
    token: c2
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c2
    staticType: C2
  correspondingParameter: <null>
  element: <null>
  staticInvokeType: null
  staticType: A
''');
  }

  test_ifNull_nullableInt_int() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? x, int y) {
  x ?? y;
}
''');

    assertResolvedNodeText(findNode.binary('x ?? y'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: int?
  operator: ??
  rightOperand: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: int
  element: <null>
  staticInvokeType: null
  staticType: int
''');
  }

  test_ifNull_nullableInt_nullableDouble() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? x, double? y) {
  x ?? y;
}
''');

    assertResolvedNodeText(findNode.binary('x ?? y'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: int?
  operator: ??
  rightOperand: SimpleIdentifier
    token: y
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::y
    staticType: double?
  element: <null>
  staticInvokeType: null
  staticType: num?
''');
  }

  test_ifNull_nullableInt_nullableInt() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int? x) {
  x ?? x;
}
''');

    assertResolvedNodeText(findNode.binary('x ?? x'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: int?
  operator: ??
  rightOperand: SimpleIdentifier
    token: x
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: int?
  element: <null>
  staticInvokeType: null
  staticType: int?
''');
  }

  test_plus_extensionType_int() async {
    await resolveTestCodeWithDiagnostics('''
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
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: Int
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: <testLibrary>::@extensionType::Int::@method::+::@formalParameter::other
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: int
  element: <testLibrary>::@extensionType::Int::@method::+
  staticInvokeType: Int Function(int)
  staticType: Int
''');
  }

  test_plus_int_never() async {
    await resolveTestCodeWithDiagnostics('''
f(int a, Never b) {
  a + b;
}
''');

    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: Never
  element: dart:core::@class::num::@method::+
  staticInvokeType: num Function(num)
  staticType: num
''');
  }

  test_plus_never_int() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Never a, int b) {
  a + b;
//^
// [diag.receiverOfTypeNever] The receiver is of type 'Never', and will never complete with a value.
//  ^^^
// [diag.deadCode] Dead code.
}
''');

    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: Never
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: int
  element: <null>
  staticInvokeType: null
  staticType: Never
''');
  }

  test_plus_switchExpression_left() async {
    await resolveTestCodeWithDiagnostics(r'''
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
      element: <testLibrary>::@function::f::@formalParameter::x
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
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  element: dart:core::@class::num::@method::+
  staticInvokeType: num Function(num)
  staticType: int
''');
  }

  test_plus_switchExpression_right() async {
    await resolveTestCodeWithDiagnostics(r'''
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
      element: <testLibrary>::@function::f::@formalParameter::x
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
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  element: dart:core::@class::num::@method::+
  staticInvokeType: num Function(num)
  staticType: int
''');
  }

  test_star_syntheticOperand_both() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  final v = * ;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
//          ^
// [diag.missingIdentifier] Expected an identifier.
//            ^
// [diag.missingIdentifier] Expected an identifier.
}
''');

    var node = findNode.singleBinaryExpression;
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
    element: <null>
    staticType: InvalidType
  operator: *
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
    correspondingParameter: <null>
    element: <null>
    staticType: InvalidType
  element: <null>
  staticInvokeType: null
  staticType: InvalidType
''');
  }

  test_star_syntheticOperand_left() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  final v = * 2;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
//          ^
// [diag.missingIdentifier] Expected an identifier.
}
''');

    var node = findNode.singleBinaryExpression;
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
    element: <null>
    staticType: InvalidType
  operator: *
  rightOperand: IntegerLiteral
    literal: 2
    correspondingParameter: <null>
    staticType: int
  element: <null>
  staticInvokeType: null
  staticType: InvalidType
''');
  }

  test_star_syntheticOperand_right() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  final v = 2 * ;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
//              ^
// [diag.missingIdentifier] Expected an identifier.
}
''');

    var node = findNode.singleBinaryExpression;
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: IntegerLiteral
    literal: 2
    staticType: int
  operator: *
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
    correspondingParameter: dart:core::@class::num::@method::*::@formalParameter::other
    element: <null>
    staticType: InvalidType
  element: dart:core::@class::num::@method::*
  staticInvokeType: num Function(num)
  staticType: double
''');
  }

  test_superQualifier_plus() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    correspondingParameter: <testLibrary>::@class::A::@method::+::@formalParameter::other
    staticType: int
  element: <testLibrary>::@class::A::@method::+
  staticInvokeType: int Function(int)
  staticType: int
''');
  }

  test_thisExpression_plus() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    correspondingParameter: <testLibrary>::@class::A::@method::+::@formalParameter::other
    staticType: int
  element: <testLibrary>::@class::A::@method::+
  staticInvokeType: int Function(int)
  staticType: int
''');
  }
}

mixin BinaryExpressionResolutionTestCases on PubPackageResolutionTest {
  test_bangEq() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int a, int b) {
  a != b;
}
''');

    assertResolvedNodeText(findNode.binary('a != b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: !=
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: dart:core::@class::num::@method::==::@formalParameter::other
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: int
  element: dart:core::@class::num::@method::==
  staticInvokeType: bool Function(Object)
  staticType: bool
''');
  }

  test_bangEq_extensionOverride_left() async {
    await assertErrorsInCode(
      r'''
extension E on int {}

void f(int a) {
  E(a) != 0;
}
''',
      [error(diag.undefinedExtensionOperator, 46, 2)],
    );

    assertResolvedNodeText(findNode.binary('!= 0'), r'''
BinaryExpression
  leftOperand: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
    staticType: null
  operator: !=
  rightOperand: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  element: <null>
  staticInvokeType: null
  staticType: InvalidType
''');
  }

  test_bangEqEq() async {
    await assertErrorsInCode(
      r'''
f(int a, int b) {
  a !== b;
}
''',
      [error(diag.unsupportedOperator, 22, 1)],
    );

    assertResolvedNodeText(findNode.binary('a !== b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: !==
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: int
  element: <null>
  staticInvokeType: null
  staticType: InvalidType
''');
  }

  test_eqEq_dynamic_int() async {
    await resolveTestCodeWithDiagnostics(r'''
f(dynamic a) {
  a == 0;
}
''');

    var node = findNode.binary('a == 0');
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: dynamic
  operator: ==
  rightOperand: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
    staticType: int
  element: dart:core::@class::Object::@method::==
  staticInvokeType: bool Function(Object)
  staticType: bool
''');
  }

  test_eqEq_extensionOverride_left() async {
    await assertErrorsInCode(
      r'''
extension E on int {}

void f(int a) {
  E(a) == 0;
}
''',
      [error(diag.undefinedExtensionOperator, 46, 2)],
    );

    assertResolvedNodeText(findNode.binary('== 0'), r'''
BinaryExpression
  leftOperand: ExtensionOverride
    name: E
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: a
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
    staticType: null
  operator: ==
  rightOperand: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  element: <null>
  staticInvokeType: null
  staticType: bool
''');
  }

  test_eqEq_int_int() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int a, int b) {
  a == b;
}
''');

    var node = findNode.binary('a == b');
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: ==
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: dart:core::@class::num::@method::==::@formalParameter::other
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: int
  element: dart:core::@class::num::@method::==
  staticInvokeType: bool Function(Object)
  staticType: bool
''');
  }

  test_eqEq_invalidType_int() async {
    await assertErrorsInCode(
      r'''
void f(A a) {
  a == 0;
}
''',
      [error(diag.undefinedClass, 7, 1)],
    );

    var node = findNode.binary('a == 0');
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: InvalidType
  operator: ==
  rightOperand: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::Object::@method::==::@formalParameter::other
    staticType: int
  element: dart:core::@class::Object::@method::==
  staticInvokeType: bool Function(Object)
  staticType: bool
''');
  }

  test_eqEqEq() async {
    await assertErrorsInCode(
      r'''
f(int a, int b) {
  a === b;
}
''',
      [error(diag.unsupportedOperator, 22, 1)],
    );

    assertResolvedNodeText(findNode.binary('a === b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: ===
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: int
  element: <null>
  staticInvokeType: null
  staticType: InvalidType
''');
  }

  test_ifNull() async {
    await resolveTestCodeWithDiagnostics('''
f(int? a, double b) {
  a ?? b;
}
''');

    assertResolvedNodeText(findNode.binary('a ?? b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int?
  operator: ??
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: double
  element: <null>
  staticInvokeType: null
  staticType: num
''');
  }

  test_logicalAnd() async {
    await resolveTestCodeWithDiagnostics(r'''
f(bool a, bool b) {
  a && b;
}
''');

    assertResolvedNodeText(findNode.binary('a && b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: bool
  operator: &&
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool
  element: <null>
  staticInvokeType: null
  staticType: bool
''');
  }

  test_logicalOr() async {
    await resolveTestCodeWithDiagnostics(r'''
f(bool a, bool b) {
  a || b;
}
''');

    assertResolvedNodeText(findNode.binary('a || b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: bool
  operator: ||
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: bool
  element: <null>
  staticInvokeType: null
  staticType: bool
''');
  }

  test_minus_int_context_int() async {
    await resolveTestCodeWithDiagnostics('''
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
    element: <testLibrary>::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: dart:core::@class::num::@method::-::@formalParameter::other
  staticInvokeType: int Function()
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_minus_int_double() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int a, double b) {
  a - b;
}
''');

    assertResolvedNodeText(findNode.binary('a - b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: -
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: dart:core::@class::num::@method::-::@formalParameter::other
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: double
  element: dart:core::@class::num::@method::-
  staticInvokeType: num Function(num)
  staticType: double
''');
  }

  test_minus_int_int() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int a, int b) {
  a - b;
}
''');

    assertResolvedNodeText(findNode.binary('a - b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: -
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: dart:core::@class::num::@method::-::@formalParameter::other
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: int
  element: dart:core::@class::num::@method::-
  staticInvokeType: num Function(num)
  staticType: int
''');
  }

  test_mod_int_context_int() async {
    await resolveTestCodeWithDiagnostics('''
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
    element: <testLibrary>::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: dart:core::@class::num::@method::%::@formalParameter::other
  staticInvokeType: int Function()
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_mod_int_double() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int a, double b) {
  a % b;
}
''');

    assertResolvedNodeText(findNode.binary('a % b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: %
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: dart:core::@class::num::@method::%::@formalParameter::other
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: double
  element: dart:core::@class::num::@method::%
  staticInvokeType: num Function(num)
  staticType: double
''');
  }

  test_mod_int_int() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int a, int b) {
  a % b;
}
''');

    assertResolvedNodeText(findNode.binary('a % b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: %
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: dart:core::@class::num::@method::%::@formalParameter::other
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: int
  element: dart:core::@class::num::@method::%
  staticInvokeType: num Function(num)
  staticType: int
''');
  }

  test_plus_double_context_double() async {
    await resolveTestCodeWithDiagnostics('''
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
    element: <testLibrary>::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: dart:core::@class::double::@method::+::@formalParameter::other
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_plus_double_context_int() async {
    await resolveTestCodeWithDiagnostics('''
T f<T>() => throw Error();
g(double a) {
  h(a + f());
//  ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'double' can't be assigned to the parameter type 'int'.
}
h(int x) {}
''');
    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: dart:core::@class::double::@method::+::@formalParameter::other
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_plus_double_context_none() async {
    await resolveTestCodeWithDiagnostics('''
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
    element: <testLibrary>::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: dart:core::@class::double::@method::+::@formalParameter::other
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_plus_double_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
f(double a, dynamic b) {
  a + b;
}
''');
    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: double
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: dart:core::@class::double::@method::+::@formalParameter::other
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: dynamic
  element: dart:core::@class::double::@method::+
  staticInvokeType: double Function(num)
  staticType: double
''');
  }

  test_plus_int_context_double() async {
    await resolveTestCodeWithDiagnostics('''
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
    element: <testLibrary>::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
  staticInvokeType: double Function()
  staticType: double
  typeArgumentTypes
    double
''');
  }

  test_plus_int_context_int() async {
    await resolveTestCodeWithDiagnostics('''
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
''');
  }

  test_plus_int_context_int_target_rewritten() async {
    await resolveTestCodeWithDiagnostics('''
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
''');
  }

  test_plus_int_context_int_via_extension_explicit() async {
    await resolveTestCodeWithDiagnostics('''
extension E on int {
  String operator+(num x) => '';
}
T f<T>() => throw Error();
g(int a) {
  h(E(a) + f());
//  ^^^^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
}
h(int x) {}
''');
    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: <testLibrary>::@extension::E::@method::+::@formalParameter::x
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_plus_int_context_none() async {
    await resolveTestCodeWithDiagnostics('''
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
    element: <testLibrary>::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_plus_int_double() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int a, double b) {
  a + b;
}
''');
    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: double
  element: dart:core::@class::num::@method::+
  staticInvokeType: num Function(num)
  staticType: double
''');
  }

  test_plus_int_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int a, dynamic b) {
  a + b;
}
''');
    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: dynamic
  element: dart:core::@class::num::@method::+
  staticInvokeType: num Function(num)
  staticType: num
''');
  }

  test_plus_int_int() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int a, int b) {
  a + b;
}
''');
    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
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
''');
  }

  test_plus_int_int_target_rewritten() async {
    await resolveTestCodeWithDiagnostics('''
f(int Function() a, int b) {
  a() + b;
}
''');
    assertResolvedNodeText(findNode.binary('a() + b'), r'''
BinaryExpression
  leftOperand: FunctionExpressionInvocation
    function: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: int Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    element: <null>
    staticInvokeType: int Function()
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
''');
  }

  test_plus_int_int_via_extension_explicit() async {
    await resolveTestCodeWithDiagnostics('''
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
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: int
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: int
    staticType: null
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: <testLibrary>::@extension::E::@method::+::@formalParameter::other
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: int
  element: <testLibrary>::@extension::E::@method::+
  staticInvokeType: String Function(int)
  staticType: String
''');
  }

  test_plus_int_num() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int a, num b) {
  a + b;
}
''');
    assertResolvedNodeText(findNode.binary('a + b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: num
  element: dart:core::@class::num::@method::+
  staticInvokeType: num Function(num)
  staticType: num
''');
  }

  test_plus_int_typeVariable_via_extension() async {
    await resolveTestCodeWithDiagnostics('''
class Foo {}

extension FooExtension<F extends Foo> on F {
  F operator +(int i) => this;

  F get gg => this + 1;
}
''');
    assertResolvedNodeText(findNode.binary('this + 1'), r'''
BinaryExpression
  leftOperand: ThisExpression
    thisKeyword: this
    staticType: F
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
    correspondingParameter: i@null
    staticType: int
  element: MethodMember
    baseElement: <testLibrary>::@extension::FooExtension::@method::+
    substitution: {F: F}
  staticInvokeType: F Function(int)
  staticType: F
''');
  }

  test_plus_invalidType_int() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  x + 0;
//^
// [diag.undefinedIdentifier] Undefined name 'x'.
}
''');
    var node = findNode.binary('x + 0');
    assertResolvedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
    element: <null>
    staticType: InvalidType
  operator: +
  rightOperand: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  element: <null>
  staticInvokeType: null
  staticType: InvalidType
''');
  }

  test_plus_num_context_int() async {
    await resolveTestCodeWithDiagnostics('''
T f<T>() => throw Error();
g(num a) {
  h(a + f());
//  ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'num' can't be assigned to the parameter type 'int'.
}
h(int x) {}
''');

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_plus_other_context_int() async {
    await resolveTestCodeWithDiagnostics('''
abstract class A {
  num operator+(String x);
}
T f<T>() => throw Error();
g(A a) {
  h(a + f());
//  ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'num' can't be assigned to the parameter type 'int'.
}
h(int x) {}
''');

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: <testLibrary>::@class::A::@method::+::@formalParameter::x
  staticInvokeType: String Function()
  staticType: String
  typeArgumentTypes
    String
''');
  }

  test_plus_other_context_int_via_extension_explicit() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
extension E on A {
  String operator+(num x) => '';
}
T f<T>() => throw Error();
g(A a) {
  h(E(a) + f());
//  ^^^^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
}
h(int x) {}
''');

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: <testLibrary>::@extension::E::@method::+::@formalParameter::x
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_plus_other_context_int_via_extension_implicit() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
extension E on A {
  String operator+(num x) => '';
}
T f<T>() => throw Error();
g(A a) {
  h(a + f());
//  ^^^^^^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type 'int'.
}
h(int x) {}
''');

    var node = findNode.methodInvocation('f()');
    assertResolvedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
    element: <testLibrary>::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: <testLibrary>::@extension::E::@method::+::@formalParameter::x
  staticInvokeType: num Function()
  staticType: num
  typeArgumentTypes
    num
''');
  }

  test_plus_other_double() async {
    await resolveTestCodeWithDiagnostics('''
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
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: <testLibrary>::@class::A::@method::+::@formalParameter::other
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: double
  element: <testLibrary>::@class::A::@method::+
  staticInvokeType: String Function(double)
  staticType: String
''');
  }

  test_plus_other_int_via_extension_explicit() async {
    await resolveTestCodeWithDiagnostics('''
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
          correspondingParameter: <null>
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: A
      rightParenthesis: )
    element: <testLibrary>::@extension::E
    extendedType: A
    staticType: null
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: <testLibrary>::@extension::E::@method::+::@formalParameter::other
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: int
  element: <testLibrary>::@extension::E::@method::+
  staticInvokeType: String Function(int)
  staticType: String
''');
  }

  test_plus_other_int_via_extension_implicit() async {
    await resolveTestCodeWithDiagnostics('''
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
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
  operator: +
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: <testLibrary>::@extension::E::@method::+::@formalParameter::other
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: int
  element: <testLibrary>::@extension::E::@method::+
  staticInvokeType: String Function(int)
  staticType: String
''');
  }

  test_receiverTypeParameter_bound_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
f<T extends dynamic>(T a) {
  a + 0;
}
''');

    assertResolvedNodeText(findNode.binary('a + 0'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: T
  operator: +
  rightOperand: IntegerLiteral
    literal: 0
    correspondingParameter: <null>
    staticType: int
  element: <null>
  staticInvokeType: null
  staticType: dynamic
''');
  }

  test_receiverTypeParameter_bound_num() async {
    await resolveTestCodeWithDiagnostics(r'''
f<T extends num>(T a) {
  a + 0;
}
''');

    assertResolvedNodeText(findNode.binary('a + 0'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: T
  operator: +
  rightOperand: IntegerLiteral
    literal: 0
    correspondingParameter: dart:core::@class::num::@method::+::@formalParameter::other
    staticType: int
  element: dart:core::@class::num::@method::+
  staticInvokeType: num Function(num)
  staticType: num
''');
  }

  test_slash() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int a, int b) {
  a / b;
}
''');

    assertResolvedNodeText(findNode.binary('a / b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: /
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: dart:core::@class::num::@method::/::@formalParameter::other
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: int
  element: dart:core::@class::num::@method::/
  staticInvokeType: double Function(num)
  staticType: double
''');
  }

  test_star_int_context_int() async {
    await resolveTestCodeWithDiagnostics('''
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
    element: <testLibrary>::@function::f
    staticType: T Function<T>()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  correspondingParameter: dart:core::@class::num::@method::*::@formalParameter::other
  staticInvokeType: int Function()
  staticType: int
  typeArgumentTypes
    int
''');
  }

  test_star_int_double() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int a, double b) {
  a * b;
}
''');

    assertResolvedNodeText(findNode.binary('a * b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: *
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: dart:core::@class::num::@method::*::@formalParameter::other
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: double
  element: dart:core::@class::num::@method::*
  staticInvokeType: num Function(num)
  staticType: double
''');
  }

  test_star_int_int() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int a, int b) {
  a * b;
}
''');

    assertResolvedNodeText(findNode.binary('a * b'), r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: int
  operator: *
  rightOperand: SimpleIdentifier
    token: b
    correspondingParameter: dart:core::@class::num::@method::*::@formalParameter::other
    element: <testLibrary>::@function::f::@formalParameter::b
    staticType: int
  element: dart:core::@class::num::@method::*
  staticInvokeType: num Function(num)
  staticType: int
''');
  }
}

@reflectiveTest
class InferenceUpdate3Test extends PubPackageResolutionTest {
  test_ifNull_contextIsConvertedToATypeUsingGreatestClosure() async {
    await resolveTestCodeWithDiagnostics('''
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
    element: <testLibrary>::@function::f::@formalParameter::c1
    staticType: C1<int>?
  operator: ??
  rightOperand: SimpleIdentifier
    token: c2
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c2
    staticType: C2<double>
  correspondingParameter: ParameterMember
    baseElement: <testLibrary>::@function::contextB1::@formalParameter::b1
    substitution: {T: Object?}
  element: <null>
  staticInvokeType: null
  staticType: B1<Object?>
''');
  }

  test_ifNull_contextNotUsedIfLhsDoesNotSatisfyContext() async {
    await resolveTestCodeWithDiagnostics('''
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
    element: <testLibrary>::@function::f::@formalParameter::b2
    staticType: B2?
  operator: ??
  rightOperand: SimpleIdentifier
    token: c1
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c1
    staticType: C1
  correspondingParameter: <null>
  element: <null>
  staticInvokeType: null
  staticType: B2
''');
  }

  test_ifNull_contextNotUsedIfRhsDoesNotSatisfyContext() async {
    await resolveTestCodeWithDiagnostics('''
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
    element: <testLibrary>::@function::f::@formalParameter::c1
    staticType: C1?
  operator: ??
  rightOperand: SimpleIdentifier
    token: b2
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::b2
    staticType: B2
  correspondingParameter: <null>
  element: <null>
  staticInvokeType: null
  staticType: B2
''');
  }

  test_ifNull_contextUsedInsteadOfLubIfLubDoesNotSatisfyContext() async {
    await resolveTestCodeWithDiagnostics('''
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
    element: <testLibrary>::@function::f::@formalParameter::c1
    staticType: C1?
  operator: ??
  rightOperand: SimpleIdentifier
    token: c2
    correspondingParameter: <null>
    element: <testLibrary>::@function::f::@formalParameter::c2
    staticType: C2
  element: <null>
  staticInvokeType: null
  staticType: B1
''');
  }
}
