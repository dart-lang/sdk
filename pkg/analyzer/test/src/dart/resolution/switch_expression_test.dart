// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SwitchExpressionResolutionTest);
  });
}

@reflectiveTest
class SwitchExpressionResolutionTest extends PubPackageResolutionTest {
  test_contextType_case_expression() async {
    await assertNoErrorsInCode(r'''
class A {
  T foo<T>() => throw 0;

  int bar(Object? x) {
    return switch (x) {
      _ => foo(),
    };
  }
}
''');

    final node = findNode.switchExpression('switch');
    assertResolvedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: self::@class::A::@method::bar::@parameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  cases
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          name: _
      arrow: =>
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: foo
          staticElement: self::@class::A::@method::foo
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: int Function()
        staticType: int
        typeArgumentTypes
          int
  rightBracket: }
  staticType: int
''');
  }

  test_rewrite_case_expression() async {
    await assertNoErrorsInCode(r'''
void f(Object? x, int Function() a) {
  (switch (x) {
    _ => a(),
  });
}
''');

    final node = findNode.switchExpressionCase('_');
    assertResolvedNodeText(node, r'''
SwitchExpressionCase
  guardedPattern: GuardedPattern
    pattern: DeclaredVariablePattern
      name: _
  arrow: =>
  expression: FunctionExpressionInvocation
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
''');
  }

  test_rewrite_case_pattern() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  (switch (x) {
    const A() => 0,
    _ => 1,
  });
}

class A {
  const A();
}
''');

    final node = findNode.switchExpressionCase('=> 0');
    assertResolvedNodeText(node, r'''
SwitchExpressionCase
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      const: const
      expression: InstanceCreationExpression
        constructorName: ConstructorName
          type: NamedType
            name: SimpleIdentifier
              token: A
              staticElement: self::@class::A
              staticType: null
            type: A
          staticElement: self::@class::A::@constructor::new
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticType: A
  arrow: =>
  expression: IntegerLiteral
    literal: 0
    staticType: int
''');
  }

  test_rewrite_case_whenClause() async {
    await assertNoErrorsInCode(r'''
void f(Object? x, bool Function() a) {
  (switch (x) {
    0 when a() => true,
    _ => false,
  });
}
''');

    final node = findNode.switchExpressionCase('=> true');
    assertResolvedNodeText(node, r'''
SwitchExpressionCase
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 0
        staticType: int
    whenClause: WhenClause
      whenKeyword: when
      expression: FunctionExpressionInvocation
        function: SimpleIdentifier
          token: a
          staticElement: self::@function::f::@parameter::a
          staticType: bool Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticElement: <null>
        staticInvokeType: bool Function()
        staticType: bool
  arrow: =>
  expression: BooleanLiteral
    literal: true
    staticType: bool
''');
  }

  test_rewrite_expression() async {
    await assertNoErrorsInCode(r'''
void f(int Function() a) {
  (switch (a()) {
    _ => 0,
  });
}
''');

    final node = findNode.switchExpression('switch');
    assertResolvedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: FunctionExpressionInvocation
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
  rightParenthesis: )
  leftBracket: {
  cases
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          name: _
      arrow: =>
      expression: IntegerLiteral
        literal: 0
        staticType: int
  rightBracket: }
  staticType: int
''');
  }

  test_staticType_cases_leastUpperBound() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  (switch (x) {
    true => 0,
    _ => null,
  });
}
''');

    final node = findNode.switchExpression('switch');
    assertResolvedNodeText(node, r'''
SwitchExpression
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
        pattern: ConstantPattern
          expression: BooleanLiteral
            literal: true
            staticType: bool
      arrow: =>
      expression: IntegerLiteral
        literal: 0
        staticType: int
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          name: _
      arrow: =>
      expression: NullLiteral
        literal: null
        staticType: Null
  rightBracket: }
  staticType: int?
''');
  }

  test_staticType_cases_same() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  (switch (x) {
    true => 0,
    _ => 1,
  });
}
''');

    final node = findNode.switchExpression('switch');
    assertResolvedNodeText(node, r'''
SwitchExpression
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
        pattern: ConstantPattern
          expression: BooleanLiteral
            literal: true
            staticType: bool
      arrow: =>
      expression: IntegerLiteral
        literal: 0
        staticType: int
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          name: _
      arrow: =>
      expression: IntegerLiteral
        literal: 1
        staticType: int
  rightBracket: }
  staticType: int
''');
  }

  test_variables_logicalOr() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  (switch (x) {
    <int>[var a || var a] => a,
    _ => 0,
  });
}
''');

    final node = findNode.switchExpression('switch');
    assertResolvedNodeText(node, r'''
SwitchExpression
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
        pattern: ListPattern
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: SimpleIdentifier
                  token: int
                  staticElement: dart:core::@class::int
                  staticType: null
                type: int
            rightBracket: >
          leftBracket: [
          elements
            BinaryPattern
              leftOperand: DeclaredVariablePattern
                keyword: var
                name: a
                declaredElement: hasImplicitType a@50
                  type: int
              operator: ||
              rightOperand: DeclaredVariablePattern
                keyword: var
                name: a
                declaredElement: hasImplicitType a@59
                  type: int
          rightBracket: ]
          requiredType: List<int>
      arrow: =>
      expression: SimpleIdentifier
        token: a
        staticElement: a[a@50, a@59]
        staticType: int
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          name: _
      arrow: =>
      expression: IntegerLiteral
        literal: 0
        staticType: int
  rightBracket: }
  staticType: int
''');
  }

  test_variables_scope() async {
    await assertErrorsInCode(r'''
const a = 0;
void f(Object? x) {
  (switch (x) {
    [int a, == a] when a > 0 => a,
    _ => 0,
  });
}
''', [
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 64, 1,
          contextMessages: [message('/home/test/lib/test.dart', 58, 1)]),
    ]);

    final node = findNode.switchExpression('switch');
    assertResolvedNodeText(node, r'''
SwitchExpression
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
        pattern: ListPattern
          leftBracket: [
          elements
            DeclaredVariablePattern
              type: NamedType
                name: SimpleIdentifier
                  token: int
                  staticElement: dart:core::@class::int
                  staticType: null
                type: int
              name: a
              declaredElement: a@58
                type: int
            RelationalPattern
              operator: ==
              operand: SimpleIdentifier
                token: a
                staticElement: a@58
                staticType: int
              element: dart:core::@class::Object::@method::==
          rightBracket: ]
          requiredType: List<Object?>
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              staticElement: a@58
              staticType: int
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              parameter: dart:core::@class::num::@method::>::@parameter::other
              staticType: int
            staticElement: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      arrow: =>
      expression: SimpleIdentifier
        token: a
        staticElement: a@58
        staticType: int
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          name: _
      arrow: =>
      expression: IntegerLiteral
        literal: 0
        staticType: int
  rightBracket: }
  staticType: int
''');
  }

  test_variables_singleCase() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  (switch (x) {
    int a when a > 0 => a,
    _ => a,
  });
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 72, 1),
    ]);

    final node = findNode.switchExpression('switch');
    assertResolvedNodeText(node, r'''
SwitchExpression
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
        pattern: DeclaredVariablePattern
          type: NamedType
            name: SimpleIdentifier
              token: int
              staticElement: dart:core::@class::int
              staticType: null
            type: int
          name: a
          declaredElement: a@44
            type: int
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              staticElement: a@44
              staticType: int
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              parameter: dart:core::@class::num::@method::>::@parameter::other
              staticType: int
            staticElement: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      arrow: =>
      expression: SimpleIdentifier
        token: a
        staticElement: a@44
        staticType: int
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          name: _
      arrow: =>
      expression: SimpleIdentifier
        token: a
        staticElement: <null>
        staticType: dynamic
  rightBracket: }
  staticType: dynamic
''');
  }
}
