// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ListPatternResolutionTest);
  });
}

@reflectiveTest
class ListPatternResolutionTest extends PatternsResolutionTest {
  test_matchDynamic_noTypeArguments_variable_typed() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case [int a]:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
      name: a
      declaredElement: a@41
        type: int
  rightBracket: ]
  requiredType: List<dynamic>
''');
  }

  test_matchDynamic_noTypeArguments_variable_untyped() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case [var a]:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    VariablePattern
      keyword: var
      name: a
      declaredElement: hasImplicitType a@41
        type: dynamic
  rightBracket: ]
  requiredType: List<dynamic>
''');
  }

  test_matchDynamic_withTypeArguments_variable_untyped() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case <int>[var a]:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ListPattern
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
    VariablePattern
      keyword: var
      name: a
      declaredElement: hasImplicitType a@46
        type: dynamic
  rightBracket: ]
  requiredType: List<int>
''');
  }

  test_matchList_noTypeArguments_variable_untyped() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x) {
  switch (x) {
    case [var a]:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    VariablePattern
      keyword: var
      name: a
      declaredElement: hasImplicitType a@51
        type: int
  rightBracket: ]
  requiredType: List<int>
''');
  }

  test_matchList_withTypeArguments_variable_untyped() async {
    await assertNoErrorsInCode(r'''
void f(List<num> x) {
  switch (x) {
    case <int>[var a]:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ListPattern
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
    VariablePattern
      keyword: var
      name: a
      declaredElement: hasImplicitType a@56
        type: num
  rightBracket: ]
  requiredType: List<int>
''');
  }

  test_matchObject_noTypeArguments_constant() async {
    await assertNoErrorsInCode(r'''
void f(Object x) {
  switch (x) {
    case [0]:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    ConstantPattern
      expression: IntegerLiteral
        literal: 0
        staticType: int
  rightBracket: ]
  requiredType: List<Object?>
''');
  }

  test_matchObject_noTypeArguments_empty() async {
    await assertNoErrorsInCode(r'''
void f(Object x) {
  switch (x) {
    case []:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  leftBracket: [
  rightBracket: ]
  requiredType: List<Object?>
''');
  }

  test_matchObject_noTypeArguments_variable_typed() async {
    await assertNoErrorsInCode(r'''
void f(Object x) {
  switch (x) {
    case [int a]:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
      name: a
      declaredElement: a@48
        type: int
  rightBracket: ]
  requiredType: List<Object?>
''');
  }

  test_matchObject_noTypeArguments_variable_untyped() async {
    await assertNoErrorsInCode(r'''
void f(Object x) {
  switch (x) {
    case [var a]:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    VariablePattern
      keyword: var
      name: a
      declaredElement: hasImplicitType a@48
        type: Object?
  rightBracket: ]
  requiredType: List<Object?>
''');
  }

  test_matchObject_withTypeArguments_constant() async {
    await assertNoErrorsInCode(r'''
void f(Object x) {
  switch (x) {
    case <int>[0]:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ListPattern
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
    ConstantPattern
      expression: IntegerLiteral
        literal: 0
        staticType: int
  rightBracket: ]
  requiredType: List<int>
''');
  }

  test_matchObject_withTypeArguments_variable_typed() async {
    await assertNoErrorsInCode(r'''
void f(Object x) {
  switch (x) {
    case <num>[int a]:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: SimpleIdentifier
          token: num
          staticElement: dart:core::@class::num
          staticType: null
        type: num
    rightBracket: >
  leftBracket: [
  elements
    VariablePattern
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
      name: a
      declaredElement: a@53
        type: int
  rightBracket: ]
  requiredType: List<num>
''');
  }

  test_matchObject_withTypeArguments_variable_untyped() async {
    await assertNoErrorsInCode(r'''
void f(Object x) {
  switch (x) {
    case <int>[var a]:
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ListPattern
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
    VariablePattern
      keyword: var
      name: a
      declaredElement: hasImplicitType a@53
        type: Object?
  rightBracket: ]
  requiredType: List<int>
''');
  }
}
