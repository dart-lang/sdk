// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/node_text_expectations.dart';
import '../src/diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecoveryParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

/// The class `RecoveryParserTest` defines parser tests that test the parsing of
/// invalid code sequences to ensure that the correct recovery steps are taken
/// in the parser.
@reflectiveTest
class RecoveryParserTest extends ParserDiagnosticsTest {
  void test_additiveExpression_missing_LHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = + y;
//      ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: +
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_additiveExpression_missing_LHS_RHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = +;
//      ^
// [diag.missingIdentifier] Expected an identifier.
//       ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: +
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_additiveExpression_missing_RHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = x +;
//         ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: +
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_additiveExpression_missing_RHS_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = super +;
//             ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SuperExpression
    superKeyword: super
  operator: +
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_additiveExpression_precedence_multiplicative_left() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = * +;
//      ^
// [diag.missingIdentifier] Expected an identifier.
//        ^
// [diag.missingIdentifier] Expected an identifier.
//         ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: <empty> <synthetic>
    operator: *
    rightOperand: SimpleIdentifier
      token: <empty> <synthetic>
  operator: +
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_additiveExpression_precedence_multiplicative_right() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = + *;
//      ^
// [diag.missingIdentifier] Expected an identifier.
//        ^
// [diag.missingIdentifier] Expected an identifier.
//         ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: +
  rightOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: <empty> <synthetic>
    operator: *
    rightOperand: SimpleIdentifier
      token: <empty> <synthetic>
''');
  }

  void test_additiveExpression_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = super + +;
//              ^
// [diag.missingIdentifier] Expected an identifier.
//               ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SuperExpression
      superKeyword: super
    operator: +
    rightOperand: SimpleIdentifier
      token: <empty> <synthetic>
  operator: +
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_assignableSelector() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = a.b[];
//          ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
IndexExpression
  target: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
    period: .
    identifier: SimpleIdentifier
      token: b
  leftBracket: [
  index: SimpleIdentifier
    token: <empty> <synthetic>
  rightBracket: ]
''');
  }

  void test_assignmentExpression_missing_compound1() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = = y = 0;
//      ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: <empty> <synthetic>
  operator: =
  rightHandSide: AssignmentExpression
    leftHandSide: SimpleIdentifier
      token: y
    operator: =
    rightHandSide: IntegerLiteral
      literal: 0
''');
  }

  void test_assignmentExpression_missing_compound2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = x = = 0;
//          ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
  operator: =
  rightHandSide: AssignmentExpression
    leftHandSide: SimpleIdentifier
      token: <empty> <synthetic>
    operator: =
    rightHandSide: IntegerLiteral
      literal: 0
''');
  }

  void test_assignmentExpression_missing_compound3() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = x = y =;
//             ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
  operator: =
  rightHandSide: AssignmentExpression
    leftHandSide: SimpleIdentifier
      token: y
    operator: =
    rightHandSide: SimpleIdentifier
      token: <empty> <synthetic>
''');
  }

  void test_assignmentExpression_missing_LHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = = 0;
//      ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: <empty> <synthetic>
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
''');
  }

  void test_assignmentExpression_missing_RHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = x =;
//         ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
  operator: =
  rightHandSide: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_bitwiseAndExpression_missing_LHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = & y;
//      ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: &
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_bitwiseAndExpression_missing_LHS_RHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = &;
//      ^
// [diag.missingIdentifier] Expected an identifier.
//       ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: &
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_bitwiseAndExpression_missing_RHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = x &;
//         ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: &
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_bitwiseAndExpression_missing_RHS_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = super &;
//             ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SuperExpression
    superKeyword: super
  operator: &
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_bitwiseAndExpression_precedence_equality_left() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = == &&;
//      ^^
// [diag.missingIdentifier] Expected an identifier.
//         ^^
// [diag.missingIdentifier] Expected an identifier.
//           ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: <empty> <synthetic>
    operator: ==
    rightOperand: SimpleIdentifier
      token: <empty> <synthetic>
  operator: &&
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_bitwiseAndExpression_precedence_equality_right() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = && ==;
//      ^^
// [diag.missingIdentifier] Expected an identifier.
//         ^^
// [diag.missingIdentifier] Expected an identifier.
//           ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: &&
  rightOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: <empty> <synthetic>
    operator: ==
    rightOperand: SimpleIdentifier
      token: <empty> <synthetic>
''');
  }

  void test_bitwiseAndExpression_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = super &  &;
//               ^
// [diag.missingIdentifier] Expected an identifier.
//                ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SuperExpression
      superKeyword: super
    operator: &
    rightOperand: SimpleIdentifier
      token: <empty> <synthetic>
  operator: &
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_bitwiseOrExpression_missing_LHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = | y;
//      ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: |
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_bitwiseOrExpression_missing_LHS_RHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = |;
//      ^
// [diag.missingIdentifier] Expected an identifier.
//       ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: |
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_bitwiseOrExpression_missing_RHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = x |;
//         ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: |
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_bitwiseOrExpression_missing_RHS_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = super |;
//             ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SuperExpression
    superKeyword: super
  operator: |
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_bitwiseOrExpression_precedence_xor_left() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = ^ |;
//      ^
// [diag.missingIdentifier] Expected an identifier.
//        ^
// [diag.missingIdentifier] Expected an identifier.
//         ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: <empty> <synthetic>
    operator: ^
    rightOperand: SimpleIdentifier
      token: <empty> <synthetic>
  operator: |
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_bitwiseOrExpression_precedence_xor_right() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = | ^;
//      ^
// [diag.missingIdentifier] Expected an identifier.
//        ^
// [diag.missingIdentifier] Expected an identifier.
//         ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: |
  rightOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: <empty> <synthetic>
    operator: ^
    rightOperand: SimpleIdentifier
      token: <empty> <synthetic>
''');
  }

  void test_bitwiseOrExpression_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = super |  |;
//               ^
// [diag.missingIdentifier] Expected an identifier.
//                ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SuperExpression
      superKeyword: super
    operator: |
    rightOperand: SimpleIdentifier
      token: <empty> <synthetic>
  operator: |
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_bitwiseXorExpression_missing_LHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = ^ y;
//      ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: ^
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_bitwiseXorExpression_missing_LHS_RHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = ^;
//      ^
// [diag.missingIdentifier] Expected an identifier.
//       ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: ^
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_bitwiseXorExpression_missing_RHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = x ^;
//         ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: ^
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_bitwiseXorExpression_missing_RHS_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = super ^;
//             ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SuperExpression
    superKeyword: super
  operator: ^
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_bitwiseXorExpression_precedence_and_left() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = & ^;
//      ^
// [diag.missingIdentifier] Expected an identifier.
//        ^
// [diag.missingIdentifier] Expected an identifier.
//         ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: <empty> <synthetic>
    operator: &
    rightOperand: SimpleIdentifier
      token: <empty> <synthetic>
  operator: ^
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_bitwiseXorExpression_precedence_and_right() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = ^ &;
//      ^
// [diag.missingIdentifier] Expected an identifier.
//        ^
// [diag.missingIdentifier] Expected an identifier.
//         ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: ^
  rightOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: <empty> <synthetic>
    operator: &
    rightOperand: SimpleIdentifier
      token: <empty> <synthetic>
''');
  }

  void test_bitwiseXorExpression_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = super ^  ^;
//               ^
// [diag.missingIdentifier] Expected an identifier.
//                ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SuperExpression
      superKeyword: super
    operator: ^
    rightOperand: SimpleIdentifier
      token: <empty> <synthetic>
  operator: ^
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_classTypeAlias_withBody() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {}
class B = Object with A {}
//                    ^
// [diag.expectedToken] Expected to find ';'.
//                      ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
    ClassTypeAlias
      typedefKeyword: class
      name: B
      equals: =
      superclass: NamedType
        name: Object
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: A
      semicolon: ; <synthetic>
''');
  }

  void test_combinator_badIdentifier() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import "/testB.dart" show @
//                        ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ';'.
//                         ^
// [diag.missingConstFinalVarOrType][column 28][length 0] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: "/testB.dart"
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_combinator_missingIdentifier() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import "/testB.dart" show ;
//                        ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: "/testB.dart"
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ;
''');
  }

  void test_conditionalExpression_missingElse() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = x ? y :;
//             ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: x
  question: ?
  thenExpression: SimpleIdentifier
    token: y
  colon: :
  elseExpression: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_conditionalExpression_missingThen() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = x ? : z;
//          ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: x
  question: ?
  thenExpression: SimpleIdentifier
    token: <empty> <synthetic>
  colon: :
  elseExpression: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = x ? super : z;
//          ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: x
  question: ?
  thenExpression: SuperExpression
    superKeyword: super
  colon: :
  elseExpression: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_super2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = x ? z : super;
//              ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: x
  question: ?
  thenExpression: SimpleIdentifier
    token: z
  colon: :
  elseExpression: SuperExpression
    superKeyword: super
''');
  }

  void test_declarationBeforeDirective() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class foo { } import 'bar.dart';
//            ^^^^^^
// [diag.directiveAfterDeclaration] Directives must appear before any declarations.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'bar.dart'
      semicolon: ;
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: foo
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_dotShorthand_missing_identifier() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = .;
//       ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: <empty> <synthetic>
  isDotShorthand: true
''');
  }

  void test_equalityExpression_missing_LHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = == y;
//      ^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: ==
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_equalityExpression_missing_LHS_RHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = ==;
//      ^^
// [diag.missingIdentifier] Expected an identifier.
//        ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: ==
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_equalityExpression_missing_RHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = x ==;
//          ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: ==
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_equalityExpression_missing_RHS_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = super ==;
//              ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SuperExpression
    superKeyword: super
  operator: ==
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_equalityExpression_precedence_relational_right() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = == is;
//      ^^
// [diag.missingIdentifier] Expected an identifier.
//         ^^
// [diag.missingIdentifier] Expected an identifier.
//           ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: ==
  rightOperand: IsExpression
    expression: SimpleIdentifier
      token: <empty> <synthetic>
    isOperator: is
    type: NamedType
      name: <empty> <synthetic>
''');
  }

  void test_equalityExpression_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = super ==  ==;
//                ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.equalityCannotBeEqualityOperand] A comparison expression can't be an operand of another comparison expression.
//                  ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SuperExpression
      superKeyword: super
    operator: ==
    rightOperand: SimpleIdentifier
      token: <empty> <synthetic>
  operator: ==
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_equalityExpression_superRHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = 1 == super;
//           ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: IntegerLiteral
    literal: 1
  operator: ==
  rightOperand: SuperExpression
    superKeyword: super
''');
  }

  void test_expressionList_multiple_end() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = [, 2, 3, 4];
//       ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleListLiteral;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements
    SimpleIdentifier
      token: <empty> <synthetic>
    IntegerLiteral
      literal: 2
    IntegerLiteral
      literal: 3
    IntegerLiteral
      literal: 4
  rightBracket: ]
''');
  }

  void test_expressionList_multiple_middle() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = [1, 2, , 4];
//             ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleListLiteral;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements
    IntegerLiteral
      literal: 1
    IntegerLiteral
      literal: 2
    SimpleIdentifier
      token: <empty> <synthetic>
    IntegerLiteral
      literal: 4
  rightBracket: ]
''');
  }

  void test_expressionList_multiple_start() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = [1, 2, 3];
''');
    var node = parseResult.findNode.singleListLiteral;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements
    IntegerLiteral
      literal: 1
    IntegerLiteral
      literal: 2
    IntegerLiteral
      literal: 3
  rightBracket: ]
''');
  }

  void test_functionExpression_in_ConstructorFieldInitializer() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A { A() : a = (){}; var v; }
//                      ^
// [diag.expectedClassMember] Expected a class member.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        members
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: A
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: a
                equals: =
                expression: RecordLiteral
                  leftParenthesis: (
                  rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: v
            semicolon: ;
        rightBracket: }
''');
  }

  void test_functionExpression_named() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = m(f() => 0);;
//        ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                  ^
// [diag.unexpectedToken] Unexpected text ';'.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: m
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IntegerLiteral
            literal: 0
    rightParenthesis: )
''');
  }

  void test_ifStatement_noElse_statement() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  if (x v) f(x);
//      ^
// [diag.expectedToken] Expected to find ')'.
}
''');
    var node = parseResult.findNode.firstBlock.statements[0];
    assertParsedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  rightParenthesis: )
  thenStatement: ExpressionStatement
    expression: MethodInvocation
      methodName: SimpleIdentifier
        token: f
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: x
        rightParenthesis: )
    semicolon: ;
''');
  }

  void test_importDirectivePartial_as() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'b.dart' d as b;
//              ^
// [diag.unexpectedToken] Unexpected text 'd'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'b.dart'
      asKeyword: as
      prefix: SimpleIdentifier
        token: b
      semicolon: ;
''');
  }

  void test_importDirectivePartial_hide() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'b.dart' d hide foo;
//              ^
// [diag.unexpectedToken] Unexpected text 'd'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'b.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: foo
      semicolon: ;
''');
  }

  void test_importDirectivePartial_show() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'b.dart' d show foo;
//              ^
// [diag.unexpectedToken] Unexpected text 'd'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'b.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: foo
      semicolon: ;
''');
  }

  void test_incomplete_conditionalExpression() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = x ? 0;
//           ^
// [diag.expectedToken] Expected to find ':'.
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: x
  question: ?
  thenExpression: IntegerLiteral
    literal: 0
  colon: : <synthetic>
  elseExpression: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_incomplete_constructorInitializers_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
C() : {}
//  ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//    ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: C
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
''');
  }

  void test_incomplete_constructorInitializers_missingEquals() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
C() : x(3) {}
//  ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//      ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: C
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
    FunctionDeclaration
      name: x
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: <empty> <synthetic>
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_incomplete_constructorInitializers_this() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
C() : this {}
//  ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//    ^^^^
// [diag.expectedIdentifierButGotKeyword] 'this' can't be used as an identifier because it's a keyword.
// [diag.missingFunctionParameters] Functions must have an explicit list of parameters.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: C
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
    FunctionDeclaration
      name: this
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: ( <synthetic>
          rightParenthesis: ) <synthetic>
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_incomplete_constructorInitializers_thisField() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
C() : this.g {}
//  ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//    ^^^^
// [diag.expectedIdentifierButGotKeyword] 'this' can't be used as an identifier because it's a keyword.
// [diag.missingFunctionParameters] Functions must have an explicit list of parameters.
//        ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//         ^
// [diag.missingFunctionParameters] Functions must have an explicit list of parameters.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: C
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
    FunctionDeclaration
      name: this
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: ( <synthetic>
          rightParenthesis: ) <synthetic>
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
    FunctionDeclaration
      name: g
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: ( <synthetic>
          rightParenthesis: ) <synthetic>
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_incomplete_constructorInitializers_thisPeriod() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
C() : this. {}
//  ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//    ^^^^
// [diag.expectedIdentifierButGotKeyword] 'this' can't be used as an identifier because it's a keyword.
// [diag.missingFunctionParameters] Functions must have an explicit list of parameters.
//        ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//          ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: C
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
    FunctionDeclaration
      name: this
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: ( <synthetic>
          rightParenthesis: ) <synthetic>
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
''');
  }

  void test_incomplete_constructorInitializers_variable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
C() : x {}
//  ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//    ^
// [diag.missingFunctionParameters] Functions must have an explicit list of parameters.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: C
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
    FunctionDeclaration
      name: x
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: ( <synthetic>
          rightParenthesis: ) <synthetic>
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_incomplete_functionExpression() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = () a => null;
//         ^
// [diag.unexpectedToken] Unexpected text 'a'.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: NullLiteral
      literal: null
''');
  }

  void test_incomplete_functionExpression2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = () a {};
//         ^
// [diag.unexpectedToken] Unexpected text 'a'.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_incomplete_returnType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
Map<Symbol, convertStringToSymbolMap(Map<String, dynamic> map) {
// [diag.missingFunctionParameters][column 1][length 3] Functions must have an explicit list of parameters.
//          ^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.expectedToken] Expected to find '>'.
  if (map == null) return null;
  Map<Symbol, dynamic> result = new Map<Symbol, dynamic>();
  map.forEach((name, value) {
    result[new Symbol(name)] = value;
  });
  return result;
}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: Map
      functionExpression: FunctionExpression
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: Symbol
            TypeParameter
              name: convertStringToSymbolMap
          rightBracket: > <synthetic>
        parameters: FormalParameterList
          leftParenthesis: ( <synthetic>
          rightParenthesis: ) <synthetic>
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: BinaryExpression
                  leftOperand: SimpleIdentifier
                    token: map
                  operator: ==
                  rightOperand: NullLiteral
                    literal: null
                rightParenthesis: )
                thenStatement: ReturnStatement
                  returnKeyword: return
                  expression: NullLiteral
                    literal: null
                  semicolon: ;
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: Map
                    typeArguments: TypeArgumentList
                      leftBracket: <
                      arguments
                        NamedType
                          name: Symbol
                        NamedType
                          name: dynamic
                      rightBracket: >
                  variables
                    VariableDeclaration
                      name: result
                      equals: =
                      initializer: InstanceCreationExpression
                        keyword: new
                        constructorName: ConstructorName
                          type: NamedType
                            name: Map
                            typeArguments: TypeArgumentList
                              leftBracket: <
                              arguments
                                NamedType
                                  name: Symbol
                                NamedType
                                  name: dynamic
                              rightBracket: >
                        argumentList: ArgumentList
                          leftParenthesis: (
                          rightParenthesis: )
                semicolon: ;
              ExpressionStatement
                expression: MethodInvocation
                  target: SimpleIdentifier
                    token: map
                  operator: .
                  methodName: SimpleIdentifier
                    token: forEach
                  argumentList: ArgumentList
                    leftParenthesis: (
                    arguments
                      FunctionExpression
                        parameters: FormalParameterList
                          leftParenthesis: (
                          parameter: RegularFormalParameter
                            name: name
                          parameter: RegularFormalParameter
                            name: value
                          rightParenthesis: )
                        body: BlockFunctionBody
                          block: Block
                            leftBracket: {
                            statements
                              ExpressionStatement
                                expression: AssignmentExpression
                                  leftHandSide: IndexExpression
                                    target: SimpleIdentifier
                                      token: result
                                    leftBracket: [
                                    index: InstanceCreationExpression
                                      keyword: new
                                      constructorName: ConstructorName
                                        type: NamedType
                                          name: Symbol
                                      argumentList: ArgumentList
                                        leftParenthesis: (
                                        arguments
                                          SimpleIdentifier
                                            token: name
                                        rightParenthesis: )
                                    rightBracket: ]
                                  operator: =
                                  rightHandSide: SimpleIdentifier
                                    token: value
                                semicolon: ;
                            rightBracket: }
                    rightParenthesis: )
                semicolon: ;
              ReturnStatement
                returnKeyword: return
                expression: SimpleIdentifier
                  token: result
                semicolon: ;
            rightBracket: }
''');
  }

  void test_incomplete_topLevelFunction() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
foo();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: foo
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: EmptyFunctionBody
          semicolon: ;
''');
  }

  void test_incomplete_topLevelFunction_language305() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.5
foo();
//   ^
// [diag.missingFunctionBody] A function body must be provided.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: foo
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: EmptyFunctionBody
          semicolon: ;
''');
  }

  void test_incomplete_topLevelVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
String
// [diag.missingConstFinalVarOrType][column 1][length 6] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken][column 1][length 6] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: String
      semicolon: ; <synthetic>
''');
  }

  void test_incomplete_topLevelVariable_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
const
// [diag.expectedToken][column 1][length 5] Expected to find ';'.
//   ^
// [diag.missingIdentifier][column 6][length 0] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_incomplete_topLevelVariable_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final
// [diag.expectedToken][column 1][length 5] Expected to find ';'.
//   ^
// [diag.missingIdentifier][column 6][length 0] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        variables
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_incomplete_topLevelVariable_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var
// [diag.expectedToken][column 1][length 3] Expected to find ';'.
// ^
// [diag.missingIdentifier][column 4][length 0] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_incompleteField_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  const
//^^^^^
// [diag.expectedToken] Expected to find ';'.
}
// [diag.missingIdentifier][column 1][length 1] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: const
              variables
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_incompleteField_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  final
//^^^^^
// [diag.expectedToken] Expected to find ';'.
}
// [diag.missingIdentifier][column 1][length 1] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: final
              variables
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_incompleteField_static() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  static c
//       ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            staticKeyword: static
            fields: VariableDeclarationList
              variables
                VariableDeclaration
                  name: c
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_incompleteField_static2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  static c x
//         ^
// [diag.expectedToken] Expected to find ';'.
}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            staticKeyword: static
            fields: VariableDeclarationList
              type: NamedType
                name: c
              variables
                VariableDeclaration
                  name: x
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_incompleteField_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  A
//^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            fields: VariableDeclarationList
              variables
                VariableDeclaration
                  name: A
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_incompleteField_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  var
//^^^
// [diag.expectedToken] Expected to find ';'.
}
// [diag.missingIdentifier][column 1][length 1] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_incompleteForEach() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  for (String item i) {}
//            ^^^^
// [diag.expectedToken] Expected to find ';'.
//                 ^
// [diag.expectedToken] Expected to find ';'.
}
''');
    var node = parseResult.findNode.firstBlock.statements[0];
    assertParsedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithDeclarations
    variables: VariableDeclarationList
      type: NamedType
        name: String
      variables
        VariableDeclaration
          name: item
    leftSeparator: ; <synthetic>
    condition: SimpleIdentifier
      token: i
    rightSeparator: ; <synthetic>
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  void test_incompleteForEach2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  for (String item i) {}
//            ^^^^
// [diag.expectedToken] Expected to find ';'.
//                 ^
// [diag.expectedToken] Expected to find ';'.
}
''');
    var node = parseResult.findNode.firstBlock.statements[0];
    assertParsedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithDeclarations
    variables: VariableDeclarationList
      type: NamedType
        name: String
      variables
        VariableDeclaration
          name: item
    leftSeparator: ; <synthetic>
    condition: SimpleIdentifier
      token: i
    rightSeparator: ; <synthetic>
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  void test_incompleteLocalVariable_atTheEndOfBlock() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  String v }
//       ^
// [diag.expectedToken] Expected to find ';'.
}
// [diag.expectedExecutable][column 1][length 1] Expected a method, getter, setter or operator declaration.
''');
    var node = parseResult.findNode.firstBlock.statements[0];
    assertParsedNodeText(node, r'''
VariableDeclarationStatement
  variables: VariableDeclarationList
    type: NamedType
      name: String
    variables
      VariableDeclaration
        name: v
  semicolon: ; <synthetic>
''');
  }

  void test_incompleteLocalVariable_atTheEndOfBlock_modifierOnly() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  final }
//^^^^^
// [diag.expectedToken] Expected to find ';'.
//      ^
// [diag.missingIdentifier] Expected an identifier.
}
// [diag.expectedExecutable][column 1][length 1] Expected a method, getter, setter or operator declaration.
''');
    var node = parseResult.findNode.firstBlock.statements[0];
    assertParsedNodeText(node, r'''
VariableDeclarationStatement
  variables: VariableDeclarationList
    keyword: final
    variables
      VariableDeclaration
        name: <empty> <synthetic>
  semicolon: ; <synthetic>
''');
  }

  void test_incompleteLocalVariable_beforeIdentifier() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  String v String v2;
//       ^
// [diag.expectedToken] Expected to find ';'.
}
''');
    var node = parseResult.findNode.firstBlock.statements[0];
    assertParsedNodeText(node, r'''
VariableDeclarationStatement
  variables: VariableDeclarationList
    type: NamedType
      name: String
    variables
      VariableDeclaration
        name: v
  semicolon: ; <synthetic>
''');
  }

  void test_incompleteLocalVariable_beforeKeyword() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  String v if (true) {}
//       ^
// [diag.expectedToken] Expected to find ';'.
}
''');
    var node = parseResult.findNode.firstBlock.statements[0];
    assertParsedNodeText(node, r'''
VariableDeclarationStatement
  variables: VariableDeclarationList
    type: NamedType
      name: String
    variables
      VariableDeclaration
        name: v
  semicolon: ; <synthetic>
''');
  }

  void test_incompleteLocalVariable_beforeNextBlock() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  String v {}
//       ^
// [diag.expectedToken] Expected to find ';'.
}
''');
    var node = parseResult.findNode.firstBlock.statements[0];
    assertParsedNodeText(node, r'''
VariableDeclarationStatement
  variables: VariableDeclarationList
    type: NamedType
      name: String
    variables
      VariableDeclaration
        name: v
  semicolon: ; <synthetic>
''');
  }

  void test_incompleteLocalVariable_parameterizedType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  List<String> v {}
//             ^
// [diag.expectedToken] Expected to find ';'.
}
''');
    var node = parseResult.findNode.firstBlock.statements[0];
    assertParsedNodeText(node, r'''
VariableDeclarationStatement
  variables: VariableDeclarationList
    type: NamedType
      name: List
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: String
        rightBracket: >
    variables
      VariableDeclaration
        name: v
  semicolon: ; <synthetic>
''');
  }

  void test_incompleteTypeArguments_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  final List<int f;
//           ^^^
// [diag.expectedToken] Expected to find '>'.
}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: final
              type: NamedType
                name: List
                typeArguments: TypeArgumentList
                  leftBracket: <
                  arguments
                    NamedType
                      name: int
                  rightBracket: > <synthetic>
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_incompleteTypeParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C<K {
//      ^
// [diag.expectedToken] Expected to find '>'.
}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: K
          rightBracket: > <synthetic>
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_incompleteTypeParameters2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C<K extends L<T> {
//                   ^
// [diag.expectedToken] Expected to find '>'.
}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: K
              extendsKeyword: extends
              bound: NamedType
                name: L
                typeArguments: TypeArgumentList
                  leftBracket: <
                  arguments
                    NamedType
                      name: T
                  rightBracket: >
          rightBracket: > <synthetic>
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_incompleteTypeParameters3() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C<K extends L<T {
//                  ^
// [diag.expectedToken] Expected to find '>'.
}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: K
              extendsKeyword: extends
              bound: NamedType
                name: L
                typeArguments: TypeArgumentList
                  leftBracket: <
                  arguments
                    NamedType
                      name: T
                  rightBracket: > <synthetic>
          rightBracket: > <synthetic>
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_invalidFunctionBodyModifier() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() sync {}
//  ^^^^
// [diag.missingStarAfterSync] The modifier 'sync' must be followed by a star ('*').
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: sync
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_invalidMapLiteral() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f = Map<A, B> {}; }
//                ^^^
// [diag.literalWithClass] A map literal can't be prefixed by 'Map'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SetOrMapLiteral
                    typeArguments: TypeArgumentList
                      leftBracket: <
                      arguments
                        NamedType
                          name: A
                        NamedType
                          name: B
                      rightBracket: >
                    leftBracket: {
                    rightBracket: }
                    isMap: false
            semicolon: ;
        rightBracket: }
''');
  }

  void test_invalidTypeParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  G<int double> g;
//      ^^^^^^
// [diag.expectedToken] Expected to find ','.
}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            fields: VariableDeclarationList
              type: NamedType
                name: G
                typeArguments: TypeArgumentList
                  leftBracket: <
                  arguments
                    NamedType
                      name: int
                    NamedType
                      name: double
                  rightBracket: >
              variables
                VariableDeclaration
                  name: g
            semicolon: ;
        rightBracket: }
''');
  }

  void test_invalidTypeParameters_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C<X super Y> {}
//      ^
// [diag.expectedToken] Expected to find '>'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: X
          rightBracket: >
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_isExpression_noType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class Bar<T extends Foo> {m(x){if (x is ) return;if (x is !)}}
//                                      ^
// [diag.expectedTypeName] Expected a type name.
//                                                         ^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedToken] Expected to find ';'.
//                                                          ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: Bar
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: T
              extendsKeyword: extends
              bound: NamedType
                name: Foo
          rightBracket: >
      body: BlockClassBody
        leftBracket: {
        members
          MethodDeclaration
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: x
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                statements
                  IfStatement
                    ifKeyword: if
                    leftParenthesis: (
                    expression: IsExpression
                      expression: SimpleIdentifier
                        token: x
                      isOperator: is
                      type: NamedType
                        name: <empty> <synthetic>
                    rightParenthesis: )
                    thenStatement: ReturnStatement
                      returnKeyword: return
                      semicolon: ;
                  IfStatement
                    ifKeyword: if
                    leftParenthesis: (
                    expression: IsExpression
                      expression: SimpleIdentifier
                        token: x
                      isOperator: is
                      notOperator: !
                      type: NamedType
                        name: <empty> <synthetic>
                    rightParenthesis: )
                    thenStatement: ExpressionStatement
                      expression: SimpleIdentifier
                        token: <empty> <synthetic>
                      semicolon: ; <synthetic>
                rightBracket: }
        rightBracket: }
''');
  }

  void test_issue_34610_get() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { get C.named => null; }
//        ^^^
// [diag.getterConstructor] Constructors can't be a getter.
//            ^
// [diag.missingMethodParameters] Methods must have an explicit list of parameters.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            period: .
            name: named
            parameters: FormalParameterList
              leftParenthesis: ( <synthetic>
              rightParenthesis: ) <synthetic>
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: NullLiteral
                literal: null
              semicolon: ;
        rightBracket: }
''');
  }

  void test_issue_34610_initializers() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { C.named : super(); }
//        ^
// [diag.missingMethodParameters] Methods must have an explicit list of parameters.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            period: .
            name: named
            parameters: FormalParameterList
              leftParenthesis: ( <synthetic>
              rightParenthesis: ) <synthetic>
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                argumentList: ArgumentList
                  leftParenthesis: (
                  rightParenthesis: )
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_issue_34610_missing_param() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { C => null; }
//        ^
// [diag.missingMethodParameters] Methods must have an explicit list of parameters.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: ( <synthetic>
              rightParenthesis: ) <synthetic>
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: NullLiteral
                literal: null
              semicolon: ;
        rightBracket: }
''');
  }

  void test_issue_34610_named_missing_param() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { C.named => null; }
//        ^
// [diag.missingMethodParameters] Methods must have an explicit list of parameters.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            period: .
            name: named
            parameters: FormalParameterList
              leftParenthesis: ( <synthetic>
              rightParenthesis: ) <synthetic>
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: NullLiteral
                literal: null
              semicolon: ;
        rightBracket: }
''');
  }

  void test_issue_34610_set() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { set C.named => null; }
//        ^^^
// [diag.setterConstructor] Constructors can't be a setter.
//            ^
// [diag.missingMethodParameters] Methods must have an explicit list of parameters.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            period: .
            name: named
            parameters: FormalParameterList
              leftParenthesis: ( <synthetic>
              rightParenthesis: ) <synthetic>
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: NullLiteral
                literal: null
              semicolon: ;
        rightBracket: }
''');
  }

  void test_keywordInPlaceOfIdentifier() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
do() {}
// [diag.expectedIdentifierButGotKeyword][column 1][length 2] 'do' can't be used as an identifier because it's a keyword.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: do
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_logicalAndExpression_missing_LHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = && y;
//      ^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: &&
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_logicalAndExpression_missing_LHS_RHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = &&;
//      ^^
// [diag.missingIdentifier] Expected an identifier.
//        ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: &&
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_logicalAndExpression_missing_RHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = x &&;
//          ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: &&
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_logicalAndExpression_precedence_bitwiseOr_left() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = | &&;
//      ^
// [diag.missingIdentifier] Expected an identifier.
//        ^^
// [diag.missingIdentifier] Expected an identifier.
//          ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: <empty> <synthetic>
    operator: |
    rightOperand: SimpleIdentifier
      token: <empty> <synthetic>
  operator: &&
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_logicalAndExpression_precedence_bitwiseOr_right() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = && |;
//      ^^
// [diag.missingIdentifier] Expected an identifier.
//         ^
// [diag.missingIdentifier] Expected an identifier.
//          ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: &&
  rightOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: <empty> <synthetic>
    operator: |
    rightOperand: SimpleIdentifier
      token: <empty> <synthetic>
''');
  }

  void test_logicalOrExpression_missing_LHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = || y;
//      ^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: ||
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_logicalOrExpression_missing_LHS_RHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = ||;
//      ^^
// [diag.missingIdentifier] Expected an identifier.
//        ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: ||
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_logicalOrExpression_missing_RHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = x ||;
//          ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: ||
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_logicalOrExpression_precedence_logicalAnd_left() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = && ||;
//      ^^
// [diag.missingIdentifier] Expected an identifier.
//         ^^
// [diag.missingIdentifier] Expected an identifier.
//           ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: <empty> <synthetic>
    operator: &&
    rightOperand: SimpleIdentifier
      token: <empty> <synthetic>
  operator: ||
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_logicalOrExpression_precedence_logicalAnd_right() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = || &&;
//      ^^
// [diag.missingIdentifier] Expected an identifier.
//         ^^
// [diag.missingIdentifier] Expected an identifier.
//           ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: ||
  rightOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: <empty> <synthetic>
    operator: &&
    rightOperand: SimpleIdentifier
      token: <empty> <synthetic>
''');
  }

  void test_method_missingBody() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { b() }
//            ^
// [diag.missingFunctionBody] A function body must be provided.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          MethodDeclaration
            name: b
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_missing_commaInArgumentList() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = f(x: 1 y: 2);
//             ^
// [diag.expectedToken] Expected to find ','.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NamedArgument
        name: x
        colon: :
        argumentExpression: IntegerLiteral
          literal: 1
      NamedArgument
        name: y
        colon: :
        argumentExpression: IntegerLiteral
          literal: 2
    rightParenthesis: )
''');
  }

  void test_missingComma_beforeNamedArgument() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
(a b: c)
// [diag.expectedExecutable][column 1][length 1] Expected a method, getter, setter or operator declaration.
// ^
// [diag.expectedToken] Expected to find ';'.
//  ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//    ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
//     ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: a
        variables
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: c
      semicolon: ; <synthetic>
''');
  }

  void test_missingGet() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  int length {}
//    ^^^^^^
// [diag.missingMethodParameters] Methods must have an explicit list of parameters.
  void foo() {}
}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          MethodDeclaration
            returnType: NamedType
              name: int
            name: length
            parameters: FormalParameterList
              leftParenthesis: ( <synthetic>
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
          MethodDeclaration
            returnType: NamedType
              name: void
            name: foo
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_missingIdentifier_afterAnnotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@override }
//        ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_missingSemicolon_variableDeclarationList() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
String n x = "";
//     ^
// [diag.expectedToken] Expected to find ';'.
//       ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: String
        variables
          VariableDeclaration
            name: n
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: SimpleStringLiteral
              literal: ""
      semicolon: ;
''');
  }

  void test_multiplicativeExpression_missing_LHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = * y;
//      ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: *
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_multiplicativeExpression_missing_LHS_RHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = *;
//      ^
// [diag.missingIdentifier] Expected an identifier.
//       ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: *
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_multiplicativeExpression_missing_RHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = x *;
//         ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: *
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_multiplicativeExpression_missing_RHS_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = super *;
//             ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SuperExpression
    superKeyword: super
  operator: *
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_multiplicativeExpression_precedence_unary_left() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = -x *;
//          ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: PrefixExpression
    operator: -
    operand: SimpleIdentifier
      token: x
  operator: *
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_multiplicativeExpression_precedence_unary_right() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = * -y;
//      ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: *
  rightOperand: PrefixExpression
    operator: -
    operand: SimpleIdentifier
      token: y
''');
  }

  void test_multiplicativeExpression_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = super ==  ==;
//                ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.equalityCannotBeEqualityOperand] A comparison expression can't be an operand of another comparison expression.
//                  ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SuperExpression
      superKeyword: super
    operator: ==
    rightOperand: SimpleIdentifier
      token: <empty> <synthetic>
  operator: ==
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_namedParameterOutsideGroup() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A { b(c: 0, Foo d: 0, e){} }
//           ^
// [diag.namedParameterOutsideGroup] Named parameters must be enclosed in curly braces ('{' and '}').
//                     ^
// [diag.namedParameterOutsideGroup] Named parameters must be enclosed in curly braces ('{' and '}').
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        members
          MethodDeclaration
            name: b
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: c
                defaultClause: FormalParameterDefaultClause
                  separator: :
                  value: IntegerLiteral
                    literal: 0
              parameter: RegularFormalParameter
                type: NamedType
                  name: Foo
                name: d
                defaultClause: FormalParameterDefaultClause
                  separator: :
                  value: IntegerLiteral
                    literal: 0
              parameter: RegularFormalParameter
                name: e
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_nonStringLiteralUri_import() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import dart:io; class C {}
// [diag.expectedToken][column 1][length 6] Expected to find ';'.
//     ^^^^
// [diag.expectedStringLiteral] Expected a string literal.
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
//         ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//          ^^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: "" <synthetic>
      semicolon: ; <synthetic>
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: dart
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: io
      semicolon: ;
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_prefixExpression_missing_operand_minus() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = -;
//       ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PrefixExpression
  operator: -
  operand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_primaryExpression_argumentDefinitionTest() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = ?a;
//      ^
// [diag.missingIdentifier] Expected an identifier.
//        ^
// [diag.expectedToken] Expected to find ':'.
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: <empty> <synthetic>
  question: ?
  thenExpression: SimpleIdentifier
    token: a
  colon: : <synthetic>
  elseExpression: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_relationalExpression_missing_LHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = is y;
//      ^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
IsExpression
  expression: SimpleIdentifier
    token: <empty> <synthetic>
  isOperator: is
  type: NamedType
    name: y
''');
  }

  void test_relationalExpression_missing_LHS_RHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = is;
//      ^^
// [diag.missingIdentifier] Expected an identifier.
//        ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
IsExpression
  expression: SimpleIdentifier
    token: <empty> <synthetic>
  isOperator: is
  type: NamedType
    name: <empty> <synthetic>
''');
  }

  void test_relationalExpression_missing_RHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = x is;
//          ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
IsExpression
  expression: SimpleIdentifier
    token: x
  isOperator: is
  type: NamedType
    name: <empty> <synthetic>
''');
  }

  void test_relationalExpression_precedence_shift_right() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = << is;
//      ^^
// [diag.missingIdentifier] Expected an identifier.
//         ^^
// [diag.missingIdentifier] Expected an identifier.
//           ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
IsExpression
  expression: BinaryExpression
    leftOperand: SimpleIdentifier
      token: <empty> <synthetic>
    operator: <<
    rightOperand: SimpleIdentifier
      token: <empty> <synthetic>
  isOperator: is
  type: NamedType
    name: <empty> <synthetic>
''');
  }

  void test_shiftExpression_missing_LHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = << y;
//      ^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: <<
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_shiftExpression_missing_LHS_RHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = <<;
//      ^^
// [diag.missingIdentifier] Expected an identifier.
//        ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: <<
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_shiftExpression_missing_RHS() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = x <<;
//          ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: <<
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_shiftExpression_missing_RHS_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = super <<;
//              ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SuperExpression
    superKeyword: super
  operator: <<
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_shiftExpression_precedence_unary_left() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = + <<;
//      ^
// [diag.missingIdentifier] Expected an identifier.
//        ^^
// [diag.missingIdentifier] Expected an identifier.
//          ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: <empty> <synthetic>
    operator: +
    rightOperand: SimpleIdentifier
      token: <empty> <synthetic>
  operator: <<
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_shiftExpression_precedence_unary_right() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = << +;
//      ^^
// [diag.missingIdentifier] Expected an identifier.
//         ^
// [diag.missingIdentifier] Expected an identifier.
//          ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: <<
  rightOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: <empty> <synthetic>
    operator: +
    rightOperand: SimpleIdentifier
      token: <empty> <synthetic>
''');
  }

  void test_shiftExpression_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = super << <<;
//               ^^
// [diag.missingIdentifier] Expected an identifier.
//                 ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SuperExpression
      superKeyword: super
    operator: <<
    rightOperand: SimpleIdentifier
      token: <empty> <synthetic>
  operator: <<
  rightOperand: SimpleIdentifier
    token: <empty> <synthetic>
''');
  }

  void test_typedef_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef n
//      ^
// [diag.expectedToken] Expected to find ';'.
//       ^
// [diag.missingTypedefParameters][column 10][length 0] Typedefs must have an explicit list of parameters.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      name: n
      parameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_unaryPlus() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = +2;
//      ^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: <empty> <synthetic>
  operator: +
  rightOperand: IntegerLiteral
    literal: 2
''');
  }
}
