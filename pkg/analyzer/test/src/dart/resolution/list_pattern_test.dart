// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ListPatternResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ListPatternResolutionTest extends PubPackageResolutionTest {
  test_matchDynamic_noTypeArguments_variable_typed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  switch (x) {
    case [int a]:
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    DeclaredVariablePattern
      type: NamedType
        name: int
        element: dart:core::@class::int
        type: int
      name: a
      declaredFragment: isPublic a@41
        element: isPublic
          type: int
      matchedValueType: dynamic
  rightBracket: ]
  matchedValueType: dynamic
  requiredType: List<dynamic>
''');
  }

  test_matchDynamic_noTypeArguments_variable_untyped() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  switch (x) {
    case [var a]:
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    DeclaredVariablePattern
      keyword: var
      name: a
      declaredFragment: isPublic a@41
        element: hasImplicitType isPublic
          type: dynamic
      matchedValueType: dynamic
  rightBracket: ]
  matchedValueType: dynamic
  requiredType: List<dynamic>
''');
  }

  test_matchDynamic_withTypeArguments_variable_untyped() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  switch (x) {
    case <int>[var a]:
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  leftBracket: [
  elements
    DeclaredVariablePattern
      keyword: var
      name: a
      declaredFragment: isPublic a@46
        element: hasImplicitType isPublic
          type: int
      matchedValueType: int
  rightBracket: ]
  matchedValueType: dynamic
  requiredType: List<int>
''');
  }

  test_matchList_noTypeArguments_restElement_noPattern() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(List<int> x) {
  if (x case [0, ...]) {}
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    ConstantPattern
      expression: IntegerLiteral
        literal: 0
        staticType: int
      matchedValueType: int
    RestPatternElement
      operator: ...
  rightBracket: ]
  matchedValueType: List<int>
  requiredType: List<int>
''');
  }

  test_matchList_noTypeArguments_restElement_withPattern() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(List<int> x) {
  if (x case [0, ...var rest]) {}
//                      ^^^^
// [diag.unusedLocalVariable] The value of the local variable 'rest' isn't used.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    ConstantPattern
      expression: IntegerLiteral
        literal: 0
        staticType: int
      matchedValueType: int
    RestPatternElement
      operator: ...
      pattern: DeclaredVariablePattern
        keyword: var
        name: rest
        declaredFragment: isPublic rest@46
          element: hasImplicitType isPublic
            type: List<int>
        matchedValueType: List<int>
  rightBracket: ]
  matchedValueType: List<int>
  requiredType: List<int>
''');
  }

  test_matchList_noTypeArguments_variable_untyped() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(List<int> x) {
  switch (x) {
    case [var a]:
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    DeclaredVariablePattern
      keyword: var
      name: a
      declaredFragment: isPublic a@51
        element: hasImplicitType isPublic
          type: int
      matchedValueType: int
  rightBracket: ]
  matchedValueType: List<int>
  requiredType: List<int>
''');
  }

  test_matchList_withTypeArguments_variable_untyped() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(List<num> x) {
  switch (x) {
    case <int>[var a]:
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  leftBracket: [
  elements
    DeclaredVariablePattern
      keyword: var
      name: a
      declaredFragment: isPublic a@56
        element: hasImplicitType isPublic
          type: int
      matchedValueType: int
  rightBracket: ]
  matchedValueType: List<num>
  requiredType: List<int>
''');
  }

  test_matchObject_noTypeArguments_constant() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  switch (x) {
    case [0]:
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    ConstantPattern
      expression: IntegerLiteral
        literal: 0
        staticType: int
      matchedValueType: Object?
  rightBracket: ]
  matchedValueType: Object
  requiredType: List<Object?>
''');
  }

  test_matchObject_noTypeArguments_empty() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  switch (x) {
    case []:
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  leftBracket: [
  rightBracket: ]
  matchedValueType: Object
  requiredType: List<Object?>
''');
  }

  test_matchObject_noTypeArguments_variable_typed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  switch (x) {
    case [int a]:
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    DeclaredVariablePattern
      type: NamedType
        name: int
        element: dart:core::@class::int
        type: int
      name: a
      declaredFragment: isPublic a@48
        element: isPublic
          type: int
      matchedValueType: Object?
  rightBracket: ]
  matchedValueType: Object
  requiredType: List<Object?>
''');
  }

  test_matchObject_noTypeArguments_variable_untyped() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  switch (x) {
    case [var a]:
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    DeclaredVariablePattern
      keyword: var
      name: a
      declaredFragment: isPublic a@48
        element: hasImplicitType isPublic
          type: Object?
      matchedValueType: Object?
  rightBracket: ]
  matchedValueType: Object
  requiredType: List<Object?>
''');
  }

  test_matchObject_withTypeArguments_constant() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  switch (x) {
    case <int>[0]:
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  leftBracket: [
  elements
    ConstantPattern
      expression: IntegerLiteral
        literal: 0
        staticType: int
      matchedValueType: int
  rightBracket: ]
  matchedValueType: Object
  requiredType: List<int>
''');
  }

  test_matchObject_withTypeArguments_variable_typed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  switch (x) {
    case <num>[int a]:
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: num
        element: dart:core::@class::num
        type: num
    rightBracket: >
  leftBracket: [
  elements
    DeclaredVariablePattern
      type: NamedType
        name: int
        element: dart:core::@class::int
        type: int
      name: a
      declaredFragment: isPublic a@53
        element: isPublic
          type: int
      matchedValueType: num
  rightBracket: ]
  matchedValueType: Object
  requiredType: List<num>
''');
  }

  test_matchObject_withTypeArguments_variable_untyped() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object x) {
  switch (x) {
    case <int>[var a]:
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  leftBracket: [
  elements
    DeclaredVariablePattern
      keyword: var
      name: a
      declaredFragment: isPublic a@53
        element: hasImplicitType isPublic
          type: int
      matchedValueType: int
  rightBracket: ]
  matchedValueType: Object
  requiredType: List<int>
''');
  }

  test_variableDeclaration_inferredType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(List<int> x) {
  var [a] = x;
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
    var node = result.findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: ListPattern
    leftBracket: [
    elements
      DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@29
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
    rightBracket: ]
    matchedValueType: List<int>
    requiredType: List<int>
  equals: =
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: List<int>
  patternTypeSchema: List<_>
''');
  }

  test_variableDeclaration_typeSchema_withTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var <int>[a] = g();
//          ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}

T g<T>() => throw 0;
''');
    var node = result.findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: ListPattern
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    leftBracket: [
    elements
      DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@23
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
    rightBracket: ]
    matchedValueType: List<int>
    requiredType: List<int>
  equals: =
  expression: MethodInvocation
    methodName: SimpleIdentifier
      token: g
      element: <testLibrary>::@function::g
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticInvokeType: List<int> Function()
    staticType: List<int>
    typeArgumentTypes
      List<int>
  patternTypeSchema: List<int>
''');
  }

  test_variableDeclaration_typeSchema_withVariableType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var [int a] = g();
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}

T g<T>() => throw 0;
''');
    var node = result.findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: ListPattern
    leftBracket: [
    elements
      DeclaredVariablePattern
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: a
        declaredFragment: isPublic a@22
          element: isPublic
            type: int
        matchedValueType: int
    rightBracket: ]
    matchedValueType: List<int>
    requiredType: List<int>
  equals: =
  expression: MethodInvocation
    methodName: SimpleIdentifier
      token: g
      element: <testLibrary>::@function::g
      staticType: T Function<T>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticInvokeType: List<int> Function()
    staticType: List<int>
    typeArgumentTypes
      List<int>
  patternTypeSchema: List<int>
''');
  }
}
