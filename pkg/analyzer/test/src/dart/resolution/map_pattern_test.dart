// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MapPatternResolutionTest);
  });
}

@reflectiveTest
class MapPatternResolutionTest extends PubPackageResolutionTest {
  test_matchDynamic_noTypeArguments_variable_typed() async {
    await assertErrorsInCode(
      r'''
void f(x) {
  switch (x) {
    case {0: String a}:
      break;
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 47, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: IntegerLiteral
        literal: 0
        staticType: int
      separator: :
      value: DeclaredVariablePattern
        type: NamedType
          name: String
          element2: dart:core::@class::String
          type: String
        name: a
        declaredFragment: isPublic a@47
          element: isPublic
            type: String
        matchedValueType: dynamic
  rightBracket: }
  matchedValueType: dynamic
  requiredType: Map<dynamic, dynamic>
''');
  }

  test_matchDynamic_noTypeArguments_variable_untyped() async {
    await assertErrorsInCode(
      r'''
void f(x) {
  switch (x) {
    case {0: var a}:
      break;
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 44, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: IntegerLiteral
        literal: 0
        staticType: int
      separator: :
      value: DeclaredVariablePattern
        keyword: var
        name: a
        declaredFragment: isPublic a@44
          element: hasImplicitType isPublic
            type: dynamic
        matchedValueType: dynamic
  rightBracket: }
  matchedValueType: dynamic
  requiredType: Map<dynamic, dynamic>
''');
  }

  test_matchDynamic_withTypeArguments_variable_untyped() async {
    await assertErrorsInCode(
      r'''
void f(x) {
  switch (x) {
    case <int, String>{0: var a}:
      break;
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 57, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
      NamedType
        name: String
        element2: dart:core::@class::String
        type: String
    rightBracket: >
  leftBracket: {
  elements
    MapPatternEntry
      key: IntegerLiteral
        literal: 0
        staticType: int
      separator: :
      value: DeclaredVariablePattern
        keyword: var
        name: a
        declaredFragment: isPublic a@57
          element: hasImplicitType isPublic
            type: String
        matchedValueType: String
  rightBracket: }
  matchedValueType: dynamic
  requiredType: Map<int, String>
''');
  }

  test_matchMap_noTypeArguments_empty() async {
    await assertErrorsInCode(
      r'''
void f(Map<int, String> x) {
  if (x case {}) {}
}
''',
      [error(CompileTimeErrorCode.emptyMapPattern, 42, 2)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  rightBracket: }
  matchedValueType: Map<int, String>
  requiredType: Map<int, String>
''');
  }

  test_matchMap_noTypeArguments_restElement_first() async {
    await assertErrorsInCode(
      r'''
void f(Map<int, String> x) {
  if (x case {..., 0: ''}) {}
}
''',
      [error(CompileTimeErrorCode.restElementInMapPattern, 43, 3)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    RestPatternElement
      operator: ...
    MapPatternEntry
      key: IntegerLiteral
        literal: 0
        staticType: int
      separator: :
      value: ConstantPattern
        expression: SimpleStringLiteral
          literal: ''
        matchedValueType: String
  rightBracket: }
  matchedValueType: Map<int, String>
  requiredType: Map<int, String>
''');
  }

  test_matchMap_noTypeArguments_restElement_last() async {
    await assertErrorsInCode(
      r'''
void f(Map<int, String> x) {
  if (x case {0: '', ...}) {}
}
''',
      [error(CompileTimeErrorCode.restElementInMapPattern, 50, 3)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: IntegerLiteral
        literal: 0
        staticType: int
      separator: :
      value: ConstantPattern
        expression: SimpleStringLiteral
          literal: ''
        matchedValueType: String
    RestPatternElement
      operator: ...
  rightBracket: }
  matchedValueType: Map<int, String>
  requiredType: Map<int, String>
''');
  }

  test_matchMap_noTypeArguments_restElement_multiple() async {
    await assertErrorsInCode(
      r'''
void f(Map<int, String> x) {
  if (x case {..., 0: '', ...}) {}
}
''',
      [
        error(CompileTimeErrorCode.restElementInMapPattern, 43, 3),
        error(CompileTimeErrorCode.restElementInMapPattern, 55, 3),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    RestPatternElement
      operator: ...
    MapPatternEntry
      key: IntegerLiteral
        literal: 0
        staticType: int
      separator: :
      value: ConstantPattern
        expression: SimpleStringLiteral
          literal: ''
        matchedValueType: String
    RestPatternElement
      operator: ...
  rightBracket: }
  matchedValueType: Map<int, String>
  requiredType: Map<int, String>
''');
  }

  test_matchMap_noTypeArguments_restElement_withPattern() async {
    await assertErrorsInCode(
      r'''
void f(Map<int, String> x) {
  if (x case {0: '', ...var rest}) {}
}
''',
      [
        error(CompileTimeErrorCode.restElementInMapPattern, 50, 11),
        error(WarningCode.unusedLocalVariable, 57, 4),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: IntegerLiteral
        literal: 0
        staticType: int
      separator: :
      value: ConstantPattern
        expression: SimpleStringLiteral
          literal: ''
        matchedValueType: String
    RestPatternElement
      operator: ...
      pattern: DeclaredVariablePattern
        keyword: var
        name: rest
        declaredFragment: isPublic rest@57
          element: hasImplicitType isPublic
            type: dynamic
        matchedValueType: dynamic
  rightBracket: }
  matchedValueType: Map<int, String>
  requiredType: Map<int, String>
''');
  }

  test_matchMap_noTypeArguments_variable_untyped() async {
    await assertErrorsInCode(
      r'''
void f(Map<int, String> x) {
  if (x case {0: var a}) {}
}
''',
      [error(WarningCode.unusedLocalVariable, 50, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: IntegerLiteral
        literal: 0
        staticType: int
      separator: :
      value: DeclaredVariablePattern
        keyword: var
        name: a
        declaredFragment: isPublic a@50
          element: hasImplicitType isPublic
            type: String
        matchedValueType: String
  rightBracket: }
  matchedValueType: Map<int, String>
  requiredType: Map<int, String>
''');
  }

  test_matchMap_withTypeArguments_variable_untyped() async {
    await assertErrorsInCode(
      r'''
void f(Map<bool, num> x) {
  if (x case <bool, int>{true: var a}) {}
}
''',
      [error(WarningCode.unusedLocalVariable, 62, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: bool
        element2: dart:core::@class::bool
        type: bool
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  leftBracket: {
  elements
    MapPatternEntry
      key: BooleanLiteral
        literal: true
        staticType: bool
      separator: :
      value: DeclaredVariablePattern
        keyword: var
        name: a
        declaredFragment: isPublic a@62
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
  rightBracket: }
  matchedValueType: Map<bool, num>
  requiredType: Map<bool, int>
''');
  }

  test_matchObject_noTypeArguments_constant() async {
    await assertNoErrorsInCode(r'''
void f(Object x) {
  if (x case {true: 0}) {}
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: BooleanLiteral
        literal: true
        staticType: bool
      separator: :
      value: ConstantPattern
        expression: IntegerLiteral
          literal: 0
          staticType: int
        matchedValueType: Object?
  rightBracket: }
  matchedValueType: Object
  requiredType: Map<Object?, Object?>
''');
  }

  test_matchObject_noTypeArguments_empty() async {
    await assertErrorsInCode(
      r'''
void f(Object x) {
  if (x case {}) {}
}
''',
      [error(CompileTimeErrorCode.emptyMapPattern, 32, 2)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  rightBracket: }
  matchedValueType: Object
  requiredType: Map<Object?, Object?>
''');
  }

  test_matchObject_noTypeArguments_variable_typed() async {
    await assertErrorsInCode(
      r'''
void f(Object x) {
  if (x case {true: int a}) {}
}
''',
      [error(WarningCode.unusedLocalVariable, 43, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: BooleanLiteral
        literal: true
        staticType: bool
      separator: :
      value: DeclaredVariablePattern
        type: NamedType
          name: int
          element2: dart:core::@class::int
          type: int
        name: a
        declaredFragment: isPublic a@43
          element: isPublic
            type: int
        matchedValueType: Object?
  rightBracket: }
  matchedValueType: Object
  requiredType: Map<Object?, Object?>
''');
  }

  test_matchObject_noTypeArguments_variable_untyped() async {
    await assertErrorsInCode(
      r'''
void f(Object x) {
  if (x case {true: var a}) {}
}
''',
      [error(WarningCode.unusedLocalVariable, 43, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: BooleanLiteral
        literal: true
        staticType: bool
      separator: :
      value: DeclaredVariablePattern
        keyword: var
        name: a
        declaredFragment: isPublic a@43
          element: hasImplicitType isPublic
            type: Object?
        matchedValueType: Object?
  rightBracket: }
  matchedValueType: Object
  requiredType: Map<Object?, Object?>
''');
  }

  test_matchObject_withTypeArguments_constant() async {
    await assertNoErrorsInCode(r'''
void f(Object x) {
  if (x case <bool, int>{true: 0}) {}
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: bool
        element2: dart:core::@class::bool
        type: bool
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  leftBracket: {
  elements
    MapPatternEntry
      key: BooleanLiteral
        literal: true
        staticType: bool
      separator: :
      value: ConstantPattern
        expression: IntegerLiteral
          literal: 0
          staticType: int
        matchedValueType: int
  rightBracket: }
  matchedValueType: Object
  requiredType: Map<bool, int>
''');
  }

  test_matchObject_withTypeArguments_variable_untyped() async {
    await assertErrorsInCode(
      r'''
void f(Object x) {
  if (x case <bool, int>{true: var a}) {}
}
''',
      [error(WarningCode.unusedLocalVariable, 54, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: bool
        element2: dart:core::@class::bool
        type: bool
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  leftBracket: {
  elements
    MapPatternEntry
      key: BooleanLiteral
        literal: true
        staticType: bool
      separator: :
      value: DeclaredVariablePattern
        keyword: var
        name: a
        declaredFragment: isPublic a@54
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
  rightBracket: }
  matchedValueType: Object
  requiredType: Map<bool, int>
''');
  }

  test_rewrite_key() async {
    await assertErrorsInCode(
      r'''
void f(x, bool Function() a) {
  if (x case {a(): 0}) {}
}
''',
      [error(CompileTimeErrorCode.nonConstantMapPatternKey, 45, 3)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: FunctionExpressionInvocation
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
      separator: :
      value: ConstantPattern
        expression: IntegerLiteral
          literal: 0
          staticType: int
        matchedValueType: dynamic
  rightBracket: }
  matchedValueType: dynamic
  requiredType: Map<dynamic, dynamic>
''');
  }

  test_variableDeclaration_inferredType() async {
    await assertErrorsInCode(
      r'''
void f(Map<bool, int> x) {
  var {true: a} = x;
}
''',
      [error(WarningCode.unusedLocalVariable, 40, 1)],
    );
    var node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: MapPattern
    leftBracket: {
    elements
      MapPatternEntry
        key: BooleanLiteral
          literal: true
          staticType: bool
        separator: :
        value: DeclaredVariablePattern
          name: a
          declaredFragment: isPublic a@40
            element: hasImplicitType isPublic
              type: int
          matchedValueType: int
    rightBracket: }
    matchedValueType: Map<bool, int>
    requiredType: Map<bool, int>
  equals: =
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Map<bool, int>
  patternTypeSchema: Map<_, _>
''');
  }

  test_variableDeclaration_typeSchema_withTypeArguments() async {
    await assertErrorsInCode(
      r'''
void f() {
  var <bool, int>{true: a} = g();
}

T g<T>() => throw 0;
''',
      [error(WarningCode.unusedLocalVariable, 35, 1)],
    );
    var node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: MapPattern
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: bool
          element2: dart:core::@class::bool
          type: bool
        NamedType
          name: int
          element2: dart:core::@class::int
          type: int
      rightBracket: >
    leftBracket: {
    elements
      MapPatternEntry
        key: BooleanLiteral
          literal: true
          staticType: bool
        separator: :
        value: DeclaredVariablePattern
          name: a
          declaredFragment: isPublic a@35
            element: hasImplicitType isPublic
              type: int
          matchedValueType: int
    rightBracket: }
    matchedValueType: Map<bool, int>
    requiredType: Map<bool, int>
  equals: =
  expression: MethodInvocation
    methodName: SimpleIdentifier
      token: g
      element: <testLibrary>::@function::g
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticInvokeType: Map<bool, int> Function()
    staticType: Map<bool, int>
    typeArgumentTypes
      Map<bool, int>
  patternTypeSchema: Map<bool, int>
''');
  }

  test_variableDeclaration_typeSchema_withVariableType() async {
    await assertErrorsInCode(
      r'''
void f() {
  var {true: int a} = g();
}

T g<T>() => throw 0;
''',
      [error(WarningCode.unusedLocalVariable, 28, 1)],
    );
    var node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: MapPattern
    leftBracket: {
    elements
      MapPatternEntry
        key: BooleanLiteral
          literal: true
          staticType: bool
        separator: :
        value: DeclaredVariablePattern
          type: NamedType
            name: int
            element2: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@28
            element: isPublic
              type: int
          matchedValueType: int
    rightBracket: }
    matchedValueType: Map<Object?, int>
    requiredType: Map<Object?, int>
  equals: =
  expression: MethodInvocation
    methodName: SimpleIdentifier
      token: g
      element: <testLibrary>::@function::g
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticInvokeType: Map<Object?, int> Function()
    staticType: Map<Object?, int>
    typeArgumentTypes
      Map<Object?, int>
  patternTypeSchema: Map<_, int>
''');
  }
}
