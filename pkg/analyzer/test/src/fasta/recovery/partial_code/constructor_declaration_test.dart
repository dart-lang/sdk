// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ConstructorTest extends ParserDiagnosticsTest {
  void test_constructor_colon_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : @annotation var f;}
''');
    parseResult.assertErrors([
      error(diag.missingInitializer, 13, 1),
      error(diag.missingFunctionBody, 15, 1),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_colon_block_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : {} @annotation var f;}
''');
    parseResult.assertErrors([error(diag.missingInitializer, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
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

  void test_constructor_colon_block_eof() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : {}}
''');
    parseResult.assertErrors([error(diag.missingInitializer, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_constructor_colon_block_field() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : {} var f;}
''');
    parseResult.assertErrors([error(diag.missingInitializer, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
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

  void test_constructor_colon_block_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : {} const f = 0;}
''');
    parseResult.assertErrors([error(diag.missingInitializer, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
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

  void test_constructor_colon_block_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : {} final f = 0;}
''');
    parseResult.assertErrors([error(diag.missingInitializer, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
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

  void test_constructor_colon_block_getter() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : {} int get a => 0;}
''');
    parseResult.assertErrors([error(diag.missingInitializer, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
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

  void test_constructor_colon_block_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : {} int a(b) => 0;}
''');
    parseResult.assertErrors([error(diag.missingInitializer, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
          MethodDeclaration
            returnType: NamedType
              name: int
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

  void test_constructor_colon_block_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : {} void a(b) {}}
''');
    parseResult.assertErrors([error(diag.missingInitializer, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
          MethodDeclaration
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

  void test_constructor_colon_block_setter() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : {} set a(b) {}}
''');
    parseResult.assertErrors([error(diag.missingInitializer, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
          MethodDeclaration
            propertyKeyword: set
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

  void test_constructor_colon_eof() {
    var parseResult = parseStringWithErrors(r'''
class C {C() :}
''');
    parseResult.assertErrors([
      error(diag.missingInitializer, 13, 1),
      error(diag.missingFunctionBody, 14, 1),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_constructor_colon_field() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : var f;}
''');
    parseResult.assertErrors([
      error(diag.missingInitializer, 13, 1),
      error(diag.missingFunctionBody, 15, 3),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_colon_field_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f @annotation var f;}
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 15, 1),
      error(diag.missingFunctionBody, 17, 1),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: f
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_colon_field_comma_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f = 0, @annotation var f;}
''');
    parseResult.assertErrors([
      error(diag.missingInitializer, 20, 1),
      error(diag.missingFunctionBody, 22, 1),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: f
                equals: =
                expression: IntegerLiteral
                  literal: 0
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_colon_field_comma_eof() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f = 0,}
''');
    parseResult.assertErrors([
      error(diag.missingInitializer, 20, 1),
      error(diag.missingFunctionBody, 21, 1),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: f
                equals: =
                expression: IntegerLiteral
                  literal: 0
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_constructor_colon_field_comma_field() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f = 0, var f;}
''');
    parseResult.assertErrors([
      error(diag.missingInitializer, 20, 1),
      error(diag.missingFunctionBody, 22, 3),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: f
                equals: =
                expression: IntegerLiteral
                  literal: 0
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_colon_field_comma_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f = 0, const f = 0;}
''');
    parseResult.assertErrors([
      error(diag.missingInitializer, 20, 1),
      error(diag.missingFunctionBody, 22, 5),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: f
                equals: =
                expression: IntegerLiteral
                  literal: 0
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_colon_field_comma_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f = 0, final f = 0;}
''');
    parseResult.assertErrors([
      error(diag.missingInitializer, 20, 1),
      error(diag.missingFunctionBody, 22, 5),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: f
                equals: =
                expression: IntegerLiteral
                  literal: 0
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_colon_field_comma_getter() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f = 0, int get a => 0;}
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 22, 3),
      error(diag.missingFunctionBody, 26, 3),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: f
                equals: =
                expression: IntegerLiteral
                  literal: 0
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: int
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_colon_field_comma_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f = 0, int a(b) => 0;}
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 22, 3),
      error(diag.missingFunctionBody, 26, 1),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: f
                equals: =
                expression: IntegerLiteral
                  literal: 0
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: int
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
          MethodDeclaration
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

  void test_constructor_colon_field_comma_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f = 0, void a(b) {}}
''');
    parseResult.assertErrors([
      error(diag.missingInitializer, 20, 1),
      error(diag.missingFunctionBody, 22, 4),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: f
                equals: =
                expression: IntegerLiteral
                  literal: 0
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
          MethodDeclaration
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

  void test_constructor_colon_field_comma_setter() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f = 0, set a(b) {}}
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 22, 3),
      error(diag.missingFunctionBody, 26, 1),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: f
                equals: =
                expression: IntegerLiteral
                  literal: 0
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: set
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
          MethodDeclaration
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

  void test_constructor_colon_field_eof() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f}
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 15, 1),
      error(diag.missingFunctionBody, 16, 1),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: f
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_constructor_colon_field_field() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f var f;}
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 15, 1),
      error(diag.missingFunctionBody, 17, 3),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: f
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_colon_field_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f const f = 0;}
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 15, 1),
      error(diag.missingFunctionBody, 17, 5),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: f
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_colon_field_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f final f = 0;}
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 15, 1),
      error(diag.missingFunctionBody, 17, 5),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: f
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_colon_field_getter() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f int get a => 0;}
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 15, 1),
      error(diag.missingFunctionBody, 17, 3),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: f
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_colon_field_increment_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f++ @annotation var f;}
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 15, 1),
      error(diag.missingFunctionBody, 19, 1),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: PostfixExpression
                  operand: SimpleIdentifier
                    token: f
                  operator: ++
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_colon_field_increment_eof() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f++}
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 15, 1),
      error(diag.missingFunctionBody, 18, 1),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: PostfixExpression
                  operand: SimpleIdentifier
                    token: f
                  operator: ++
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_constructor_colon_field_increment_field() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f++ var f;}
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 15, 1),
      error(diag.missingFunctionBody, 19, 3),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: PostfixExpression
                  operand: SimpleIdentifier
                    token: f
                  operator: ++
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_colon_field_increment_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f++ const f = 0;}
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 15, 1),
      error(diag.missingFunctionBody, 19, 5),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: PostfixExpression
                  operand: SimpleIdentifier
                    token: f
                  operator: ++
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_colon_field_increment_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f++ final f = 0;}
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 15, 1),
      error(diag.missingFunctionBody, 19, 5),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: PostfixExpression
                  operand: SimpleIdentifier
                    token: f
                  operator: ++
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_colon_field_increment_getter() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f++ int get a => 0;}
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 15, 1),
      error(diag.missingFunctionBody, 19, 3),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: PostfixExpression
                  operand: SimpleIdentifier
                    token: f
                  operator: ++
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_colon_field_increment_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f++ int a(b) => 0;}
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 15, 1),
      error(diag.missingFunctionBody, 19, 3),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: PostfixExpression
                  operand: SimpleIdentifier
                    token: f
                  operator: ++
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: int
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

  void test_constructor_colon_field_increment_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f++ void a(b) {}}
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 15, 1),
      error(diag.missingFunctionBody, 19, 4),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: PostfixExpression
                  operand: SimpleIdentifier
                    token: f
                  operator: ++
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
          MethodDeclaration
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

  void test_constructor_colon_field_increment_setter() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f++ set a(b) {}}
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 15, 1),
      error(diag.missingFunctionBody, 19, 3),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: PostfixExpression
                  operand: SimpleIdentifier
                    token: f
                  operator: ++
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
          MethodDeclaration
            propertyKeyword: set
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

  void test_constructor_colon_field_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f int a(b) => 0;}
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 15, 1),
      error(diag.missingFunctionBody, 17, 3),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: f
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: int
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

  void test_constructor_colon_field_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f void a(b) {}}
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 15, 1),
      error(diag.missingFunctionBody, 17, 4),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: f
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
          MethodDeclaration
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

  void test_constructor_colon_field_setter() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : f set a(b) {}}
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 15, 1),
      error(diag.missingFunctionBody, 17, 3),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: f
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
          MethodDeclaration
            propertyKeyword: set
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

  void test_constructor_colon_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : const f = 0;}
''');
    parseResult.assertErrors([
      error(diag.missingInitializer, 13, 1),
      error(diag.missingFunctionBody, 15, 5),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_colon_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : final f = 0;}
''');
    parseResult.assertErrors([
      error(diag.missingInitializer, 13, 1),
      error(diag.missingFunctionBody, 15, 5),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_colon_getter() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : int get a => 0;}
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 15, 3),
      error(diag.missingFunctionBody, 19, 3),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: int
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_colon_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : int a(b) => 0;}
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 15, 3),
      error(diag.missingFunctionBody, 19, 1),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: int
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
          MethodDeclaration
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

  void test_constructor_colon_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : void a(b) {}}
''');
    parseResult.assertErrors([
      error(diag.missingInitializer, 13, 1),
      error(diag.missingFunctionBody, 15, 4),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
          MethodDeclaration
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

  void test_constructor_colon_semicolon_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : ; @annotation var f;}
''');
    parseResult.assertErrors([error(diag.missingInitializer, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
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

  void test_constructor_colon_semicolon_eof() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : ;}
''');
    parseResult.assertErrors([error(diag.missingInitializer, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_constructor_colon_semicolon_field() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : ; var f;}
''');
    parseResult.assertErrors([error(diag.missingInitializer, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
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

  void test_constructor_colon_semicolon_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : ; const f = 0;}
''');
    parseResult.assertErrors([error(diag.missingInitializer, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
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

  void test_constructor_colon_semicolon_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : ; final f = 0;}
''');
    parseResult.assertErrors([error(diag.missingInitializer, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
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

  void test_constructor_colon_semicolon_getter() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : ; int get a => 0;}
''');
    parseResult.assertErrors([error(diag.missingInitializer, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
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

  void test_constructor_colon_semicolon_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : ; int a(b) => 0;}
''');
    parseResult.assertErrors([error(diag.missingInitializer, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
          MethodDeclaration
            returnType: NamedType
              name: int
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

  void test_constructor_colon_semicolon_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : ; void a(b) {}}
''');
    parseResult.assertErrors([error(diag.missingInitializer, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
          MethodDeclaration
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

  void test_constructor_colon_semicolon_setter() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : ; set a(b) {}}
''');
    parseResult.assertErrors([error(diag.missingInitializer, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
          MethodDeclaration
            propertyKeyword: set
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

  void test_constructor_colon_setter() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : set a(b) {}}
''');
    parseResult.assertErrors([
      error(diag.missingAssignmentInInitializer, 15, 3),
      error(diag.missingFunctionBody, 19, 1),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: set
                equals: = <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
          MethodDeclaration
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

  void test_constructor_super_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super @annotation var f;}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 1),
      error(diag.missingFunctionBody, 21, 1),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_super_dot_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super. @annotation var f;}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 22, 1),
      error(diag.expectedToken, 22, 1),
      error(diag.missingFunctionBody, 22, 1),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                period: .
                constructorName: SimpleIdentifier
                  token: <empty> <synthetic>
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_super_dot_eof() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super.}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 1),
      error(diag.expectedToken, 21, 1),
      error(diag.missingFunctionBody, 21, 1),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                period: .
                constructorName: SimpleIdentifier
                  token: <empty> <synthetic>
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_constructor_super_dot_field() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super. var f;}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 22, 3),
      error(diag.expectedToken, 22, 3),
      error(diag.missingFunctionBody, 22, 3),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                period: .
                constructorName: SimpleIdentifier
                  token: <empty> <synthetic>
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_super_dot_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super. const f = 0;}
''');
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 22, 5),
      error(diag.expectedToken, 28, 1),
      error(diag.missingIdentifier, 22, 5),
      error(diag.expectedToken, 28, 1),
      error(diag.invalidSuperInInitializer, 15, 5),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: f
                equals: =
                expression: IntegerLiteral
                  literal: 0
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_constructor_super_dot_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super. final f = 0;}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 22, 5),
      error(diag.expectedToken, 22, 5),
      error(diag.missingFunctionBody, 22, 5),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                period: .
                constructorName: SimpleIdentifier
                  token: <empty> <synthetic>
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_super_dot_getter() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super. int get a => 0;}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 3),
      error(diag.missingFunctionBody, 26, 3),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                period: .
                constructorName: SimpleIdentifier
                  token: int
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_super_dot_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super. int a(b) => 0;}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
      error(diag.missingFunctionBody, 26, 1),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                period: .
                constructorName: SimpleIdentifier
                  token: int
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
          MethodDeclaration
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

  void test_constructor_super_dot_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super. void a(b) {}}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 22, 4),
      error(diag.expectedToken, 22, 4),
      error(diag.missingFunctionBody, 22, 4),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                period: .
                constructorName: SimpleIdentifier
                  token: <empty> <synthetic>
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
          MethodDeclaration
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

  void test_constructor_super_dot_setter() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super. set a(b) {}}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
      error(diag.missingFunctionBody, 26, 1),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                period: .
                constructorName: SimpleIdentifier
                  token: set
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
          MethodDeclaration
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

  void test_constructor_super_eof() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 20, 1),
      error(diag.missingFunctionBody, 20, 1),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_constructor_super_field() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super var f;}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 3),
      error(diag.missingFunctionBody, 21, 3),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_super_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super const f = 0;}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 5),
      error(diag.missingFunctionBody, 21, 5),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_super_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super final f = 0;}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 5),
      error(diag.missingFunctionBody, 21, 5),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_super_getter() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super int get a => 0;}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 3),
      error(diag.missingFunctionBody, 21, 3),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_super_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super int a(b) => 0;}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 3),
      error(diag.missingFunctionBody, 21, 3),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
          MethodDeclaration
            returnType: NamedType
              name: int
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

  void test_constructor_super_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super void a(b) {}}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 4),
      error(diag.missingFunctionBody, 21, 4),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
          MethodDeclaration
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

  void test_constructor_super_qdot_annotation() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super?. @annotation var f;}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
      error(diag.invalidOperatorQuestionmarkPeriodForSuper, 20, 2),
      error(diag.missingFunctionBody, 23, 1),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                period: ?.
                constructorName: SimpleIdentifier
                  token: <empty> <synthetic>
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_super_qdot_eof() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super?.}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.invalidOperatorQuestionmarkPeriodForSuper, 20, 2),
      error(diag.missingFunctionBody, 22, 1),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                period: ?.
                constructorName: SimpleIdentifier
                  token: <empty> <synthetic>
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_constructor_super_qdot_field() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super?. var f;}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 3),
      error(diag.invalidOperatorQuestionmarkPeriodForSuper, 20, 2),
      error(diag.missingFunctionBody, 23, 3),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                period: ?.
                constructorName: SimpleIdentifier
                  token: <empty> <synthetic>
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_super_qdot_fieldConst() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super?. const f = 0;}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 5),
      error(diag.invalidOperatorQuestionmarkPeriodForSuper, 20, 2),
      error(diag.missingFunctionBody, 23, 5),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                period: ?.
                constructorName: SimpleIdentifier
                  token: <empty> <synthetic>
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_super_qdot_fieldFinal() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super?. final f = 0;}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 5),
      error(diag.invalidOperatorQuestionmarkPeriodForSuper, 20, 2),
      error(diag.missingFunctionBody, 23, 5),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                period: ?.
                constructorName: SimpleIdentifier
                  token: <empty> <synthetic>
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_super_qdot_getter() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super?. int get a => 0;}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 3),
      error(diag.invalidOperatorQuestionmarkPeriodForSuper, 20, 2),
      error(diag.missingFunctionBody, 27, 3),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                period: ?.
                constructorName: SimpleIdentifier
                  token: int
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_constructor_super_qdot_methodNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super?. int a(b) => 0;}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.invalidOperatorQuestionmarkPeriodForSuper, 20, 2),
      error(diag.missingFunctionBody, 27, 1),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                period: ?.
                constructorName: SimpleIdentifier
                  token: int
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
          MethodDeclaration
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

  void test_constructor_super_qdot_methodVoid() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super?. void a(b) {}}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 4),
      error(diag.invalidOperatorQuestionmarkPeriodForSuper, 20, 2),
      error(diag.missingFunctionBody, 23, 4),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                period: ?.
                constructorName: SimpleIdentifier
                  token: <empty> <synthetic>
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
          MethodDeclaration
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

  void test_constructor_super_qdot_setter() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super?. set a(b) {}}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.invalidOperatorQuestionmarkPeriodForSuper, 20, 2),
      error(diag.missingFunctionBody, 27, 1),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                period: ?.
                constructorName: SimpleIdentifier
                  token: set
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
          MethodDeclaration
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

  void test_constructor_super_setter() {
    var parseResult = parseStringWithErrors(r'''
class C {C() : super set a(b) {}}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 3),
      error(diag.missingFunctionBody, 21, 3),
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
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
          MethodDeclaration
            propertyKeyword: set
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
}
