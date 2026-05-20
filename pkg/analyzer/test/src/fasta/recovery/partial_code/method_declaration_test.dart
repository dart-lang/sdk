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
  void test_method_declaration_noType_emptyNamed_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, {}) @annotation var f; }
//                ^
// [diag.missingIdentifier] Expected an identifier.
//                   ^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_noType_emptyNamed_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, {}) }
//                ^
// [diag.missingIdentifier] Expected an identifier.
//                   ^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_noType_emptyNamed_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, {}) var f; }
//                ^
// [diag.missingIdentifier] Expected an identifier.
//                   ^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_noType_emptyNamed_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, {}) const f = 0; }
//                ^
// [diag.missingIdentifier] Expected an identifier.
//                   ^^^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_noType_emptyNamed_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, {}) final f = 0; }
//                ^
// [diag.missingIdentifier] Expected an identifier.
//                   ^^^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_noType_emptyNamed_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, {}) int get a => 0; }
//                ^
// [diag.missingIdentifier] Expected an identifier.
//                   ^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_noType_emptyNamed_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, {}) int a(b) => 0; }
//                ^
// [diag.missingIdentifier] Expected an identifier.
//                   ^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_noType_emptyNamed_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, {}) void a(b) {} }
//                ^
// [diag.missingIdentifier] Expected an identifier.
//                   ^^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_noType_emptyNamed_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, {}) set a(b) {} }
//                ^
// [diag.missingIdentifier] Expected an identifier.
//                   ^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_noType_emptyOptional_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, []) @annotation var f; }
//                ^
// [diag.missingIdentifier] Expected an identifier.
//                   ^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_noType_emptyOptional_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, []) }
//                ^
// [diag.missingIdentifier] Expected an identifier.
//                   ^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_noType_emptyOptional_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, []) var f; }
//                ^
// [diag.missingIdentifier] Expected an identifier.
//                   ^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_noType_emptyOptional_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, []) const f = 0; }
//                ^
// [diag.missingIdentifier] Expected an identifier.
//                   ^^^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_noType_emptyOptional_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, []) final f = 0; }
//                ^
// [diag.missingIdentifier] Expected an identifier.
//                   ^^^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_noType_emptyOptional_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, []) int get a => 0; }
//                ^
// [diag.missingIdentifier] Expected an identifier.
//                   ^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_noType_emptyOptional_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, []) int a(b) => 0; }
//                ^
// [diag.missingIdentifier] Expected an identifier.
//                   ^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_noType_emptyOptional_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, []) void a(b) {} }
//                ^
// [diag.missingIdentifier] Expected an identifier.
//                   ^^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_noType_emptyOptional_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, []) set a(b) {} }
//                ^
// [diag.missingIdentifier] Expected an identifier.
//                   ^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_noType_leftParen_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m( @annotation var f; }
//                       ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
//                            ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                metadata
                  Annotation
                    atSign: @
                    name: SimpleIdentifier
                      token: annotation
                constFinalOrVarKeyword: var
                name: f
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_noType_leftParen_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m( }
//           ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_noType_leftParen_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m( var f; }
//           ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
//                ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                constFinalOrVarKeyword: var
                name: f
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_noType_leftParen_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m( const f = 0; }
//           ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
//                   ^
// [diag.namedParameterOutsideGroup] Named parameters must be enclosed in curly braces ('{' and '}').
//                      ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                constFinalOrVarKeyword: const
                name: f
                defaultClause: FormalParameterDefaultClause
                  separator: =
                  value: IntegerLiteral
                    literal: 0
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_noType_leftParen_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m( final f = 0; }
//           ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
//                   ^
// [diag.namedParameterOutsideGroup] Named parameters must be enclosed in curly braces ('{' and '}').
//                      ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                constFinalOrVarKeyword: final
                name: f
                defaultClause: FormalParameterDefaultClause
                  separator: =
                  value: IntegerLiteral
                    literal: 0
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_noType_leftParen_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m( int get a => 0; }
//                   ^
// [diag.unexpectedToken] Unexpected text 'a'.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: int
                name: get
              rightParenthesis: ) <synthetic>
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_noType_leftParen_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m( int a(b) => 0; }
//                    ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: int
                name: a
                functionTypedSuffix: FunctionTypedFormalParameterSuffix
                  formalParameters: FormalParameterList
                    leftParenthesis: (
                    parameter: RegularFormalParameter
                      name: b
                    rightParenthesis: )
              rightParenthesis: ) <synthetic>
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_noType_leftParen_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m( void a(b) {} }
//                     ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: void
                name: a
                functionTypedSuffix: FunctionTypedFormalParameterSuffix
                  formalParameters: FormalParameterList
                    leftParenthesis: (
                    parameter: RegularFormalParameter
                      name: b
                    rightParenthesis: )
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_method_declaration_noType_leftParen_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m( set a(b) {} }
//               ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: set
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_noType_noParams_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m() @annotation var f; }
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_noType_noParams_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m() }
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
            name: m
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

  void test_method_declaration_noType_noParams_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m() var f; }
//            ^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_noType_noParams_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m() const f = 0; }
//            ^^^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_noType_noParams_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m() final f = 0; }
//            ^^^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_noType_noParams_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m() int get a => 0; }
//            ^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_noType_noParams_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m() int a(b) => 0; }
//            ^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_noType_noParams_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m() void a(b) {} }
//            ^^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_noType_noParams_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m() set a(b) {} }
//            ^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_noType_paramAndComma_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, @annotation var f; }
//                           ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
//                                ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                metadata
                  Annotation
                    atSign: @
                    name: SimpleIdentifier
                      token: annotation
                constFinalOrVarKeyword: var
                name: f
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_noType_paramAndComma_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, }
//               ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_noType_paramAndComma_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, var f; }
//               ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
//                    ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                constFinalOrVarKeyword: var
                name: f
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_noType_paramAndComma_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, const f = 0; }
//               ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
//                       ^
// [diag.namedParameterOutsideGroup] Named parameters must be enclosed in curly braces ('{' and '}').
//                          ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                constFinalOrVarKeyword: const
                name: f
                defaultClause: FormalParameterDefaultClause
                  separator: =
                  value: IntegerLiteral
                    literal: 0
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_noType_paramAndComma_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, final f = 0; }
//               ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
//                       ^
// [diag.namedParameterOutsideGroup] Named parameters must be enclosed in curly braces ('{' and '}').
//                          ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                constFinalOrVarKeyword: final
                name: f
                defaultClause: FormalParameterDefaultClause
                  separator: =
                  value: IntegerLiteral
                    literal: 0
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_noType_paramAndComma_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, int get a => 0; }
//                       ^
// [diag.unexpectedToken] Unexpected text 'a'.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                type: NamedType
                  name: int
                name: get
              rightParenthesis: ) <synthetic>
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_noType_paramAndComma_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, int a(b) => 0; }
//                        ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                type: NamedType
                  name: int
                name: a
                functionTypedSuffix: FunctionTypedFormalParameterSuffix
                  formalParameters: FormalParameterList
                    leftParenthesis: (
                    parameter: RegularFormalParameter
                      name: b
                    rightParenthesis: )
              rightParenthesis: ) <synthetic>
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_noType_paramAndComma_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, void a(b) {} }
//                         ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                type: NamedType
                  name: void
                name: a
                functionTypedSuffix: FunctionTypedFormalParameterSuffix
                  formalParameters: FormalParameterList
                    leftParenthesis: (
                    parameter: RegularFormalParameter
                      name: b
                    rightParenthesis: )
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_method_declaration_noType_paramAndComma_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b, set a(b) {} }
//                   ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                name: set
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_noType_paramName_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B @annotation var f; }
//            ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: B
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

  void test_method_declaration_noType_paramName_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B }
//            ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: B
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_noType_paramName_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B var f; }
//            ^^^
// [diag.missingFunctionBody] A function body must be provided.
//            ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: B
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

  void test_method_declaration_noType_paramName_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B const f = 0; }
//            ^^^^^
// [diag.missingFunctionBody] A function body must be provided.
//            ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: B
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

  void test_method_declaration_noType_paramName_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B final f = 0; }
//            ^^^^^
// [diag.missingFunctionBody] A function body must be provided.
//            ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: B
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

  void test_method_declaration_noType_paramName_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B int get a => 0; }
//                ^^^
// [diag.missingFunctionBody] A function body must be provided.
//                ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: int
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

  void test_method_declaration_noType_paramName_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B int a(b) => 0; }
//                ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: int
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_noType_paramName_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B void a(b) {} }
//            ^^^^
// [diag.missingFunctionBody] A function body must be provided.
//            ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: B
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

  void test_method_declaration_noType_paramName_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B set a(b) {} }
//                ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: set
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_noType_params_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(b, c) @annotation var f; }
//                ^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_noType_params_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(b, c) }
//                ^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_noType_params_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(b, c) var f; }
//                ^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_noType_params_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(b, c) const f = 0; }
//                ^^^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_noType_params_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(b, c) final f = 0; }
//                ^^^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_noType_params_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(b, c) int get a => 0; }
//                ^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_noType_params_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(b, c) int a(b) => 0; }
//                ^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_noType_params_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(b, c) void a(b) {} }
//                ^^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_noType_params_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(b, c) set a(b) {} }
//                ^^^
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_noType_paramTypeAndName_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b @annotation var f; }
//              ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_noType_paramTypeAndName_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b }
//              ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_noType_paramTypeAndName_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b var f; }
//              ^^^
// [diag.missingFunctionBody] A function body must be provided.
//              ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_noType_paramTypeAndName_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b const f = 0; }
//              ^^^^^
// [diag.missingFunctionBody] A function body must be provided.
//              ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_noType_paramTypeAndName_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b final f = 0; }
//              ^^^^^
// [diag.missingFunctionBody] A function body must be provided.
//              ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_noType_paramTypeAndName_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b int get a => 0; }
//              ^^^
// [diag.missingFunctionBody] A function body must be provided.
//              ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_noType_paramTypeAndName_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b int a(b) => 0; }
//              ^^^
// [diag.missingFunctionBody] A function body must be provided.
//              ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_noType_paramTypeAndName_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b void a(b) {} }
//              ^^^^
// [diag.missingFunctionBody] A function body must be provided.
//              ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_noType_paramTypeAndName_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { m(B b set a(b) {} }
//              ^^^
// [diag.missingFunctionBody] A function body must be provided.
//              ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_static_noType_emptyNamed_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, {}) @annotation var f; }
//                       ^
// [diag.missingIdentifier] Expected an identifier.
//                          ^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_static_noType_emptyNamed_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, {}) }
//                       ^
// [diag.missingIdentifier] Expected an identifier.
//                          ^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_static_noType_emptyNamed_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, {}) var f; }
//                       ^
// [diag.missingIdentifier] Expected an identifier.
//                          ^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_static_noType_emptyNamed_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, {}) const f = 0; }
//                       ^
// [diag.missingIdentifier] Expected an identifier.
//                          ^^^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_static_noType_emptyNamed_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, {}) final f = 0; }
//                       ^
// [diag.missingIdentifier] Expected an identifier.
//                          ^^^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_static_noType_emptyNamed_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, {}) int get a => 0; }
//                       ^
// [diag.missingIdentifier] Expected an identifier.
//                          ^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_static_noType_emptyNamed_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, {}) int a(b) => 0; }
//                       ^
// [diag.missingIdentifier] Expected an identifier.
//                          ^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_static_noType_emptyNamed_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, {}) void a(b) {} }
//                       ^
// [diag.missingIdentifier] Expected an identifier.
//                          ^^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_static_noType_emptyNamed_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, {}) set a(b) {} }
//                       ^
// [diag.missingIdentifier] Expected an identifier.
//                          ^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_static_noType_emptyOptional_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, []) @annotation var f; }
//                       ^
// [diag.missingIdentifier] Expected an identifier.
//                          ^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_static_noType_emptyOptional_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, []) }
//                       ^
// [diag.missingIdentifier] Expected an identifier.
//                          ^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_static_noType_emptyOptional_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, []) var f; }
//                       ^
// [diag.missingIdentifier] Expected an identifier.
//                          ^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_static_noType_emptyOptional_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, []) const f = 0; }
//                       ^
// [diag.missingIdentifier] Expected an identifier.
//                          ^^^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_static_noType_emptyOptional_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, []) final f = 0; }
//                       ^
// [diag.missingIdentifier] Expected an identifier.
//                          ^^^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_static_noType_emptyOptional_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, []) int get a => 0; }
//                       ^
// [diag.missingIdentifier] Expected an identifier.
//                          ^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_static_noType_emptyOptional_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, []) int a(b) => 0; }
//                       ^
// [diag.missingIdentifier] Expected an identifier.
//                          ^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_static_noType_emptyOptional_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, []) void a(b) {} }
//                       ^
// [diag.missingIdentifier] Expected an identifier.
//                          ^^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_static_noType_emptyOptional_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, []) set a(b) {} }
//                       ^
// [diag.missingIdentifier] Expected an identifier.
//                          ^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_static_noType_leftParen_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m( @annotation var f; }
//                              ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
//                                   ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                metadata
                  Annotation
                    atSign: @
                    name: SimpleIdentifier
                      token: annotation
                constFinalOrVarKeyword: var
                name: f
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_static_noType_leftParen_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m( }
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_static_noType_leftParen_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m( var f; }
//                  ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
//                       ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                constFinalOrVarKeyword: var
                name: f
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_static_noType_leftParen_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m( const f = 0; }
//                  ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
//                          ^
// [diag.namedParameterOutsideGroup] Named parameters must be enclosed in curly braces ('{' and '}').
//                             ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                constFinalOrVarKeyword: const
                name: f
                defaultClause: FormalParameterDefaultClause
                  separator: =
                  value: IntegerLiteral
                    literal: 0
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_static_noType_leftParen_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m( final f = 0; }
//                  ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
//                          ^
// [diag.namedParameterOutsideGroup] Named parameters must be enclosed in curly braces ('{' and '}').
//                             ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                constFinalOrVarKeyword: final
                name: f
                defaultClause: FormalParameterDefaultClause
                  separator: =
                  value: IntegerLiteral
                    literal: 0
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_static_noType_leftParen_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m( int get a => 0; }
//                          ^
// [diag.unexpectedToken] Unexpected text 'a'.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: int
                name: get
              rightParenthesis: ) <synthetic>
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_static_noType_leftParen_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m( int a(b) => 0; }
//                           ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: int
                name: a
                functionTypedSuffix: FunctionTypedFormalParameterSuffix
                  formalParameters: FormalParameterList
                    leftParenthesis: (
                    parameter: RegularFormalParameter
                      name: b
                    rightParenthesis: )
              rightParenthesis: ) <synthetic>
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_static_noType_leftParen_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m( void a(b) {} }
//                            ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: void
                name: a
                functionTypedSuffix: FunctionTypedFormalParameterSuffix
                  formalParameters: FormalParameterList
                    leftParenthesis: (
                    parameter: RegularFormalParameter
                      name: b
                    rightParenthesis: )
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_method_declaration_static_noType_leftParen_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m( set a(b) {} }
//                      ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: set
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_static_noType_noParams_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m() @annotation var f; }
//                   ^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_static_noType_noParams_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m() }
//                   ^
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
            modifierKeyword: static
            name: m
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

  void test_method_declaration_static_noType_noParams_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m() var f; }
//                   ^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_static_noType_noParams_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m() const f = 0; }
//                   ^^^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_static_noType_noParams_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m() final f = 0; }
//                   ^^^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_static_noType_noParams_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m() int get a => 0; }
//                   ^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_static_noType_noParams_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m() int a(b) => 0; }
//                   ^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_static_noType_noParams_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m() void a(b) {} }
//                   ^^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_static_noType_noParams_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m() set a(b) {} }
//                   ^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_static_noType_paramAndComma_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, @annotation var f; }
//                                  ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
//                                       ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                metadata
                  Annotation
                    atSign: @
                    name: SimpleIdentifier
                      token: annotation
                constFinalOrVarKeyword: var
                name: f
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_static_noType_paramAndComma_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, }
//                      ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_static_noType_paramAndComma_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, var f; }
//                      ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
//                           ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                constFinalOrVarKeyword: var
                name: f
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_static_noType_paramAndComma_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, const f = 0; }
//                      ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
//                              ^
// [diag.namedParameterOutsideGroup] Named parameters must be enclosed in curly braces ('{' and '}').
//                                 ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                constFinalOrVarKeyword: const
                name: f
                defaultClause: FormalParameterDefaultClause
                  separator: =
                  value: IntegerLiteral
                    literal: 0
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_static_noType_paramAndComma_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, final f = 0; }
//                      ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
//                              ^
// [diag.namedParameterOutsideGroup] Named parameters must be enclosed in curly braces ('{' and '}').
//                                 ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                constFinalOrVarKeyword: final
                name: f
                defaultClause: FormalParameterDefaultClause
                  separator: =
                  value: IntegerLiteral
                    literal: 0
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_static_noType_paramAndComma_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, int get a => 0; }
//                              ^
// [diag.unexpectedToken] Unexpected text 'a'.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                type: NamedType
                  name: int
                name: get
              rightParenthesis: ) <synthetic>
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_static_noType_paramAndComma_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, int a(b) => 0; }
//                               ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                type: NamedType
                  name: int
                name: a
                functionTypedSuffix: FunctionTypedFormalParameterSuffix
                  formalParameters: FormalParameterList
                    leftParenthesis: (
                    parameter: RegularFormalParameter
                      name: b
                    rightParenthesis: )
              rightParenthesis: ) <synthetic>
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_static_noType_paramAndComma_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, void a(b) {} }
//                                ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                type: NamedType
                  name: void
                name: a
                functionTypedSuffix: FunctionTypedFormalParameterSuffix
                  formalParameters: FormalParameterList
                    leftParenthesis: (
                    parameter: RegularFormalParameter
                      name: b
                    rightParenthesis: )
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_method_declaration_static_noType_paramAndComma_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b, set a(b) {} }
//                          ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                name: set
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_static_noType_paramName_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B @annotation var f; }
//                   ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: B
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

  void test_method_declaration_static_noType_paramName_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B }
//                   ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: B
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_static_noType_paramName_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B var f; }
//                   ^^^
// [diag.missingFunctionBody] A function body must be provided.
//                   ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: B
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

  void test_method_declaration_static_noType_paramName_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B const f = 0; }
//                   ^^^^^
// [diag.missingFunctionBody] A function body must be provided.
//                   ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: B
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

  void test_method_declaration_static_noType_paramName_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B final f = 0; }
//                   ^^^^^
// [diag.missingFunctionBody] A function body must be provided.
//                   ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: B
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

  void test_method_declaration_static_noType_paramName_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B int get a => 0; }
//                       ^^^
// [diag.missingFunctionBody] A function body must be provided.
//                       ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: int
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

  void test_method_declaration_static_noType_paramName_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B int a(b) => 0; }
//                       ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: int
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_static_noType_paramName_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B void a(b) {} }
//                   ^^^^
// [diag.missingFunctionBody] A function body must be provided.
//                   ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: B
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

  void test_method_declaration_static_noType_paramName_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B set a(b) {} }
//                       ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: set
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_static_noType_params_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(b, c) @annotation var f; }
//                       ^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_static_noType_params_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(b, c) }
//                       ^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_static_noType_params_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(b, c) var f; }
//                       ^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_static_noType_params_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(b, c) const f = 0; }
//                       ^^^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_static_noType_params_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(b, c) final f = 0; }
//                       ^^^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_static_noType_params_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(b, c) int get a => 0; }
//                       ^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_static_noType_params_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(b, c) int a(b) => 0; }
//                       ^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_static_noType_params_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(b, c) void a(b) {} }
//                       ^^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_static_noType_params_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(b, c) set a(b) {} }
//                       ^^^
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
            modifierKeyword: static
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_static_noType_paramTypeAndName_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b @annotation var f; }
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_static_noType_paramTypeAndName_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b }
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_static_noType_paramTypeAndName_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b var f; }
//                     ^^^
// [diag.missingFunctionBody] A function body must be provided.
//                     ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_static_noType_paramTypeAndName_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b const f = 0; }
//                     ^^^^^
// [diag.missingFunctionBody] A function body must be provided.
//                     ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_static_noType_paramTypeAndName_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b final f = 0; }
//                     ^^^^^
// [diag.missingFunctionBody] A function body must be provided.
//                     ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_static_noType_paramTypeAndName_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b int get a => 0; }
//                     ^^^
// [diag.missingFunctionBody] A function body must be provided.
//                     ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_static_noType_paramTypeAndName_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b int a(b) => 0; }
//                     ^^^
// [diag.missingFunctionBody] A function body must be provided.
//                     ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_static_noType_paramTypeAndName_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b void a(b) {} }
//                     ^^^^
// [diag.missingFunctionBody] A function body must be provided.
//                     ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_static_noType_paramTypeAndName_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static m(B b set a(b) {} }
//                     ^^^
// [diag.missingFunctionBody] A function body must be provided.
//                     ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_static_type_emptyNamed_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, {}) @annotation var f; }
//                         ^
// [diag.missingIdentifier] Expected an identifier.
//                            ^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_static_type_emptyNamed_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, {}) }
//                         ^
// [diag.missingIdentifier] Expected an identifier.
//                            ^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_static_type_emptyNamed_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, {}) var f; }
//                         ^
// [diag.missingIdentifier] Expected an identifier.
//                            ^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_static_type_emptyNamed_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, {}) const f = 0; }
//                         ^
// [diag.missingIdentifier] Expected an identifier.
//                            ^^^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_static_type_emptyNamed_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, {}) final f = 0; }
//                         ^
// [diag.missingIdentifier] Expected an identifier.
//                            ^^^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_static_type_emptyNamed_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, {}) int get a => 0; }
//                         ^
// [diag.missingIdentifier] Expected an identifier.
//                            ^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_static_type_emptyNamed_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, {}) int a(b) => 0; }
//                         ^
// [diag.missingIdentifier] Expected an identifier.
//                            ^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_static_type_emptyNamed_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, {}) void a(b) {} }
//                         ^
// [diag.missingIdentifier] Expected an identifier.
//                            ^^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_static_type_emptyNamed_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, {}) set a(b) {} }
//                         ^
// [diag.missingIdentifier] Expected an identifier.
//                            ^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_static_type_emptyOptional_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, []) @annotation var f; }
//                         ^
// [diag.missingIdentifier] Expected an identifier.
//                            ^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_static_type_emptyOptional_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, []) }
//                         ^
// [diag.missingIdentifier] Expected an identifier.
//                            ^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_static_type_emptyOptional_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, []) var f; }
//                         ^
// [diag.missingIdentifier] Expected an identifier.
//                            ^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_static_type_emptyOptional_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, []) const f = 0; }
//                         ^
// [diag.missingIdentifier] Expected an identifier.
//                            ^^^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_static_type_emptyOptional_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, []) final f = 0; }
//                         ^
// [diag.missingIdentifier] Expected an identifier.
//                            ^^^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_static_type_emptyOptional_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, []) int get a => 0; }
//                         ^
// [diag.missingIdentifier] Expected an identifier.
//                            ^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_static_type_emptyOptional_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, []) int a(b) => 0; }
//                         ^
// [diag.missingIdentifier] Expected an identifier.
//                            ^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_static_type_emptyOptional_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, []) void a(b) {} }
//                         ^
// [diag.missingIdentifier] Expected an identifier.
//                            ^^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_static_type_emptyOptional_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, []) set a(b) {} }
//                         ^
// [diag.missingIdentifier] Expected an identifier.
//                            ^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_static_type_leftParen_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m( @annotation var f; }
//                                ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
//                                     ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                metadata
                  Annotation
                    atSign: @
                    name: SimpleIdentifier
                      token: annotation
                constFinalOrVarKeyword: var
                name: f
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_static_type_leftParen_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m( }
//                    ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_static_type_leftParen_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m( var f; }
//                    ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
//                         ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                constFinalOrVarKeyword: var
                name: f
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_static_type_leftParen_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m( const f = 0; }
//                    ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
//                            ^
// [diag.namedParameterOutsideGroup] Named parameters must be enclosed in curly braces ('{' and '}').
//                               ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                constFinalOrVarKeyword: const
                name: f
                defaultClause: FormalParameterDefaultClause
                  separator: =
                  value: IntegerLiteral
                    literal: 0
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_static_type_leftParen_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m( final f = 0; }
//                    ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
//                            ^
// [diag.namedParameterOutsideGroup] Named parameters must be enclosed in curly braces ('{' and '}').
//                               ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                constFinalOrVarKeyword: final
                name: f
                defaultClause: FormalParameterDefaultClause
                  separator: =
                  value: IntegerLiteral
                    literal: 0
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_static_type_leftParen_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m( int get a => 0; }
//                            ^
// [diag.unexpectedToken] Unexpected text 'a'.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: int
                name: get
              rightParenthesis: ) <synthetic>
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_static_type_leftParen_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m( int a(b) => 0; }
//                             ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: int
                name: a
                functionTypedSuffix: FunctionTypedFormalParameterSuffix
                  formalParameters: FormalParameterList
                    leftParenthesis: (
                    parameter: RegularFormalParameter
                      name: b
                    rightParenthesis: )
              rightParenthesis: ) <synthetic>
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_static_type_leftParen_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m( void a(b) {} }
//                              ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: void
                name: a
                functionTypedSuffix: FunctionTypedFormalParameterSuffix
                  formalParameters: FormalParameterList
                    leftParenthesis: (
                    parameter: RegularFormalParameter
                      name: b
                    rightParenthesis: )
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_method_declaration_static_type_leftParen_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m( set a(b) {} }
//                        ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: set
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_static_type_noParams_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m() @annotation var f; }
//                     ^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_static_type_noParams_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m() }
//                     ^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
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

  void test_method_declaration_static_type_noParams_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m() var f; }
//                     ^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_static_type_noParams_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m() const f = 0; }
//                     ^^^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_static_type_noParams_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m() final f = 0; }
//                     ^^^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_static_type_noParams_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m() int get a => 0; }
//                     ^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_static_type_noParams_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m() int a(b) => 0; }
//                     ^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_static_type_noParams_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m() void a(b) {} }
//                     ^^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_static_type_noParams_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m() set a(b) {} }
//                     ^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_static_type_paramAndComma_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, @annotation var f; }
//                                    ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
//                                         ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                metadata
                  Annotation
                    atSign: @
                    name: SimpleIdentifier
                      token: annotation
                constFinalOrVarKeyword: var
                name: f
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_static_type_paramAndComma_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, }
//                        ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_static_type_paramAndComma_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, var f; }
//                        ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
//                             ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                constFinalOrVarKeyword: var
                name: f
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_static_type_paramAndComma_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, const f = 0; }
//                        ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
//                                ^
// [diag.namedParameterOutsideGroup] Named parameters must be enclosed in curly braces ('{' and '}').
//                                   ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                constFinalOrVarKeyword: const
                name: f
                defaultClause: FormalParameterDefaultClause
                  separator: =
                  value: IntegerLiteral
                    literal: 0
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_static_type_paramAndComma_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, final f = 0; }
//                        ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
//                                ^
// [diag.namedParameterOutsideGroup] Named parameters must be enclosed in curly braces ('{' and '}').
//                                   ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                constFinalOrVarKeyword: final
                name: f
                defaultClause: FormalParameterDefaultClause
                  separator: =
                  value: IntegerLiteral
                    literal: 0
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_static_type_paramAndComma_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, int get a => 0; }
//                                ^
// [diag.unexpectedToken] Unexpected text 'a'.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                type: NamedType
                  name: int
                name: get
              rightParenthesis: ) <synthetic>
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_static_type_paramAndComma_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, int a(b) => 0; }
//                                 ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                type: NamedType
                  name: int
                name: a
                functionTypedSuffix: FunctionTypedFormalParameterSuffix
                  formalParameters: FormalParameterList
                    leftParenthesis: (
                    parameter: RegularFormalParameter
                      name: b
                    rightParenthesis: )
              rightParenthesis: ) <synthetic>
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_static_type_paramAndComma_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, void a(b) {} }
//                                  ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                type: NamedType
                  name: void
                name: a
                functionTypedSuffix: FunctionTypedFormalParameterSuffix
                  formalParameters: FormalParameterList
                    leftParenthesis: (
                    parameter: RegularFormalParameter
                      name: b
                    rightParenthesis: )
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_method_declaration_static_type_paramAndComma_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b, set a(b) {} }
//                            ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                name: set
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_static_type_paramName_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B @annotation var f; }
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: B
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

  void test_method_declaration_static_type_paramName_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B }
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: B
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_static_type_paramName_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B var f; }
//                     ^^^
// [diag.missingFunctionBody] A function body must be provided.
//                     ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: B
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

  void test_method_declaration_static_type_paramName_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B const f = 0; }
//                     ^^^^^
// [diag.missingFunctionBody] A function body must be provided.
//                     ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: B
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

  void test_method_declaration_static_type_paramName_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B final f = 0; }
//                     ^^^^^
// [diag.missingFunctionBody] A function body must be provided.
//                     ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: B
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

  void test_method_declaration_static_type_paramName_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B int get a => 0; }
//                         ^^^
// [diag.missingFunctionBody] A function body must be provided.
//                         ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: int
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

  void test_method_declaration_static_type_paramName_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B int a(b) => 0; }
//                         ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: int
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_static_type_paramName_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B void a(b) {} }
//                     ^^^^
// [diag.missingFunctionBody] A function body must be provided.
//                     ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: B
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

  void test_method_declaration_static_type_paramName_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B set a(b) {} }
//                         ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: set
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_static_type_params_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(b, c) @annotation var f; }
//                         ^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_static_type_params_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(b, c) }
//                         ^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_static_type_params_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(b, c) var f; }
//                         ^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_static_type_params_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(b, c) const f = 0; }
//                         ^^^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_static_type_params_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(b, c) final f = 0; }
//                         ^^^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_static_type_params_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(b, c) int get a => 0; }
//                         ^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_static_type_params_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(b, c) int a(b) => 0; }
//                         ^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_static_type_params_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(b, c) void a(b) {} }
//                         ^^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_static_type_params_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(b, c) set a(b) {} }
//                         ^^^
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
            modifierKeyword: static
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_static_type_paramTypeAndName_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b @annotation var f; }
//                       ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_static_type_paramTypeAndName_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b }
//                       ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_static_type_paramTypeAndName_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b var f; }
//                       ^^^
// [diag.missingFunctionBody] A function body must be provided.
//                       ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_static_type_paramTypeAndName_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b const f = 0; }
//                       ^^^^^
// [diag.missingFunctionBody] A function body must be provided.
//                       ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_static_type_paramTypeAndName_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b final f = 0; }
//                       ^^^^^
// [diag.missingFunctionBody] A function body must be provided.
//                       ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_static_type_paramTypeAndName_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b int get a => 0; }
//                       ^^^
// [diag.missingFunctionBody] A function body must be provided.
//                       ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_static_type_paramTypeAndName_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b int a(b) => 0; }
//                       ^^^
// [diag.missingFunctionBody] A function body must be provided.
//                       ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_static_type_paramTypeAndName_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b void a(b) {} }
//                       ^^^^
// [diag.missingFunctionBody] A function body must be provided.
//                       ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_static_type_paramTypeAndName_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { static A m(B b set a(b) {} }
//                       ^^^
// [diag.missingFunctionBody] A function body must be provided.
//                       ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_type_emptyNamed_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, {}) @annotation var f; }
//                  ^
// [diag.missingIdentifier] Expected an identifier.
//                     ^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_type_emptyNamed_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, {}) }
//                  ^
// [diag.missingIdentifier] Expected an identifier.
//                     ^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_type_emptyNamed_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, {}) var f; }
//                  ^
// [diag.missingIdentifier] Expected an identifier.
//                     ^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_type_emptyNamed_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, {}) const f = 0; }
//                  ^
// [diag.missingIdentifier] Expected an identifier.
//                     ^^^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_type_emptyNamed_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, {}) final f = 0; }
//                  ^
// [diag.missingIdentifier] Expected an identifier.
//                     ^^^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_type_emptyNamed_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, {}) int get a => 0; }
//                  ^
// [diag.missingIdentifier] Expected an identifier.
//                     ^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_type_emptyNamed_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, {}) int a(b) => 0; }
//                  ^
// [diag.missingIdentifier] Expected an identifier.
//                     ^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_type_emptyNamed_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, {}) void a(b) {} }
//                  ^
// [diag.missingIdentifier] Expected an identifier.
//                     ^^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
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

  void test_method_declaration_type_emptyNamed_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, {}) set a(b) {} }
//                  ^
// [diag.missingIdentifier] Expected an identifier.
//                     ^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: {
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: }
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_type_emptyOptional_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, []) @annotation var f; }
//                  ^
// [diag.missingIdentifier] Expected an identifier.
//                     ^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_type_emptyOptional_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, []) }
//                  ^
// [diag.missingIdentifier] Expected an identifier.
//                     ^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_type_emptyOptional_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, []) var f; }
//                  ^
// [diag.missingIdentifier] Expected an identifier.
//                     ^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_type_emptyOptional_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, []) const f = 0; }
//                  ^
// [diag.missingIdentifier] Expected an identifier.
//                     ^^^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_type_emptyOptional_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, []) final f = 0; }
//                  ^
// [diag.missingIdentifier] Expected an identifier.
//                     ^^^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_type_emptyOptional_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, []) int get a => 0; }
//                  ^
// [diag.missingIdentifier] Expected an identifier.
//                     ^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_type_emptyOptional_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, []) int a(b) => 0; }
//                  ^
// [diag.missingIdentifier] Expected an identifier.
//                     ^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_type_emptyOptional_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, []) void a(b) {} }
//                  ^
// [diag.missingIdentifier] Expected an identifier.
//                     ^^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
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

  void test_method_declaration_type_emptyOptional_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, []) set a(b) {} }
//                  ^
// [diag.missingIdentifier] Expected an identifier.
//                     ^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              leftDelimiter: [
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
              rightDelimiter: ]
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_type_leftParen_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m( @annotation var f; }
//                         ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
//                              ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                metadata
                  Annotation
                    atSign: @
                    name: SimpleIdentifier
                      token: annotation
                constFinalOrVarKeyword: var
                name: f
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_type_leftParen_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m( }
//             ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_type_leftParen_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m( var f; }
//             ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
//                  ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                constFinalOrVarKeyword: var
                name: f
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_type_leftParen_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m( const f = 0; }
//             ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
//                     ^
// [diag.namedParameterOutsideGroup] Named parameters must be enclosed in curly braces ('{' and '}').
//                        ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                constFinalOrVarKeyword: const
                name: f
                defaultClause: FormalParameterDefaultClause
                  separator: =
                  value: IntegerLiteral
                    literal: 0
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_type_leftParen_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m( final f = 0; }
//             ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
//                     ^
// [diag.namedParameterOutsideGroup] Named parameters must be enclosed in curly braces ('{' and '}').
//                        ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                constFinalOrVarKeyword: final
                name: f
                defaultClause: FormalParameterDefaultClause
                  separator: =
                  value: IntegerLiteral
                    literal: 0
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_type_leftParen_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m( int get a => 0; }
//                     ^
// [diag.unexpectedToken] Unexpected text 'a'.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: int
                name: get
              rightParenthesis: ) <synthetic>
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_type_leftParen_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m( int a(b) => 0; }
//                      ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: int
                name: a
                functionTypedSuffix: FunctionTypedFormalParameterSuffix
                  formalParameters: FormalParameterList
                    leftParenthesis: (
                    parameter: RegularFormalParameter
                      name: b
                    rightParenthesis: )
              rightParenthesis: ) <synthetic>
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_type_leftParen_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m( void a(b) {} }
//                       ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: void
                name: a
                functionTypedSuffix: FunctionTypedFormalParameterSuffix
                  formalParameters: FormalParameterList
                    leftParenthesis: (
                    parameter: RegularFormalParameter
                      name: b
                    rightParenthesis: )
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_method_declaration_type_leftParen_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m( set a(b) {} }
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: set
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_type_noParams_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m() @annotation var f; }
//              ^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_type_noParams_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m() }
//              ^
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
            returnType: NamedType
              name: A
            name: m
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

  void test_method_declaration_type_noParams_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m() var f; }
//              ^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_type_noParams_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m() const f = 0; }
//              ^^^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_type_noParams_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m() final f = 0; }
//              ^^^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_type_noParams_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m() int get a => 0; }
//              ^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_type_noParams_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m() int a(b) => 0; }
//              ^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_type_noParams_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m() void a(b) {} }
//              ^^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
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

  void test_method_declaration_type_noParams_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m() set a(b) {} }
//              ^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_type_paramAndComma_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, @annotation var f; }
//                             ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
//                                  ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                metadata
                  Annotation
                    atSign: @
                    name: SimpleIdentifier
                      token: annotation
                constFinalOrVarKeyword: var
                name: f
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_type_paramAndComma_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, }
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_type_paramAndComma_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, var f; }
//                 ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
//                      ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                constFinalOrVarKeyword: var
                name: f
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_type_paramAndComma_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, const f = 0; }
//                 ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
//                         ^
// [diag.namedParameterOutsideGroup] Named parameters must be enclosed in curly braces ('{' and '}').
//                            ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                constFinalOrVarKeyword: const
                name: f
                defaultClause: FormalParameterDefaultClause
                  separator: =
                  value: IntegerLiteral
                    literal: 0
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_type_paramAndComma_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, final f = 0; }
//                 ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
//                         ^
// [diag.namedParameterOutsideGroup] Named parameters must be enclosed in curly braces ('{' and '}').
//                            ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                constFinalOrVarKeyword: final
                name: f
                defaultClause: FormalParameterDefaultClause
                  separator: =
                  value: IntegerLiteral
                    literal: 0
              rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_type_paramAndComma_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, int get a => 0; }
//                         ^
// [diag.unexpectedToken] Unexpected text 'a'.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                type: NamedType
                  name: int
                name: get
              rightParenthesis: ) <synthetic>
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_type_paramAndComma_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, int a(b) => 0; }
//                          ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                type: NamedType
                  name: int
                name: a
                functionTypedSuffix: FunctionTypedFormalParameterSuffix
                  formalParameters: FormalParameterList
                    leftParenthesis: (
                    parameter: RegularFormalParameter
                      name: b
                    rightParenthesis: )
              rightParenthesis: ) <synthetic>
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_declaration_type_paramAndComma_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, void a(b) {} }
//                           ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                type: NamedType
                  name: void
                name: a
                functionTypedSuffix: FunctionTypedFormalParameterSuffix
                  formalParameters: FormalParameterList
                    leftParenthesis: (
                    parameter: RegularFormalParameter
                      name: b
                    rightParenthesis: )
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: }
''');
  }

  void test_method_declaration_type_paramAndComma_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b, set a(b) {} }
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              parameter: RegularFormalParameter
                name: set
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_type_paramName_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B @annotation var f; }
//              ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: B
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

  void test_method_declaration_type_paramName_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B }
//              ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: B
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_type_paramName_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B var f; }
//              ^^^
// [diag.missingFunctionBody] A function body must be provided.
//              ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: B
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

  void test_method_declaration_type_paramName_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B const f = 0; }
//              ^^^^^
// [diag.missingFunctionBody] A function body must be provided.
//              ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: B
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

  void test_method_declaration_type_paramName_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B final f = 0; }
//              ^^^^^
// [diag.missingFunctionBody] A function body must be provided.
//              ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: B
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

  void test_method_declaration_type_paramName_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B int get a => 0; }
//                  ^^^
// [diag.missingFunctionBody] A function body must be provided.
//                  ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: int
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

  void test_method_declaration_type_paramName_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B int a(b) => 0; }
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: int
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_type_paramName_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B void a(b) {} }
//              ^^^^
// [diag.missingFunctionBody] A function body must be provided.
//              ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: B
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

  void test_method_declaration_type_paramName_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B set a(b) {} }
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: set
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_type_params_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(b, c) @annotation var f; }
//                  ^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_type_params_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(b, c) }
//                  ^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_type_params_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(b, c) var f; }
//                  ^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_type_params_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(b, c) const f = 0; }
//                  ^^^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_type_params_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(b, c) final f = 0; }
//                  ^^^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_type_params_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(b, c) int get a => 0; }
//                  ^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_type_params_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(b, c) int a(b) => 0; }
//                  ^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_type_params_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(b, c) void a(b) {} }
//                  ^^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
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

  void test_method_declaration_type_params_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(b, c) set a(b) {} }
//                  ^^^
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
            returnType: NamedType
              name: A
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              parameter: RegularFormalParameter
                name: c
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_method_declaration_type_paramTypeAndName_annotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b @annotation var f; }
//                ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_type_paramTypeAndName_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b }
//                ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
        rightBracket: }
''');
  }

  void test_method_declaration_type_paramTypeAndName_field() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b var f; }
//                ^^^
// [diag.missingFunctionBody] A function body must be provided.
//                ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_type_paramTypeAndName_fieldConst() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b const f = 0; }
//                ^^^^^
// [diag.missingFunctionBody] A function body must be provided.
//                ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_type_paramTypeAndName_fieldFinal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b final f = 0; }
//                ^^^^^
// [diag.missingFunctionBody] A function body must be provided.
//                ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_type_paramTypeAndName_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b int get a => 0; }
//                ^^^
// [diag.missingFunctionBody] A function body must be provided.
//                ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_type_paramTypeAndName_methodNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b int a(b) => 0; }
//                ^^^
// [diag.missingFunctionBody] A function body must be provided.
//                ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_type_paramTypeAndName_methodVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b void a(b) {} }
//                ^^^^
// [diag.missingFunctionBody] A function body must be provided.
//                ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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

  void test_method_declaration_type_paramTypeAndName_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C { A m(B b set a(b) {} }
//                ^^^
// [diag.missingFunctionBody] A function body must be provided.
//                ^
// [diag.expectedToken] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
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
            name: m
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: B
                name: b
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
