// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MapPatternResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MapPatternResolutionTest extends PubPackageResolutionTest {
  test_matchDynamic_noTypeArguments_variable_typed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  switch (x) {
    case {0: String a}:
//                  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
          element: dart:core::@class::String
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  switch (x) {
    case {0: var a}:
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  switch (x) {
    case <int, String>{0: var a}:
//                            ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
      NamedType
        name: String
        element: dart:core::@class::String
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Map<int, String> x) {
  if (x case {}) {}
//           ^^
// [diag.emptyMapPattern] A map pattern must have at least one entry.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  rightBracket: }
  matchedValueType: Map<int, String>
  requiredType: Map<int, String>
''');
  }

  test_matchMap_noTypeArguments_restElement_first() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Map<int, String> x) {
  if (x case {..., 0: ''}) {}
//            ^^^
// [diag.restElementInMapPattern] A map pattern can't contain a rest pattern.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Map<int, String> x) {
  if (x case {0: '', ...}) {}
//                   ^^^
// [diag.restElementInMapPattern] A map pattern can't contain a rest pattern.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Map<int, String> x) {
  if (x case {..., 0: '', ...}) {}
//            ^^^
// [diag.restElementInMapPattern] A map pattern can't contain a rest pattern.
//                        ^^^
// [diag.restElementInMapPattern] A map pattern can't contain a rest pattern.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Map<int, String> x) {
  if (x case {0: '', ...var rest}) {}
//                   ^^^^^^^^^^^
// [diag.restElementInMapPattern] A map pattern can't contain a rest pattern.
//                          ^^^^
// [diag.unusedLocalVariable] The value of the local variable 'rest' isn't used.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Map<int, String> x) {
  if (x case {0: var a}) {}
//                   ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Map<bool, num> x) {
  if (x case <bool, int>{true: var a}) {}
//                                 ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: bool
        element: dart:core::@class::bool
        type: bool
      NamedType
        name: int
        element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  if (x case {true: 0}) {}
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  if (x case {}) {}
//           ^^
// [diag.emptyMapPattern] A map pattern must have at least one entry.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  rightBracket: }
  matchedValueType: Object
  requiredType: Map<Object?, Object?>
''');
  }

  test_matchObject_noTypeArguments_variable_typed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  if (x case {true: int a}) {}
//                      ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
          element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  if (x case {true: var a}) {}
//                      ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  if (x case <bool, int>{true: 0}) {}
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: bool
        element: dart:core::@class::bool
        type: bool
      NamedType
        name: int
        element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  if (x case <bool, int>{true: var a}) {}
//                                 ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: bool
        element: dart:core::@class::bool
        type: bool
      NamedType
        name: int
        element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x, bool Function() a) {
  if (x case {a(): 0}) {}
//            ^^^
// [diag.nonConstantMapPatternKey] Key expressions in map patterns must be constants.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Map<bool, int> x) {
  var {true: a} = x;
//           ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var node = result.findNode.singlePatternVariableDeclaration;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var <bool, int>{true: a} = g();
//                      ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}

T g<T>() => throw 0;
''');
    var node = result.findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: MapPattern
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: bool
          element: dart:core::@class::bool
          type: bool
        NamedType
          name: int
          element: dart:core::@class::int
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var {true: int a} = g();
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}

T g<T>() => throw 0;
''');
    var node = result.findNode.singlePatternVariableDeclaration;
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
            element: dart:core::@class::int
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
