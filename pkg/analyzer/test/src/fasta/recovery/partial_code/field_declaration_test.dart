// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MethodTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MethodTest extends ParserDiagnosticsTest {
  void test_field_declaration_const_equals_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { const f = @annotation var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 20, 1),
      error(diag.expectedToken, 18, 1),
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_const_equals_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { const f = }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 20, 1),
      error(diag.expectedToken, 18, 1),
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_const_equals_field() {
    var parseResult = parseStringWithErrors(r'''
class C { const f = var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 20, 3),
      error(diag.expectedToken, 18, 1),
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_const_equals_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { const f = const f = 0; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
      error(diag.missingAssignableSelector, 20, 8),
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: AssignmentExpression
                    leftHandSide: InstanceCreationExpression
                      keyword: const
                      constructorName: ConstructorName
                        type: NamedType
                          name: f
                      argumentList: ArgumentList
                        leftParenthesis: ( <synthetic>
                        rightParenthesis: ) <synthetic>
                    operator: =
                    rightHandSide: IntegerLiteral
                      literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_const_equals_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { const f = final f = 0; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 20, 5),
      error(diag.expectedToken, 18, 1),
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_const_equals_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { const f = int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 3)]);
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
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: int
            semicolon: ; <synthetic>
          MethodDeclaration
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

  void test_field_declaration_const_equals_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { const f = int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.namedFunctionExpression, 24, 1)]);
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
                  name: f
                  equals: =
                  initializer: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      parameter: RegularFormalParameter
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

  void test_field_declaration_const_equals_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { const f = void a(b) {} }
''');
    parseResult.assertErrors([
      error(diag.namedFunctionExpression, 25, 1),
      error(diag.expectedToken, 31, 1),
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      parameter: RegularFormalParameter
                        name: b
                      rightParenthesis: )
                    body: BlockFunctionBody
                      block: Block
                        leftBracket: {
                        rightBracket: }
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_const_equals_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { const f = set a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 3)]);
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
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: set
            semicolon: ; <synthetic>
          MethodDeclaration
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_const_initializer_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { const f = 0 @annotation var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_const_initializer_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { const f = 0 }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_const_initializer_field() {
    var parseResult = parseStringWithErrors(r'''
class C { const f = 0 var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_const_initializer_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { const f = 0 const f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_const_initializer_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { const f = 0 final f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_const_initializer_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { const f = 0 int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: int
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

  void test_field_declaration_const_initializer_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { const f = 0 int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: int
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_const_initializer_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { const f = 0 void a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_const_initializer_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { const f = 0 set a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_const_name_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { const f @annotation var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
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
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_const_name_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { const f }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
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
                  name: f
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_const_name_field() {
    var parseResult = parseStringWithErrors(r'''
class C { const f var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
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
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_const_name_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { const f const f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
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
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_const_name_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { const f final f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
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
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_const_name_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { const f int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 18, 3)]);
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
              type: NamedType
                name: f
              variables
                VariableDeclaration
                  name: int
            semicolon: ; <synthetic>
          MethodDeclaration
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

  void test_field_declaration_const_name_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { const f int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 18, 3)]);
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
              type: NamedType
                name: f
              variables
                VariableDeclaration
                  name: int
            semicolon: ; <synthetic>
          MethodDeclaration
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_const_name_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { const f void a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
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
                  name: f
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_const_name_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { const f set a(b) {} }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 10, 5)]);
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
              name: f
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_const_noName_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { const @annotation var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 16, 1),
      error(diag.expectedToken, 10, 5),
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
              keyword: const
              variables
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_const_noName_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { const }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 16, 1),
      error(diag.expectedToken, 10, 5),
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
              keyword: const
              variables
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_const_noName_field() {
    var parseResult = parseStringWithErrors(r'''
class C { const var f; }
''');
    parseResult.assertErrors([error(diag.conflictingModifiers, 16, 3)]);
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
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_const_noName_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { const const f = 0; }
''');
    parseResult.assertErrors([error(diag.duplicatedModifier, 16, 5)]);
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_const_noName_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { const final f = 0; }
''');
    parseResult.assertErrors([error(diag.constAndFinal, 16, 5)]);
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_const_noName_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { const int get a => 0; }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 10, 5)]);
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

  void test_field_declaration_const_noName_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { const int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.constMethod, 10, 5)]);
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
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_const_noName_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { const void a(b) {} }
''');
    parseResult.assertErrors([error(diag.constMethod, 10, 5)]);
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
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_const_noName_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { const set a(b) {} }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 10, 5)]);
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
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_final_equals_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { final f = @annotation var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 20, 1),
      error(diag.expectedToken, 18, 1),
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_final_equals_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { final f = }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 20, 1),
      error(diag.expectedToken, 18, 1),
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_final_equals_field() {
    var parseResult = parseStringWithErrors(r'''
class C { final f = var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 20, 3),
      error(diag.expectedToken, 18, 1),
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_final_equals_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { final f = const f = 0; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
      error(diag.missingAssignableSelector, 20, 8),
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: AssignmentExpression
                    leftHandSide: InstanceCreationExpression
                      keyword: const
                      constructorName: ConstructorName
                        type: NamedType
                          name: f
                      argumentList: ArgumentList
                        leftParenthesis: ( <synthetic>
                        rightParenthesis: ) <synthetic>
                    operator: =
                    rightHandSide: IntegerLiteral
                      literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_final_equals_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { final f = final f = 0; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 20, 5),
      error(diag.expectedToken, 18, 1),
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_final_equals_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { final f = int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 3)]);
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
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: int
            semicolon: ; <synthetic>
          MethodDeclaration
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

  void test_field_declaration_final_equals_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { final f = int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.namedFunctionExpression, 24, 1)]);
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
                  name: f
                  equals: =
                  initializer: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      parameter: RegularFormalParameter
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

  void test_field_declaration_final_equals_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { final f = void a(b) {} }
''');
    parseResult.assertErrors([
      error(diag.namedFunctionExpression, 25, 1),
      error(diag.expectedToken, 31, 1),
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      parameter: RegularFormalParameter
                        name: b
                      rightParenthesis: )
                    body: BlockFunctionBody
                      block: Block
                        leftBracket: {
                        rightBracket: }
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_final_equals_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { final f = set a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 3)]);
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
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: set
            semicolon: ; <synthetic>
          MethodDeclaration
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_final_initializer_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { final f = 0 @annotation var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_final_initializer_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { final f = 0 }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_final_initializer_field() {
    var parseResult = parseStringWithErrors(r'''
class C { final f = 0 var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_final_initializer_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { final f = 0 const f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_final_initializer_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { final f = 0 final f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_final_initializer_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { final f = 0 int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: int
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

  void test_field_declaration_final_initializer_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { final f = 0 int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: int
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_final_initializer_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { final f = 0 void a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_final_initializer_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { final f = 0 set a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_final_name_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { final f @annotation var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
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
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_final_name_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { final f }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
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
                  name: f
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_final_name_field() {
    var parseResult = parseStringWithErrors(r'''
class C { final f var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
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
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_final_name_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { final f const f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
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
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_final_name_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { final f final f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
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
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_final_name_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { final f int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 18, 3)]);
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
                name: f
              variables
                VariableDeclaration
                  name: int
            semicolon: ; <synthetic>
          MethodDeclaration
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

  void test_field_declaration_final_name_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { final f int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 18, 3)]);
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
                name: f
              variables
                VariableDeclaration
                  name: int
            semicolon: ; <synthetic>
          MethodDeclaration
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_final_name_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { final f void a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
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
                  name: f
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_final_name_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { final f set a(b) {} }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 10, 5)]);
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
              name: f
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_final_noName_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { final @annotation var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 16, 1),
      error(diag.expectedToken, 10, 5),
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
              keyword: final
              variables
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_final_noName_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { final }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 16, 1),
      error(diag.expectedToken, 10, 5),
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
              keyword: final
              variables
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_final_noName_field() {
    var parseResult = parseStringWithErrors(r'''
class C { final var f; }
''');
    parseResult.assertErrors([error(diag.finalAndVar, 16, 3)]);
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
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_final_noName_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { final const f = 0; }
''');
    parseResult.assertErrors([error(diag.constAndFinal, 16, 5)]);
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_final_noName_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { final final f = 0; }
''');
    parseResult.assertErrors([error(diag.duplicatedModifier, 16, 5)]);
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_final_noName_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { final int get a => 0; }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 10, 5)]);
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

  void test_field_declaration_final_noName_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { final int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 10, 5)]);
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
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_final_noName_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { final void a(b) {} }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 10, 5)]);
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
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_final_noName_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { final set a(b) {} }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 10, 5)]);
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
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_const_equals_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f = @annotation var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 27, 1),
      error(diag.expectedToken, 25, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_static_const_equals_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f = }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 27, 1),
      error(diag.expectedToken, 25, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_const_equals_field() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f = var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 27, 3),
      error(diag.expectedToken, 25, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_static_const_equals_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f = const f = 0; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.missingAssignableSelector, 27, 8),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: AssignmentExpression
                    leftHandSide: InstanceCreationExpression
                      keyword: const
                      constructorName: ConstructorName
                        type: NamedType
                          name: f
                      argumentList: ArgumentList
                        leftParenthesis: ( <synthetic>
                        rightParenthesis: ) <synthetic>
                    operator: =
                    rightHandSide: IntegerLiteral
                      literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_static_const_equals_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f = final f = 0; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 27, 5),
      error(diag.expectedToken, 25, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_static_const_equals_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f = int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 27, 3)]);
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: int
            semicolon: ; <synthetic>
          MethodDeclaration
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

  void test_field_declaration_static_const_equals_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f = int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.namedFunctionExpression, 31, 1)]);
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      parameter: RegularFormalParameter
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

  void test_field_declaration_static_const_equals_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f = void a(b) {} }
''');
    parseResult.assertErrors([
      error(diag.namedFunctionExpression, 32, 1),
      error(diag.expectedToken, 38, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      parameter: RegularFormalParameter
                        name: b
                      rightParenthesis: )
                    body: BlockFunctionBody
                      block: Block
                        leftBracket: {
                        rightBracket: }
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_const_equals_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f = set a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 27, 3)]);
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: set
            semicolon: ; <synthetic>
          MethodDeclaration
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_const_initializer_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f = 0 @annotation var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 27, 1)]);
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_static_const_initializer_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f = 0 }
''');
    parseResult.assertErrors([error(diag.expectedToken, 27, 1)]);
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_const_initializer_field() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f = 0 var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 27, 1)]);
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_static_const_initializer_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f = 0 const f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 27, 1)]);
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_static_const_initializer_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f = 0 final f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 27, 1)]);
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_static_const_initializer_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f = 0 int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 27, 1)]);
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: int
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

  void test_field_declaration_static_const_initializer_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f = 0 int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 27, 1)]);
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: int
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_static_const_initializer_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f = 0 void a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 27, 1)]);
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_const_initializer_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f = 0 set a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 27, 1)]);
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_const_name_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f @annotation var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_static_const_name_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_const_name_field() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_static_const_name_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f const f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_static_const_name_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f final f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_static_const_name_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 25, 3)]);
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
              keyword: const
              type: NamedType
                name: f
              variables
                VariableDeclaration
                  name: int
            semicolon: ; <synthetic>
          MethodDeclaration
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

  void test_field_declaration_static_const_name_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 25, 3)]);
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
              keyword: const
              type: NamedType
                name: f
              variables
                VariableDeclaration
                  name: int
            semicolon: ; <synthetic>
          MethodDeclaration
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_static_const_name_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f void a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_const_name_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { static const f set a(b) {} }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 17, 5)]);
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
            modifierKeyword: static
            returnType: NamedType
              name: f
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_const_noName_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { static const @annotation var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 23, 1),
      error(diag.expectedToken, 17, 5),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: const
              variables
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_static_const_noName_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { static const }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 23, 1),
      error(diag.expectedToken, 17, 5),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: const
              variables
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_const_noName_field() {
    var parseResult = parseStringWithErrors(r'''
class C { static const var f; }
''');
    parseResult.assertErrors([error(diag.conflictingModifiers, 23, 3)]);
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_static_const_noName_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { static const const f = 0; }
''');
    parseResult.assertErrors([error(diag.duplicatedModifier, 23, 5)]);
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

  void test_field_declaration_static_const_noName_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { static const final f = 0; }
''');
    parseResult.assertErrors([error(diag.constAndFinal, 23, 5)]);
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

  void test_field_declaration_static_const_noName_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { static const int get a => 0; }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 17, 5)]);
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
            modifierKeyword: static
            returnType: NamedType
              name: int
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

  void test_field_declaration_static_const_noName_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static const int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.constMethod, 17, 5)]);
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
            modifierKeyword: static
            returnType: NamedType
              name: int
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_static_const_noName_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static const void a(b) {} }
''');
    parseResult.assertErrors([error(diag.constMethod, 17, 5)]);
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
            modifierKeyword: static
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_const_noName_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { static const set a(b) {} }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 17, 5)]);
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
            modifierKeyword: static
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_final_equals_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f = @annotation var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 27, 1),
      error(diag.expectedToken, 25, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_static_final_equals_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f = }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 27, 1),
      error(diag.expectedToken, 25, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_final_equals_field() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f = var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 27, 3),
      error(diag.expectedToken, 25, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_static_final_equals_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f = const f = 0; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.missingAssignableSelector, 27, 8),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: AssignmentExpression
                    leftHandSide: InstanceCreationExpression
                      keyword: const
                      constructorName: ConstructorName
                        type: NamedType
                          name: f
                      argumentList: ArgumentList
                        leftParenthesis: ( <synthetic>
                        rightParenthesis: ) <synthetic>
                    operator: =
                    rightHandSide: IntegerLiteral
                      literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_static_final_equals_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f = final f = 0; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 27, 5),
      error(diag.expectedToken, 25, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_static_final_equals_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f = int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 27, 3)]);
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: int
            semicolon: ; <synthetic>
          MethodDeclaration
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

  void test_field_declaration_static_final_equals_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f = int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.namedFunctionExpression, 31, 1)]);
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      parameter: RegularFormalParameter
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

  void test_field_declaration_static_final_equals_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f = void a(b) {} }
''');
    parseResult.assertErrors([
      error(diag.namedFunctionExpression, 32, 1),
      error(diag.expectedToken, 38, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      parameter: RegularFormalParameter
                        name: b
                      rightParenthesis: )
                    body: BlockFunctionBody
                      block: Block
                        leftBracket: {
                        rightBracket: }
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_final_equals_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f = set a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 27, 3)]);
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: set
            semicolon: ; <synthetic>
          MethodDeclaration
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_final_initializer_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f = 0 @annotation var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 27, 1)]);
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_static_final_initializer_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f = 0 }
''');
    parseResult.assertErrors([error(diag.expectedToken, 27, 1)]);
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_final_initializer_field() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f = 0 var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 27, 1)]);
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_static_final_initializer_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f = 0 const f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 27, 1)]);
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_static_final_initializer_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f = 0 final f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 27, 1)]);
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_static_final_initializer_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f = 0 int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 27, 1)]);
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: int
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

  void test_field_declaration_static_final_initializer_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f = 0 int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 27, 1)]);
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: int
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_static_final_initializer_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f = 0 void a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 27, 1)]);
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_final_initializer_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f = 0 set a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 27, 1)]);
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_final_name_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f @annotation var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_static_final_name_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_final_name_field() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_static_final_name_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f const f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_static_final_name_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f final f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_static_final_name_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 25, 3)]);
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
              keyword: final
              type: NamedType
                name: f
              variables
                VariableDeclaration
                  name: int
            semicolon: ; <synthetic>
          MethodDeclaration
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

  void test_field_declaration_static_final_name_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 25, 3)]);
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
              keyword: final
              type: NamedType
                name: f
              variables
                VariableDeclaration
                  name: int
            semicolon: ; <synthetic>
          MethodDeclaration
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_static_final_name_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f void a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_final_name_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { static final f set a(b) {} }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 17, 5)]);
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
            modifierKeyword: static
            returnType: NamedType
              name: f
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_final_noName_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { static final @annotation var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 23, 1),
      error(diag.expectedToken, 17, 5),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: final
              variables
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_static_final_noName_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { static final }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 23, 1),
      error(diag.expectedToken, 17, 5),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: final
              variables
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_final_noName_field() {
    var parseResult = parseStringWithErrors(r'''
class C { static final var f; }
''');
    parseResult.assertErrors([error(diag.finalAndVar, 23, 3)]);
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_static_final_noName_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { static final const f = 0; }
''');
    parseResult.assertErrors([error(diag.constAndFinal, 23, 5)]);
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

  void test_field_declaration_static_final_noName_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { static final final f = 0; }
''');
    parseResult.assertErrors([error(diag.duplicatedModifier, 23, 5)]);
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

  void test_field_declaration_static_final_noName_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { static final int get a => 0; }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 17, 5)]);
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
            modifierKeyword: static
            returnType: NamedType
              name: int
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

  void test_field_declaration_static_final_noName_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static final int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 17, 5)]);
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
            modifierKeyword: static
            returnType: NamedType
              name: int
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_static_final_noName_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static final void a(b) {} }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 17, 5)]);
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
            modifierKeyword: static
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_final_noName_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { static final set a(b) {} }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 17, 5)]);
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
            modifierKeyword: static
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_type_equals_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f = @annotation var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 23, 1),
      error(diag.expectedToken, 21, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              type: NamedType
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_static_type_equals_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f = }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 23, 1),
      error(diag.expectedToken, 21, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              type: NamedType
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_type_equals_field() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f = var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 23, 3),
      error(diag.expectedToken, 21, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              type: NamedType
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_static_type_equals_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f = const f = 0; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.missingAssignableSelector, 23, 8),
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
            staticKeyword: static
            fields: VariableDeclarationList
              type: NamedType
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: AssignmentExpression
                    leftHandSide: InstanceCreationExpression
                      keyword: const
                      constructorName: ConstructorName
                        type: NamedType
                          name: f
                      argumentList: ArgumentList
                        leftParenthesis: ( <synthetic>
                        rightParenthesis: ) <synthetic>
                    operator: =
                    rightHandSide: IntegerLiteral
                      literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_static_type_equals_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f = final f = 0; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 23, 5),
      error(diag.expectedToken, 21, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              type: NamedType
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_static_type_equals_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f = int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 3)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: int
            semicolon: ; <synthetic>
          MethodDeclaration
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

  void test_field_declaration_static_type_equals_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f = int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.namedFunctionExpression, 27, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      parameter: RegularFormalParameter
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

  void test_field_declaration_static_type_equals_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f = void a(b) {} }
''');
    parseResult.assertErrors([
      error(diag.namedFunctionExpression, 28, 1),
      error(diag.expectedToken, 34, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              type: NamedType
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      parameter: RegularFormalParameter
                        name: b
                      rightParenthesis: )
                    body: BlockFunctionBody
                      block: Block
                        leftBracket: {
                        rightBracket: }
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_type_equals_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f = set a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 3)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: set
            semicolon: ; <synthetic>
          MethodDeclaration
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_type_initializer_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f = 0 @annotation var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_static_type_initializer_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f = 0 }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_type_initializer_field() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f = 0 var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_static_type_initializer_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f = 0 const f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_static_type_initializer_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f = 0 final f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_static_type_initializer_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f = 0 int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: int
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

  void test_field_declaration_static_type_initializer_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f = 0 int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: int
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_static_type_initializer_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f = 0 void a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_type_initializer_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f = 0 set a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_type_name_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f @annotation var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 19, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_static_type_name_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f }
''');
    parseResult.assertErrors([error(diag.expectedToken, 19, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_type_name_field() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 19, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_static_type_name_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f const f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 19, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_static_type_name_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f final f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 19, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_static_type_name_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 19, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: int
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

  void test_field_declaration_static_type_name_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 19, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: int
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_static_type_name_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f void a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 19, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_type_name_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { static A f set a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 19, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          MethodDeclaration
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_type_noName_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { static A @annotation var f; }
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 17, 1),
      error(diag.expectedToken, 17, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              variables
                VariableDeclaration
                  name: A
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_static_type_noName_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { static A }
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 17, 1),
      error(diag.expectedToken, 17, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              variables
                VariableDeclaration
                  name: A
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_type_noName_field() {
    var parseResult = parseStringWithErrors(r'''
class C { static A var f; }
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 17, 1),
      error(diag.expectedToken, 17, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              variables
                VariableDeclaration
                  name: A
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_static_type_noName_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { static A const f = 0; }
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 17, 1),
      error(diag.expectedToken, 17, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              variables
                VariableDeclaration
                  name: A
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_static_type_noName_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { static A final f = 0; }
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 17, 1),
      error(diag.expectedToken, 17, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              variables
                VariableDeclaration
                  name: A
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_static_type_noName_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { static A int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 19, 3)]);
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
                name: A
              variables
                VariableDeclaration
                  name: int
            semicolon: ; <synthetic>
          MethodDeclaration
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

  void test_field_declaration_static_type_noName_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static A int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 19, 3)]);
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
                name: A
              variables
                VariableDeclaration
                  name: int
            semicolon: ; <synthetic>
          MethodDeclaration
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_static_type_noName_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static A void a(b) {} }
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 17, 1),
      error(diag.expectedToken, 17, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              variables
                VariableDeclaration
                  name: A
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_type_noName_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { static A set a(b) {} }
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_var_equals_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f = @annotation var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 25, 1),
      error(diag.expectedToken, 23, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_static_var_equals_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f = }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 25, 1),
      error(diag.expectedToken, 23, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_var_equals_field() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f = var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 25, 3),
      error(diag.expectedToken, 23, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_static_var_equals_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f = const f = 0; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.missingAssignableSelector, 25, 8),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: AssignmentExpression
                    leftHandSide: InstanceCreationExpression
                      keyword: const
                      constructorName: ConstructorName
                        type: NamedType
                          name: f
                      argumentList: ArgumentList
                        leftParenthesis: ( <synthetic>
                        rightParenthesis: ) <synthetic>
                    operator: =
                    rightHandSide: IntegerLiteral
                      literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_static_var_equals_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f = final f = 0; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 25, 5),
      error(diag.expectedToken, 23, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_static_var_equals_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f = int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 25, 3)]);
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: int
            semicolon: ; <synthetic>
          MethodDeclaration
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

  void test_field_declaration_static_var_equals_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f = int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.namedFunctionExpression, 29, 1)]);
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      parameter: RegularFormalParameter
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

  void test_field_declaration_static_var_equals_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f = void a(b) {} }
''');
    parseResult.assertErrors([
      error(diag.namedFunctionExpression, 30, 1),
      error(diag.expectedToken, 36, 1),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      parameter: RegularFormalParameter
                        name: b
                      rightParenthesis: )
                    body: BlockFunctionBody
                      block: Block
                        leftBracket: {
                        rightBracket: }
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_var_equals_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f = set a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 25, 3)]);
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: set
            semicolon: ; <synthetic>
          MethodDeclaration
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_var_initializer_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f = 0 @annotation var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 25, 1)]);
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_static_var_initializer_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f = 0 }
''');
    parseResult.assertErrors([error(diag.expectedToken, 25, 1)]);
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_var_initializer_field() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f = 0 var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 25, 1)]);
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_static_var_initializer_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f = 0 const f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 25, 1)]);
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_static_var_initializer_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f = 0 final f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 25, 1)]);
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_static_var_initializer_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f = 0 int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 25, 1)]);
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: int
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

  void test_field_declaration_static_var_initializer_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f = 0 int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 25, 1)]);
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: int
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_static_var_initializer_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f = 0 void a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 25, 1)]);
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_var_initializer_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f = 0 set a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 25, 1)]);
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_var_name_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f @annotation var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_static_var_name_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f }
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_var_name_field() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_static_var_name_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f const f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_static_var_name_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f final f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_static_var_name_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f int get a => 0; }
''');
    parseResult.assertErrors([
      error(diag.varAndType, 17, 3),
      error(diag.expectedToken, 23, 3),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: var
              type: NamedType
                name: f
              variables
                VariableDeclaration
                  name: int
            semicolon: ; <synthetic>
          MethodDeclaration
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

  void test_field_declaration_static_var_name_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f int a(b) => 0; }
''');
    parseResult.assertErrors([
      error(diag.varAndType, 17, 3),
      error(diag.expectedToken, 23, 3),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: var
              type: NamedType
                name: f
              variables
                VariableDeclaration
                  name: int
            semicolon: ; <synthetic>
          MethodDeclaration
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_static_var_name_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f void a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_var_name_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { static var f set a(b) {} }
''');
    parseResult.assertErrors([error(diag.varReturnType, 17, 3)]);
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
            modifierKeyword: static
            returnType: NamedType
              name: f
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_var_noName_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { static var @annotation var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 1),
      error(diag.expectedToken, 17, 3),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_static_var_noName_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { static var }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 1),
      error(diag.expectedToken, 17, 3),
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
            staticKeyword: static
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_var_noName_field() {
    var parseResult = parseStringWithErrors(r'''
class C { static var var f; }
''');
    parseResult.assertErrors([error(diag.duplicatedModifier, 21, 3)]);
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_static_var_noName_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { static var const f = 0; }
''');
    parseResult.assertErrors([error(diag.conflictingModifiers, 21, 5)]);
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
              keyword: var
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

  void test_field_declaration_static_var_noName_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { static var final f = 0; }
''');
    parseResult.assertErrors([error(diag.finalAndVar, 21, 5)]);
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
              keyword: var
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

  void test_field_declaration_static_var_noName_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { static var int get a => 0; }
''');
    parseResult.assertErrors([error(diag.varReturnType, 17, 3)]);
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
            modifierKeyword: static
            returnType: NamedType
              name: int
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

  void test_field_declaration_static_var_noName_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static var int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.varReturnType, 17, 3)]);
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
            modifierKeyword: static
            returnType: NamedType
              name: int
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_static_var_noName_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { static var void a(b) {} }
''');
    parseResult.assertErrors([error(diag.varReturnType, 17, 3)]);
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
            modifierKeyword: static
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_static_var_noName_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { static var set a(b) {} }
''');
    parseResult.assertErrors([error(diag.varReturnType, 17, 3)]);
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
            modifierKeyword: static
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_type_equals_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { A f = @annotation var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 16, 1),
      error(diag.expectedToken, 14, 1),
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_type_equals_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { A f = }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 16, 1),
      error(diag.expectedToken, 14, 1),
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_type_equals_field() {
    var parseResult = parseStringWithErrors(r'''
class C { A f = var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 16, 3),
      error(diag.expectedToken, 14, 1),
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_type_equals_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { A f = const f = 0; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.missingAssignableSelector, 16, 8),
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: AssignmentExpression
                    leftHandSide: InstanceCreationExpression
                      keyword: const
                      constructorName: ConstructorName
                        type: NamedType
                          name: f
                      argumentList: ArgumentList
                        leftParenthesis: ( <synthetic>
                        rightParenthesis: ) <synthetic>
                    operator: =
                    rightHandSide: IntegerLiteral
                      literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_type_equals_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { A f = final f = 0; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 16, 5),
      error(diag.expectedToken, 14, 1),
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_type_equals_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { A f = int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 3)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: int
            semicolon: ; <synthetic>
          MethodDeclaration
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

  void test_field_declaration_type_equals_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { A f = int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.namedFunctionExpression, 20, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      parameter: RegularFormalParameter
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

  void test_field_declaration_type_equals_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { A f = void a(b) {} }
''');
    parseResult.assertErrors([
      error(diag.namedFunctionExpression, 21, 1),
      error(diag.expectedToken, 27, 1),
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      parameter: RegularFormalParameter
                        name: b
                      rightParenthesis: )
                    body: BlockFunctionBody
                      block: Block
                        leftBracket: {
                        rightBracket: }
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_type_equals_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { A f = set a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 3)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: set
            semicolon: ; <synthetic>
          MethodDeclaration
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_type_initializer_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { A f = 0 @annotation var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_type_initializer_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { A f = 0 }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_type_initializer_field() {
    var parseResult = parseStringWithErrors(r'''
class C { A f = 0 var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_type_initializer_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { A f = 0 const f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_type_initializer_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { A f = 0 final f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_type_initializer_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { A f = 0 int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: int
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

  void test_field_declaration_type_initializer_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { A f = 0 int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: int
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_type_initializer_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { A f = 0 void a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_type_initializer_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { A f = 0 set a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_type_name_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { A f @annotation var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_type_name_comma_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { A f, @annotation var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 15, 1),
      error(diag.expectedToken, 13, 1),
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
                name: A
              variables
                VariableDeclaration
                  name: f
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_type_name_comma_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { A f, }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 15, 1),
      error(diag.expectedToken, 13, 1),
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
                name: A
              variables
                VariableDeclaration
                  name: f
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_type_name_comma_field() {
    var parseResult = parseStringWithErrors(r'''
class C { A f, var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 15, 3),
      error(diag.expectedToken, 13, 1),
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
                name: A
              variables
                VariableDeclaration
                  name: f
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_type_name_comma_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { A f, const f = 0; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 15, 5),
      error(diag.expectedToken, 13, 1),
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
                name: A
              variables
                VariableDeclaration
                  name: f
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_type_name_comma_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { A f, final f = 0; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 15, 5),
      error(diag.expectedToken, 13, 1),
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
                name: A
              variables
                VariableDeclaration
                  name: f
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_type_name_comma_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { A f, int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 15, 3)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                VariableDeclaration
                  name: int
            semicolon: ; <synthetic>
          MethodDeclaration
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

  void test_field_declaration_type_name_comma_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { A f, int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 15, 3)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                VariableDeclaration
                  name: int
            semicolon: ; <synthetic>
          MethodDeclaration
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_type_name_comma_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { A f, void a(b) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 15, 4),
      error(diag.expectedToken, 13, 1),
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
                name: A
              variables
                VariableDeclaration
                  name: f
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_type_name_comma_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { A f, set a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 15, 3)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
                VariableDeclaration
                  name: set
            semicolon: ; <synthetic>
          MethodDeclaration
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_type_name_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { A f }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_type_name_field() {
    var parseResult = parseStringWithErrors(r'''
class C { A f var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_type_name_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { A f const f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_type_name_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { A f final f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_type_name_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { A f int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: int
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

  void test_field_declaration_type_name_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { A f int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: int
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_type_name_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { A f void a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_type_name_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { A f set a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
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
                name: A
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
          MethodDeclaration
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_type_noName_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { A @annotation var f; }
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 10, 1),
      error(diag.expectedToken, 10, 1),
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
              variables
                VariableDeclaration
                  name: A
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_type_noName_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { A }
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 10, 1),
      error(diag.expectedToken, 10, 1),
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
              variables
                VariableDeclaration
                  name: A
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_type_noName_field() {
    var parseResult = parseStringWithErrors(r'''
class C { A var f; }
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 10, 1),
      error(diag.expectedToken, 10, 1),
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
              variables
                VariableDeclaration
                  name: A
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_type_noName_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { A const f = 0; }
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 10, 1),
      error(diag.expectedToken, 10, 1),
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
              variables
                VariableDeclaration
                  name: A
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_type_noName_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { A final f = 0; }
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 10, 1),
      error(diag.expectedToken, 10, 1),
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
              variables
                VariableDeclaration
                  name: A
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_type_noName_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { A int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 3)]);
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
                name: A
              variables
                VariableDeclaration
                  name: int
            semicolon: ; <synthetic>
          MethodDeclaration
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

  void test_field_declaration_type_noName_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { A int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 3)]);
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
                name: A
              variables
                VariableDeclaration
                  name: int
            semicolon: ; <synthetic>
          MethodDeclaration
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_type_noName_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { A void a(b) {} }
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 10, 1),
      error(diag.expectedToken, 10, 1),
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
              variables
                VariableDeclaration
                  name: A
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_type_noName_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { A set a(b) {} }
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
            returnType: NamedType
              name: A
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_var_equals_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { var f = @annotation var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 18, 1),
      error(diag.expectedToken, 16, 1),
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_var_equals_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { var f = }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 18, 1),
      error(diag.expectedToken, 16, 1),
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_var_equals_field() {
    var parseResult = parseStringWithErrors(r'''
class C { var f = var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 18, 3),
      error(diag.expectedToken, 16, 1),
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_var_equals_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { var f = const f = 0; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 1),
      error(diag.missingAssignableSelector, 18, 8),
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: AssignmentExpression
                    leftHandSide: InstanceCreationExpression
                      keyword: const
                      constructorName: ConstructorName
                        type: NamedType
                          name: f
                      argumentList: ArgumentList
                        leftParenthesis: ( <synthetic>
                        rightParenthesis: ) <synthetic>
                    operator: =
                    rightHandSide: IntegerLiteral
                      literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_var_equals_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { var f = final f = 0; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 18, 5),
      error(diag.expectedToken, 16, 1),
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_var_equals_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { var f = int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 18, 3)]);
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
                  initializer: SimpleIdentifier
                    token: int
            semicolon: ; <synthetic>
          MethodDeclaration
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

  void test_field_declaration_var_equals_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { var f = int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.namedFunctionExpression, 22, 1)]);
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
                  initializer: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      parameter: RegularFormalParameter
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

  void test_field_declaration_var_equals_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { var f = void a(b) {} }
''');
    parseResult.assertErrors([
      error(diag.namedFunctionExpression, 23, 1),
      error(diag.expectedToken, 29, 1),
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
                  equals: =
                  initializer: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      parameter: RegularFormalParameter
                        name: b
                      rightParenthesis: )
                    body: BlockFunctionBody
                      block: Block
                        leftBracket: {
                        rightBracket: }
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_var_equals_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { var f = set a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 18, 3)]);
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
                  initializer: SimpleIdentifier
                    token: set
            semicolon: ; <synthetic>
          MethodDeclaration
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_var_initializer_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { var f = 0 @annotation var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 18, 1)]);
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
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_var_initializer_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { var f = 0 }
''');
    parseResult.assertErrors([error(diag.expectedToken, 18, 1)]);
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
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_var_initializer_field() {
    var parseResult = parseStringWithErrors(r'''
class C { var f = 0 var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 18, 1)]);
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
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_var_initializer_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { var f = 0 const f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 18, 1)]);
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
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_var_initializer_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { var f = 0 final f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 18, 1)]);
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
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_var_initializer_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { var f = 0 int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 18, 1)]);
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
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: int
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

  void test_field_declaration_var_initializer_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { var f = 0 int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 18, 1)]);
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
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: int
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_var_initializer_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { var f = 0 void a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 18, 1)]);
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
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_var_initializer_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { var f = 0 set a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 18, 1)]);
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
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
          MethodDeclaration
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_var_name_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { var f @annotation var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 1)]);
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
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_var_name_comma_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { var f, @annotation var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 17, 1),
      error(diag.expectedToken, 15, 1),
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_var_name_comma_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { var f, }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 17, 1),
      error(diag.expectedToken, 15, 1),
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_var_name_comma_field() {
    var parseResult = parseStringWithErrors(r'''
class C { var f, var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 17, 3),
      error(diag.expectedToken, 15, 1),
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_var_name_comma_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { var f, const f = 0; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 17, 5),
      error(diag.expectedToken, 15, 1),
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_var_name_comma_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { var f, final f = 0; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 17, 5),
      error(diag.expectedToken, 15, 1),
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_var_name_comma_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { var f, int get a => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 17, 3)]);
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
                VariableDeclaration
                  name: int
            semicolon: ; <synthetic>
          MethodDeclaration
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

  void test_field_declaration_var_name_comma_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { var f, int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 17, 3)]);
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
                VariableDeclaration
                  name: int
            semicolon: ; <synthetic>
          MethodDeclaration
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_var_name_comma_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { var f, void a(b) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 17, 4),
      error(diag.expectedToken, 15, 1),
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_var_name_comma_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { var f, set a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 17, 3)]);
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
                VariableDeclaration
                  name: set
            semicolon: ; <synthetic>
          MethodDeclaration
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_var_name_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { var f }
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 1)]);
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
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_var_name_field() {
    var parseResult = parseStringWithErrors(r'''
class C { var f var f; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 1)]);
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
            semicolon: ; <synthetic>
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_var_name_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { var f const f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 1)]);
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
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_var_name_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { var f final f = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 1)]);
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
            semicolon: ; <synthetic>
          FieldDeclaration
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

  void test_field_declaration_var_name_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { var f int get a => 0; }
''');
    parseResult.assertErrors([
      error(diag.varAndType, 10, 3),
      error(diag.expectedToken, 16, 3),
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
              keyword: var
              type: NamedType
                name: f
              variables
                VariableDeclaration
                  name: int
            semicolon: ; <synthetic>
          MethodDeclaration
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

  void test_field_declaration_var_name_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { var f int a(b) => 0; }
''');
    parseResult.assertErrors([
      error(diag.varAndType, 10, 3),
      error(diag.expectedToken, 16, 3),
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
              keyword: var
              type: NamedType
                name: f
              variables
                VariableDeclaration
                  name: int
            semicolon: ; <synthetic>
          MethodDeclaration
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_var_name_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { var f void a(b) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 1)]);
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
            semicolon: ; <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_var_name_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { var f set a(b) {} }
''');
    parseResult.assertErrors([error(diag.varReturnType, 10, 3)]);
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
              name: f
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_var_noName_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C { var @annotation var f; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 14, 1),
      error(diag.expectedToken, 10, 3),
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
              keyword: var
              variables
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
          FieldDeclaration
            metadata
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

  void test_field_declaration_var_noName_eof() {
    var parseResult = parseStringWithErrors(r'''
class C { var }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 14, 1),
      error(diag.expectedToken, 10, 3),
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
              keyword: var
              variables
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_var_noName_field() {
    var parseResult = parseStringWithErrors(r'''
class C { var var f; }
''');
    parseResult.assertErrors([error(diag.duplicatedModifier, 14, 3)]);
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
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_var_noName_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C { var const f = 0; }
''');
    parseResult.assertErrors([error(diag.conflictingModifiers, 14, 5)]);
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
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_var_noName_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C { var final f = 0; }
''');
    parseResult.assertErrors([error(diag.finalAndVar, 14, 5)]);
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
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_var_noName_getter() {
    var parseResult = parseStringWithErrors(r'''
class C { var int get a => 0; }
''');
    parseResult.assertErrors([error(diag.varReturnType, 10, 3)]);
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

  void test_field_declaration_var_noName_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { var int a(b) => 0; }
''');
    parseResult.assertErrors([error(diag.varReturnType, 10, 3)]);
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
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
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

  void test_field_declaration_var_noName_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C { var void a(b) {} }
''');
    parseResult.assertErrors([error(diag.varReturnType, 10, 3)]);
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
              name: void
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_field_declaration_var_noName_setter() {
    var parseResult = parseStringWithErrors(r'''
class C { var set a(b) {} }
''');
    parseResult.assertErrors([error(diag.varReturnType, 10, 3)]);
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
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }
}
