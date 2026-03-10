// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnnotationTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AnnotationTest extends ParserDiagnosticsTest {
  void test_annotation_classMember_ampersand_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { @ @annotation var f; }
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 12, 1)]);
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
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: <empty> <synthetic>
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: annotation
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_annotation_classMember_ampersand_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { @ }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 12, 1),
      error(diag.expectedClassMember, 12, 1),
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
        rightBracket: }
''');
  }

  void test_annotation_classMember_ampersand_field() {
    var parseResult = parseStringWithErrors(r'''
class C { @ var f; }
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 12, 3)]);
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
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: <empty> <synthetic>
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_annotation_classMember_ampersand_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { @ const f = 0; }
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 12, 5)]);
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
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: <empty> <synthetic>
            fields: VariableDeclarationList
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_annotation_classMember_ampersand_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { @ final f = 0; }
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 12, 5)]);
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
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: <empty> <synthetic>
            fields: VariableDeclarationList
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_annotation_classMember_ampersand_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { @ int get a => 0; }
''');
    parseResult.assertErrors([]);
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
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: int
            propertyKeyword: get
            name: a
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
              semicolon: ;
        rightBracket: }
''');
  }

  void test_annotation_classMember_ampersand_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { @ int a(b) => 0; }
''');
    parseResult.assertErrors([]);
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
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: int
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: SimpleFormalParameter
                name: b
              rightParenthesis: )
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
              semicolon: ;
        rightBracket: }
''');
  }

  void test_annotation_classMember_ampersand_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { @ void a(b) {} }
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 12, 4)]);
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
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: <empty> <synthetic>
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: SimpleFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_annotation_classMember_ampersand_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { @ set a(b) {} }
''');
    parseResult.assertErrors([]);
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
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: SimpleFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_annotation_classMember_leftParen_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { @a( @annotation var f; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.missingIdentifier, 14, 1),
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
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: a
                arguments: ArgumentList
                  leftParenthesis: (
                  arguments
                    SimpleIdentifier
                      token: <empty> <synthetic>
                  rightParenthesis: ) <synthetic>
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: annotation
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_annotation_classMember_leftParen_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { @a( }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 14, 1),
      error(diag.expectedClassMember, 14, 1),
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
        rightBracket: }
''');
  }

  void test_annotation_classMember_leftParen_field() {
    var parseResult = parseStringWithErrors(r'''
class C { @a( var f; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 1),
      error(diag.missingIdentifier, 14, 3),
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
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: a
                arguments: ArgumentList
                  leftParenthesis: (
                  arguments
                    SimpleIdentifier
                      token: <empty> <synthetic>
                  rightParenthesis: ) <synthetic>
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_annotation_classMember_leftParen_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { @a( const f = 0; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.expectedToken, 20, 1),
      error(diag.missingAssignableSelector, 14, 8),
      error(diag.expectedClassMember, 25, 1),
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
        rightBracket: }
''');
  }

  void test_annotation_classMember_leftParen_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { @a( final f = 0; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.missingIdentifier, 14, 5),
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
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: a
                arguments: ArgumentList
                  leftParenthesis: (
                  arguments
                    SimpleIdentifier
                      token: <empty> <synthetic>
                  rightParenthesis: ) <synthetic>
            fields: VariableDeclarationList
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_annotation_classMember_leftParen_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { @a( int get a => 0; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.expectedToken, 18, 3),
      error(diag.expectedToken, 22, 1),
      error(diag.missingIdentifier, 24, 2),
      error(diag.missingMethodParameters, 24, 2),
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
            metadata
              Annotation
                atSign: @
                name: SimpleIdentifier
                  token: a
                arguments: ArgumentList
                  leftParenthesis: (
                  arguments
                    SimpleIdentifier
                      token: int
                    SimpleIdentifier
                      token: get
                    SimpleIdentifier
                      token: a
                  rightParenthesis: ) <synthetic>
            name: <empty> <synthetic>
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

  void test_annotation_classMember_leftParen_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { @a( int a(b) => 0; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.namedFunctionExpression, 18, 1),
      error(diag.expectedClassMember, 27, 1),
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
        rightBracket: }
''');
  }

  void test_annotation_classMember_leftParen_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { @a( void a(b) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.namedFunctionExpression, 19, 1),
      error(diag.expectedClassMember, 27, 1),
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
        rightBracket: }
''');
  }

  void test_annotation_classMember_leftParen_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { @a( set a(b) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
      error(diag.expectedToken, 18, 1),
      error(diag.namedFunctionExpression, 18, 1),
      error(diag.expectedClassMember, 26, 1),
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
        rightBracket: }
''');
  }

  void test_annotation_local_ampersand_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { @ assert (true); }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 6),
      error(diag.expectedToken, 6, 1),
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
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: BooleanLiteral
                  literal: true
                rightParenthesis: )
                semicolon: ;
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_block() {
    var parseResult = parseStringWithErrors(r'''
f() { @ {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 1),
      error(diag.expectedToken, 6, 1),
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
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_break() {
    var parseResult = parseStringWithErrors(r'''
f() { @ break; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 5),
      error(diag.expectedToken, 6, 1),
      error(diag.breakOutsideOfLoop, 8, 5),
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
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { @ continue; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 8),
      error(diag.expectedToken, 6, 1),
      error(diag.continueOutsideOfLoop, 8, 8),
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
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_do() {
    var parseResult = parseStringWithErrors(r'''
f() { @ do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 2),
      error(diag.expectedToken, 6, 1),
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
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: BooleanLiteral
                  literal: true
                rightParenthesis: )
                semicolon: ;
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { @ }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 1),
      error(diag.expectedToken, 6, 1),
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
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_for() {
    var parseResult = parseStringWithErrors(r'''
f() { @ for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 3),
      error(diag.expectedToken, 6, 1),
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
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    name: x
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: y
                rightParenthesis: )
                body: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_if() {
    var parseResult = parseStringWithErrors(r'''
f() { @ if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 2),
      error(diag.expectedToken, 6, 1),
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
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: BooleanLiteral
                  literal: true
                rightParenthesis: )
                thenStatement: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { @ l: {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 9, 1),
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
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: l
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { @ int f() {} }
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
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              FunctionDeclarationStatement
                functionDeclaration: FunctionDeclaration
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: int
                  name: f
                  functionExpression: FunctionExpression
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

  void test_annotation_local_ampersand_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { @ void f() {} }
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 4)]);
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
              FunctionDeclarationStatement
                functionDeclaration: FunctionDeclaration
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  returnType: NamedType
                    name: void
                  name: f
                  functionExpression: FunctionExpression
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

  void test_annotation_local_ampersand_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { @ var x; }
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 3)]);
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
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  keyword: var
                  variables
                    VariableDeclaration
                      name: x
                semicolon: ;
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_return() {
    var parseResult = parseStringWithErrors(r'''
f() { @ return; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 6),
      error(diag.expectedToken, 6, 1),
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
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { @ switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 6),
      error(diag.expectedToken, 6, 1),
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
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: x
                rightParenthesis: )
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_try() {
    var parseResult = parseStringWithErrors(r'''
f() { @ try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 3),
      error(diag.expectedToken, 6, 1),
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
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_annotation_local_ampersand_while() {
    var parseResult = parseStringWithErrors(r'''
f() { @ while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 5),
      error(diag.expectedToken, 6, 1),
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
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: <empty> <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: BooleanLiteral
                  literal: true
                rightParenthesis: )
                body: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { @a( assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 25, 1),
      error(diag.missingIdentifier, 23, 1),
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
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          FunctionExpressionInvocation
                            function: SimpleIdentifier
                              token: assert
                            argumentList: ArgumentList
                              leftParenthesis: (
                              arguments
                                BooleanLiteral
                                  literal: true
                              rightParenthesis: )
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ;
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_block() {
    var parseResult = parseStringWithErrors(r'''
f() { @a( {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 1),
      error(diag.missingIdentifier, 13, 1),
      error(diag.expectedToken, 11, 1),
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
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          SetOrMapLiteral
                            leftBracket: {
                            rightBracket: }
                            isMap: false
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_break() {
    var parseResult = parseStringWithErrors(r'''
f() { @a( break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 17, 1),
      error(diag.missingIdentifier, 10, 5),
      error(diag.expectedToken, 8, 1),
      error(diag.breakOutsideOfLoop, 10, 5),
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
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          SimpleIdentifier
                            token: <empty> <synthetic>
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { @a( continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 20, 1),
      error(diag.missingIdentifier, 10, 8),
      error(diag.expectedToken, 8, 1),
      error(diag.continueOutsideOfLoop, 10, 8),
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
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          SimpleIdentifier
                            token: <empty> <synthetic>
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_do() {
    var parseResult = parseStringWithErrors(r'''
f() { @a( do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.missingIdentifier, 10, 2),
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
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          SimpleIdentifier
                            token: <empty> <synthetic>
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: BooleanLiteral
                  literal: true
                rightParenthesis: )
                semicolon: ;
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { @a( }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 1),
      error(diag.missingIdentifier, 10, 1),
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
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_for() {
    var parseResult = parseStringWithErrors(r'''
f() { @a( for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.missingIdentifier, 10, 3),
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
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          SimpleIdentifier
                            token: <empty> <synthetic>
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    name: x
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: y
                rightParenthesis: )
                body: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_if() {
    var parseResult = parseStringWithErrors(r'''
f() { @a( if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
      error(diag.missingIdentifier, 10, 2),
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
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          SimpleIdentifier
                            token: <empty> <synthetic>
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: BooleanLiteral
                  literal: true
                rightParenthesis: )
                thenStatement: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { @a( l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 16, 1),
      error(diag.missingIdentifier, 16, 1),
      error(diag.expectedToken, 14, 1),
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
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          NamedExpression
                            name: Label
                              label: SimpleIdentifier
                                token: l
                              colon: :
                            expression: SetOrMapLiteral
                              leftBracket: {
                              rightBracket: }
                              isMap: false
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { @a( int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 1),
      error(diag.namedFunctionExpression, 14, 1),
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
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          FunctionExpression
                            parameters: FormalParameterList
                              leftParenthesis: (
                              rightParenthesis: )
                            body: BlockFunctionBody
                              block: Block
                                leftBracket: {
                                rightBracket: }
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { @a( void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.namedFunctionExpression, 15, 1),
      error(diag.missingIdentifier, 22, 1),
      error(diag.expectedToken, 20, 1),
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
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          FunctionExpression
                            parameters: FormalParameterList
                              leftParenthesis: (
                              rightParenthesis: )
                            body: BlockFunctionBody
                              block: Block
                                leftBracket: {
                                rightBracket: }
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { @a( var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 17, 1),
      error(diag.missingIdentifier, 10, 3),
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
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          SimpleIdentifier
                            token: <empty> <synthetic>
                        rightParenthesis: ) <synthetic>
                  keyword: var
                  variables
                    VariableDeclaration
                      name: x
                semicolon: ;
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_return() {
    var parseResult = parseStringWithErrors(r'''
f() { @a( return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 1),
      error(diag.unexpectedToken, 10, 6),
      error(diag.missingIdentifier, 16, 1),
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
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          SimpleIdentifier
                            token: <empty> <synthetic>
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ;
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { @a( switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 1),
      error(diag.missingIdentifier, 24, 1),
      error(diag.expectedToken, 22, 1),
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
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          SwitchExpression
                            switchKeyword: switch
                            leftParenthesis: (
                            expression: SimpleIdentifier
                              token: x
                            rightParenthesis: )
                            leftBracket: {
                            rightBracket: }
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_try() {
    var parseResult = parseStringWithErrors(r'''
f() { @a( try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.missingIdentifier, 10, 3),
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
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          SimpleIdentifier
                            token: <empty> <synthetic>
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_annotation_local_leftParen_while() {
    var parseResult = parseStringWithErrors(r'''
f() { @a( while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
      error(diag.missingIdentifier, 10, 5),
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
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  metadata
                    Annotation
                      atSign: @
                      name: SimpleIdentifier
                        token: a
                      arguments: ArgumentList
                        leftParenthesis: (
                        arguments
                          SimpleIdentifier
                            token: <empty> <synthetic>
                        rightParenthesis: ) <synthetic>
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: BooleanLiteral
                  literal: true
                rightParenthesis: )
                body: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_annotation_topLevel_ampersand_class() {
    var parseResult = parseStringWithErrors(r'''
@ class A {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 2, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: <empty> <synthetic>
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_annotation_topLevel_ampersand_const() {
    var parseResult = parseStringWithErrors(r'''
@ const a = 0;
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 2, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: <empty> <synthetic>
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: IntegerLiteral
              literal: 0
      semicolon: ;
''');
  }

  void test_annotation_topLevel_ampersand_enum() {
    var parseResult = parseStringWithErrors(r'''
@ enum E { v }
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 2, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: <empty> <synthetic>
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: EnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_annotation_topLevel_ampersand_eof() {
    var parseResult = parseStringWithErrors(r'''
@
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 2, 0),
      error(diag.expectedExecutable, 2, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_annotation_topLevel_ampersand_final() {
    var parseResult = parseStringWithErrors(r'''
@ final a = 0;
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 2, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: <empty> <synthetic>
      variables: VariableDeclarationList
        keyword: final
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: IntegerLiteral
              literal: 0
      semicolon: ;
''');
  }

  void test_annotation_topLevel_ampersand_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
@ int f() {}
''');
    parseResult.assertErrors([]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: int
      name: f
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

  void test_annotation_topLevel_ampersand_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
@ void f() {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 2, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: <empty> <synthetic>
      returnType: NamedType
        name: void
      name: f
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

  void test_annotation_topLevel_ampersand_getter() {
    var parseResult = parseStringWithErrors(r'''
@ int get a => 0;
''');
    parseResult.assertErrors([]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: int
      propertyKeyword: get
      name: a
      functionExpression: FunctionExpression
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IntegerLiteral
            literal: 0
          semicolon: ;
''');
  }

  void test_annotation_topLevel_ampersand_mixin() {
    var parseResult = parseStringWithErrors(r'''
@ mixin M {}
''');
    parseResult.assertErrors([error(diag.missingFunctionParameters, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: mixin
      name: M
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

  void test_annotation_topLevel_ampersand_setter() {
    var parseResult = parseStringWithErrors(r'''
@ set a(b) {}
''');
    parseResult.assertErrors([]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: set
      name: a
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_annotation_topLevel_ampersand_typedef() {
    var parseResult = parseStringWithErrors(r'''
@ typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 10, 1),
      error(diag.expectedToken, 14, 1),
      error(diag.missingFunctionBody, 30, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: typedef
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: A
            equals: =
            initializer: SimpleIdentifier
              token: B
      semicolon: ; <synthetic>
    FunctionDeclaration
      name: Function
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            name: C
          parameter: SimpleFormalParameter
            name: D
          rightParenthesis: )
        body: EmptyFunctionBody
          semicolon: ;
''');
  }

  void test_annotation_topLevel_ampersand_var() {
    var parseResult = parseStringWithErrors(r'''
@ var a;
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 2, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: <empty> <synthetic>
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_annotation_topLevel_leftParen_class() {
    var parseResult = parseStringWithErrors(r'''
@a( class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 15, 1),
      error(diag.expectedIdentifierButGotKeyword, 4, 5),
      error(diag.expectedToken, 10, 1),
      error(diag.expectedToken, 12, 1),
      error(diag.expectedExecutable, 15, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_annotation_topLevel_leftParen_const() {
    var parseResult = parseStringWithErrors(r'''
@a( const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 17, 1),
      error(diag.expectedToken, 10, 1),
      error(diag.missingAssignableSelector, 4, 8),
      error(diag.unexpectedToken, 15, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_annotation_topLevel_leftParen_enum() {
    var parseResult = parseStringWithErrors(r'''
@a( enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 17, 1),
      error(diag.expectedIdentifierButGotKeyword, 4, 4),
      error(diag.expectedToken, 9, 1),
      error(diag.expectedToken, 11, 1),
      error(diag.expectedExecutable, 17, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_annotation_topLevel_leftParen_eof() {
    var parseResult = parseStringWithErrors(r'''
@a(
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 4, 1),
      error(diag.expectedExecutable, 4, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_annotation_topLevel_leftParen_final() {
    var parseResult = parseStringWithErrors(r'''
@a( final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 17, 1),
      error(diag.missingIdentifier, 4, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: a
          arguments: ArgumentList
            leftParenthesis: (
            arguments
              SimpleIdentifier
                token: <empty> <synthetic>
            rightParenthesis: ) <synthetic>
      variables: VariableDeclarationList
        keyword: final
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: IntegerLiteral
              literal: 0
      semicolon: ;
''');
  }

  void test_annotation_topLevel_leftParen_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
@a( int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 15, 1),
      error(diag.namedFunctionExpression, 8, 1),
      error(diag.expectedExecutable, 15, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_annotation_topLevel_leftParen_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
@a( void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 16, 1),
      error(diag.namedFunctionExpression, 9, 1),
      error(diag.expectedExecutable, 16, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_annotation_topLevel_leftParen_getter() {
    var parseResult = parseStringWithErrors(r'''
@a( int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 20, 1),
      error(diag.expectedToken, 8, 3),
      error(diag.expectedToken, 12, 1),
      error(diag.expectedExecutable, 14, 2),
      error(diag.expectedExecutable, 17, 1),
      error(diag.unexpectedToken, 18, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_annotation_topLevel_leftParen_mixin() {
    var parseResult = parseStringWithErrors(r'''
@a( mixin M {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 15, 1),
      error(diag.expectedToken, 10, 1),
      error(diag.expectedToken, 12, 1),
      error(diag.expectedExecutable, 15, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_annotation_topLevel_leftParen_setter() {
    var parseResult = parseStringWithErrors(r'''
@a( set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 16, 1),
      error(diag.expectedToken, 8, 1),
      error(diag.namedFunctionExpression, 8, 1),
      error(diag.expectedExecutable, 16, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_annotation_topLevel_leftParen_typedef() {
    var parseResult = parseStringWithErrors(r'''
@a( typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.expectedToken, 12, 1),
      error(diag.expectedToken, 18, 8),
      error(diag.unexpectedToken, 32, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
''');
  }

  void test_annotation_topLevel_leftParen_var() {
    var parseResult = parseStringWithErrors(r'''
@a( var a;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 11, 1),
      error(diag.missingIdentifier, 4, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: a
          arguments: ArgumentList
            leftParenthesis: (
            arguments
              SimpleIdentifier
                token: <empty> <synthetic>
            rightParenthesis: ) <synthetic>
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }
}
