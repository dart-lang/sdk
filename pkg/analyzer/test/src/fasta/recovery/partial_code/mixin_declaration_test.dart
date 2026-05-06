// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinDeclarationTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MixinDeclarationTest extends ParserDiagnosticsTest {
  void test_mixin_declaration_extend_class() {
    var parseResult = parseStringWithErrors(r'''
mixin A extend class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 6),
      error(diag.expectedTypeName, 15, 5),
      error(diag.expectedMixinBody, 15, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extend
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_extend_const() {
    var parseResult = parseStringWithErrors(r'''
mixin A extend const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 6),
      error(diag.expectedTypeName, 15, 5),
      error(diag.expectedMixinBody, 15, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extend
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_extend_enum() {
    var parseResult = parseStringWithErrors(r'''
mixin A extend enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 6),
      error(diag.expectedTypeName, 15, 4),
      error(diag.expectedMixinBody, 15, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extend
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_extend_eof() {
    var parseResult = parseStringWithErrors(r'''
mixin A extend
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 6),
      error(diag.expectedTypeName, 15, 0),
      error(diag.expectedMixinBody, 15, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extend
        superclassConstraints
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_mixin_declaration_extend_final() {
    var parseResult = parseStringWithErrors(r'''
mixin A extend final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 6),
      error(diag.expectedTypeName, 15, 5),
      error(diag.expectedMixinBody, 15, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extend
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_extend_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A extend int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 6),
      error(diag.expectedMixinBody, 15, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extend
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_extend_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A extend void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 6),
      error(diag.expectedTypeName, 15, 4),
      error(diag.expectedMixinBody, 15, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extend
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_extend_getter() {
    var parseResult = parseStringWithErrors(r'''
mixin A extend int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 6),
      error(diag.expectedMixinBody, 15, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extend
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_extend_mixin() {
    var parseResult = parseStringWithErrors(r'''
mixin A extend mixin M {}
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 6),
      error(diag.builtInIdentifierAsType, 15, 5),
      error(diag.unexpectedToken, 21, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extend
        superclassConstraints
          NamedType
            name: mixin
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_mixin_declaration_extend_setter() {
    var parseResult = parseStringWithErrors(r'''
mixin A extend set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 6),
      error(diag.expectedTypeName, 15, 3),
      error(diag.expectedMixinBody, 15, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extend
        superclassConstraints
          NamedType
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_mixin_declaration_extend_typedef() {
    var parseResult = parseStringWithErrors(r'''
mixin A extend typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 6),
      error(diag.expectedTypeName, 15, 7),
      error(diag.expectedMixinBody, 15, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extend
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_extend_var() {
    var parseResult = parseStringWithErrors(r'''
mixin A extend var a;
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 6),
      error(diag.expectedTypeName, 15, 3),
      error(diag.expectedMixinBody, 15, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extend
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_extends_class() {
    var parseResult = parseStringWithErrors(r'''
mixin A extends class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 7),
      error(diag.expectedTypeName, 16, 5),
      error(diag.expectedMixinBody, 16, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extends
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_extends_const() {
    var parseResult = parseStringWithErrors(r'''
mixin A extends const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 7),
      error(diag.expectedTypeName, 16, 5),
      error(diag.expectedMixinBody, 16, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extends
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_extends_enum() {
    var parseResult = parseStringWithErrors(r'''
mixin A extends enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 7),
      error(diag.expectedTypeName, 16, 4),
      error(diag.expectedMixinBody, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extends
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_extends_eof() {
    var parseResult = parseStringWithErrors(r'''
mixin A extends
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 7),
      error(diag.expectedTypeName, 16, 0),
      error(diag.expectedMixinBody, 16, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extends
        superclassConstraints
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_mixin_declaration_extends_final() {
    var parseResult = parseStringWithErrors(r'''
mixin A extends final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 7),
      error(diag.expectedTypeName, 16, 5),
      error(diag.expectedMixinBody, 16, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extends
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_extends_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A extends int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 7),
      error(diag.expectedMixinBody, 16, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extends
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_extends_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A extends void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 7),
      error(diag.expectedTypeName, 16, 4),
      error(diag.expectedMixinBody, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extends
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_extends_getter() {
    var parseResult = parseStringWithErrors(r'''
mixin A extends int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 7),
      error(diag.expectedMixinBody, 16, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extends
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_extends_mixin() {
    var parseResult = parseStringWithErrors(r'''
mixin A extends mixin M {}
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 7),
      error(diag.builtInIdentifierAsType, 16, 5),
      error(diag.unexpectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extends
        superclassConstraints
          NamedType
            name: mixin
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_mixin_declaration_extends_setter() {
    var parseResult = parseStringWithErrors(r'''
mixin A extends set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 7),
      error(diag.expectedTypeName, 16, 3),
      error(diag.expectedMixinBody, 16, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extends
        superclassConstraints
          NamedType
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_mixin_declaration_extends_typedef() {
    var parseResult = parseStringWithErrors(r'''
mixin A extends typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 7),
      error(diag.expectedTypeName, 16, 7),
      error(diag.expectedMixinBody, 16, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extends
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_extends_var() {
    var parseResult = parseStringWithErrors(r'''
mixin A extends var a;
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 7),
      error(diag.expectedTypeName, 16, 3),
      error(diag.expectedMixinBody, 16, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extends
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_implements_class() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 19, 5),
      error(diag.expectedMixinBody, 19, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
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

  void test_mixin_declaration_implements_const() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 19, 5),
      error(diag.expectedMixinBody, 19, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
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

  void test_mixin_declaration_implements_enum() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 19, 4),
      error(diag.expectedMixinBody, 19, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
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

  void test_mixin_declaration_implements_eof() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 19, 0),
      error(diag.expectedMixinBody, 19, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_mixin_declaration_implements_final() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 19, 5),
      error(diag.expectedMixinBody, 19, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
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

  void test_mixin_declaration_implements_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements int f() {}
''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 19, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
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

  void test_mixin_declaration_implements_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 19, 4),
      error(diag.expectedMixinBody, 19, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
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

  void test_mixin_declaration_implements_getter() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 19, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
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

  void test_mixin_declaration_implements_mixin() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements mixin M {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 19, 5),
      error(diag.unexpectedToken, 25, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: mixin
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_mixin_declaration_implements_setter() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 19, 3),
      error(diag.expectedMixinBody, 19, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_mixin_declaration_implements_typedef() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 19, 7),
      error(diag.expectedMixinBody, 19, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
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

  void test_mixin_declaration_implements_var() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements var a;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 19, 3),
      error(diag.expectedMixinBody, 19, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
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

  void test_mixin_declaration_implementsBody_class() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements {} class A {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_implementsBody_const() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements {} const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_implementsBody_enum() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements {} enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_implementsBody_eof() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_mixin_declaration_implementsBody_final() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements {} final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_implementsBody_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements {} int f() {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_implementsBody_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements {} void f() {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_implementsBody_getter() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements {} int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_implementsBody_mixin() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements {} mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_implementsBody_setter() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements {} set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
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

  void test_mixin_declaration_implementsBody_typedef() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements {} typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_implementsBody_var() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements {} var a;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_implementsNameComma_class() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements B, class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 22, 5),
      error(diag.expectedMixinBody, 22, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
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

  void test_mixin_declaration_implementsNameComma_const() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements B, const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 22, 5),
      error(diag.expectedMixinBody, 22, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
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

  void test_mixin_declaration_implementsNameComma_enum() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements B, enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 22, 4),
      error(diag.expectedMixinBody, 22, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
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

  void test_mixin_declaration_implementsNameComma_eof() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements B,
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 22, 0),
      error(diag.expectedMixinBody, 22, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_mixin_declaration_implementsNameComma_final() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements B, final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 22, 5),
      error(diag.expectedMixinBody, 22, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
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

  void test_mixin_declaration_implementsNameComma_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements B, int f() {}
''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 22, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
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

  void test_mixin_declaration_implementsNameComma_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements B, void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 22, 4),
      error(diag.expectedMixinBody, 22, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
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

  void test_mixin_declaration_implementsNameComma_getter() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements B, int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 22, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
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

  void test_mixin_declaration_implementsNameComma_mixin() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements B, mixin M {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 22, 5),
      error(diag.unexpectedToken, 28, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
            name: mixin
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_mixin_declaration_implementsNameComma_setter() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements B, set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 22, 3),
      error(diag.expectedMixinBody, 22, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_mixin_declaration_implementsNameComma_typedef() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements B, typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 22, 7),
      error(diag.expectedMixinBody, 22, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
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

  void test_mixin_declaration_implementsNameComma_var() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements B, var a;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 22, 3),
      error(diag.expectedMixinBody, 22, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
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

  void test_mixin_declaration_implementsNameCommaBody_class() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements B, {} class A {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_implementsNameCommaBody_const() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements B, {} const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_implementsNameCommaBody_enum() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements B, {} enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_implementsNameCommaBody_eof() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements B, {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_mixin_declaration_implementsNameCommaBody_final() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements B, {} final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_implementsNameCommaBody_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements B, {} int f() {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_implementsNameCommaBody_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements B, {} void f() {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_implementsNameCommaBody_getter() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements B, {} int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_implementsNameCommaBody_mixin() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements B, {} mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_implementsNameCommaBody_setter() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements B, {} set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
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

  void test_mixin_declaration_implementsNameCommaBody_typedef() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements B, {} typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_implementsNameCommaBody_var() {
    var parseResult = parseStringWithErrors(r'''
mixin A implements B, {} var a;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_keyword_class() {
    var parseResult = parseStringWithErrors(r'''
mixin class A {}
''');
    parseResult.assertErrors([]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      mixinKeyword: mixin
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_mixin_declaration_keyword_const() {
    var parseResult = parseStringWithErrors(r'''
mixin const a = 0;
''');
    parseResult.assertErrors([
      error(diag.mixinPrimaryConstructor, 6, 5),
      error(diag.expectedMixinBody, 12, 1),
      error(diag.expectedExecutable, 14, 1),
      error(diag.expectedExecutable, 16, 1),
      error(diag.unexpectedToken, 17, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: a
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_mixin_declaration_keyword_enum() {
    var parseResult = parseStringWithErrors(r'''
mixin enum E { v }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 4),
      error(diag.expectedMixinBody, 6, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
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

  void test_mixin_declaration_keyword_eof() {
    var parseResult = parseStringWithErrors(r'''
mixin
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 0),
      error(diag.expectedMixinBody, 6, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_mixin_declaration_keyword_final() {
    var parseResult = parseStringWithErrors(r'''
mixin final a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 5),
      error(diag.expectedMixinBody, 6, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
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

  void test_mixin_declaration_keyword_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin int f() {}
''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
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

  void test_mixin_declaration_keyword_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin void f() {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 4),
      error(diag.expectedMixinBody, 6, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: <empty> <synthetic>
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

  void test_mixin_declaration_keyword_getter() {
    var parseResult = parseStringWithErrors(r'''
mixin int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
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

  void test_mixin_declaration_keyword_mixin() {
    var parseResult = parseStringWithErrors(r'''
mixin mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 5),
      error(diag.expectedMixinBody, 6, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: <empty> <synthetic>
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

  void test_mixin_declaration_keyword_setter() {
    var parseResult = parseStringWithErrors(r'''
mixin set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 3),
      error(diag.expectedMixinBody, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_mixin_declaration_keyword_typedef() {
    var parseResult = parseStringWithErrors(r'''
mixin typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 7),
      error(diag.expectedMixinBody, 6, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
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

  void test_mixin_declaration_keyword_var() {
    var parseResult = parseStringWithErrors(r'''
mixin var a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 3),
      error(diag.expectedMixinBody, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
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

  void test_mixin_declaration_named_class() {
    var parseResult = parseStringWithErrors(r'''
mixin A class A {}
''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_named_const() {
    var parseResult = parseStringWithErrors(r'''
mixin A const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_named_enum() {
    var parseResult = parseStringWithErrors(r'''
mixin A enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_named_eof() {
    var parseResult = parseStringWithErrors(r'''
mixin A
''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_mixin_declaration_named_final() {
    var parseResult = parseStringWithErrors(r'''
mixin A final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_named_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A int f() {}
''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_named_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A void f() {}
''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_named_getter() {
    var parseResult = parseStringWithErrors(r'''
mixin A int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_named_mixin() {
    var parseResult = parseStringWithErrors(r'''
mixin A mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_named_setter() {
    var parseResult = parseStringWithErrors(r'''
mixin A set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
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

  void test_mixin_declaration_named_typedef() {
    var parseResult = parseStringWithErrors(r'''
mixin A typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_named_var() {
    var parseResult = parseStringWithErrors(r'''
mixin A var a;
''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_on_class() {
    var parseResult = parseStringWithErrors(r'''
mixin A on class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 11, 5),
      error(diag.expectedMixinBody, 11, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_on_const() {
    var parseResult = parseStringWithErrors(r'''
mixin A on const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 11, 5),
      error(diag.expectedMixinBody, 11, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_on_enum() {
    var parseResult = parseStringWithErrors(r'''
mixin A on enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 11, 4),
      error(diag.expectedMixinBody, 11, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_on_eof() {
    var parseResult = parseStringWithErrors(r'''
mixin A on
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 11, 0),
      error(diag.expectedMixinBody, 11, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_mixin_declaration_on_final() {
    var parseResult = parseStringWithErrors(r'''
mixin A on final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 11, 5),
      error(diag.expectedMixinBody, 11, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_on_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A on int f() {}
''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 11, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_on_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A on void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 11, 4),
      error(diag.expectedMixinBody, 11, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_on_getter() {
    var parseResult = parseStringWithErrors(r'''
mixin A on int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 11, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_on_mixin() {
    var parseResult = parseStringWithErrors(r'''
mixin A on mixin M {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 11, 5),
      error(diag.unexpectedToken, 17, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: mixin
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_mixin_declaration_on_setter() {
    var parseResult = parseStringWithErrors(r'''
mixin A on set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 11, 3),
      error(diag.expectedMixinBody, 11, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_mixin_declaration_on_typedef() {
    var parseResult = parseStringWithErrors(r'''
mixin A on typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 11, 7),
      error(diag.expectedMixinBody, 11, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_on_var() {
    var parseResult = parseStringWithErrors(r'''
mixin A on var a;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 11, 3),
      error(diag.expectedMixinBody, 11, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onBody_class() {
    var parseResult = parseStringWithErrors(r'''
mixin A on {} class A {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 11, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onBody_const() {
    var parseResult = parseStringWithErrors(r'''
mixin A on {} const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 11, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onBody_enum() {
    var parseResult = parseStringWithErrors(r'''
mixin A on {} enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 11, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onBody_eof() {
    var parseResult = parseStringWithErrors(r'''
mixin A on {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 11, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_mixin_declaration_onBody_final() {
    var parseResult = parseStringWithErrors(r'''
mixin A on {} final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 11, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onBody_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A on {} int f() {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 11, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onBody_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A on {} void f() {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 11, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onBody_getter() {
    var parseResult = parseStringWithErrors(r'''
mixin A on {} int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 11, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onBody_mixin() {
    var parseResult = parseStringWithErrors(r'''
mixin A on {} mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 11, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onBody_setter() {
    var parseResult = parseStringWithErrors(r'''
mixin A on {} set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 11, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
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

  void test_mixin_declaration_onBody_typedef() {
    var parseResult = parseStringWithErrors(r'''
mixin A on {} typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 11, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onBody_var() {
    var parseResult = parseStringWithErrors(r'''
mixin A on {} var a;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 11, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onImplementsNameBody_class() {
    var parseResult = parseStringWithErrors(r'''
mixin A on implements B {} class A {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 11, 10),
      error(diag.unexpectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: implements
      body: BlockClassBody
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

  void test_mixin_declaration_onImplementsNameBody_const() {
    var parseResult = parseStringWithErrors(r'''
mixin A on implements B {} const a = 0;
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 11, 10),
      error(diag.unexpectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: implements
      body: BlockClassBody
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

  void test_mixin_declaration_onImplementsNameBody_enum() {
    var parseResult = parseStringWithErrors(r'''
mixin A on implements B {} enum E { v }
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 11, 10),
      error(diag.unexpectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: implements
      body: BlockClassBody
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

  void test_mixin_declaration_onImplementsNameBody_eof() {
    var parseResult = parseStringWithErrors(r'''
mixin A on implements B {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 11, 10),
      error(diag.unexpectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: implements
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_mixin_declaration_onImplementsNameBody_final() {
    var parseResult = parseStringWithErrors(r'''
mixin A on implements B {} final a = 0;
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 11, 10),
      error(diag.unexpectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: implements
      body: BlockClassBody
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

  void test_mixin_declaration_onImplementsNameBody_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A on implements B {} int f() {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 11, 10),
      error(diag.unexpectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: implements
      body: BlockClassBody
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

  void test_mixin_declaration_onImplementsNameBody_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A on implements B {} void f() {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 11, 10),
      error(diag.unexpectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: implements
      body: BlockClassBody
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

  void test_mixin_declaration_onImplementsNameBody_getter() {
    var parseResult = parseStringWithErrors(r'''
mixin A on implements B {} int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 11, 10),
      error(diag.unexpectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: implements
      body: BlockClassBody
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

  void test_mixin_declaration_onImplementsNameBody_mixin() {
    var parseResult = parseStringWithErrors(r'''
mixin A on implements B {} mixin M {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 11, 10),
      error(diag.unexpectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: implements
      body: BlockClassBody
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

  void test_mixin_declaration_onImplementsNameBody_setter() {
    var parseResult = parseStringWithErrors(r'''
mixin A on implements B {} set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 11, 10),
      error(diag.unexpectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: implements
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
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

  void test_mixin_declaration_onImplementsNameBody_typedef() {
    var parseResult = parseStringWithErrors(r'''
mixin A on implements B {} typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 11, 10),
      error(diag.unexpectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: implements
      body: BlockClassBody
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

  void test_mixin_declaration_onImplementsNameBody_var() {
    var parseResult = parseStringWithErrors(r'''
mixin A on implements B {} var a;
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 11, 10),
      error(diag.unexpectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: implements
      body: BlockClassBody
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

  void test_mixin_declaration_onNameComma_class() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B, class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 14, 5),
      error(diag.expectedMixinBody, 14, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
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

  void test_mixin_declaration_onNameComma_const() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B, const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 14, 5),
      error(diag.expectedMixinBody, 14, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
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

  void test_mixin_declaration_onNameComma_enum() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B, enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 14, 4),
      error(diag.expectedMixinBody, 14, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
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

  void test_mixin_declaration_onNameComma_eof() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B,
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 14, 0),
      error(diag.expectedMixinBody, 14, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_mixin_declaration_onNameComma_final() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B, final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 14, 5),
      error(diag.expectedMixinBody, 14, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
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

  void test_mixin_declaration_onNameComma_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B, int f() {}
''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 14, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
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

  void test_mixin_declaration_onNameComma_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B, void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 14, 4),
      error(diag.expectedMixinBody, 14, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
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

  void test_mixin_declaration_onNameComma_getter() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B, int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 14, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
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

  void test_mixin_declaration_onNameComma_mixin() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B, mixin M {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 14, 5),
      error(diag.unexpectedToken, 20, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
            name: mixin
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_mixin_declaration_onNameComma_setter() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B, set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 14, 3),
      error(diag.expectedMixinBody, 14, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_mixin_declaration_onNameComma_typedef() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B, typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 14, 7),
      error(diag.expectedMixinBody, 14, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
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

  void test_mixin_declaration_onNameComma_var() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B, var a;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 14, 3),
      error(diag.expectedMixinBody, 14, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
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

  void test_mixin_declaration_onNameCommaBody_class() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B, {} class A {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onNameCommaBody_const() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B, {} const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onNameCommaBody_enum() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B, {} enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onNameCommaBody_eof() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B, {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_mixin_declaration_onNameCommaBody_final() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B, {} final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onNameCommaBody_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B, {} int f() {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onNameCommaBody_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B, {} void f() {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onNameCommaBody_getter() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B, {} int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onNameCommaBody_mixin() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B, {} mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onNameCommaBody_setter() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B, {} set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
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

  void test_mixin_declaration_onNameCommaBody_typedef() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B, {} typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onNameCommaBody_var() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B, {} var a;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onNameImplements_class() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B implements class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 24, 5),
      error(diag.expectedMixinBody, 24, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
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

  void test_mixin_declaration_onNameImplements_const() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B implements const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 24, 5),
      error(diag.expectedMixinBody, 24, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
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

  void test_mixin_declaration_onNameImplements_enum() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B implements enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 24, 4),
      error(diag.expectedMixinBody, 24, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
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

  void test_mixin_declaration_onNameImplements_eof() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B implements
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 24, 0),
      error(diag.expectedMixinBody, 24, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_mixin_declaration_onNameImplements_final() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B implements final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 24, 5),
      error(diag.expectedMixinBody, 24, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
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

  void test_mixin_declaration_onNameImplements_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B implements int f() {}
''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 24, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
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

  void test_mixin_declaration_onNameImplements_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B implements void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 24, 4),
      error(diag.expectedMixinBody, 24, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
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

  void test_mixin_declaration_onNameImplements_getter() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B implements int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedMixinBody, 24, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
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

  void test_mixin_declaration_onNameImplements_mixin() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B implements mixin M {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 24, 5),
      error(diag.unexpectedToken, 30, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: mixin
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_mixin_declaration_onNameImplements_setter() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B implements set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 24, 3),
      error(diag.expectedMixinBody, 24, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_mixin_declaration_onNameImplements_typedef() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B implements typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 24, 7),
      error(diag.expectedMixinBody, 24, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
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

  void test_mixin_declaration_onNameImplements_var() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B implements var a;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 24, 3),
      error(diag.expectedMixinBody, 24, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
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

  void test_mixin_declaration_onNameImplementsBody_class() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B implements {} class A {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onNameImplementsBody_const() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B implements {} const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onNameImplementsBody_enum() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B implements {} enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onNameImplementsBody_eof() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B implements {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_mixin_declaration_onNameImplementsBody_final() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B implements {} final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onNameImplementsBody_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B implements {} int f() {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onNameImplementsBody_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B implements {} void f() {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onNameImplementsBody_getter() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B implements {} int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onNameImplementsBody_mixin() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B implements {} mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onNameImplementsBody_setter() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B implements {} set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
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

  void test_mixin_declaration_onNameImplementsBody_typedef() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B implements {} typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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

  void test_mixin_declaration_onNameImplementsBody_var() {
    var parseResult = parseStringWithErrors(r'''
mixin A on B implements {} var a;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
      implementsClause: ImplementsClause
        implementsKeyword: implements
        interfaces
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
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
}
