// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f = @annotation var f; }
//                ^
// [diag.expectedToken] Expected to find ';'.
//                  ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f = }
//                ^
// [diag.expectedToken] Expected to find ';'.
//                  ^
// [diag.missingIdentifier] Expected an identifier.
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
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_const_equals_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f = var f; }
//                ^
// [diag.expectedToken] Expected to find ';'.
//                  ^^^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f = const f = 0; }
//                  ^^^^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
//                        ^
// [diag.expectedToken] Expected to find '('.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f = final f = 0; }
//                ^
// [diag.expectedToken] Expected to find ';'.
//                  ^^^^^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f = int get a => 0; }
//                  ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f = int a(b) => 0; }
//                      ^
// [diag.namedFunctionExpression] Function expressions can't be named.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f = void a(b) {} }
//                       ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                             ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f = set a(b) {} }
//                  ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f = 0 @annotation var f; }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f = 0 }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_const_initializer_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f = 0 var f; }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f = 0 const f = 0; }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f = 0 final f = 0; }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f = 0 int get a => 0; }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f = 0 int a(b) => 0; }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f = 0 void a(b) {} }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f = 0 set a(b) {} }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f @annotation var f; }
//              ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f }
//              ^
// [diag.expectedToken] Expected to find ';'.
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
                  name: f
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_const_name_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f var f; }
//              ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f const f = 0; }
//              ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f final f = 0; }
//              ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f int get a => 0; }
//                ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f int a(b) => 0; }
//                ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f void a(b) {} }
//              ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const f set a(b) {} }
//        ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const @annotation var f; }
//        ^^^^^
// [diag.expectedToken] Expected to find ';'.
//              ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const }
//        ^^^^^
// [diag.expectedToken] Expected to find ';'.
//              ^
// [diag.missingIdentifier] Expected an identifier.
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

  void test_field_declaration_const_noName_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const var f; }
//              ^^^
// [diag.conflictingModifiers] Members can't be declared to be both 'var' and 'const'.
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
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_const_noName_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const const f = 0; }
//              ^^^^^
// [diag.duplicatedModifier] The modifier 'const' was already specified.
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_const_noName_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const final f = 0; }
//              ^^^^^
// [diag.constAndFinal] Members can't be declared to be both 'const' and 'final'.
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_const_noName_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const int get a => 0; }
//        ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const int a(b) => 0; }
//        ^^^^^
// [diag.constMethod] Getters, setters and methods can't be declared to be 'const'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const void a(b) {} }
//        ^^^^^
// [diag.constMethod] Getters, setters and methods can't be declared to be 'const'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { const set a(b) {} }
//        ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f = @annotation var f; }
//                ^
// [diag.expectedToken] Expected to find ';'.
//                  ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f = }
//                ^
// [diag.expectedToken] Expected to find ';'.
//                  ^
// [diag.missingIdentifier] Expected an identifier.
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
                  name: f
                  equals: =
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_final_equals_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f = var f; }
//                ^
// [diag.expectedToken] Expected to find ';'.
//                  ^^^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f = const f = 0; }
//                  ^^^^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
//                        ^
// [diag.expectedToken] Expected to find '('.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f = final f = 0; }
//                ^
// [diag.expectedToken] Expected to find ';'.
//                  ^^^^^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f = int get a => 0; }
//                  ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f = int a(b) => 0; }
//                      ^
// [diag.namedFunctionExpression] Function expressions can't be named.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f = void a(b) {} }
//                       ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                             ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f = set a(b) {} }
//                  ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f = 0 @annotation var f; }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f = 0 }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_final_initializer_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f = 0 var f; }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f = 0 const f = 0; }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f = 0 final f = 0; }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f = 0 int get a => 0; }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f = 0 int a(b) => 0; }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f = 0 void a(b) {} }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f = 0 set a(b) {} }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f @annotation var f; }
//              ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f }
//              ^
// [diag.expectedToken] Expected to find ';'.
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
                  name: f
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_final_name_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f var f; }
//              ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f const f = 0; }
//              ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f final f = 0; }
//              ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f int get a => 0; }
//                ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f int a(b) => 0; }
//                ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f void a(b) {} }
//              ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final f set a(b) {} }
//        ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final @annotation var f; }
//        ^^^^^
// [diag.expectedToken] Expected to find ';'.
//              ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final }
//        ^^^^^
// [diag.expectedToken] Expected to find ';'.
//              ^
// [diag.missingIdentifier] Expected an identifier.
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

  void test_field_declaration_final_noName_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final var f; }
//              ^^^
// [diag.finalAndVar] Members can't be declared to be both 'final' and 'var'.
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
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_final_noName_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final const f = 0; }
//              ^^^^^
// [diag.constAndFinal] Members can't be declared to be both 'const' and 'final'.
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_final_noName_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final final f = 0; }
//              ^^^^^
// [diag.duplicatedModifier] The modifier 'final' was already specified.
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
                  name: f
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_final_noName_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final int get a => 0; }
//        ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final int a(b) => 0; }
//        ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final void a(b) {} }
//        ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { final set a(b) {} }
//        ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f = @annotation var f; }
//                       ^
// [diag.expectedToken] Expected to find ';'.
//                         ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f = }
//                       ^
// [diag.expectedToken] Expected to find ';'.
//                         ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f = var f; }
//                       ^
// [diag.expectedToken] Expected to find ';'.
//                         ^^^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f = const f = 0; }
//                         ^^^^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
//                               ^
// [diag.expectedToken] Expected to find '('.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f = final f = 0; }
//                       ^
// [diag.expectedToken] Expected to find ';'.
//                         ^^^^^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f = int get a => 0; }
//                         ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f = int a(b) => 0; }
//                             ^
// [diag.namedFunctionExpression] Function expressions can't be named.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f = void a(b) {} }
//                              ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                                    ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f = set a(b) {} }
//                         ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f = 0 @annotation var f; }
//                         ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f = 0 }
//                         ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f = 0 var f; }
//                         ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f = 0 const f = 0; }
//                         ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f = 0 final f = 0; }
//                         ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f = 0 int get a => 0; }
//                         ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f = 0 int a(b) => 0; }
//                         ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f = 0 void a(b) {} }
//                         ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f = 0 set a(b) {} }
//                         ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f @annotation var f; }
//                     ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f }
//                     ^
// [diag.expectedToken] Expected to find ';'.
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_const_name_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f var f; }
//                     ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f const f = 0; }
//                     ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f final f = 0; }
//                     ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f int get a => 0; }
//                       ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f int a(b) => 0; }
//                       ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f void a(b) {} }
//                     ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const f set a(b) {} }
//               ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const @annotation var f; }
//               ^^^^^
// [diag.expectedToken] Expected to find ';'.
//                     ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const }
//               ^^^^^
// [diag.expectedToken] Expected to find ';'.
//                     ^
// [diag.missingIdentifier] Expected an identifier.
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
              keyword: const
              variables
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_const_noName_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const var f; }
//                     ^^^
// [diag.conflictingModifiers] Members can't be declared to be both 'var' and 'const'.
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
              keyword: const
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_static_const_noName_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const const f = 0; }
//                     ^^^^^
// [diag.duplicatedModifier] The modifier 'const' was already specified.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const final f = 0; }
//                     ^^^^^
// [diag.constAndFinal] Members can't be declared to be both 'const' and 'final'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const int get a => 0; }
//               ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const int a(b) => 0; }
//               ^^^^^
// [diag.constMethod] Getters, setters and methods can't be declared to be 'const'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const void a(b) {} }
//               ^^^^^
// [diag.constMethod] Getters, setters and methods can't be declared to be 'const'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static const set a(b) {} }
//               ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f = @annotation var f; }
//                       ^
// [diag.expectedToken] Expected to find ';'.
//                         ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f = }
//                       ^
// [diag.expectedToken] Expected to find ';'.
//                         ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f = var f; }
//                       ^
// [diag.expectedToken] Expected to find ';'.
//                         ^^^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f = const f = 0; }
//                         ^^^^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
//                               ^
// [diag.expectedToken] Expected to find '('.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f = final f = 0; }
//                       ^
// [diag.expectedToken] Expected to find ';'.
//                         ^^^^^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f = int get a => 0; }
//                         ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f = int a(b) => 0; }
//                             ^
// [diag.namedFunctionExpression] Function expressions can't be named.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f = void a(b) {} }
//                              ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                                    ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f = set a(b) {} }
//                         ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f = 0 @annotation var f; }
//                         ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f = 0 }
//                         ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f = 0 var f; }
//                         ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f = 0 const f = 0; }
//                         ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f = 0 final f = 0; }
//                         ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f = 0 int get a => 0; }
//                         ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f = 0 int a(b) => 0; }
//                         ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f = 0 void a(b) {} }
//                         ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f = 0 set a(b) {} }
//                         ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f @annotation var f; }
//                     ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f }
//                     ^
// [diag.expectedToken] Expected to find ';'.
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_final_name_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f var f; }
//                     ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f const f = 0; }
//                     ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f final f = 0; }
//                     ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f int get a => 0; }
//                       ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f int a(b) => 0; }
//                       ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f void a(b) {} }
//                     ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final f set a(b) {} }
//               ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final @annotation var f; }
//               ^^^^^
// [diag.expectedToken] Expected to find ';'.
//                     ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final }
//               ^^^^^
// [diag.expectedToken] Expected to find ';'.
//                     ^
// [diag.missingIdentifier] Expected an identifier.
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
              keyword: final
              variables
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_final_noName_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final var f; }
//                     ^^^
// [diag.finalAndVar] Members can't be declared to be both 'final' and 'var'.
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
              keyword: final
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_static_final_noName_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final const f = 0; }
//                     ^^^^^
// [diag.constAndFinal] Members can't be declared to be both 'const' and 'final'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final final f = 0; }
//                     ^^^^^
// [diag.duplicatedModifier] The modifier 'final' was already specified.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final int get a => 0; }
//               ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final int a(b) => 0; }
//               ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final void a(b) {} }
//               ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static final set a(b) {} }
//               ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f = @annotation var f; }
//                   ^
// [diag.expectedToken] Expected to find ';'.
//                     ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f = }
//                   ^
// [diag.expectedToken] Expected to find ';'.
//                     ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f = var f; }
//                   ^
// [diag.expectedToken] Expected to find ';'.
//                     ^^^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f = const f = 0; }
//                     ^^^^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
//                           ^
// [diag.expectedToken] Expected to find '('.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f = final f = 0; }
//                   ^
// [diag.expectedToken] Expected to find ';'.
//                     ^^^^^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f = int get a => 0; }
//                     ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f = int a(b) => 0; }
//                         ^
// [diag.namedFunctionExpression] Function expressions can't be named.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f = void a(b) {} }
//                          ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                                ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f = set a(b) {} }
//                     ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f = 0 @annotation var f; }
//                     ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f = 0 }
//                     ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f = 0 var f; }
//                     ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f = 0 const f = 0; }
//                     ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f = 0 final f = 0; }
//                     ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f = 0 int get a => 0; }
//                     ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f = 0 int a(b) => 0; }
//                     ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f = 0 void a(b) {} }
//                     ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f = 0 set a(b) {} }
//                     ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f @annotation var f; }
//                 ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f }
//                 ^
// [diag.expectedToken] Expected to find ';'.
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
                name: A
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_type_name_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f var f; }
//                 ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f const f = 0; }
//                 ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f final f = 0; }
//                 ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f int get a => 0; }
//                 ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f int a(b) => 0; }
//                 ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f void a(b) {} }
//                 ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A f set a(b) {} }
//                 ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A @annotation var f; }
//               ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A }
//               ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
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
                  name: A
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_type_noName_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A var f; }
//               ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A const f = 0; }
//               ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A final f = 0; }
//               ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A int get a => 0; }
//                 ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A int a(b) => 0; }
//                 ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A void a(b) {} }
//               ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A set a(b) {} }
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f = @annotation var f; }
//                     ^
// [diag.expectedToken] Expected to find ';'.
//                       ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f = }
//                     ^
// [diag.expectedToken] Expected to find ';'.
//                       ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f = var f; }
//                     ^
// [diag.expectedToken] Expected to find ';'.
//                       ^^^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f = const f = 0; }
//                       ^^^^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
//                             ^
// [diag.expectedToken] Expected to find '('.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f = final f = 0; }
//                     ^
// [diag.expectedToken] Expected to find ';'.
//                       ^^^^^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f = int get a => 0; }
//                       ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f = int a(b) => 0; }
//                           ^
// [diag.namedFunctionExpression] Function expressions can't be named.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f = void a(b) {} }
//                            ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                                  ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f = set a(b) {} }
//                       ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f = 0 @annotation var f; }
//                       ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f = 0 }
//                       ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f = 0 var f; }
//                       ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f = 0 const f = 0; }
//                       ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f = 0 final f = 0; }
//                       ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f = 0 int get a => 0; }
//                       ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f = 0 int a(b) => 0; }
//                       ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f = 0 void a(b) {} }
//                       ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f = 0 set a(b) {} }
//                       ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f @annotation var f; }
//                   ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f }
//                   ^
// [diag.expectedToken] Expected to find ';'.
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_var_name_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f var f; }
//                   ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f const f = 0; }
//                   ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f final f = 0; }
//                   ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f int get a => 0; }
//               ^^^
// [diag.varAndType] Variables can't be declared using both 'var' and a type name.
//                     ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f int a(b) => 0; }
//               ^^^
// [diag.varAndType] Variables can't be declared using both 'var' and a type name.
//                     ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f void a(b) {} }
//                   ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var f set a(b) {} }
//               ^^^
// [diag.varReturnType] The return type can't be 'var'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var @annotation var f; }
//               ^^^
// [diag.expectedToken] Expected to find ';'.
//                   ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var }
//               ^^^
// [diag.expectedToken] Expected to find ';'.
//                   ^
// [diag.missingIdentifier] Expected an identifier.
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
              keyword: var
              variables
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_static_var_noName_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var var f; }
//                   ^^^
// [diag.duplicatedModifier] The modifier 'var' was already specified.
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
              keyword: var
              variables
                VariableDeclaration
                  name: f
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_static_var_noName_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var const f = 0; }
//                   ^^^^^
// [diag.conflictingModifiers] Members can't be declared to be both 'const' and 'var'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var final f = 0; }
//                   ^^^^^
// [diag.finalAndVar] Members can't be declared to be both 'final' and 'var'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var int get a => 0; }
//               ^^^
// [diag.varReturnType] The return type can't be 'var'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var int a(b) => 0; }
//               ^^^
// [diag.varReturnType] The return type can't be 'var'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var void a(b) {} }
//               ^^^
// [diag.varReturnType] The return type can't be 'var'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static var set a(b) {} }
//               ^^^
// [diag.varReturnType] The return type can't be 'var'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f = @annotation var f; }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f = }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f = var f; }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^^^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f = const f = 0; }
//              ^^^^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
//                    ^
// [diag.expectedToken] Expected to find '('.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f = final f = 0; }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^^^^^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f = int get a => 0; }
//              ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f = int a(b) => 0; }
//                  ^
// [diag.namedFunctionExpression] Function expressions can't be named.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f = void a(b) {} }
//                   ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                         ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f = set a(b) {} }
//              ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f = 0 @annotation var f; }
//              ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f = 0 }
//              ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f = 0 var f; }
//              ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f = 0 const f = 0; }
//              ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f = 0 final f = 0; }
//              ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f = 0 int get a => 0; }
//              ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f = 0 int a(b) => 0; }
//              ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f = 0 void a(b) {} }
//              ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f = 0 set a(b) {} }
//              ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f @annotation var f; }
//          ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f, @annotation var f; }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f, }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f, var f; }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^^^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f, const f = 0; }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^^^^^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f, final f = 0; }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^^^^^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f, int get a => 0; }
//             ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f, int a(b) => 0; }
//             ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f, void a(b) {} }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^^^^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f, set a(b) {} }
//             ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f }
//          ^
// [diag.expectedToken] Expected to find ';'.
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
                name: A
              variables
                VariableDeclaration
                  name: f
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_type_name_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f var f; }
//          ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f const f = 0; }
//          ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f final f = 0; }
//          ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f int get a => 0; }
//          ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f int a(b) => 0; }
//          ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f void a(b) {} }
//          ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A f set a(b) {} }
//          ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A @annotation var f; }
//        ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A }
//        ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
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

  void test_field_declaration_type_noName_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A var f; }
//        ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A const f = 0; }
//        ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A final f = 0; }
//        ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A int get a => 0; }
//          ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A int a(b) => 0; }
//          ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A void a(b) {} }
//        ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A set a(b) {} }
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f = @annotation var f; }
//              ^
// [diag.expectedToken] Expected to find ';'.
//                ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f = }
//              ^
// [diag.expectedToken] Expected to find ';'.
//                ^
// [diag.missingIdentifier] Expected an identifier.
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
                  initializer: SimpleIdentifier
                    token: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_var_equals_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f = var f; }
//              ^
// [diag.expectedToken] Expected to find ';'.
//                ^^^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f = const f = 0; }
//                ^^^^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
//                      ^
// [diag.expectedToken] Expected to find '('.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f = final f = 0; }
//              ^
// [diag.expectedToken] Expected to find ';'.
//                ^^^^^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f = int get a => 0; }
//                ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f = int a(b) => 0; }
//                    ^
// [diag.namedFunctionExpression] Function expressions can't be named.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f = void a(b) {} }
//                     ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                           ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f = set a(b) {} }
//                ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f = 0 @annotation var f; }
//                ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f = 0 }
//                ^
// [diag.expectedToken] Expected to find ';'.
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
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_var_initializer_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f = 0 var f; }
//                ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f = 0 const f = 0; }
//                ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f = 0 final f = 0; }
//                ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f = 0 int get a => 0; }
//                ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f = 0 int a(b) => 0; }
//                ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f = 0 void a(b) {} }
//                ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f = 0 set a(b) {} }
//                ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f @annotation var f; }
//            ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f, @annotation var f; }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f, }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^
// [diag.missingIdentifier] Expected an identifier.
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
                VariableDeclaration
                  name: <empty> <synthetic>
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_var_name_comma_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f, var f; }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^^^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f, const f = 0; }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^^^^^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f, final f = 0; }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^^^^^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f, int get a => 0; }
//               ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f, int a(b) => 0; }
//               ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f, void a(b) {} }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^^^^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f, set a(b) {} }
//               ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f }
//            ^
// [diag.expectedToken] Expected to find ';'.
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
            semicolon: ; <synthetic>
        rightBracket: }
''');
  }

  void test_field_declaration_var_name_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f var f; }
//            ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f const f = 0; }
//            ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f final f = 0; }
//            ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f int get a => 0; }
//        ^^^
// [diag.varAndType] Variables can't be declared using both 'var' and a type name.
//              ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f int a(b) => 0; }
//        ^^^
// [diag.varAndType] Variables can't be declared using both 'var' and a type name.
//              ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f void a(b) {} }
//            ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var f set a(b) {} }
//        ^^^
// [diag.varReturnType] The return type can't be 'var'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var @annotation var f; }
//        ^^^
// [diag.expectedToken] Expected to find ';'.
//            ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var }
//        ^^^
// [diag.expectedToken] Expected to find ';'.
//            ^
// [diag.missingIdentifier] Expected an identifier.
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

  void test_field_declaration_var_noName_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var var f; }
//            ^^^
// [diag.duplicatedModifier] The modifier 'var' was already specified.
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
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_var_noName_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var const f = 0; }
//            ^^^^^
// [diag.conflictingModifiers] Members can't be declared to be both 'const' and 'var'.
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
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_var_noName_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var final f = 0; }
//            ^^^^^
// [diag.finalAndVar] Members can't be declared to be both 'final' and 'var'.
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
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ;
        rightBracket: }
''');
  }

  void test_field_declaration_var_noName_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var int get a => 0; }
//        ^^^
// [diag.varReturnType] The return type can't be 'var'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var int a(b) => 0; }
//        ^^^
// [diag.varReturnType] The return type can't be 'var'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var void a(b) {} }
//        ^^^
// [diag.varReturnType] The return type can't be 'var'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { var set a(b) {} }
//        ^^^
// [diag.varReturnType] The return type can't be 'var'.
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
