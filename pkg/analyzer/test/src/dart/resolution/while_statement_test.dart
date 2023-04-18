// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WhileStatementResolutionTest);
  });
}

@reflectiveTest
class WhileStatementResolutionTest extends PubPackageResolutionTest {
  test_break() async {
    await assertNoErrorsInCode('''
void f() {
  while (true) {
    break;
  }
}
''');

    final node = findNode.singleWhileStatement;
    assertResolvedNodeText(node, r'''
WhileStatement
  whileKeyword: while
  leftParenthesis: (
  condition: BooleanLiteral
    literal: true
    staticType: bool
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      BreakStatement
        breakKeyword: break
        semicolon: ;
    rightBracket: }
''');
  }

  test_break_label() async {
    await assertNoErrorsInCode('''
void f() {
  L: while (true) {
    break L;
  }
}
''');

    final node = findNode.singleLabeledStatement;
    assertResolvedNodeText(node, r'''
LabeledStatement
  labels
    Label
      label: SimpleIdentifier
        token: L
        staticElement: L@13
        staticType: null
      colon: :
  statement: WhileStatement
    whileKeyword: while
    leftParenthesis: (
    condition: BooleanLiteral
      literal: true
      staticType: bool
    rightParenthesis: )
    body: Block
      leftBracket: {
      statements
        BreakStatement
          breakKeyword: break
          label: SimpleIdentifier
            token: L
            staticElement: L@13
            staticType: null
          semicolon: ;
      rightBracket: }
''');
  }

  test_break_label_unresolved() async {
    await assertErrorsInCode('''
void f() {
  while (true) {
    break L;
  }
}
''', [
      error(CompileTimeErrorCode.LABEL_UNDEFINED, 38, 1),
    ]);

    final node = findNode.singleWhileStatement;
    assertResolvedNodeText(node, r'''
WhileStatement
  whileKeyword: while
  leftParenthesis: (
  condition: BooleanLiteral
    literal: true
    staticType: bool
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      BreakStatement
        breakKeyword: break
        label: SimpleIdentifier
          token: L
          staticElement: <null>
          staticType: null
        semicolon: ;
    rightBracket: }
''');
  }

  test_condition_super() async {
    await assertErrorsInCode('''
class A {
  void f() {
    while (super) {}
  }
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 34, 5),
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 34, 5),
    ]);

    final node = findNode.singleWhileStatement;
    assertResolvedNodeText(node, r'''
WhileStatement
  whileKeyword: while
  leftParenthesis: (
  condition: SuperExpression
    superKeyword: super
    staticType: A
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_continue() async {
    await assertNoErrorsInCode('''
void f() {
  while (true) {
    continue;
  }
}
''');

    final node = findNode.singleWhileStatement;
    assertResolvedNodeText(node, r'''
WhileStatement
  whileKeyword: while
  leftParenthesis: (
  condition: BooleanLiteral
    literal: true
    staticType: bool
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ContinueStatement
        continueKeyword: continue
        semicolon: ;
    rightBracket: }
''');
  }

  test_continue_label() async {
    await assertNoErrorsInCode('''
void f() {
  L: while (true) {
    continue L;
  }
}
''');

    final node = findNode.singleLabeledStatement;
    assertResolvedNodeText(node, r'''
LabeledStatement
  labels
    Label
      label: SimpleIdentifier
        token: L
        staticElement: L@13
        staticType: null
      colon: :
  statement: WhileStatement
    whileKeyword: while
    leftParenthesis: (
    condition: BooleanLiteral
      literal: true
      staticType: bool
    rightParenthesis: )
    body: Block
      leftBracket: {
      statements
        ContinueStatement
          continueKeyword: continue
          label: SimpleIdentifier
            token: L
            staticElement: L@13
            staticType: null
          semicolon: ;
      rightBracket: }
''');
  }

  test_continue_label_unresolved() async {
    await assertErrorsInCode('''
void f() {
  while (true) {
    continue L;
  }
}
''', [
      error(CompileTimeErrorCode.LABEL_UNDEFINED, 41, 1),
    ]);

    final node = findNode.singleWhileStatement;
    assertResolvedNodeText(node, r'''
WhileStatement
  whileKeyword: while
  leftParenthesis: (
  condition: BooleanLiteral
    literal: true
    staticType: bool
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ContinueStatement
        continueKeyword: continue
        label: SimpleIdentifier
          token: L
          staticElement: <null>
          staticType: null
        semicolon: ;
    rightBracket: }
''');
  }
}
