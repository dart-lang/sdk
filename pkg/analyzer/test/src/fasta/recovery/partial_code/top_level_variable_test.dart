// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopLevelVariableTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class TopLevelVariableTest extends ParserDiagnosticsTest {
  void test_top_level_variable_const_class() {
    var parseResult = parseStringWithErrors(r'''
const class A {}
''');
    parseResult.assertErrors([error(diag.constClass, 0, 5)]);
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
''');
  }

  void test_top_level_variable_const_const() {
    var parseResult = parseStringWithErrors(r'''
const const a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 5),
      error(diag.expectedToken, 0, 5),
    ]);
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

  void test_top_level_variable_const_enum() {
    var parseResult = parseStringWithErrors(r'''
const enum E { v }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 4),
      error(diag.expectedToken, 0, 5),
    ]);
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

  void test_top_level_variable_const_eof() {
    var parseResult = parseStringWithErrors(r'''
const
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 0),
      error(diag.expectedToken, 0, 5),
    ]);
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

  void test_top_level_variable_const_final() {
    var parseResult = parseStringWithErrors(r'''
const final a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 5),
      error(diag.expectedToken, 0, 5),
    ]);
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

  void test_top_level_variable_const_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
const int f() {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
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

  void test_top_level_variable_const_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
const void f() {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
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

  void test_top_level_variable_const_getter() {
    var parseResult = parseStringWithErrors(r'''
const int get a => 0;
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
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

  void test_top_level_variable_const_mixin() {
    var parseResult = parseStringWithErrors(r'''
const mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 5),
      error(diag.expectedToken, 0, 5),
    ]);
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
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_const_setter() {
    var parseResult = parseStringWithErrors(r'''
const set a(b) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      propertyKeyword: set
      name: a
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_top_level_variable_const_typedef() {
    var parseResult = parseStringWithErrors(r'''
const typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 7),
      error(diag.expectedToken, 0, 5),
    ]);
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
          parameter: RegularFormalParameter
            type: NamedType
              name: C
          parameter: RegularFormalParameter
            type: NamedType
              name: D
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_top_level_variable_const_var() {
    var parseResult = parseStringWithErrors(r'''
const var a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 3),
      error(diag.expectedToken, 0, 5),
    ]);
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
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_top_level_variable_constName_class() {
    var parseResult = parseStringWithErrors(r'''
const a class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_constName_const() {
    var parseResult = parseStringWithErrors(r'''
const a const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constName_enum() {
    var parseResult = parseStringWithErrors(r'''
const a enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constName_eof() {
    var parseResult = parseStringWithErrors(r'''
const a
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
''');
  }

  void test_top_level_variable_constName_final() {
    var parseResult = parseStringWithErrors(r'''
const a final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constName_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
const a int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: a
        variables
          VariableDeclaration
            name: int
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constName_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
const a void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constName_getter() {
    var parseResult = parseStringWithErrors(r'''
const a int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: a
        variables
          VariableDeclaration
            name: int
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constName_mixin() {
    var parseResult = parseStringWithErrors(r'''
const a mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 5),
      error(diag.expectedToken, 6, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: a
        variables
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_constName_setter() {
    var parseResult = parseStringWithErrors(r'''
const a set a(b) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      returnType: NamedType
        name: a
      propertyKeyword: set
      name: a
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_top_level_variable_constName_typedef() {
    var parseResult = parseStringWithErrors(r'''
const a typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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
          parameter: RegularFormalParameter
            type: NamedType
              name: C
          parameter: RegularFormalParameter
            type: NamedType
              name: D
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_top_level_variable_constName_var() {
    var parseResult = parseStringWithErrors(r'''
const a var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_top_level_variable_constNameComma_class() {
    var parseResult = parseStringWithErrors(r'''
const a, class A {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 9, 5),
      error(diag.expectedToken, 7, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_constNameComma_const() {
    var parseResult = parseStringWithErrors(r'''
const a, const a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 9, 5),
      error(diag.expectedToken, 7, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constNameComma_enum() {
    var parseResult = parseStringWithErrors(r'''
const a, enum E { v }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 9, 4),
      error(diag.expectedToken, 7, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constNameComma_eof() {
    var parseResult = parseStringWithErrors(r'''
const a,
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 9, 0),
      error(diag.expectedToken, 7, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_top_level_variable_constNameComma_final() {
    var parseResult = parseStringWithErrors(r'''
const a, final a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 9, 5),
      error(diag.expectedToken, 7, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constNameComma_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
const a, int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 9, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: int
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constNameComma_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
const a, void f() {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 9, 4),
      error(diag.expectedToken, 7, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constNameComma_getter() {
    var parseResult = parseStringWithErrors(r'''
const a, int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 9, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: int
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constNameComma_mixin() {
    var parseResult = parseStringWithErrors(r'''
const a, mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 9, 5),
      error(diag.expectedToken, 7, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_constNameComma_setter() {
    var parseResult = parseStringWithErrors(r'''
const a, set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 9, 3),
      error(diag.expectedToken, 7, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
    FunctionDeclaration
      propertyKeyword: set
      name: a
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_top_level_variable_constNameComma_typedef() {
    var parseResult = parseStringWithErrors(r'''
const a, typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 9, 7),
      error(diag.expectedToken, 7, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
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
          parameter: RegularFormalParameter
            type: NamedType
              name: C
          parameter: RegularFormalParameter
            type: NamedType
              name: D
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_top_level_variable_constNameComma_var() {
    var parseResult = parseStringWithErrors(r'''
const a, var a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 9, 3),
      error(diag.expectedToken, 7, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_top_level_variable_constNameCommaName_class() {
    var parseResult = parseStringWithErrors(r'''
const a, b class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 9, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_constNameCommaName_const() {
    var parseResult = parseStringWithErrors(r'''
const a, b const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 9, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constNameCommaName_enum() {
    var parseResult = parseStringWithErrors(r'''
const a, b enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedToken, 9, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constNameCommaName_eof() {
    var parseResult = parseStringWithErrors(r'''
const a, b
''');
    parseResult.assertErrors([error(diag.expectedToken, 9, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
''');
  }

  void test_top_level_variable_constNameCommaName_final() {
    var parseResult = parseStringWithErrors(r'''
const a, b final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 9, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constNameCommaName_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
const a, b int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 9, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constNameCommaName_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
const a, b void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 9, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constNameCommaName_getter() {
    var parseResult = parseStringWithErrors(r'''
const a, b int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 9, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constNameCommaName_mixin() {
    var parseResult = parseStringWithErrors(r'''
const a, b mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 9, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_constNameCommaName_setter() {
    var parseResult = parseStringWithErrors(r'''
const a, b set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 9, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
    FunctionDeclaration
      propertyKeyword: set
      name: a
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_top_level_variable_constNameCommaName_typedef() {
    var parseResult = parseStringWithErrors(r'''
const a, b typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedToken, 9, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
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
          parameter: RegularFormalParameter
            type: NamedType
              name: C
          parameter: RegularFormalParameter
            type: NamedType
              name: D
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_top_level_variable_constNameCommaName_var() {
    var parseResult = parseStringWithErrors(r'''
const a, b var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 9, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_top_level_variable_constTypeName_class() {
    var parseResult = parseStringWithErrors(r'''
const int a class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_constTypeName_const() {
    var parseResult = parseStringWithErrors(r'''
const int a const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constTypeName_enum() {
    var parseResult = parseStringWithErrors(r'''
const int a enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constTypeName_eof() {
    var parseResult = parseStringWithErrors(r'''
const int a
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
''');
  }

  void test_top_level_variable_constTypeName_final() {
    var parseResult = parseStringWithErrors(r'''
const int a final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constTypeName_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
const int a int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constTypeName_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
const int a void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constTypeName_getter() {
    var parseResult = parseStringWithErrors(r'''
const int a int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constTypeName_mixin() {
    var parseResult = parseStringWithErrors(r'''
const int a mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_constTypeName_setter() {
    var parseResult = parseStringWithErrors(r'''
const int a set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
    FunctionDeclaration
      propertyKeyword: set
      name: a
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_top_level_variable_constTypeName_typedef() {
    var parseResult = parseStringWithErrors(r'''
const int a typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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
          parameter: RegularFormalParameter
            type: NamedType
              name: C
          parameter: RegularFormalParameter
            type: NamedType
              name: D
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_top_level_variable_constTypeName_var() {
    var parseResult = parseStringWithErrors(r'''
const int a var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_top_level_variable_constTypeNameComma_class() {
    var parseResult = parseStringWithErrors(r'''
const int a, class A {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 5),
      error(diag.expectedToken, 11, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_constTypeNameComma_const() {
    var parseResult = parseStringWithErrors(r'''
const int a, const a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 5),
      error(diag.expectedToken, 11, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constTypeNameComma_enum() {
    var parseResult = parseStringWithErrors(r'''
const int a, enum E { v }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 4),
      error(diag.expectedToken, 11, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constTypeNameComma_eof() {
    var parseResult = parseStringWithErrors(r'''
const int a,
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 0),
      error(diag.expectedToken, 11, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_top_level_variable_constTypeNameComma_final() {
    var parseResult = parseStringWithErrors(r'''
const int a, final a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 5),
      error(diag.expectedToken, 11, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constTypeNameComma_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
const int a, int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: int
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constTypeNameComma_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
const int a, void f() {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 4),
      error(diag.expectedToken, 11, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constTypeNameComma_getter() {
    var parseResult = parseStringWithErrors(r'''
const int a, int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: int
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constTypeNameComma_mixin() {
    var parseResult = parseStringWithErrors(r'''
const int a, mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 5),
      error(diag.expectedToken, 11, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_constTypeNameComma_setter() {
    var parseResult = parseStringWithErrors(r'''
const int a, set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 3),
      error(diag.expectedToken, 11, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
    FunctionDeclaration
      propertyKeyword: set
      name: a
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_top_level_variable_constTypeNameComma_typedef() {
    var parseResult = parseStringWithErrors(r'''
const int a, typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 7),
      error(diag.expectedToken, 11, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
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
          parameter: RegularFormalParameter
            type: NamedType
              name: C
          parameter: RegularFormalParameter
            type: NamedType
              name: D
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_top_level_variable_constTypeNameComma_var() {
    var parseResult = parseStringWithErrors(r'''
const int a, var a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 3),
      error(diag.expectedToken, 11, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_top_level_variable_constTypeNameCommaName_class() {
    var parseResult = parseStringWithErrors(r'''
const int a, b class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_constTypeNameCommaName_const() {
    var parseResult = parseStringWithErrors(r'''
const int a, b const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constTypeNameCommaName_enum() {
    var parseResult = parseStringWithErrors(r'''
const int a, b enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constTypeNameCommaName_eof() {
    var parseResult = parseStringWithErrors(r'''
const int a, b
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
''');
  }

  void test_top_level_variable_constTypeNameCommaName_final() {
    var parseResult = parseStringWithErrors(r'''
const int a, b final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constTypeNameCommaName_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
const int a, b int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constTypeNameCommaName_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
const int a, b void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constTypeNameCommaName_getter() {
    var parseResult = parseStringWithErrors(r'''
const int a, b int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
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

  void test_top_level_variable_constTypeNameCommaName_mixin() {
    var parseResult = parseStringWithErrors(r'''
const int a, b mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_constTypeNameCommaName_setter() {
    var parseResult = parseStringWithErrors(r'''
const int a, b set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
    FunctionDeclaration
      propertyKeyword: set
      name: a
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_top_level_variable_constTypeNameCommaName_typedef() {
    var parseResult = parseStringWithErrors(r'''
const int a, b typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
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
          parameter: RegularFormalParameter
            type: NamedType
              name: C
          parameter: RegularFormalParameter
            type: NamedType
              name: D
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_top_level_variable_constTypeNameCommaName_var() {
    var parseResult = parseStringWithErrors(r'''
const int a, b var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_top_level_variable_final_class() {
    var parseResult = parseStringWithErrors(r'''
final class A {}
''');
    parseResult.assertErrors([]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      finalKeyword: final
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_final_const() {
    var parseResult = parseStringWithErrors(r'''
final const a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 5),
      error(diag.expectedToken, 0, 5),
    ]);
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

  void test_top_level_variable_final_enum() {
    var parseResult = parseStringWithErrors(r'''
final enum E { v }
''');
    parseResult.assertErrors([error(diag.finalEnum, 0, 5)]);
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
            name: v
        rightBracket: }
''');
  }

  void test_top_level_variable_final_eof() {
    var parseResult = parseStringWithErrors(r'''
final
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 0),
      error(diag.expectedToken, 0, 5),
    ]);
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

  void test_top_level_variable_final_final() {
    var parseResult = parseStringWithErrors(r'''
final final a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 5),
      error(diag.expectedToken, 0, 5),
    ]);
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

  void test_top_level_variable_final_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
final int f() {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
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

  void test_top_level_variable_final_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
final void f() {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
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

  void test_top_level_variable_final_getter() {
    var parseResult = parseStringWithErrors(r'''
final int get a => 0;
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
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

  void test_top_level_variable_final_mixin() {
    var parseResult = parseStringWithErrors(r'''
final mixin M {}
''');
    parseResult.assertErrors([error(diag.finalMixin, 0, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_final_setter() {
    var parseResult = parseStringWithErrors(r'''
final set a(b) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      propertyKeyword: set
      name: a
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_top_level_variable_final_typedef() {
    var parseResult = parseStringWithErrors(r'''
final typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 7),
      error(diag.expectedToken, 0, 5),
    ]);
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
          parameter: RegularFormalParameter
            type: NamedType
              name: C
          parameter: RegularFormalParameter
            type: NamedType
              name: D
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_top_level_variable_final_var() {
    var parseResult = parseStringWithErrors(r'''
final var a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 3),
      error(diag.expectedToken, 0, 5),
    ]);
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
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_top_level_variable_finalName_class() {
    var parseResult = parseStringWithErrors(r'''
final a class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_finalName_const() {
    var parseResult = parseStringWithErrors(r'''
final a const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_finalName_enum() {
    var parseResult = parseStringWithErrors(r'''
final a enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_finalName_eof() {
    var parseResult = parseStringWithErrors(r'''
final a
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
''');
  }

  void test_top_level_variable_finalName_final() {
    var parseResult = parseStringWithErrors(r'''
final a final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_finalName_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
final a int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        type: NamedType
          name: a
        variables
          VariableDeclaration
            name: int
      semicolon: ; <synthetic>
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

  void test_top_level_variable_finalName_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
final a void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_finalName_getter() {
    var parseResult = parseStringWithErrors(r'''
final a int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        type: NamedType
          name: a
        variables
          VariableDeclaration
            name: int
      semicolon: ; <synthetic>
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

  void test_top_level_variable_finalName_mixin() {
    var parseResult = parseStringWithErrors(r'''
final a mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 5),
      error(diag.expectedToken, 6, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        type: NamedType
          name: a
        variables
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_finalName_setter() {
    var parseResult = parseStringWithErrors(r'''
final a set a(b) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 0, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      returnType: NamedType
        name: a
      propertyKeyword: set
      name: a
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_top_level_variable_finalName_typedef() {
    var parseResult = parseStringWithErrors(r'''
final a typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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
          parameter: RegularFormalParameter
            type: NamedType
              name: C
          parameter: RegularFormalParameter
            type: NamedType
              name: D
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_top_level_variable_finalName_var() {
    var parseResult = parseStringWithErrors(r'''
final a var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_top_level_variable_finalTypeName_class() {
    var parseResult = parseStringWithErrors(r'''
final int a class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_finalTypeName_const() {
    var parseResult = parseStringWithErrors(r'''
final int a const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_finalTypeName_enum() {
    var parseResult = parseStringWithErrors(r'''
final int a enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_finalTypeName_eof() {
    var parseResult = parseStringWithErrors(r'''
final int a
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
''');
  }

  void test_top_level_variable_finalTypeName_final() {
    var parseResult = parseStringWithErrors(r'''
final int a final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_finalTypeName_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
final int a int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_finalTypeName_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
final int a void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_finalTypeName_getter() {
    var parseResult = parseStringWithErrors(r'''
final int a int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_finalTypeName_mixin() {
    var parseResult = parseStringWithErrors(r'''
final int a mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_finalTypeName_setter() {
    var parseResult = parseStringWithErrors(r'''
final int a set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
    FunctionDeclaration
      propertyKeyword: set
      name: a
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_top_level_variable_finalTypeName_typedef() {
    var parseResult = parseStringWithErrors(r'''
final int a typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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
          parameter: RegularFormalParameter
            type: NamedType
              name: C
          parameter: RegularFormalParameter
            type: NamedType
              name: D
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_top_level_variable_finalTypeName_var() {
    var parseResult = parseStringWithErrors(r'''
final int a var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: final
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_top_level_variable_type_class() {
    var parseResult = parseStringWithErrors(r'''
int class A {}
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 0, 3),
      error(diag.expectedToken, 0, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: int
      semicolon: ; <synthetic>
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_type_const() {
    var parseResult = parseStringWithErrors(r'''
int const a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 0, 3),
      error(diag.expectedToken, 0, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: int
      semicolon: ; <synthetic>
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

  void test_top_level_variable_type_enum() {
    var parseResult = parseStringWithErrors(r'''
int enum E { v }
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 0, 3),
      error(diag.expectedToken, 0, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: int
      semicolon: ; <synthetic>
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

  void test_top_level_variable_type_eof() {
    var parseResult = parseStringWithErrors(r'''
int
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 0, 3),
      error(diag.expectedToken, 0, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: int
      semicolon: ; <synthetic>
''');
  }

  void test_top_level_variable_type_final() {
    var parseResult = parseStringWithErrors(r'''
int final a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 0, 3),
      error(diag.expectedToken, 0, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: int
      semicolon: ; <synthetic>
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

  void test_top_level_variable_type_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
int int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 4, 3)]);
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
            name: int
      semicolon: ; <synthetic>
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

  void test_top_level_variable_type_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
int void f() {}
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 0, 3),
      error(diag.expectedToken, 0, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: int
      semicolon: ; <synthetic>
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

  void test_top_level_variable_type_getter() {
    var parseResult = parseStringWithErrors(r'''
int int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 4, 3)]);
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
            name: int
      semicolon: ; <synthetic>
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

  void test_top_level_variable_type_mixin() {
    var parseResult = parseStringWithErrors(r'''
int mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 4, 5),
      error(diag.expectedToken, 0, 3),
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
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_type_setter() {
    var parseResult = parseStringWithErrors(r'''
int set a(b) {}
''');
    parseResult.assertErrors([]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      returnType: NamedType
        name: int
      propertyKeyword: set
      name: a
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_top_level_variable_type_typedef() {
    var parseResult = parseStringWithErrors(r'''
int typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 0, 3),
      error(diag.expectedToken, 0, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: int
      semicolon: ; <synthetic>
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
          parameter: RegularFormalParameter
            type: NamedType
              name: C
          parameter: RegularFormalParameter
            type: NamedType
              name: D
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_top_level_variable_type_var() {
    var parseResult = parseStringWithErrors(r'''
int var a;
''');
    parseResult.assertErrors([
      error(diag.missingConstFinalVarOrType, 0, 3),
      error(diag.expectedToken, 0, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: int
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_top_level_variable_typeName_class() {
    var parseResult = parseStringWithErrors(r'''
int a class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 4, 1)]);
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
            name: a
      semicolon: ; <synthetic>
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_typeName_const() {
    var parseResult = parseStringWithErrors(r'''
int a const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 4, 1)]);
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
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_typeName_enum() {
    var parseResult = parseStringWithErrors(r'''
int a enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedToken, 4, 1)]);
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
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_typeName_eof() {
    var parseResult = parseStringWithErrors(r'''
int a
''');
    parseResult.assertErrors([error(diag.expectedToken, 4, 1)]);
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
            name: a
      semicolon: ; <synthetic>
''');
  }

  void test_top_level_variable_typeName_final() {
    var parseResult = parseStringWithErrors(r'''
int a final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 4, 1)]);
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
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_typeName_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
int a int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 4, 1)]);
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
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_typeName_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
int a void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 4, 1)]);
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
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_typeName_getter() {
    var parseResult = parseStringWithErrors(r'''
int a int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 4, 1)]);
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
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_typeName_mixin() {
    var parseResult = parseStringWithErrors(r'''
int a mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 4, 1)]);
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
            name: a
      semicolon: ; <synthetic>
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_typeName_setter() {
    var parseResult = parseStringWithErrors(r'''
int a set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 4, 1)]);
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
            name: a
      semicolon: ; <synthetic>
    FunctionDeclaration
      propertyKeyword: set
      name: a
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_top_level_variable_typeName_typedef() {
    var parseResult = parseStringWithErrors(r'''
int a typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedToken, 4, 1)]);
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
            name: a
      semicolon: ; <synthetic>
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
          parameter: RegularFormalParameter
            type: NamedType
              name: C
          parameter: RegularFormalParameter
            type: NamedType
              name: D
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_top_level_variable_typeName_var() {
    var parseResult = parseStringWithErrors(r'''
int a var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 4, 1)]);
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
            name: a
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_top_level_variable_var_class() {
    var parseResult = parseStringWithErrors(r'''
var class A {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 4, 5),
      error(diag.expectedToken, 0, 3),
    ]);
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
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_var_const() {
    var parseResult = parseStringWithErrors(r'''
var const a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 4, 5),
      error(diag.expectedToken, 0, 3),
    ]);
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

  void test_top_level_variable_var_enum() {
    var parseResult = parseStringWithErrors(r'''
var enum E { v }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 4, 4),
      error(diag.expectedToken, 0, 3),
    ]);
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

  void test_top_level_variable_var_eof() {
    var parseResult = parseStringWithErrors(r'''
var
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 4, 0),
      error(diag.expectedToken, 0, 3),
    ]);
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

  void test_top_level_variable_var_final() {
    var parseResult = parseStringWithErrors(r'''
var final a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 4, 5),
      error(diag.expectedToken, 0, 3),
    ]);
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

  void test_top_level_variable_var_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
var int f() {}
''');
    parseResult.assertErrors([error(diag.varReturnType, 0, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
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

  void test_top_level_variable_var_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
var void f() {}
''');
    parseResult.assertErrors([error(diag.varReturnType, 0, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
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

  void test_top_level_variable_var_getter() {
    var parseResult = parseStringWithErrors(r'''
var int get a => 0;
''');
    parseResult.assertErrors([error(diag.varReturnType, 0, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
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

  void test_top_level_variable_var_mixin() {
    var parseResult = parseStringWithErrors(r'''
var mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 4, 5),
      error(diag.expectedToken, 0, 3),
    ]);
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
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_var_setter() {
    var parseResult = parseStringWithErrors(r'''
var set a(b) {}
''');
    parseResult.assertErrors([error(diag.varReturnType, 0, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      propertyKeyword: set
      name: a
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_top_level_variable_var_typedef() {
    var parseResult = parseStringWithErrors(r'''
var typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 4, 7),
      error(diag.expectedToken, 0, 3),
    ]);
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
          parameter: RegularFormalParameter
            type: NamedType
              name: C
          parameter: RegularFormalParameter
            type: NamedType
              name: D
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_top_level_variable_var_var() {
    var parseResult = parseStringWithErrors(r'''
var var a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 4, 3),
      error(diag.expectedToken, 0, 3),
    ]);
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
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_top_level_variable_varName_class() {
    var parseResult = parseStringWithErrors(r'''
var a class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 4, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_varName_const() {
    var parseResult = parseStringWithErrors(r'''
var a const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 4, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_varName_enum() {
    var parseResult = parseStringWithErrors(r'''
var a enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedToken, 4, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_varName_eof() {
    var parseResult = parseStringWithErrors(r'''
var a
''');
    parseResult.assertErrors([error(diag.expectedToken, 4, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
''');
  }

  void test_top_level_variable_varName_final() {
    var parseResult = parseStringWithErrors(r'''
var a final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 4, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_varName_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
var a int f() {}
''');
    parseResult.assertErrors([
      error(diag.varAndType, 0, 3),
      error(diag.expectedToken, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        type: NamedType
          name: a
        variables
          VariableDeclaration
            name: int
      semicolon: ; <synthetic>
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

  void test_top_level_variable_varName_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
var a void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 4, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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

  void test_top_level_variable_varName_getter() {
    var parseResult = parseStringWithErrors(r'''
var a int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.varAndType, 0, 3),
      error(diag.expectedToken, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        type: NamedType
          name: a
        variables
          VariableDeclaration
            name: int
      semicolon: ; <synthetic>
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

  void test_top_level_variable_varName_mixin() {
    var parseResult = parseStringWithErrors(r'''
var a mixin M {}
''');
    parseResult.assertErrors([
      error(diag.varAndType, 0, 3),
      error(diag.missingIdentifier, 6, 5),
      error(diag.expectedToken, 4, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        type: NamedType
          name: a
        variables
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_varName_setter() {
    var parseResult = parseStringWithErrors(r'''
var a set a(b) {}
''');
    parseResult.assertErrors([error(diag.varReturnType, 0, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      returnType: NamedType
        name: a
      propertyKeyword: set
      name: a
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_top_level_variable_varName_typedef() {
    var parseResult = parseStringWithErrors(r'''
var a typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedToken, 4, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
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
          parameter: RegularFormalParameter
            type: NamedType
              name: C
          parameter: RegularFormalParameter
            type: NamedType
              name: D
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_top_level_variable_varName_var() {
    var parseResult = parseStringWithErrors(r'''
var a var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 4, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_top_level_variable_varNameEquals_class() {
    var parseResult = parseStringWithErrors(r'''
var a = class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 8, 5),
      error(diag.expectedToken, 8, 5),
      error(diag.missingFunctionParameters, 14, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: SimpleIdentifier
              token: class
      semicolon: ; <synthetic>
    FunctionDeclaration
      name: A
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

  void test_top_level_variable_varNameEquals_const() {
    var parseResult = parseStringWithErrors(r'''
var a = const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 14, 1),
      error(diag.missingAssignableSelector, 8, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: AssignmentExpression
              leftHandSide: InstanceCreationExpression
                keyword: const
                constructorName: ConstructorName
                  type: NamedType
                    name: a
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
              operator: =
              rightHandSide: IntegerLiteral
                literal: 0
      semicolon: ;
''');
  }

  void test_top_level_variable_varNameEquals_enum() {
    var parseResult = parseStringWithErrors(r'''
var a = enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 8, 4),
      error(diag.expectedToken, 8, 4),
      error(diag.missingFunctionParameters, 13, 1),
      error(diag.expectedToken, 17, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: SimpleIdentifier
              token: enum
      semicolon: ; <synthetic>
    FunctionDeclaration
      name: E
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: ( <synthetic>
          rightParenthesis: ) <synthetic>
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: SimpleIdentifier
                  token: v
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_top_level_variable_varNameEquals_eof() {
    var parseResult = parseStringWithErrors(r'''
var a =
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 0),
      error(diag.expectedToken, 6, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_top_level_variable_varNameEquals_final() {
    var parseResult = parseStringWithErrors(r'''
var a = final a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 5),
      error(diag.expectedToken, 6, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
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

  void test_top_level_variable_varNameEquals_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
var a = int f() {}
''');
    parseResult.assertErrors([
      error(diag.namedFunctionExpression, 12, 1),
      error(diag.expectedToken, 17, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: FunctionExpression
              parameters: FormalParameterList
                leftParenthesis: (
                rightParenthesis: )
              body: BlockFunctionBody
                block: Block
                  leftBracket: {
                  rightBracket: }
      semicolon: ; <synthetic>
''');
  }

  void test_top_level_variable_varNameEquals_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
var a = void f() {}
''');
    parseResult.assertErrors([
      error(diag.namedFunctionExpression, 13, 1),
      error(diag.expectedToken, 18, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: FunctionExpression
              parameters: FormalParameterList
                leftParenthesis: (
                rightParenthesis: )
              body: BlockFunctionBody
                block: Block
                  leftBracket: {
                  rightBracket: }
      semicolon: ; <synthetic>
''');
  }

  void test_top_level_variable_varNameEquals_getter() {
    var parseResult = parseStringWithErrors(r'''
var a = int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: SimpleIdentifier
              token: int
      semicolon: ; <synthetic>
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

  void test_top_level_variable_varNameEquals_mixin() {
    var parseResult = parseStringWithErrors(r'''
var a = mixin M {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 5),
      error(diag.missingFunctionParameters, 14, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: SimpleIdentifier
              token: mixin
      semicolon: ; <synthetic>
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

  void test_top_level_variable_varNameEquals_setter() {
    var parseResult = parseStringWithErrors(r'''
var a = set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: SimpleIdentifier
              token: set
      semicolon: ; <synthetic>
    FunctionDeclaration
      name: a
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_top_level_variable_varNameEquals_typedef() {
    var parseResult = parseStringWithErrors(r'''
var a = typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 7),
      error(diag.missingConstFinalVarOrType, 16, 1),
      error(diag.expectedToken, 20, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: SimpleIdentifier
              token: typedef
      semicolon: ; <synthetic>
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
          parameter: RegularFormalParameter
            name: C
          parameter: RegularFormalParameter
            name: D
          rightParenthesis: )
        body: EmptyFunctionBody
          semicolon: ;
''');
  }

  void test_top_level_variable_varNameEquals_var() {
    var parseResult = parseStringWithErrors(r'''
var a = var a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 3),
      error(diag.expectedToken, 6, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_top_level_variable_varNameEqualsExpression_class() {
    var parseResult = parseStringWithErrors(r'''
var a = b class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: SimpleIdentifier
              token: b
      semicolon: ; <synthetic>
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_varNameEqualsExpression_const() {
    var parseResult = parseStringWithErrors(r'''
var a = b const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: SimpleIdentifier
              token: b
      semicolon: ; <synthetic>
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

  void test_top_level_variable_varNameEqualsExpression_enum() {
    var parseResult = parseStringWithErrors(r'''
var a = b enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: SimpleIdentifier
              token: b
      semicolon: ; <synthetic>
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

  void test_top_level_variable_varNameEqualsExpression_eof() {
    var parseResult = parseStringWithErrors(r'''
var a = b
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: SimpleIdentifier
              token: b
      semicolon: ; <synthetic>
''');
  }

  void test_top_level_variable_varNameEqualsExpression_final() {
    var parseResult = parseStringWithErrors(r'''
var a = b final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: SimpleIdentifier
              token: b
      semicolon: ; <synthetic>
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

  void test_top_level_variable_varNameEqualsExpression_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
var a = b int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: SimpleIdentifier
              token: b
      semicolon: ; <synthetic>
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

  void test_top_level_variable_varNameEqualsExpression_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
var a = b void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: SimpleIdentifier
              token: b
      semicolon: ; <synthetic>
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

  void test_top_level_variable_varNameEqualsExpression_getter() {
    var parseResult = parseStringWithErrors(r'''
var a = b int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: SimpleIdentifier
              token: b
      semicolon: ; <synthetic>
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

  void test_top_level_variable_varNameEqualsExpression_mixin() {
    var parseResult = parseStringWithErrors(r'''
var a = b mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: SimpleIdentifier
              token: b
      semicolon: ; <synthetic>
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_top_level_variable_varNameEqualsExpression_setter() {
    var parseResult = parseStringWithErrors(r'''
var a = b set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: SimpleIdentifier
              token: b
      semicolon: ; <synthetic>
    FunctionDeclaration
      propertyKeyword: set
      name: a
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_top_level_variable_varNameEqualsExpression_typedef() {
    var parseResult = parseStringWithErrors(r'''
var a = b typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: SimpleIdentifier
              token: b
      semicolon: ; <synthetic>
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
          parameter: RegularFormalParameter
            type: NamedType
              name: C
          parameter: RegularFormalParameter
            type: NamedType
              name: D
          rightParenthesis: )
      semicolon: ;
''');
  }

  void test_top_level_variable_varNameEqualsExpression_var() {
    var parseResult = parseStringWithErrors(r'''
var a = b var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
            equals: =
            initializer: SimpleIdentifier
              token: b
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }
}
