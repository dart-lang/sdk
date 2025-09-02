// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SwitchExpressionResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SwitchExpressionResolutionTest extends PubPackageResolutionTest {
  test_case_expression_void() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  (switch(x) {
    0 => 0,
    _ => g(),
  });
}

void g() {}
''');

    var node = findNode.singleSwitchExpression;
    assertResolvedNodeText(node, r'''
SwitchExpression
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
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 0
            staticType: int
          matchedValueType: Object?
      arrow: =>
      expression: IntegerLiteral
        literal: 0
        staticType: int
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: WildcardPattern
          name: _
          matchedValueType: Object?
      arrow: =>
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: g
          element: <testLibrary>::@function::g
          staticType: void Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticInvokeType: void Function()
        staticType: void
  rightBracket: }
  staticType: void
''');
  }

  test_cases_empty() async {
    await assertErrorsInCode(
      r'''
final a = switch (0) {};
''',
      [error(CompileTimeErrorCode.nonExhaustiveSwitchExpression, 10, 6)],
    );

    var node = findNode.singleSwitchExpression;
    assertResolvedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: IntegerLiteral
    literal: 0
    staticType: int
  rightParenthesis: )
  leftBracket: {
  rightBracket: }
  staticType: Never
''');
  }

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

    var node = findNode.switchExpression('switch');
    assertResolvedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@class::A::@method::bar::@formalParameter::x
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
      expression: MethodInvocation
        methodName: SimpleIdentifier
          token: foo
          element: <testLibrary>::@class::A::@method::foo
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

  test_expression_void() async {
    await assertErrorsInCode(
      '''
void f(void x) {
  (switch(x) {
    _ => 0,
  });
}
''',
      [error(CompileTimeErrorCode.useOfVoidResult, 27, 1)],
    );

    var node = findNode.singleSwitchExpression;
    assertResolvedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: void
  rightParenthesis: )
  leftBracket: {
  cases
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: WildcardPattern
          name: _
          matchedValueType: void
      arrow: =>
      expression: IntegerLiteral
        literal: 0
        staticType: int
  rightBracket: }
  staticType: int
''');
  }

  test_joinedVariables_inLocalFunction() async {
    // Note: this is an important case to test because when variables are inside
    // a local function, their enclosing element is `null`.
    await assertNoErrorsInCode('''
abstract class C {
  List<int> get values;
}
abstract class D {
  List<int> get values;
}
test(Object o) => () =>
  switch (o) {
    C(:var values) || D(:var values) =>
      [for (var value in values) value + 1],
    _ => []
  };
''');

    var node = findNode.simple('value + 1');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: value
  element: value@185
  staticType: int
''');
  }

  test_location_topLevel() async {
    await assertNoErrorsInCode(r'''
num a = 0;

final b = switch (a) {
  int(:var isEven) when isEven => 1,
  _ => 0,
};
''');

    var node = findNode.singleSwitchExpression;
    assertResolvedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: a
    element: <testLibrary>::@getter::a
    staticType: num
  rightParenthesis: )
  leftBracket: {
  cases
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: ObjectPattern
          type: NamedType
            name: int
            element2: dart:core::@class::int
            type: int
          leftParenthesis: (
          fields
            PatternField
              name: PatternFieldName
                colon: :
              pattern: DeclaredVariablePattern
                keyword: var
                name: isEven
                declaredFragment: isPublic isEven@46
                  element: hasImplicitType isPublic
                    type: bool
                matchedValueType: bool
              element2: dart:core::@class::int::@getter::isEven
          rightParenthesis: )
          matchedValueType: num
        whenClause: WhenClause
          whenKeyword: when
          expression: SimpleIdentifier
            token: isEven
            element: isEven@46
            staticType: bool
      arrow: =>
      expression: IntegerLiteral
        literal: 1
        staticType: int
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: WildcardPattern
          name: _
          matchedValueType: num
      arrow: =>
      expression: IntegerLiteral
        literal: 0
        staticType: int
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

    var node = findNode.switchExpressionCase('_');
    assertResolvedNodeText(node, r'''
SwitchExpressionCase
  guardedPattern: GuardedPattern
    pattern: WildcardPattern
      name: _
      matchedValueType: Object?
  arrow: =>
  expression: FunctionExpressionInvocation
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

    var node = findNode.switchExpressionCase('=> 0');
    assertResolvedNodeText(node, r'''
SwitchExpressionCase
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      constKeyword: const
      expression: InstanceCreationExpression
        constructorName: ConstructorName
          type: NamedType
            name: A
            element2: <testLibrary>::@class::A
            type: A
          element: <testLibrary>::@class::A::@constructor::new
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticType: A
      matchedValueType: Object?
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

    var node = findNode.switchExpressionCase('=> true');
    assertResolvedNodeText(node, r'''
SwitchExpressionCase
  guardedPattern: GuardedPattern
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 0
        staticType: int
      matchedValueType: Object?
    whenClause: WhenClause
      whenKeyword: when
      expression: FunctionExpressionInvocation
        function: SimpleIdentifier
          token: a
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: bool Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        element: <null>
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

    var node = findNode.switchExpression('switch');
    assertResolvedNodeText(node, r'''
SwitchExpression
  switchKeyword: switch
  leftParenthesis: (
  expression: FunctionExpressionInvocation
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
  rightParenthesis: )
  leftBracket: {
  cases
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: WildcardPattern
          name: _
          matchedValueType: int
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

    var node = findNode.switchExpression('switch');
    assertResolvedNodeText(node, r'''
SwitchExpression
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
        pattern: ConstantPattern
          expression: BooleanLiteral
            literal: true
            staticType: bool
          matchedValueType: Object?
      arrow: =>
      expression: IntegerLiteral
        literal: 0
        staticType: int
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: WildcardPattern
          name: _
          matchedValueType: Object?
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

    var node = findNode.switchExpression('switch');
    assertResolvedNodeText(node, r'''
SwitchExpression
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
        pattern: ConstantPattern
          expression: BooleanLiteral
            literal: true
            staticType: bool
          matchedValueType: Object?
      arrow: =>
      expression: IntegerLiteral
        literal: 0
        staticType: int
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
''');
  }

  test_variables_logicalOr() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  (switch (x) {
    <int>[var a || var a] => a,
    _ => 0,
  });
}
''',
      [error(WarningCode.deadCode, 52, 8)],
    );

    var node = findNode.switchExpression('switch');
    assertResolvedNodeText(node, r'''
SwitchExpression
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
        pattern: ListPattern
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: int
                element2: dart:core::@class::int
                type: int
            rightBracket: >
          leftBracket: [
          elements
            LogicalOrPattern
              leftOperand: DeclaredVariablePattern
                keyword: var
                name: a
                declaredFragment: isPublic a@50
                  element: hasImplicitType isPublic
                    type: int
                matchedValueType: int
              operator: ||
              rightOperand: DeclaredVariablePattern
                keyword: var
                name: a
                declaredFragment: isPublic a@59
                  element: hasImplicitType isPublic
                    type: int
                matchedValueType: int
              matchedValueType: int
          rightBracket: ]
          matchedValueType: Object?
          requiredType: List<int>
      arrow: =>
      expression: SimpleIdentifier
        token: a
        element: a@null
        staticType: int
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: WildcardPattern
          name: _
          matchedValueType: Object?
      arrow: =>
      expression: IntegerLiteral
        literal: 0
        staticType: int
  rightBracket: }
  staticType: int
''');
  }

  test_variables_scope() async {
    await assertErrorsInCode(
      r'''
const a = 0;
void f(Object? x) {
  (switch (x) {
    [int a, == a] when a > 0 => a,
    _ => 0,
  });
}
''',
      [
        error(
          CompileTimeErrorCode.nonConstantRelationalPatternExpression,
          64,
          1,
        ),
        error(
          CompileTimeErrorCode.referencedBeforeDeclaration,
          64,
          1,
          contextMessages: [message(testFile, 58, 1)],
        ),
      ],
    );

    var node = findNode.switchExpression('switch');
    assertResolvedNodeText(node, r'''
SwitchExpression
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
        pattern: ListPattern
          leftBracket: [
          elements
            DeclaredVariablePattern
              type: NamedType
                name: int
                element2: dart:core::@class::int
                type: int
              name: a
              declaredFragment: isPublic a@58
                element: isPublic
                  type: int
              matchedValueType: Object?
            RelationalPattern
              operator: ==
              operand: SimpleIdentifier
                token: a
                element: a@58
                staticType: int
              element2: dart:core::@class::Object::@method::==
              matchedValueType: Object?
          rightBracket: ]
          matchedValueType: Object?
          requiredType: List<Object?>
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              element: a@58
              staticType: int
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
              staticType: int
            element: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      arrow: =>
      expression: SimpleIdentifier
        token: a
        element: a@58
        staticType: int
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: WildcardPattern
          name: _
          matchedValueType: Object?
      arrow: =>
      expression: IntegerLiteral
        literal: 0
        staticType: int
  rightBracket: }
  staticType: int
''');
  }

  test_variables_singleCase() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  (switch (x) {
    int a when a > 0 => a,
    _ => a,
  });
}
''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 72, 1)],
    );

    var node = findNode.switchExpression('switch');
    assertResolvedNodeText(node, r'''
SwitchExpression
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
        pattern: DeclaredVariablePattern
          type: NamedType
            name: int
            element2: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@44
            element: isPublic
              type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              element: a@44
              staticType: int
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
              staticType: int
            element: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      arrow: =>
      expression: SimpleIdentifier
        token: a
        element: a@44
        staticType: int
    SwitchExpressionCase
      guardedPattern: GuardedPattern
        pattern: WildcardPattern
          name: _
          matchedValueType: Object?
      arrow: =>
      expression: SimpleIdentifier
        token: a
        element: <null>
        staticType: InvalidType
  rightBracket: }
  staticType: InvalidType
''');
  }
}
