// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PostfixPatternResolutionTest);
  });
}

@reflectiveTest
class PostfixPatternResolutionTest extends PubPackageResolutionTest {
  test_nullAssert_ifCase() async {
    await assertNoErrorsInCode(r'''
void f(int? x) {
  if (x case var y!) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
PostfixPattern
  operand: DeclaredVariablePattern
    keyword: var
    name: y
    declaredElement: hasImplicitType y@34
      type: int
  operator: !
''');
  }

  test_nullAssert_switchCase() async {
    await assertNoErrorsInCode(r'''
void f(int? x) {
  switch (x) {
    case var y!:
      break;
  }
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
PostfixPattern
  operand: DeclaredVariablePattern
    keyword: var
    name: y
    declaredElement: hasImplicitType y@45
      type: int
  operator: !
''');
  }

  test_nullAssert_variableDeclaration() async {
    await assertNoErrorsInCode(r'''
void f(int? x) {
  var (a!) = x;
}
''');
    final node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: PostfixPattern
      operand: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@24
          type: int
      operator: !
    rightParenthesis: )
  equals: =
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: int?
''');
  }

  test_nullCheck_ifCase() async {
    await assertNoErrorsInCode(r'''
void f(int? x) {
  if (x case var y?) {}
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
PostfixPattern
  operand: DeclaredVariablePattern
    keyword: var
    name: y
    declaredElement: hasImplicitType y@34
      type: int
  operator: ?
''');
  }

  test_nullCheck_switchCase() async {
    await assertNoErrorsInCode(r'''
void f(int? x) {
  switch (x) {
    case var y?:
      break;
  }
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
PostfixPattern
  operand: DeclaredVariablePattern
    keyword: var
    name: y
    declaredElement: hasImplicitType y@45
      type: int
  operator: ?
''');
  }

  /// TODO(scheglov) finish
  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/50066')
  test_nullCheck_variableDeclaration() async {
    await assertNoErrorsInCode(r'''
void f(int? x) {
  var (a?) = x;
}
''');
    final node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: ParenthesizedPattern
    leftParenthesis: (
    pattern: PostfixPattern
      operand: VariablePattern
        name: a
        declaredElement: hasImplicitType a@24
          type: int
      operator: !
    rightParenthesis: )
  equals: =
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: int?
''');
  }
}
