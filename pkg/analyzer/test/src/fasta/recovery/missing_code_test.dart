// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ListLiteralTest);
    defineReflectiveTests(MapLiteralTest);
    defineReflectiveTests(MissingCodeTest);
    defineReflectiveTests(ParameterListTest);
    defineReflectiveTests(TypedefTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

/// Test how well the parser recovers when tokens are missing in a list literal.
@reflectiveTest
class ListLiteralTest extends ParserDiagnosticsTest {
  void test_extraComma() {
    var parseResult = parseStringWithErrors(r'''
f() => [a, , b];
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 11, 1)]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: ListLiteral
            leftBracket: [
            elements
              SimpleIdentifier
                token: a
              SimpleIdentifier
                token: <empty> <synthetic>
              SimpleIdentifier
                token: b
            rightBracket: ]
          semicolon: ;
''');
  }

  void test_missingComma() {
    var parseResult = parseStringWithErrors(r'''
f() => [a, b c];
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: ListLiteral
            leftBracket: [
            elements
              SimpleIdentifier
                token: a
              SimpleIdentifier
                token: b
              SimpleIdentifier
                token: c
            rightBracket: ]
          semicolon: ;
''');
  }

  void test_missingComma_afterIf() {
    var parseResult = parseStringWithErrors(r'''
f() => [a, if (x) b c];
''');
    parseResult.assertErrors([error(diag.expectedElseOrComma, 20, 1)]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: ListLiteral
            leftBracket: [
            elements
              SimpleIdentifier
                token: a
              IfElement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: x
                rightParenthesis: )
                thenElement: SimpleIdentifier
                  token: b
              SimpleIdentifier
                token: c
            rightBracket: ]
          semicolon: ;
''');
  }

  void test_missingComma_afterIfElse() {
    var parseResult = parseStringWithErrors(r'''
f() => [a, if (x) b else y c];
''');
    parseResult.assertErrors([error(diag.expectedToken, 27, 1)]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: ListLiteral
            leftBracket: [
            elements
              SimpleIdentifier
                token: a
              IfElement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: x
                rightParenthesis: )
                thenElement: SimpleIdentifier
                  token: b
                elseKeyword: else
                elseElement: SimpleIdentifier
                  token: y
              SimpleIdentifier
                token: c
            rightBracket: ]
          semicolon: ;
''');
  }
}

/// Test how well the parser recovers when tokens are missing in a map literal.
@reflectiveTest
class MapLiteralTest extends ParserDiagnosticsTest {
  void test_missingComma() {
    var parseResult = parseStringWithErrors(r'''
f() => {a: b, c: d e: f};
''');
    parseResult.assertErrors([error(diag.expectedToken, 19, 1)]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: SetOrMapLiteral
            leftBracket: {
            elements
              MapLiteralEntry
                key: SimpleIdentifier
                  token: a
                separator: :
                value: SimpleIdentifier
                  token: b
              MapLiteralEntry
                key: SimpleIdentifier
                  token: c
                separator: :
                value: SimpleIdentifier
                  token: d
              MapLiteralEntry
                key: SimpleIdentifier
                  token: e
                separator: :
                value: SimpleIdentifier
                  token: f
            rightBracket: }
            isMap: false
          semicolon: ;
''');
  }

  void test_missingComma_afterIf() {
    var parseResult = parseStringWithErrors(r'''
f() => {a: b, if (x) c: d e: f};
''');
    parseResult.assertErrors([error(diag.expectedElseOrComma, 26, 1)]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: SetOrMapLiteral
            leftBracket: {
            elements
              MapLiteralEntry
                key: SimpleIdentifier
                  token: a
                separator: :
                value: SimpleIdentifier
                  token: b
              IfElement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: x
                rightParenthesis: )
                thenElement: MapLiteralEntry
                  key: SimpleIdentifier
                    token: c
                  separator: :
                  value: SimpleIdentifier
                    token: d
              MapLiteralEntry
                key: SimpleIdentifier
                  token: e
                separator: :
                value: SimpleIdentifier
                  token: f
            rightBracket: }
            isMap: false
          semicolon: ;
''');
  }

  void test_missingComma_afterIfElse() {
    var parseResult = parseStringWithErrors(r'''
f() => {a: b, if (x) c: d else y: z e: f};
''');
    parseResult.assertErrors([error(diag.expectedToken, 36, 1)]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: SetOrMapLiteral
            leftBracket: {
            elements
              MapLiteralEntry
                key: SimpleIdentifier
                  token: a
                separator: :
                value: SimpleIdentifier
                  token: b
              IfElement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: x
                rightParenthesis: )
                thenElement: MapLiteralEntry
                  key: SimpleIdentifier
                    token: c
                  separator: :
                  value: SimpleIdentifier
                    token: d
                elseKeyword: else
                elseElement: MapLiteralEntry
                  key: SimpleIdentifier
                    token: y
                  separator: :
                  value: SimpleIdentifier
                    token: z
              MapLiteralEntry
                key: SimpleIdentifier
                  token: e
                separator: :
                value: SimpleIdentifier
                  token: f
            rightBracket: }
            isMap: false
          semicolon: ;
''');
  }

  void test_missingKey() {
    var parseResult = parseStringWithErrors(r'''
f() => {: b};
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: SetOrMapLiteral
            leftBracket: {
            elements
              MapLiteralEntry
                key: SimpleIdentifier
                  token: <empty> <synthetic>
                separator: :
                value: SimpleIdentifier
                  token: b
            rightBracket: }
            isMap: false
          semicolon: ;
''');
  }

  void test_missingValue_last() {
    var parseResult = parseStringWithErrors(r'''
f() => {a: };
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 11, 1)]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: SetOrMapLiteral
            leftBracket: {
            elements
              MapLiteralEntry
                key: SimpleIdentifier
                  token: a
                separator: :
                value: SimpleIdentifier
                  token: <empty> <synthetic>
            rightBracket: }
            isMap: false
          semicolon: ;
''');
  }

  void test_missingValue_notLast() {
    var parseResult = parseStringWithErrors(r'''
f() => {a: , b: c};
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 11, 1)]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: SetOrMapLiteral
            leftBracket: {
            elements
              MapLiteralEntry
                key: SimpleIdentifier
                  token: a
                separator: :
                value: SimpleIdentifier
                  token: <empty> <synthetic>
              MapLiteralEntry
                key: SimpleIdentifier
                  token: b
                separator: :
                value: SimpleIdentifier
                  token: c
            rightBracket: }
            isMap: false
          semicolon: ;
''');
  }
}

/// Test how well the parser recovers when non-paired tokens are missing.
@reflectiveTest
class MissingCodeTest extends ParserDiagnosticsTest {
  void test_ampersand() {
    var parseResult = parseStringWithErrors(r'''
f() => x &
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 0),
      error(diag.expectedToken, 9, 1),
    ]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: x
            operator: &
            rightOperand: SimpleIdentifier
              token: <empty> <synthetic>
          semicolon: ; <synthetic>
''');
  }

  void test_ampersand_super() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int operator &(x) => super &
}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 41, 1),
      error(diag.expectedToken, 39, 1),
    ]);
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
            operatorKeyword: operator
            name: &
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: x
              rightParenthesis: )
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: BinaryExpression
                leftOperand: SuperExpression
                  superKeyword: super
                operator: &
                rightOperand: SimpleIdentifier
                  token: <empty> <synthetic>
              semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_asExpression_missingLeft() {
    var parseResult = parseStringWithErrors(r'''
convert(x) => as T;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 14, 2),
      error(diag.missingConstFinalVarOrType, 17, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: convert
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: x
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: SimpleIdentifier
            token: as
          semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: T
      semicolon: ;
''');
  }

  void test_asExpression_missingRight() {
    var parseResult = parseStringWithErrors(r'''
convert(x) => x as ;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: convert
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: x
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: AsExpression
            expression: SimpleIdentifier
              token: x
            asOperator: as
            type: NamedType
              name: <empty> <synthetic>
          semicolon: ;
''');
  }

  void test_assignmentExpression() {
    var parseResult = parseStringWithErrors(r'''
f() {
  var x;
  x =
}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 1),
      error(diag.expectedToken, 19, 1),
    ]);
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
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: x
                semicolon: ;
              ExpressionStatement
                expression: AssignmentExpression
                  leftHandSide: SimpleIdentifier
                    token: x
                  operator: =
                  rightHandSide: SimpleIdentifier
                    token: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_bar() {
    var parseResult = parseStringWithErrors(r'''
f() => x |
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 0),
      error(diag.expectedToken, 9, 1),
    ]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: x
            operator: |
            rightOperand: SimpleIdentifier
              token: <empty> <synthetic>
          semicolon: ; <synthetic>
''');
  }

  void test_bar_super() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int operator |(x) => super |
}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 41, 1),
      error(diag.expectedToken, 39, 1),
    ]);
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
            operatorKeyword: operator
            name: |
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: x
              rightParenthesis: )
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: BinaryExpression
                leftOperand: SuperExpression
                  superKeyword: super
                operator: |
                rightOperand: SimpleIdentifier
                  token: <empty> <synthetic>
              semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_cascade_missingRight() {
    var parseResult = parseStringWithErrors(r'''
f(x) {
  x..
}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 1),
      error(diag.expectedToken, 10, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: CascadeExpression
                  target: SimpleIdentifier
                    token: x
                  cascadeSections
                    PropertyAccess
                      operator: ..
                      propertyName: SimpleIdentifier
                        token: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_classDeclaration_missingName() {
    var parseResult = parseStringWithErrors(r'''
class {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_combinatorsBeforePrefix() {
    var parseResult = parseStringWithErrors(r'''
import 'bar.dart' deferred;
''');
    parseResult.assertErrors([
      error(diag.missingPrefixInDeferredImport, 18, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'bar.dart'
      deferredKeyword: deferred
      semicolon: ;
''');
  }

  void test_comma_missing() {
    var parseResult = parseStringWithErrors(r'''
f(int a int b) { }
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: int
            name: a
          parameter: RegularFormalParameter
            type: NamedType
              name: int
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_conditionalExpression_else() {
    var parseResult = parseStringWithErrors(r'''
f() => x ? y :
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 15, 0),
      error(diag.expectedToken, 13, 1),
    ]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: ConditionalExpression
            condition: SimpleIdentifier
              token: x
            question: ?
            thenExpression: SimpleIdentifier
              token: y
            colon: :
            elseExpression: SimpleIdentifier
              token: <empty> <synthetic>
          semicolon: ; <synthetic>
''');
  }

  void test_conditionalExpression_then() {
    var parseResult = parseStringWithErrors(r'''
f() => x ? : z
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 1),
      error(diag.expectedToken, 13, 1),
    ]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: ConditionalExpression
            condition: SimpleIdentifier
              token: x
            question: ?
            thenExpression: SimpleIdentifier
              token: <empty> <synthetic>
            colon: :
            elseExpression: SimpleIdentifier
              token: z
          semicolon: ; <synthetic>
''');
  }

  void test_equalEqual() {
    var parseResult = parseStringWithErrors(r'''
f() => x ==
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 12, 0),
      error(diag.expectedToken, 9, 2),
    ]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: x
            operator: ==
            rightOperand: SimpleIdentifier
              token: <empty> <synthetic>
          semicolon: ; <synthetic>
''');
  }

  void test_equalEqual_super() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int operator ==(x) => super ==
}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 43, 1),
      error(diag.expectedToken, 40, 2),
    ]);
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
            operatorKeyword: operator
            name: ==
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: x
              rightParenthesis: )
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: BinaryExpression
                leftOperand: SuperExpression
                  superKeyword: super
                operator: ==
                rightOperand: SimpleIdentifier
                  token: <empty> <synthetic>
              semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_expressionBody_missingGt() {
    var parseResult = parseStringWithErrors(r'''
f(x) = x;
''');
    parseResult.assertErrors([error(diag.missingFunctionBody, 5, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: x
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: => <synthetic>
          expression: SimpleIdentifier
            token: x
          semicolon: ;
''');
  }

  void test_expressionBody_return() {
    var parseResult = parseStringWithErrors(r'''
f(x) return x;
''');
    parseResult.assertErrors([error(diag.missingFunctionBody, 5, 6)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: x
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: => <synthetic>
          expression: SimpleIdentifier
            token: x
          semicolon: ;
''');
  }

  void test_greaterThan() {
    var parseResult = parseStringWithErrors(r'''
f() => x >
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 0),
      error(diag.expectedToken, 9, 1),
    ]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: x
            operator: >
            rightOperand: SimpleIdentifier
              token: <empty> <synthetic>
          semicolon: ; <synthetic>
''');
  }

  void test_greaterThan_super() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int operator >(x) => super >
}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 41, 1),
      error(diag.expectedToken, 39, 1),
    ]);
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
            operatorKeyword: operator
            name: >
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: x
              rightParenthesis: )
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: BinaryExpression
                leftOperand: SuperExpression
                  superKeyword: super
                operator: >
                rightOperand: SimpleIdentifier
                  token: <empty> <synthetic>
              semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_greaterThanGreaterThan() {
    var parseResult = parseStringWithErrors(r'''
f() => x >>
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 12, 0),
      error(diag.expectedToken, 9, 2),
    ]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: x
            operator: >>
            rightOperand: SimpleIdentifier
              token: <empty> <synthetic>
          semicolon: ; <synthetic>
''');
  }

  void test_greaterThanGreaterThan_super() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int operator >>(x) => super >>
}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 43, 1),
      error(diag.expectedToken, 40, 2),
    ]);
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
            operatorKeyword: operator
            name: >>
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: x
              rightParenthesis: )
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: BinaryExpression
                leftOperand: SuperExpression
                  superKeyword: super
                operator: >>
                rightOperand: SimpleIdentifier
                  token: <empty> <synthetic>
              semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_greaterThanOrEqual() {
    var parseResult = parseStringWithErrors(r'''
f() => x >=
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 12, 0),
      error(diag.expectedToken, 9, 2),
    ]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: x
            operator: >=
            rightOperand: SimpleIdentifier
              token: <empty> <synthetic>
          semicolon: ; <synthetic>
''');
  }

  void test_greaterThanOrEqual_super() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int operator >=(x) => super >=
}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 43, 1),
      error(diag.expectedToken, 40, 2),
    ]);
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
            operatorKeyword: operator
            name: >=
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: x
              rightParenthesis: )
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: BinaryExpression
                leftOperand: SuperExpression
                  superKeyword: super
                operator: >=
                rightOperand: SimpleIdentifier
                  token: <empty> <synthetic>
              semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_hat() {
    var parseResult = parseStringWithErrors(r'''
f() => x ^
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 0),
      error(diag.expectedToken, 9, 1),
    ]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: x
            operator: ^
            rightOperand: SimpleIdentifier
              token: <empty> <synthetic>
          semicolon: ; <synthetic>
''');
  }

  void test_hat_super() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int operator ^(x) => super ^
}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 41, 1),
      error(diag.expectedToken, 39, 1),
    ]);
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
            operatorKeyword: operator
            name: ^
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: x
              rightParenthesis: )
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: BinaryExpression
                leftOperand: SuperExpression
                  superKeyword: super
                operator: ^
                rightOperand: SimpleIdentifier
                  token: <empty> <synthetic>
              semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_initializerList_missingComma_assert() {
    var parseResult = parseStringWithErrors(r'''
class Test {
  Test()
    : assert(true)
      assert(true);
}
''');
    parseResult.assertErrors([error(diag.expectedToken, 39, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: Test
      body: BlockClassBody
        leftBracket: {
        members
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: Test
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              AssertInitializer
                assertKeyword: assert
                leftParenthesis: (
                condition: BooleanLiteral
                  literal: true
                rightParenthesis: )
              AssertInitializer
                assertKeyword: assert
                leftParenthesis: (
                condition: BooleanLiteral
                  literal: true
                rightParenthesis: )
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_initializerList_missingComma_field() {
    var parseResult = parseStringWithErrors(r'''
class Test {
  Test()
    : assert(true)
      x = 2;
}
''');
    parseResult.assertErrors([error(diag.expectedToken, 39, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: Test
      body: BlockClassBody
        leftBracket: {
        members
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: Test
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              AssertInitializer
                assertKeyword: assert
                leftParenthesis: (
                condition: BooleanLiteral
                  literal: true
                rightParenthesis: )
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: x
                equals: =
                expression: IntegerLiteral
                  literal: 2
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_initializerList_missingComma_thisField() {
    var parseResult = parseStringWithErrors(r'''
class Test {
  Test()
    : assert(true)
      this.x = 2;
}
''');
    parseResult.assertErrors([error(diag.expectedToken, 39, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: Test
      body: BlockClassBody
        leftBracket: {
        members
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: Test
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              AssertInitializer
                assertKeyword: assert
                leftParenthesis: (
                condition: BooleanLiteral
                  literal: true
                rightParenthesis: )
              ConstructorFieldInitializer
                thisKeyword: this
                period: .
                fieldName: SimpleIdentifier
                  token: x
                equals: =
                expression: IntegerLiteral
                  literal: 2
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_isExpression_missingLeft() {
    var parseResult = parseStringWithErrors(r'''
f() {
  if (is String) {
  }
}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 12, 2)]);
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
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: IsExpression
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  isOperator: is
                  type: NamedType
                    name: String
                rightParenthesis: )
                thenStatement: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_isExpression_missingRight() {
    var parseResult = parseStringWithErrors(r'''
f(x) {
  if (x is ) {}
}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 18, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
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
                thenStatement: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_lessThan() {
    var parseResult = parseStringWithErrors(r'''
f() => x <
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 0),
      error(diag.expectedToken, 9, 1),
    ]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: x
            operator: <
            rightOperand: SimpleIdentifier
              token: <empty> <synthetic>
          semicolon: ; <synthetic>
''');
  }

  void test_lessThan_super() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int operator <(x) => super <
}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 41, 1),
      error(diag.expectedToken, 39, 1),
    ]);
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
            operatorKeyword: operator
            name: <
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: x
              rightParenthesis: )
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: BinaryExpression
                leftOperand: SuperExpression
                  superKeyword: super
                operator: <
                rightOperand: SimpleIdentifier
                  token: <empty> <synthetic>
              semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_lessThanLessThan() {
    var parseResult = parseStringWithErrors(r'''
f() => x <<
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 12, 0),
      error(diag.expectedToken, 9, 2),
    ]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: x
            operator: <<
            rightOperand: SimpleIdentifier
              token: <empty> <synthetic>
          semicolon: ; <synthetic>
''');
  }

  void test_lessThanLessThan_super() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int operator <<(x) => super <<
}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 43, 1),
      error(diag.expectedToken, 40, 2),
    ]);
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
            operatorKeyword: operator
            name: <<
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: x
              rightParenthesis: )
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: BinaryExpression
                leftOperand: SuperExpression
                  superKeyword: super
                operator: <<
                rightOperand: SimpleIdentifier
                  token: <empty> <synthetic>
              semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_lessThanOrEqual() {
    var parseResult = parseStringWithErrors(r'''
f() => x <=
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 12, 0),
      error(diag.expectedToken, 9, 2),
    ]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: x
            operator: <=
            rightOperand: SimpleIdentifier
              token: <empty> <synthetic>
          semicolon: ; <synthetic>
''');
  }

  void test_lessThanOrEqual_super() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int operator <=(x) => super <=
}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 43, 1),
      error(diag.expectedToken, 40, 2),
    ]);
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
            operatorKeyword: operator
            name: <=
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: x
              rightParenthesis: )
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: BinaryExpression
                leftOperand: SuperExpression
                  superKeyword: super
                operator: <=
                rightOperand: SimpleIdentifier
                  token: <empty> <synthetic>
              semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_minus() {
    var parseResult = parseStringWithErrors(r'''
f() => x -
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 0),
      error(diag.expectedToken, 9, 1),
    ]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: x
            operator: -
            rightOperand: SimpleIdentifier
              token: <empty> <synthetic>
          semicolon: ; <synthetic>
''');
  }

  void test_minus_super() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int operator -(x) => super -
}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 41, 1),
      error(diag.expectedToken, 39, 1),
    ]);
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
            operatorKeyword: operator
            name: -
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: x
              rightParenthesis: )
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: BinaryExpression
                leftOperand: SuperExpression
                  superKeyword: super
                operator: -
                rightOperand: SimpleIdentifier
                  token: <empty> <synthetic>
              semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_missingGet() {
    var parseResult = parseStringWithErrors(r'''
class Bar {
  int foo => 0;
}
''');
    parseResult.assertErrors([error(diag.missingMethodParameters, 18, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: Bar
      body: BlockClassBody
        leftBracket: {
        members
          MethodDeclaration
            returnType: NamedType
              name: int
            name: foo
            parameters: FormalParameterList
              leftParenthesis: ( <synthetic>
              rightParenthesis: ) <synthetic>
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
              semicolon: ;
        rightBracket: }
''');
  }

  void test_parameterList_leftParen() {
    var parseResult = parseStringWithErrors(r'''
int f int x, int y) {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 4, 1),
      error(diag.expectedToken, 13, 3),
      error(diag.missingConstFinalVarOrType, 17, 1),
      error(diag.expectedToken, 17, 1),
      error(diag.expectedExecutable, 18, 1),
      error(diag.expectedExecutable, 20, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: f
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: x
          VariableDeclaration
            name: int
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: y
      semicolon: ; <synthetic>
''');
  }

  void test_parentheses_aroundThrow() {
    var parseResult = parseStringWithErrors(r'''
f(x) => x ?? throw 0;
''');
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 13, 5),
      error(diag.expectedToken, 13, 5),
      error(diag.expectedExecutable, 19, 1),
      error(diag.unexpectedToken, 20, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: x
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: x
            operator: ??
            rightOperand: SimpleIdentifier
              token: throw
          semicolon: ; <synthetic>
''');
  }

  void test_percent() {
    var parseResult = parseStringWithErrors(r'''
f() => x %
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 0),
      error(diag.expectedToken, 9, 1),
    ]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: x
            operator: %
            rightOperand: SimpleIdentifier
              token: <empty> <synthetic>
          semicolon: ; <synthetic>
''');
  }

  void test_percent_super() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int operator %(x) => super %
}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 41, 1),
      error(diag.expectedToken, 39, 1),
    ]);
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
            operatorKeyword: operator
            name: %
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: x
              rightParenthesis: )
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: BinaryExpression
                leftOperand: SuperExpression
                  superKeyword: super
                operator: %
                rightOperand: SimpleIdentifier
                  token: <empty> <synthetic>
              semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_plus() {
    var parseResult = parseStringWithErrors(r'''
f() => x +
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 0),
      error(diag.expectedToken, 9, 1),
    ]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: x
            operator: +
            rightOperand: SimpleIdentifier
              token: <empty> <synthetic>
          semicolon: ; <synthetic>
''');
  }

  void test_plus_super() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int operator +(x) => super +
}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 41, 1),
      error(diag.expectedToken, 39, 1),
    ]);
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
            operatorKeyword: operator
            name: +
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: x
              rightParenthesis: )
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: BinaryExpression
                leftOperand: SuperExpression
                  superKeyword: super
                operator: +
                rightOperand: SimpleIdentifier
                  token: <empty> <synthetic>
              semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_prefixedIdentifier() {
    var parseResult = parseStringWithErrors(r'''
f() {
  var v = 'String';
  v.
}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 31, 1),
      error(diag.expectedToken, 29, 1),
    ]);
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
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: v
                      equals: =
                      initializer: SimpleStringLiteral
                        literal: 'String'
                semicolon: ;
              ExpressionStatement
                expression: PrefixedIdentifier
                  prefix: SimpleIdentifier
                    token: v
                  period: .
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_slash() {
    var parseResult = parseStringWithErrors(r'''
f() => x /
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 0),
      error(diag.expectedToken, 9, 1),
    ]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: x
            operator: /
            rightOperand: SimpleIdentifier
              token: <empty> <synthetic>
          semicolon: ; <synthetic>
''');
  }

  void test_slash_super() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int operator /(x) => super /
}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 41, 1),
      error(diag.expectedToken, 39, 1),
    ]);
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
            operatorKeyword: operator
            name: /
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: x
              rightParenthesis: )
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: BinaryExpression
                leftOperand: SuperExpression
                  superKeyword: super
                operator: /
                rightOperand: SimpleIdentifier
                  token: <empty> <synthetic>
              semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_star() {
    var parseResult = parseStringWithErrors(r'''
f() => x *
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 0),
      error(diag.expectedToken, 9, 1),
    ]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: x
            operator: *
            rightOperand: SimpleIdentifier
              token: <empty> <synthetic>
          semicolon: ; <synthetic>
''');
  }

  void test_star_super() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int operator *(x) => super *
}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 41, 1),
      error(diag.expectedToken, 39, 1),
    ]);
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
            operatorKeyword: operator
            name: *
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: x
              rightParenthesis: )
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: BinaryExpression
                leftOperand: SuperExpression
                  superKeyword: super
                operator: *
                rightOperand: SimpleIdentifier
                  token: <empty> <synthetic>
              semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_stringInterpolation_unclosed() {
    var parseResult = parseStringWithErrors(r'''
f() {
  print("${42");
}
''');
    parseResult.assertErrors([
      error(diag.unterminatedStringLiteral, 21, 1),
      error(diag.unterminatedStringLiteral, 23, 1),
      error(diag.expectedToken, 25, 1),
      error(diag.expectedToken, 25, 1),
      error(diag.expectedToken, 19, 3),
      error(diag.expectedToken, 25, 0),
    ]);
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
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: MethodInvocation
                  methodName: SimpleIdentifier
                    token: print
                  argumentList: ArgumentList
                    leftParenthesis: (
                    arguments
                      StringInterpolation
                        elements
                          InterpolationString
                            contents: "
                          InterpolationExpression
                            leftBracket: ${
                            expression: IntegerLiteral
                              literal: 42
                            rightBracket: }
                          InterpolationString
                            contents: " <synthetic>
                        stringValue: null
                    rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: } <synthetic>
''');
  }

  void test_tildeSlash() {
    var parseResult = parseStringWithErrors(r'''
f() => x ~/
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 12, 0),
      error(diag.expectedToken, 9, 2),
    ]);
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: x
            operator: ~/
            rightOperand: SimpleIdentifier
              token: <empty> <synthetic>
          semicolon: ; <synthetic>
''');
  }

  void test_tildeSlash_super() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int operator ~/(x) => super ~/
}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 43, 1),
      error(diag.expectedToken, 40, 2),
    ]);
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
            operatorKeyword: operator
            name: ~/
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: x
              rightParenthesis: )
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: BinaryExpression
                leftOperand: SuperExpression
                  superKeyword: super
                operator: ~/
                rightOperand: SimpleIdentifier
                  token: <empty> <synthetic>
              semicolon: ; <synthetic>
        rightBracket: }
''');
  }
}

/// Test how well the parser recovers when tokens are missing in a parameter
/// list.
@reflectiveTest
class ParameterListTest extends ParserDiagnosticsTest {
  void test_extraComma_named_last() {
    var parseResult = parseStringWithErrors(r'''
f({a, }) {}

''');
    parseResult.assertErrors([]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          leftDelimiter: {
          parameter: RegularFormalParameter
            name: a
          rightDelimiter: }
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_extraComma_named_noLast() {
    var parseResult = parseStringWithErrors(r'''
f({a, , b}) {}

''');
    parseResult.assertErrors([error(diag.missingIdentifier, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          leftDelimiter: {
          parameter: RegularFormalParameter
            name: a
          parameter: RegularFormalParameter
            name: <empty> <synthetic>
          parameter: RegularFormalParameter
            name: b
          rightDelimiter: }
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_extraComma_positional_last() {
    var parseResult = parseStringWithErrors(r'''
f([a, ]) {}

''');
    parseResult.assertErrors([]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          leftDelimiter: [
          parameter: RegularFormalParameter
            name: a
          rightDelimiter: ]
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_extraComma_positional_noLast() {
    var parseResult = parseStringWithErrors(r'''
f([a, , b]) {}

''');
    parseResult.assertErrors([error(diag.missingIdentifier, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          leftDelimiter: [
          parameter: RegularFormalParameter
            name: a
          parameter: RegularFormalParameter
            name: <empty> <synthetic>
          parameter: RegularFormalParameter
            name: b
          rightDelimiter: ]
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_extraComma_required_last() {
    var parseResult = parseStringWithErrors(r'''
f(a, ) {}

''');
    parseResult.assertErrors([]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: a
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_extraComma_required_noLast() {
    var parseResult = parseStringWithErrors(r'''
f(a, , b) {}

''');
    parseResult.assertErrors([error(diag.missingIdentifier, 5, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: a
          parameter: RegularFormalParameter
            name: <empty> <synthetic>
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_fieldFormalParameter_noPeriod_last() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int f;
  C(this);
}

''');
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 23, 4),
    ]);
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
                name: int
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: this
              rightParenthesis: )
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_fieldFormalParameter_noPeriod_notLast() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int f;
  C(this, p);
}

''');
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 23, 4),
    ]);
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
                name: int
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: this
              parameter: RegularFormalParameter
                name: p
              rightParenthesis: )
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_fieldFormalParameter_period_last() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int f;
  C(this.);
}

''');
    parseResult.assertErrors([error(diag.missingIdentifier, 28, 1)]);
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
                name: int
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: FieldFormalParameter
                thisKeyword: this
                period: .
                name: <empty> <synthetic>
              rightParenthesis: )
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_fieldFormalParameter_period_notLast() {
    var parseResult = parseStringWithErrors(r'''
class C {
  int f;
  C(this., p);
}

''');
    parseResult.assertErrors([error(diag.missingIdentifier, 28, 1)]);
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
                name: int
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: FieldFormalParameter
                thisKeyword: this
                period: .
                name: <empty> <synthetic>
              parameter: RegularFormalParameter
                name: p
              rightParenthesis: )
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_incorrectlyTerminatedGroup_named_none() {
    var parseResult = parseStringWithErrors(r'''
f({a: 0) {}

''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          leftDelimiter: {
          parameter: RegularFormalParameter
            name: a
            defaultClause: FormalParameterDefaultClause
              separator: :
              value: IntegerLiteral
                literal: 0
          rightDelimiter: } <synthetic>
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_incorrectlyTerminatedGroup_named_positional() {
    var parseResult = parseStringWithErrors(r'''
f({a: 0]) {}

''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 1),
      error(diag.expectedToken, 7, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          leftDelimiter: {
          parameter: RegularFormalParameter
            name: a
            defaultClause: FormalParameterDefaultClause
              separator: :
              value: IntegerLiteral
                literal: 0
          rightDelimiter: } <synthetic>
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_incorrectlyTerminatedGroup_none_named() {
    var parseResult = parseStringWithErrors(r'''
f(a}) {}

''');
    parseResult.assertErrors([error(diag.expectedToken, 3, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: a
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_incorrectlyTerminatedGroup_none_positional() {
    var parseResult = parseStringWithErrors(r'''
f(a]) {}

''');
    parseResult.assertErrors([error(diag.expectedToken, 3, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: a
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_incorrectlyTerminatedGroup_positional_named() {
    var parseResult = parseStringWithErrors(r'''
f([a = 0}) {}

''');
    parseResult.assertErrors([
      error(diag.expectedToken, 9, 1),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          leftDelimiter: [
          parameter: RegularFormalParameter
            name: a
            defaultClause: FormalParameterDefaultClause
              separator: =
              value: IntegerLiteral
                literal: 0
          rightDelimiter: ] <synthetic>
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_incorrectlyTerminatedGroup_positional_none() {
    // Maybe put in paired_tokens_test.dart.
    var parseResult = parseStringWithErrors(r'''
f([a = 0) {}

''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          leftDelimiter: [
          parameter: RegularFormalParameter
            name: a
            defaultClause: FormalParameterDefaultClause
              separator: =
              value: IntegerLiteral
                literal: 0
          rightDelimiter: ] <synthetic>
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_missingComma() {
    // https://github.com/dart-lang/sdk/issues/22074
    var parseResult = parseStringWithErrors(r'''
g(a, b, c) {}
h(v1, v2, v) {
  g(v1 == v2 || v1 == v 3, true);
}

''');
    parseResult.assertErrors([error(diag.expectedToken, 53, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: g
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: a
          parameter: RegularFormalParameter
            name: b
          parameter: RegularFormalParameter
            name: c
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    FunctionDeclaration
      name: h
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: v1
          parameter: RegularFormalParameter
            name: v2
          parameter: RegularFormalParameter
            name: v
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: MethodInvocation
                  methodName: SimpleIdentifier
                    token: g
                  argumentList: ArgumentList
                    leftParenthesis: (
                    arguments
                      BinaryExpression
                        leftOperand: BinaryExpression
                          leftOperand: SimpleIdentifier
                            token: v1
                          operator: ==
                          rightOperand: SimpleIdentifier
                            token: v2
                        operator: ||
                        rightOperand: BinaryExpression
                          leftOperand: SimpleIdentifier
                            token: v1
                          operator: ==
                          rightOperand: SimpleIdentifier
                            token: v
                      IntegerLiteral
                        literal: 3
                      BooleanLiteral
                        literal: true
                    rightParenthesis: )
                semicolon: ;
            rightBracket: }
''');
  }

  void test_missingDefault_named_last() {
    var parseResult = parseStringWithErrors(r'''
f({a: }) {}

''');
    parseResult.assertErrors([error(diag.missingIdentifier, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          leftDelimiter: {
          parameter: RegularFormalParameter
            name: a
            defaultClause: FormalParameterDefaultClause
              separator: :
              value: SimpleIdentifier
                token: <empty> <synthetic>
          rightDelimiter: }
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_missingDefault_named_notLast() {
    var parseResult = parseStringWithErrors(r'''
f({a: , b}) {}

''');
    parseResult.assertErrors([error(diag.missingIdentifier, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          leftDelimiter: {
          parameter: RegularFormalParameter
            name: a
            defaultClause: FormalParameterDefaultClause
              separator: :
              value: SimpleIdentifier
                token: <empty> <synthetic>
          parameter: RegularFormalParameter
            name: b
          rightDelimiter: }
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_missingDefault_positional_last() {
    var parseResult = parseStringWithErrors(r'''
f([a = ]) {}

''');
    parseResult.assertErrors([error(diag.missingIdentifier, 7, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          leftDelimiter: [
          parameter: RegularFormalParameter
            name: a
            defaultClause: FormalParameterDefaultClause
              separator: =
              value: SimpleIdentifier
                token: <empty> <synthetic>
          rightDelimiter: ]
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_missingDefault_positional_notLast() {
    var parseResult = parseStringWithErrors(r'''
f([a = , b]) {}

''');
    parseResult.assertErrors([error(diag.missingIdentifier, 7, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          leftDelimiter: [
          parameter: RegularFormalParameter
            name: a
            defaultClause: FormalParameterDefaultClause
              separator: =
              value: SimpleIdentifier
                token: <empty> <synthetic>
          parameter: RegularFormalParameter
            name: b
          rightDelimiter: ]
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_multipleGroups_mixed() {
    // TODO(brianwilkerson): Figure out the best way to recover from this.
    var parseResult = parseStringWithErrors(r'''
f([a = 0], {b: 1}) {}

''');
    parseResult.assertErrors([error(diag.expectedToken, 9, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          leftDelimiter: [
          parameter: RegularFormalParameter
            name: a
            defaultClause: FormalParameterDefaultClause
              separator: =
              value: IntegerLiteral
                literal: 0
          rightDelimiter: ]
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_multipleGroups_mixedAndMultiple() {
    // TODO(brianwilkerson): Figure out the best way to recover from this.
    var parseResult = parseStringWithErrors(r'''
f([a = 0], {b: 1}, [c = 2]) {}

''');
    parseResult.assertErrors([error(diag.expectedToken, 9, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          leftDelimiter: [
          parameter: RegularFormalParameter
            name: a
            defaultClause: FormalParameterDefaultClause
              separator: =
              value: IntegerLiteral
                literal: 0
          rightDelimiter: ]
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_multipleGroups_named() {
    var parseResult = parseStringWithErrors(r'''
f({a: 0}, {b: 1}) {}

''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          leftDelimiter: {
          parameter: RegularFormalParameter
            name: a
            defaultClause: FormalParameterDefaultClause
              separator: :
              value: IntegerLiteral
                literal: 0
          rightDelimiter: }
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_multipleGroups_positional() {
    var parseResult = parseStringWithErrors(r'''
f([a = 0], [b = 1]) {}

''');
    parseResult.assertErrors([error(diag.expectedToken, 9, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          leftDelimiter: [
          parameter: RegularFormalParameter
            name: a
            defaultClause: FormalParameterDefaultClause
              separator: =
              value: IntegerLiteral
                literal: 0
          rightDelimiter: ]
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_namedOutsideGroup() {
    var parseResult = parseStringWithErrors(r'''
f(a: 0) {}

''');
    parseResult.assertErrors([error(diag.namedParameterOutsideGroup, 3, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: a
            defaultClause: FormalParameterDefaultClause
              separator: :
              value: IntegerLiteral
                literal: 0
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_positionalOutsideGroup() {
    var parseResult = parseStringWithErrors(r'''
f(a = 0) {}

''');
    parseResult.assertErrors([error(diag.namedParameterOutsideGroup, 4, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: a
            defaultClause: FormalParameterDefaultClause
              separator: =
              value: IntegerLiteral
                literal: 0
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }
}

/// Test how well the parser recovers when tokens are missing in a typedef.
@reflectiveTest
class TypedefTest extends ParserDiagnosticsTest {
  void test_missingFunction() {
    var parseResult = parseStringWithErrors(r'''
typedef Predicate = bool <E>(E element);

''');
    parseResult.assertErrors([error(diag.expectedToken, 28, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: Predicate
      equals: =
      type: GenericFunctionType
        returnType: NamedType
          name: bool
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: E
            rightBracket: >
        functionKeyword: Function <synthetic>
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: E
            name: element
          rightParenthesis: )
      semicolon: ;
''');
  }
}
