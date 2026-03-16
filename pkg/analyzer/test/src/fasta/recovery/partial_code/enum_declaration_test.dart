// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumDeclarationTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class EnumDeclarationTest extends ParserDiagnosticsTest {
  void test_enum_declaration_comma_class() {
    var parseResult = parseStringWithErrors(r'''
enum E {, class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 1),
      error(diag.missingIdentifier, 8, 1),
      error(diag.missingIdentifier, 10, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: } <synthetic>
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_enum_declaration_comma_const() {
    var parseResult = parseStringWithErrors(r'''
enum E {, const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
      error(diag.missingIdentifier, 8, 1),
      error(diag.missingIdentifier, 10, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: } <synthetic>
    TopLevelVariableDeclaration
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

  void test_enum_declaration_comma_enum() {
    var parseResult = parseStringWithErrors(r'''
enum E {, enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
      error(diag.missingIdentifier, 8, 1),
      error(diag.missingIdentifier, 10, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: } <synthetic>
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_enum_declaration_comma_eof() {
    var parseResult = parseStringWithErrors(r'''
enum E {,
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 1),
      error(diag.missingIdentifier, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_enum_declaration_comma_final() {
    var parseResult = parseStringWithErrors(r'''
enum E {, final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
      error(diag.missingIdentifier, 8, 1),
      error(diag.missingIdentifier, 10, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: } <synthetic>
    TopLevelVariableDeclaration
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

  void test_enum_declaration_comma_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
enum E {, int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 1),
      error(diag.missingIdentifier, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: int
        rightBracket: } <synthetic>
    FunctionDeclaration
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

  void test_enum_declaration_comma_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
enum E {, void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.missingIdentifier, 8, 1),
      error(diag.missingIdentifier, 10, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: } <synthetic>
    FunctionDeclaration
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

  void test_enum_declaration_comma_getter() {
    var parseResult = parseStringWithErrors(r'''
enum E {, int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
      error(diag.missingIdentifier, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: int
        rightBracket: } <synthetic>
    FunctionDeclaration
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

  void test_enum_declaration_comma_mixin() {
    var parseResult = parseStringWithErrors(r'''
enum E {, mixin M {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 1),
      error(diag.missingIdentifier, 8, 1),
      error(diag.missingFunctionParameters, 16, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: mixin
        rightBracket: } <synthetic>
    FunctionDeclaration
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

  void test_enum_declaration_comma_setter() {
    var parseResult = parseStringWithErrors(r'''
enum E {, set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.missingIdentifier, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: set
        rightBracket: } <synthetic>
    FunctionDeclaration
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

  void test_enum_declaration_comma_typedef() {
    var parseResult = parseStringWithErrors(r'''
enum E {, typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 40, 1),
      error(diag.missingIdentifier, 8, 1),
      error(diag.missingConstFinalVarOrType, 18, 1),
      error(diag.expectedToken, 22, 1),
      error(diag.missingFunctionBody, 38, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: typedef
        rightBracket: } <synthetic>
    TopLevelVariableDeclaration
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

  void test_enum_declaration_comma_var() {
    var parseResult = parseStringWithErrors(r'''
enum E {, var a;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 17, 1),
      error(diag.missingIdentifier, 8, 1),
      error(diag.missingIdentifier, 10, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: } <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_enum_declaration_commaRightBrace_class() {
    var parseResult = parseStringWithErrors(r'''
enum E {,} class A {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: }
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_enum_declaration_commaRightBrace_const() {
    var parseResult = parseStringWithErrors(r'''
enum E {,} const a = 0;
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: }
    TopLevelVariableDeclaration
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

  void test_enum_declaration_commaRightBrace_enum() {
    var parseResult = parseStringWithErrors(r'''
enum E {,} enum E { v }
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: }
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_enum_declaration_commaRightBrace_eof() {
    var parseResult = parseStringWithErrors(r'''
enum E {,}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: }
''');
  }

  void test_enum_declaration_commaRightBrace_final() {
    var parseResult = parseStringWithErrors(r'''
enum E {,} final a = 0;
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: }
    TopLevelVariableDeclaration
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

  void test_enum_declaration_commaRightBrace_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
enum E {,} int f() {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: }
    FunctionDeclaration
      returnType: NamedType
        name: int
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

  void test_enum_declaration_commaRightBrace_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
enum E {,} void f() {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: }
    FunctionDeclaration
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

  void test_enum_declaration_commaRightBrace_getter() {
    var parseResult = parseStringWithErrors(r'''
enum E {,} int get a => 0;
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: }
    FunctionDeclaration
      returnType: NamedType
        name: int
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

  void test_enum_declaration_commaRightBrace_mixin() {
    var parseResult = parseStringWithErrors(r'''
enum E {,} mixin M {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: }
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_enum_declaration_commaRightBrace_setter() {
    var parseResult = parseStringWithErrors(r'''
enum E {,} set a(b) {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: }
    FunctionDeclaration
      propertyKeyword: set
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

  void test_enum_declaration_commaRightBrace_typedef() {
    var parseResult = parseStringWithErrors(r'''
enum E {,} typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: }
    GenericTypeAlias
      typedefKeyword: typedef
      name: A
      equals: =
      type: GenericFunctionType
        returnType: NamedType
          name: B
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            type: NamedType
              name: C
          parameter: SimpleFormalParameter
            type: NamedType
              name: D
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_enum_declaration_commaRightBrace_var() {
    var parseResult = parseStringWithErrors(r'''
enum E {,} var a;
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: }
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_enum_declaration_commaValue_class() {
    var parseResult = parseStringWithErrors(r'''
enum E {,a class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.missingIdentifier, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: a
        rightBracket: } <synthetic>
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_enum_declaration_commaValue_const() {
    var parseResult = parseStringWithErrors(r'''
enum E {,a const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 1),
      error(diag.missingIdentifier, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: a
        rightBracket: } <synthetic>
    TopLevelVariableDeclaration
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

  void test_enum_declaration_commaValue_enum() {
    var parseResult = parseStringWithErrors(r'''
enum E {,a enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 1),
      error(diag.missingIdentifier, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: a
        rightBracket: } <synthetic>
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_enum_declaration_commaValue_eof() {
    var parseResult = parseStringWithErrors(r'''
enum E {,a
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 11, 1),
      error(diag.missingIdentifier, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: a
        rightBracket: } <synthetic>
''');
  }

  void test_enum_declaration_commaValue_final() {
    var parseResult = parseStringWithErrors(r'''
enum E {,a final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 1),
      error(diag.missingIdentifier, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: a
        rightBracket: } <synthetic>
    TopLevelVariableDeclaration
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

  void test_enum_declaration_commaValue_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
enum E {,a int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.missingIdentifier, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: a
        rightBracket: } <synthetic>
    FunctionDeclaration
      returnType: NamedType
        name: int
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

  void test_enum_declaration_commaValue_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
enum E {,a void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
      error(diag.missingIdentifier, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: a
        rightBracket: } <synthetic>
    FunctionDeclaration
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

  void test_enum_declaration_commaValue_getter() {
    var parseResult = parseStringWithErrors(r'''
enum E {,a int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.missingIdentifier, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: a
        rightBracket: } <synthetic>
    FunctionDeclaration
      returnType: NamedType
        name: int
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

  void test_enum_declaration_commaValue_mixin() {
    var parseResult = parseStringWithErrors(r'''
enum E {,a mixin M {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.missingIdentifier, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: a
        rightBracket: } <synthetic>
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_enum_declaration_commaValue_setter() {
    var parseResult = parseStringWithErrors(r'''
enum E {,a set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
      error(diag.missingIdentifier, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: a
        rightBracket: } <synthetic>
    FunctionDeclaration
      propertyKeyword: set
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

  void test_enum_declaration_commaValue_typedef() {
    var parseResult = parseStringWithErrors(r'''
enum E {,a typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 41, 1),
      error(diag.missingIdentifier, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: a
        rightBracket: } <synthetic>
    GenericTypeAlias
      typedefKeyword: typedef
      name: A
      equals: =
      type: GenericFunctionType
        returnType: NamedType
          name: B
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            type: NamedType
              name: C
          parameter: SimpleFormalParameter
            type: NamedType
              name: D
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_enum_declaration_commaValue_var() {
    var parseResult = parseStringWithErrors(r'''
enum E {,a var a;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 1),
      error(diag.missingIdentifier, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: a
        rightBracket: } <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_enum_declaration_commaValueRightBrace_class() {
    var parseResult = parseStringWithErrors(r'''
enum E {, a} class A {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: a
        rightBracket: }
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_enum_declaration_commaValueRightBrace_const() {
    var parseResult = parseStringWithErrors(r'''
enum E {, a} const a = 0;
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: a
        rightBracket: }
    TopLevelVariableDeclaration
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

  void test_enum_declaration_commaValueRightBrace_enum() {
    var parseResult = parseStringWithErrors(r'''
enum E {, a} enum E { v }
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: a
        rightBracket: }
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_enum_declaration_commaValueRightBrace_eof() {
    var parseResult = parseStringWithErrors(r'''
enum E {, a}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: a
        rightBracket: }
''');
  }

  void test_enum_declaration_commaValueRightBrace_final() {
    var parseResult = parseStringWithErrors(r'''
enum E {, a} final a = 0;
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: a
        rightBracket: }
    TopLevelVariableDeclaration
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

  void test_enum_declaration_commaValueRightBrace_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
enum E {, a} int f() {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: a
        rightBracket: }
    FunctionDeclaration
      returnType: NamedType
        name: int
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

  void test_enum_declaration_commaValueRightBrace_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
enum E {, a} void f() {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: a
        rightBracket: }
    FunctionDeclaration
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

  void test_enum_declaration_commaValueRightBrace_getter() {
    var parseResult = parseStringWithErrors(r'''
enum E {, a} int get a => 0;
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: a
        rightBracket: }
    FunctionDeclaration
      returnType: NamedType
        name: int
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

  void test_enum_declaration_commaValueRightBrace_mixin() {
    var parseResult = parseStringWithErrors(r'''
enum E {, a} mixin M {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: a
        rightBracket: }
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_enum_declaration_commaValueRightBrace_setter() {
    var parseResult = parseStringWithErrors(r'''
enum E {, a} set a(b) {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: a
        rightBracket: }
    FunctionDeclaration
      propertyKeyword: set
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

  void test_enum_declaration_commaValueRightBrace_typedef() {
    var parseResult = parseStringWithErrors(r'''
enum E {, a} typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: a
        rightBracket: }
    GenericTypeAlias
      typedefKeyword: typedef
      name: A
      equals: =
      type: GenericFunctionType
        returnType: NamedType
          name: B
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            type: NamedType
              name: C
          parameter: SimpleFormalParameter
            type: NamedType
              name: D
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_enum_declaration_commaValueRightBrace_var() {
    var parseResult = parseStringWithErrors(r'''
enum E {, a} var a;
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
          EnumConstantDeclaration
            name: a
        rightBracket: }
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_enum_declaration_keyword_class() {
    var parseResult = parseStringWithErrors(r'''
enum class A {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 5, 5),
      error(diag.missingEnumBody, 5, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockEnumBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_enum_declaration_keyword_const() {
    var parseResult = parseStringWithErrors(r'''
enum const a = 0;
''');
    parseResult.assertErrors([
      error(diag.constWithoutPrimaryConstructor, 5, 5),
      error(diag.missingEnumBody, 13, 1),
      error(diag.expectedExecutable, 13, 1),
      error(diag.expectedExecutable, 15, 1),
      error(diag.unexpectedToken, 16, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: a
      body: BlockEnumBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_enum_declaration_keyword_enum() {
    var parseResult = parseStringWithErrors(r'''
enum enum E { v }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 5, 4),
      error(diag.missingEnumBody, 5, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockEnumBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_enum_declaration_keyword_eof() {
    var parseResult = parseStringWithErrors(r'''
enum
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 5, 0),
      error(diag.missingEnumBody, 5, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockEnumBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_enum_declaration_keyword_final() {
    var parseResult = parseStringWithErrors(r'''
enum final a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 5, 5),
      error(diag.missingEnumBody, 5, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockEnumBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    TopLevelVariableDeclaration
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

  void test_enum_declaration_keyword_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
enum int f() {}
''');
    parseResult.assertErrors([error(diag.unexpectedTokens, 9, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: int
      body: BlockEnumBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_enum_declaration_keyword_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
enum void f() {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 5, 4),
      error(diag.missingEnumBody, 5, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockEnumBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    FunctionDeclaration
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

  void test_enum_declaration_keyword_getter() {
    var parseResult = parseStringWithErrors(r'''
enum int get a => 0;
''');
    parseResult.assertErrors([error(diag.missingEnumBody, 9, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: int
      body: BlockEnumBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    FunctionDeclaration
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

  void test_enum_declaration_keyword_mixin() {
    var parseResult = parseStringWithErrors(r'''
enum mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 5, 5),
      error(diag.missingEnumBody, 5, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockEnumBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_enum_declaration_keyword_setter() {
    var parseResult = parseStringWithErrors(r'''
enum set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 5, 3),
      error(diag.missingEnumBody, 5, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockEnumBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    FunctionDeclaration
      propertyKeyword: set
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

  void test_enum_declaration_keyword_typedef() {
    var parseResult = parseStringWithErrors(r'''
enum typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 5, 7),
      error(diag.missingEnumBody, 5, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockEnumBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    GenericTypeAlias
      typedefKeyword: typedef
      name: A
      equals: =
      type: GenericFunctionType
        returnType: NamedType
          name: B
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            type: NamedType
              name: C
          parameter: SimpleFormalParameter
            type: NamedType
              name: D
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_enum_declaration_keyword_var() {
    var parseResult = parseStringWithErrors(r'''
enum var a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 5, 3),
      error(diag.missingEnumBody, 5, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockEnumBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_enum_declaration_leftBrace_class() {
    var parseResult = parseStringWithErrors(r'''
enum E { class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 20, 1),
      error(diag.missingIdentifier, 9, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: } <synthetic>
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_enum_declaration_leftBrace_const() {
    var parseResult = parseStringWithErrors(r'''
enum E { const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.missingIdentifier, 9, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: } <synthetic>
    TopLevelVariableDeclaration
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

  void test_enum_declaration_leftBrace_enum() {
    var parseResult = parseStringWithErrors(r'''
enum E { enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.missingIdentifier, 9, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: } <synthetic>
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_enum_declaration_leftBrace_eof() {
    var parseResult = parseStringWithErrors(r'''
enum E {
''');
    parseResult.assertErrors([error(diag.expectedToken, 9, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        rightBracket: } <synthetic>
''');
  }

  void test_enum_declaration_leftBrace_final() {
    var parseResult = parseStringWithErrors(r'''
enum E { final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.missingIdentifier, 9, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: } <synthetic>
    TopLevelVariableDeclaration
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

  void test_enum_declaration_leftBrace_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
enum E { int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: int
        rightBracket: } <synthetic>
    FunctionDeclaration
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

  void test_enum_declaration_leftBrace_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
enum E { void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 1),
      error(diag.missingIdentifier, 9, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: } <synthetic>
    FunctionDeclaration
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

  void test_enum_declaration_leftBrace_getter() {
    var parseResult = parseStringWithErrors(r'''
enum E { int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 25, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: int
        rightBracket: } <synthetic>
    FunctionDeclaration
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

  void test_enum_declaration_leftBrace_mixin() {
    var parseResult = parseStringWithErrors(r'''
enum E { mixin M {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 20, 1),
      error(diag.missingFunctionParameters, 15, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: mixin
        rightBracket: } <synthetic>
    FunctionDeclaration
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

  void test_enum_declaration_leftBrace_setter() {
    var parseResult = parseStringWithErrors(r'''
enum E { set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: set
        rightBracket: } <synthetic>
    FunctionDeclaration
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

  void test_enum_declaration_leftBrace_typedef() {
    var parseResult = parseStringWithErrors(r'''
enum E { typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 39, 1),
      error(diag.missingConstFinalVarOrType, 17, 1),
      error(diag.expectedToken, 21, 1),
      error(diag.missingFunctionBody, 37, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: typedef
        rightBracket: } <synthetic>
    TopLevelVariableDeclaration
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

  void test_enum_declaration_leftBrace_var() {
    var parseResult = parseStringWithErrors(r'''
enum E { var a;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 16, 1),
      error(diag.missingIdentifier, 9, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: } <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_enum_declaration_missingName_class() {
    var parseResult = parseStringWithErrors(r'''
enum {} class A {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 5, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockEnumBody
        leftBracket: {
        rightBracket: }
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_enum_declaration_missingName_const() {
    var parseResult = parseStringWithErrors(r'''
enum {} const a = 0;
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 5, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockEnumBody
        leftBracket: {
        rightBracket: }
    TopLevelVariableDeclaration
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

  void test_enum_declaration_missingName_enum() {
    var parseResult = parseStringWithErrors(r'''
enum {} enum E { v }
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 5, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockEnumBody
        leftBracket: {
        rightBracket: }
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_enum_declaration_missingName_eof() {
    var parseResult = parseStringWithErrors(r'''
enum {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 5, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockEnumBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_enum_declaration_missingName_final() {
    var parseResult = parseStringWithErrors(r'''
enum {} final a = 0;
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 5, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockEnumBody
        leftBracket: {
        rightBracket: }
    TopLevelVariableDeclaration
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

  void test_enum_declaration_missingName_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
enum {} int f() {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 5, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockEnumBody
        leftBracket: {
        rightBracket: }
    FunctionDeclaration
      returnType: NamedType
        name: int
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

  void test_enum_declaration_missingName_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
enum {} void f() {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 5, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockEnumBody
        leftBracket: {
        rightBracket: }
    FunctionDeclaration
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

  void test_enum_declaration_missingName_getter() {
    var parseResult = parseStringWithErrors(r'''
enum {} int get a => 0;
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 5, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockEnumBody
        leftBracket: {
        rightBracket: }
    FunctionDeclaration
      returnType: NamedType
        name: int
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

  void test_enum_declaration_missingName_mixin() {
    var parseResult = parseStringWithErrors(r'''
enum {} mixin M {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 5, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockEnumBody
        leftBracket: {
        rightBracket: }
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_enum_declaration_missingName_setter() {
    var parseResult = parseStringWithErrors(r'''
enum {} set a(b) {}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 5, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockEnumBody
        leftBracket: {
        rightBracket: }
    FunctionDeclaration
      propertyKeyword: set
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

  void test_enum_declaration_missingName_typedef() {
    var parseResult = parseStringWithErrors(r'''
enum {} typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 5, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockEnumBody
        leftBracket: {
        rightBracket: }
    GenericTypeAlias
      typedefKeyword: typedef
      name: A
      equals: =
      type: GenericFunctionType
        returnType: NamedType
          name: B
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            type: NamedType
              name: C
          parameter: SimpleFormalParameter
            type: NamedType
              name: D
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_enum_declaration_missingName_var() {
    var parseResult = parseStringWithErrors(r'''
enum {} var a;
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 5, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockEnumBody
        leftBracket: {
        rightBracket: }
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_enum_declaration_name_class() {
    var parseResult = parseStringWithErrors(r'''
enum E class A {}
''');
    parseResult.assertErrors([error(diag.missingEnumBody, 7, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_enum_declaration_name_const() {
    var parseResult = parseStringWithErrors(r'''
enum E const a = 0;
''');
    parseResult.assertErrors([error(diag.missingEnumBody, 7, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    TopLevelVariableDeclaration
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

  void test_enum_declaration_name_enum() {
    var parseResult = parseStringWithErrors(r'''
enum E enum E { v }
''');
    parseResult.assertErrors([error(diag.missingEnumBody, 7, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_enum_declaration_name_eof() {
    var parseResult = parseStringWithErrors(r'''
enum E
''');
    parseResult.assertErrors([error(diag.missingEnumBody, 7, 0)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_enum_declaration_name_final() {
    var parseResult = parseStringWithErrors(r'''
enum E final a = 0;
''');
    parseResult.assertErrors([error(diag.missingEnumBody, 7, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    TopLevelVariableDeclaration
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

  void test_enum_declaration_name_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
enum E int f() {}
''');
    parseResult.assertErrors([error(diag.missingEnumBody, 7, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    FunctionDeclaration
      returnType: NamedType
        name: int
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

  void test_enum_declaration_name_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
enum E void f() {}
''');
    parseResult.assertErrors([error(diag.missingEnumBody, 7, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    FunctionDeclaration
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

  void test_enum_declaration_name_getter() {
    var parseResult = parseStringWithErrors(r'''
enum E int get a => 0;
''');
    parseResult.assertErrors([error(diag.missingEnumBody, 7, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    FunctionDeclaration
      returnType: NamedType
        name: int
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

  void test_enum_declaration_name_mixin() {
    var parseResult = parseStringWithErrors(r'''
enum E mixin M {}
''');
    parseResult.assertErrors([error(diag.missingEnumBody, 7, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_enum_declaration_name_setter() {
    var parseResult = parseStringWithErrors(r'''
enum E set a(b) {}
''');
    parseResult.assertErrors([error(diag.missingEnumBody, 7, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    FunctionDeclaration
      propertyKeyword: set
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

  void test_enum_declaration_name_typedef() {
    var parseResult = parseStringWithErrors(r'''
enum E typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.missingEnumBody, 7, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    GenericTypeAlias
      typedefKeyword: typedef
      name: A
      equals: =
      type: GenericFunctionType
        returnType: NamedType
          name: B
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            type: NamedType
              name: C
          parameter: SimpleFormalParameter
            type: NamedType
              name: D
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_enum_declaration_name_var() {
    var parseResult = parseStringWithErrors(r'''
enum E var a;
''');
    parseResult.assertErrors([error(diag.missingEnumBody, 7, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_enum_declaration_value_class() {
    var parseResult = parseStringWithErrors(r'''
enum E {a class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: a
        rightBracket: } <synthetic>
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_enum_declaration_value_const() {
    var parseResult = parseStringWithErrors(r'''
enum E {a const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: a
        rightBracket: } <synthetic>
    TopLevelVariableDeclaration
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

  void test_enum_declaration_value_enum() {
    var parseResult = parseStringWithErrors(r'''
enum E {a enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: a
        rightBracket: } <synthetic>
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_enum_declaration_value_eof() {
    var parseResult = parseStringWithErrors(r'''
enum E {a
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: a
        rightBracket: } <synthetic>
''');
  }

  void test_enum_declaration_value_final() {
    var parseResult = parseStringWithErrors(r'''
enum E {a final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: a
        rightBracket: } <synthetic>
    TopLevelVariableDeclaration
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

  void test_enum_declaration_value_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
enum E {a int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: a
        rightBracket: } <synthetic>
    FunctionDeclaration
      returnType: NamedType
        name: int
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

  void test_enum_declaration_value_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
enum E {a void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: a
        rightBracket: } <synthetic>
    FunctionDeclaration
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

  void test_enum_declaration_value_getter() {
    var parseResult = parseStringWithErrors(r'''
enum E {a int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 26, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: a
        rightBracket: } <synthetic>
    FunctionDeclaration
      returnType: NamedType
        name: int
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

  void test_enum_declaration_value_mixin() {
    var parseResult = parseStringWithErrors(r'''
enum E {a mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: a
        rightBracket: } <synthetic>
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_enum_declaration_value_setter() {
    var parseResult = parseStringWithErrors(r'''
enum E {a set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: a
        rightBracket: } <synthetic>
    FunctionDeclaration
      propertyKeyword: set
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

  void test_enum_declaration_value_typedef() {
    var parseResult = parseStringWithErrors(r'''
enum E {a typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedToken, 40, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: a
        rightBracket: } <synthetic>
    GenericTypeAlias
      typedefKeyword: typedef
      name: A
      equals: =
      type: GenericFunctionType
        returnType: NamedType
          name: B
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            type: NamedType
              name: C
          parameter: SimpleFormalParameter
            type: NamedType
              name: D
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_enum_declaration_value_var() {
    var parseResult = parseStringWithErrors(r'''
enum E {a var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 17, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: a
        rightBracket: } <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_enum_eof_comma_eof() {
    var parseResult = parseStringWithErrors(r'''
enum E {,
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 1),
      error(diag.missingIdentifier, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: <empty> <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_enum_eof_leftBrace_eof() {
    var parseResult = parseStringWithErrors(r'''
enum E {
''');
    parseResult.assertErrors([error(diag.expectedToken, 9, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockEnumBody
        leftBracket: {
        rightBracket: } <synthetic>
''');
  }
}
