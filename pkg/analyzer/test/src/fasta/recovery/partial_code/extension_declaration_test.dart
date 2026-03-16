// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionDeclarationTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ExtensionDeclarationTest extends ParserDiagnosticsTest {
  void test_extension_declaration_extendedType_class() {
    var parseResult = parseStringWithErrors(r'''
extension E on String class A {}
''');
    parseResult.assertErrors([error(diag.expectedExtensionBody, 15, 6)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
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

  void test_extension_declaration_extendedType_const() {
    var parseResult = parseStringWithErrors(r'''
extension E on String const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedExtensionBody, 15, 6)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
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

  void test_extension_declaration_extendedType_enum() {
    var parseResult = parseStringWithErrors(r'''
extension E on String enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedExtensionBody, 15, 6)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
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

  void test_extension_declaration_extendedType_eof() {
    var parseResult = parseStringWithErrors(r'''
extension E on String
''');
    parseResult.assertErrors([error(diag.expectedExtensionBody, 15, 6)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_extendedType_final() {
    var parseResult = parseStringWithErrors(r'''
extension E on String final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedExtensionBody, 15, 6)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
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

  void test_extension_declaration_extendedType_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
extension E on String int f() {}
''');
    parseResult.assertErrors([error(diag.expectedExtensionBody, 15, 6)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
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

  void test_extension_declaration_extendedType_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
extension E on String void f() {}
''');
    parseResult.assertErrors([error(diag.expectedExtensionBody, 15, 6)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
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

  void test_extension_declaration_extendedType_getter() {
    var parseResult = parseStringWithErrors(r'''
extension E on String int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedExtensionBody, 15, 6)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
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

  void test_extension_declaration_extendedType_mixin() {
    var parseResult = parseStringWithErrors(r'''
extension E on String mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedExtensionBody, 15, 6)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
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

  void test_extension_declaration_extendedType_setter() {
    var parseResult = parseStringWithErrors(r'''
extension E on String set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedExtensionBody, 15, 6)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
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

  void test_extension_declaration_extendedType_typedef() {
    var parseResult = parseStringWithErrors(r'''
extension E on String typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedExtensionBody, 15, 6)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
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

  void test_extension_declaration_extendedType_var() {
    var parseResult = parseStringWithErrors(r'''
extension E on String var a;
''');
    parseResult.assertErrors([error(diag.expectedExtensionBody, 15, 6)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
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

  void test_extension_declaration_keyword_class() {
    var parseResult = parseStringWithErrors(r'''
extension class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 0, 9),
      error(diag.expectedTypeName, 10, 5),
      error(diag.expectedExtensionBody, 10, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_extension_declaration_keyword_const() {
    var parseResult = parseStringWithErrors(r'''
extension const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 0, 9),
      error(diag.expectedTypeName, 10, 5),
      error(diag.expectedExtensionBody, 10, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_extension_declaration_keyword_enum() {
    var parseResult = parseStringWithErrors(r'''
extension enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 0, 9),
      error(diag.expectedTypeName, 10, 4),
      error(diag.expectedExtensionBody, 10, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_extension_declaration_keyword_eof() {
    var parseResult = parseStringWithErrors(r'''
extension
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 0, 9),
      error(diag.expectedTypeName, 10, 0),
      error(diag.expectedExtensionBody, 10, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_keyword_final() {
    var parseResult = parseStringWithErrors(r'''
extension final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 0, 9),
      error(diag.expectedTypeName, 10, 5),
      error(diag.expectedExtensionBody, 10, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_extension_declaration_keyword_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
extension int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 3),
      error(diag.expectedExtensionBody, 14, 1),
      error(diag.expectedExecutable, 15, 1),
      error(diag.expectedExecutable, 16, 1),
      error(diag.expectedExecutable, 18, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: int
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: f
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_keyword_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
extension void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 0, 9),
      error(diag.expectedExtensionBody, 10, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: void
      body: BlockClassBody
        leftBracket: { <synthetic>
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

  void test_extension_declaration_keyword_getter() {
    var parseResult = parseStringWithErrors(r'''
extension int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 3),
      error(diag.expectedTypeName, 14, 3),
      error(diag.expectedExtensionBody, 14, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: int
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_extension_declaration_keyword_mixin() {
    var parseResult = parseStringWithErrors(r'''
extension mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: mixin
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_extension_declaration_keyword_setter() {
    var parseResult = parseStringWithErrors(r'''
extension set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 3),
      error(diag.expectedExtensionBody, 14, 1),
      error(diag.expectedExecutable, 15, 1),
      error(diag.missingConstFinalVarOrType, 16, 1),
      error(diag.expectedToken, 16, 1),
      error(diag.expectedExecutable, 17, 1),
      error(diag.expectedExecutable, 19, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: set
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: a
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
''');
  }

  void test_extension_declaration_keyword_typedef() {
    var parseResult = parseStringWithErrors(r'''
extension typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 7),
      error(diag.expectedExtensionBody, 18, 1),
      error(diag.expectedExecutable, 20, 1),
      error(diag.missingFunctionBody, 38, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: typedef
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: A
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    FunctionDeclaration
      returnType: NamedType
        name: B
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

  void test_extension_declaration_keyword_var() {
    var parseResult = parseStringWithErrors(r'''
extension var a;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 0, 9),
      error(diag.expectedTypeName, 10, 3),
      error(diag.expectedExtensionBody, 10, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_extension_declaration_named_class() {
    var parseResult = parseStringWithErrors(r'''
extension E class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 1),
      error(diag.expectedTypeName, 12, 5),
      error(diag.expectedExtensionBody, 12, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_extension_declaration_named_const() {
    var parseResult = parseStringWithErrors(r'''
extension E const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 1),
      error(diag.expectedTypeName, 12, 5),
      error(diag.expectedExtensionBody, 12, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_extension_declaration_named_enum() {
    var parseResult = parseStringWithErrors(r'''
extension E enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 1),
      error(diag.expectedTypeName, 12, 4),
      error(diag.expectedExtensionBody, 12, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_extension_declaration_named_eof() {
    var parseResult = parseStringWithErrors(r'''
extension E
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 1),
      error(diag.expectedTypeName, 12, 0),
      error(diag.expectedExtensionBody, 12, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_named_final() {
    var parseResult = parseStringWithErrors(r'''
extension E final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 1),
      error(diag.expectedTypeName, 12, 5),
      error(diag.expectedExtensionBody, 12, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_extension_declaration_named_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
extension E int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 1),
      error(diag.expectedExtensionBody, 12, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: int
      body: BlockClassBody
        leftBracket: { <synthetic>
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

  void test_extension_declaration_named_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
extension E void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 1),
      error(diag.expectedExtensionBody, 12, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: void
      body: BlockClassBody
        leftBracket: { <synthetic>
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

  void test_extension_declaration_named_getter() {
    var parseResult = parseStringWithErrors(r'''
extension E int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 1),
      error(diag.expectedExtensionBody, 12, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: int
      body: BlockClassBody
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

  void test_extension_declaration_named_mixin() {
    var parseResult = parseStringWithErrors(r'''
extension E mixin M {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 1),
      error(diag.builtInIdentifierAsType, 12, 5),
      error(diag.expectedExtensionBody, 12, 5),
      error(diag.missingFunctionParameters, 18, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: mixin
      body: BlockClassBody
        leftBracket: { <synthetic>
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

  void test_extension_declaration_named_setter() {
    var parseResult = parseStringWithErrors(r'''
extension E set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 1),
      error(diag.expectedTypeName, 12, 3),
      error(diag.expectedExtensionBody, 12, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_extension_declaration_named_typedef() {
    var parseResult = parseStringWithErrors(r'''
extension E typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 1),
      error(diag.expectedTypeName, 12, 7),
      error(diag.expectedExtensionBody, 12, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_extension_declaration_named_var() {
    var parseResult = parseStringWithErrors(r'''
extension E var a;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 1),
      error(diag.expectedTypeName, 12, 3),
      error(diag.expectedExtensionBody, 12, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_extension_declaration_on_class() {
    var parseResult = parseStringWithErrors(r'''
extension E on class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 15, 5),
      error(diag.expectedExtensionBody, 15, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_extension_declaration_on_const() {
    var parseResult = parseStringWithErrors(r'''
extension E on const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 15, 5),
      error(diag.expectedExtensionBody, 15, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_extension_declaration_on_enum() {
    var parseResult = parseStringWithErrors(r'''
extension E on enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 15, 4),
      error(diag.expectedExtensionBody, 15, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_extension_declaration_on_eof() {
    var parseResult = parseStringWithErrors(r'''
extension E on
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 15, 0),
      error(diag.expectedExtensionBody, 15, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_on_final() {
    var parseResult = parseStringWithErrors(r'''
extension E on final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 15, 5),
      error(diag.expectedExtensionBody, 15, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_extension_declaration_on_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
extension E on int f() {}
''');
    parseResult.assertErrors([error(diag.expectedExtensionBody, 15, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: int
      body: BlockClassBody
        leftBracket: { <synthetic>
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

  void test_extension_declaration_on_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
extension E on void f() {}
''');
    parseResult.assertErrors([error(diag.expectedExtensionBody, 15, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: void
      body: BlockClassBody
        leftBracket: { <synthetic>
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

  void test_extension_declaration_on_getter() {
    var parseResult = parseStringWithErrors(r'''
extension E on int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedExtensionBody, 15, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: int
      body: BlockClassBody
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

  void test_extension_declaration_on_mixin() {
    var parseResult = parseStringWithErrors(r'''
extension E on mixin M {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 15, 5),
      error(diag.expectedExtensionBody, 15, 5),
      error(diag.missingFunctionParameters, 21, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: mixin
      body: BlockClassBody
        leftBracket: { <synthetic>
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

  void test_extension_declaration_on_setter() {
    var parseResult = parseStringWithErrors(r'''
extension E on set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 15, 3),
      error(diag.expectedExtensionBody, 15, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_extension_declaration_on_typedef() {
    var parseResult = parseStringWithErrors(r'''
extension E on typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 15, 7),
      error(diag.expectedExtensionBody, 15, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_extension_declaration_on_var() {
    var parseResult = parseStringWithErrors(r'''
extension E on var a;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 15, 3),
      error(diag.expectedExtensionBody, 15, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_extension_declaration_partialBody_class() {
    var parseResult = parseStringWithErrors(r'''
extension E on String { class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.classInClass, 24, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: {
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_partialBody_const() {
    var parseResult = parseStringWithErrors(r'''
extension E on String { const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 37, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: const
              variables
                VariableDeclaration
                  name: a
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ;
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_partialBody_enum() {
    var parseResult = parseStringWithErrors(r'''
extension E on String { enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.enumInClass, 24, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: {
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_partialBody_eof() {
    var parseResult = parseStringWithErrors(r'''
extension E on String {
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: {
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_partialBody_final() {
    var parseResult = parseStringWithErrors(r'''
extension E on String { final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 37, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: final
              variables
                VariableDeclaration
                  name: a
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ;
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_partialBody_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
extension E on String { int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 35, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: {
        members
          MethodDeclaration
            returnType: NamedType
              name: int
            name: f
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_partialBody_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
extension E on String { void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 36, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: {
        members
          MethodDeclaration
            returnType: NamedType
              name: void
            name: f
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_partialBody_getter() {
    var parseResult = parseStringWithErrors(r'''
extension E on String { int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 40, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
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
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_partialBody_mixin() {
    var parseResult = parseStringWithErrors(r'''
extension E on String { mixin M {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.missingConstFinalVarOrType, 24, 5),
      error(diag.expectedToken, 24, 5),
      error(diag.missingFunctionParameters, 30, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            fields: VariableDeclarationList
              variables
                VariableDeclaration
                  name: mixin
            semicolon: ; <synthetic>
          MethodDeclaration
            name: M
            parameters: FormalParameterList
              leftParenthesis: ( <synthetic>
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_partialBody_setter() {
    var parseResult = parseStringWithErrors(r'''
extension E on String { set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 36, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: {
        members
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
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_partialBody_typedef() {
    var parseResult = parseStringWithErrors(r'''
extension E on String { typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 54, 1),
      error(diag.typedefInClass, 24, 7),
      error(diag.missingConstFinalVarOrType, 32, 1),
      error(diag.expectedToken, 36, 1),
      error(diag.extensionDeclaresAbstractMember, 38, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            fields: VariableDeclarationList
              variables
                VariableDeclaration
                  name: A
                  equals: =
                  initializer: SimpleIdentifier
                    token: B
            semicolon: ; <synthetic>
          MethodDeclaration
            name: Function
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: SimpleFormalParameter
                name: C
              parameter: SimpleFormalParameter
                name: D
              rightParenthesis: )
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_partialBody_var() {
    var parseResult = parseStringWithErrors(r'''
extension E on String { var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 31, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: a
            semicolon: ;
        rightBracket: } <synthetic>
''');
  }
}
