// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WhileStatementResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class WhileStatementResolutionTest extends PubPackageResolutionTest {
  test_break() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  while (true) {
    break;
  }
}
''');

    var node = result.findNode.singleWhileStatement;
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
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  L: while (true) {
    break L;
  }
}
''');

    var node = result.findNode.singleLabeledStatement;
    assertResolvedNodeText(node, r'''
LabeledStatement
  labels
    Label
      name: L
      colon: :
      declaredFragment: <testLibraryFragment> L@13
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
          label: LabelReference
            name: L
            element: L@13
          semicolon: ;
      rightBracket: }
''');
  }

  test_break_label_unresolved() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  while (true) {
    break L;
//        ^
// [diag.labelUndefined] Can't reference an undefined label 'L'.
  }
}
''');

    var node = result.findNode.singleWhileStatement;
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
        label: LabelReference
          name: L
          element: <null>
        semicolon: ;
    rightBracket: }
''');
  }

  test_condition_super() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  void f() {
    while (super) {}
//         ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
  }
}
''');

    var node = result.findNode.singleWhileStatement;
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
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  while (true) {
    continue;
  }
}
''');

    var node = result.findNode.singleWhileStatement;
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
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  L: while (true) {
    continue L;
  }
}
''');

    var node = result.findNode.singleLabeledStatement;
    assertResolvedNodeText(node, r'''
LabeledStatement
  labels
    Label
      name: L
      colon: :
      declaredFragment: <testLibraryFragment> L@13
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
          label: LabelReference
            name: L
            element: L@13
          semicolon: ;
      rightBracket: }
''');
  }

  test_continue_label_unresolved() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  while (true) {
    continue L;
//           ^
// [diag.labelUndefined] Can't reference an undefined label 'L'.
  }
}
''');

    var node = result.findNode.singleWhileStatement;
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
        label: LabelReference
          name: L
          element: <null>
        semicolon: ;
    rightBracket: }
''');
  }
}
