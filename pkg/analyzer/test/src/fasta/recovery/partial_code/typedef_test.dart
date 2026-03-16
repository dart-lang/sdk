// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypedefTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class TypedefTest extends ParserDiagnosticsTest {
  void test_typedef_equals_class() {
    var parseResult = parseStringWithErrors(r'''
typedef T = class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 12, 5),
      error(diag.expectedToken, 10, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: T
      equals: =
      type: NamedType
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

  void test_typedef_equals_const() {
    var parseResult = parseStringWithErrors(r'''
typedef T = const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 12, 5),
      error(diag.expectedToken, 10, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: T
      equals: =
      type: NamedType
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

  void test_typedef_equals_enum() {
    var parseResult = parseStringWithErrors(r'''
typedef T = enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 12, 4),
      error(diag.expectedToken, 10, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: T
      equals: =
      type: NamedType
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

  void test_typedef_equals_eof() {
    var parseResult = parseStringWithErrors(r'''
typedef T =
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 12, 0),
      error(diag.expectedToken, 10, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: T
      equals: =
      type: NamedType
        name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_typedef_equals_final() {
    var parseResult = parseStringWithErrors(r'''
typedef T = final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 12, 5),
      error(diag.expectedToken, 10, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: T
      equals: =
      type: NamedType
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

  void test_typedef_equals_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
typedef T = int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: T
      equals: =
      type: NamedType
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

  void test_typedef_equals_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
typedef T = void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: T
      equals: =
      type: NamedType
        name: void
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

  void test_typedef_equals_getter() {
    var parseResult = parseStringWithErrors(r'''
typedef T = int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: T
      equals: =
      type: NamedType
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

  void test_typedef_equals_mixin() {
    var parseResult = parseStringWithErrors(r'''
typedef T = mixin M {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 12, 5),
      error(diag.expectedToken, 12, 5),
      error(diag.missingFunctionParameters, 18, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: T
      equals: =
      type: NamedType
        name: mixin
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

  void test_typedef_equals_setter() {
    var parseResult = parseStringWithErrors(r'''
typedef T = set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 12, 3),
      error(diag.expectedToken, 10, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: T
      equals: =
      type: NamedType
        name: <empty> <synthetic>
      semicolon: ; <synthetic>
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

  void test_typedef_equals_typedef() {
    var parseResult = parseStringWithErrors(r'''
typedef T = typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 12, 7),
      error(diag.expectedToken, 10, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: T
      equals: =
      type: NamedType
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

  void test_typedef_equals_var() {
    var parseResult = parseStringWithErrors(r'''
typedef T = var a;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 12, 3),
      error(diag.expectedToken, 10, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: T
      equals: =
      type: NamedType
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

  void test_typedef_keyword_class() {
    var parseResult = parseStringWithErrors(r'''
typedef class A {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 5),
      error(diag.missingTypedefParameters, 8, 5),
      error(diag.expectedToken, 0, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      name: <empty> <synthetic>
      parameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
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

  void test_typedef_keyword_const() {
    var parseResult = parseStringWithErrors(r'''
typedef const a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 5),
      error(diag.missingTypedefParameters, 8, 5),
      error(diag.expectedToken, 0, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      name: <empty> <synthetic>
      parameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
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

  void test_typedef_keyword_enum() {
    var parseResult = parseStringWithErrors(r'''
typedef enum E { v }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 4),
      error(diag.missingTypedefParameters, 8, 4),
      error(diag.expectedToken, 0, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      name: <empty> <synthetic>
      parameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
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

  void test_typedef_keyword_eof() {
    var parseResult = parseStringWithErrors(r'''
typedef
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 0),
      error(diag.missingTypedefParameters, 8, 0),
      error(diag.expectedToken, 0, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      name: <empty> <synthetic>
      parameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_typedef_keyword_final() {
    var parseResult = parseStringWithErrors(r'''
typedef final a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 5),
      error(diag.missingTypedefParameters, 8, 5),
      error(diag.expectedToken, 0, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      name: <empty> <synthetic>
      parameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
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

  void test_typedef_keyword_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
typedef int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 14, 1),
      error(diag.expectedExecutable, 16, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      returnType: NamedType
        name: int
      name: f
      parameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      semicolon: ; <synthetic>
''');
  }

  void test_typedef_keyword_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
typedef void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 15, 1),
      error(diag.expectedExecutable, 17, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      returnType: NamedType
        name: void
      name: f
      parameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      semicolon: ; <synthetic>
''');
  }

  void test_typedef_keyword_getter() {
    var parseResult = parseStringWithErrors(r'''
typedef int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 12, 3),
      error(diag.missingTypedefParameters, 12, 3),
      error(diag.expectedToken, 8, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      returnType: NamedType
        name: int
      name: <empty> <synthetic>
      parameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
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

  void test_typedef_keyword_mixin() {
    var parseResult = parseStringWithErrors(r'''
typedef mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 5),
      error(diag.missingTypedefParameters, 8, 5),
      error(diag.expectedToken, 0, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      name: <empty> <synthetic>
      parameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
      semicolon: ; <synthetic>
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_typedef_keyword_setter() {
    var parseResult = parseStringWithErrors(r'''
typedef set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 3),
      error(diag.missingTypedefParameters, 8, 3),
      error(diag.expectedToken, 0, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      name: <empty> <synthetic>
      parameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
      semicolon: ; <synthetic>
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

  void test_typedef_keyword_typedef() {
    var parseResult = parseStringWithErrors(r'''
typedef typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 7),
      error(diag.missingTypedefParameters, 8, 7),
      error(diag.expectedToken, 0, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      name: <empty> <synthetic>
      parameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
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

  void test_typedef_keyword_var() {
    var parseResult = parseStringWithErrors(r'''
typedef var a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 3),
      error(diag.missingTypedefParameters, 8, 3),
      error(diag.expectedToken, 0, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      name: <empty> <synthetic>
      parameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
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

  void test_typedef_keywordEquals_class() {
    var parseResult = parseStringWithErrors(r'''
typedef = class A {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 1),
      error(diag.expectedTypeName, 10, 5),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: <empty> <synthetic>
      equals: =
      type: NamedType
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

  void test_typedef_keywordEquals_const() {
    var parseResult = parseStringWithErrors(r'''
typedef = const a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 1),
      error(diag.expectedTypeName, 10, 5),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: <empty> <synthetic>
      equals: =
      type: NamedType
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

  void test_typedef_keywordEquals_enum() {
    var parseResult = parseStringWithErrors(r'''
typedef = enum E { v }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 1),
      error(diag.expectedTypeName, 10, 4),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: <empty> <synthetic>
      equals: =
      type: NamedType
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

  void test_typedef_keywordEquals_eof() {
    var parseResult = parseStringWithErrors(r'''
typedef =
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 1),
      error(diag.expectedTypeName, 10, 0),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: <empty> <synthetic>
      equals: =
      type: NamedType
        name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_typedef_keywordEquals_final() {
    var parseResult = parseStringWithErrors(r'''
typedef = final a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 1),
      error(diag.expectedTypeName, 10, 5),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: <empty> <synthetic>
      equals: =
      type: NamedType
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

  void test_typedef_keywordEquals_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
typedef = int f() {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 1),
      error(diag.expectedToken, 10, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: <empty> <synthetic>
      equals: =
      type: NamedType
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

  void test_typedef_keywordEquals_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
typedef = void f() {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 1),
      error(diag.expectedToken, 10, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: <empty> <synthetic>
      equals: =
      type: NamedType
        name: void
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

  void test_typedef_keywordEquals_getter() {
    var parseResult = parseStringWithErrors(r'''
typedef = int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 1),
      error(diag.expectedToken, 10, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: <empty> <synthetic>
      equals: =
      type: NamedType
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

  void test_typedef_keywordEquals_mixin() {
    var parseResult = parseStringWithErrors(r'''
typedef = mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 1),
      error(diag.builtInIdentifierAsType, 10, 5),
      error(diag.expectedToken, 10, 5),
      error(diag.missingFunctionParameters, 16, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: <empty> <synthetic>
      equals: =
      type: NamedType
        name: mixin
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

  void test_typedef_keywordEquals_setter() {
    var parseResult = parseStringWithErrors(r'''
typedef = set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 1),
      error(diag.expectedTypeName, 10, 3),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: <empty> <synthetic>
      equals: =
      type: NamedType
        name: <empty> <synthetic>
      semicolon: ; <synthetic>
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

  void test_typedef_keywordEquals_typedef() {
    var parseResult = parseStringWithErrors(r'''
typedef = typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 1),
      error(diag.expectedTypeName, 10, 7),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: <empty> <synthetic>
      equals: =
      type: NamedType
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

  void test_typedef_keywordEquals_var() {
    var parseResult = parseStringWithErrors(r'''
typedef = var a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 1),
      error(diag.expectedTypeName, 10, 3),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: <empty> <synthetic>
      equals: =
      type: NamedType
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

  void test_typedef_name_class() {
    var parseResult = parseStringWithErrors(r'''
typedef T class A {}
''');
    parseResult.assertErrors([
      error(diag.missingTypedefParameters, 10, 5),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      name: T
      parameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
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

  void test_typedef_name_const() {
    var parseResult = parseStringWithErrors(r'''
typedef T const a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingTypedefParameters, 10, 5),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      name: T
      parameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
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

  void test_typedef_name_enum() {
    var parseResult = parseStringWithErrors(r'''
typedef T enum E { v }
''');
    parseResult.assertErrors([
      error(diag.missingTypedefParameters, 10, 4),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      name: T
      parameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
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

  void test_typedef_name_eof() {
    var parseResult = parseStringWithErrors(r'''
typedef T
''');
    parseResult.assertErrors([
      error(diag.missingTypedefParameters, 10, 0),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      name: T
      parameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_typedef_name_final() {
    var parseResult = parseStringWithErrors(r'''
typedef T final a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingTypedefParameters, 10, 5),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      name: T
      parameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
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

  void test_typedef_name_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
typedef T int f() {}
''');
    parseResult.assertErrors([
      error(diag.missingTypedefParameters, 14, 1),
      error(diag.expectedToken, 10, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      returnType: NamedType
        name: T
      name: int
      parameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
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

  void test_typedef_name_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
typedef T void f() {}
''');
    parseResult.assertErrors([
      error(diag.missingTypedefParameters, 10, 4),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      name: T
      parameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
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

  void test_typedef_name_getter() {
    var parseResult = parseStringWithErrors(r'''
typedef T int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.missingTypedefParameters, 14, 3),
      error(diag.expectedToken, 10, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      returnType: NamedType
        name: T
      name: int
      parameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
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

  void test_typedef_name_mixin() {
    var parseResult = parseStringWithErrors(r'''
typedef T mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 10, 5),
      error(diag.missingTypedefParameters, 10, 5),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      returnType: NamedType
        name: T
      name: <empty> <synthetic>
      parameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
      semicolon: ; <synthetic>
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_typedef_name_setter() {
    var parseResult = parseStringWithErrors(r'''
typedef T set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 10, 3),
      error(diag.missingTypedefParameters, 10, 3),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      returnType: NamedType
        name: T
      name: <empty> <synthetic>
      parameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
      semicolon: ; <synthetic>
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

  void test_typedef_name_typedef() {
    var parseResult = parseStringWithErrors(r'''
typedef T typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingTypedefParameters, 10, 7),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      name: T
      parameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
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

  void test_typedef_name_var() {
    var parseResult = parseStringWithErrors(r'''
typedef T var a;
''');
    parseResult.assertErrors([
      error(diag.missingTypedefParameters, 10, 3),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionTypeAlias
      typedefKeyword: typedef
      name: T
      parameters: FormalParameterList
        leftParenthesis: ( <synthetic>
        rightParenthesis: ) <synthetic>
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
