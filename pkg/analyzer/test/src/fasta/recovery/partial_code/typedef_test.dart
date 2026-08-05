// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T = class A {}
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T = const a = 0;
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T = enum E { v }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T =
//        ^
// [diag.expectedToken] Expected to find ';'.
//         ^
// [diag.expectedTypeName][column 12][length 0] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T = final a = 0;
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T = int f() {}
//          ^^^
// [diag.expectedToken] Expected to find ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T = void f() {}
//          ^^^^
// [diag.expectedToken] Expected to find ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T = int get a => 0;
//          ^^^
// [diag.expectedToken] Expected to find ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T = mixin M {}
//          ^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'mixin' can't be used as a type.
// [diag.expectedToken] Expected to find ';'.
//                ^
// [diag.missingFunctionParameters] Functions must have an explicit list of parameters.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T = set a(b) {}
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_typedef_equals_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T = typedef A = B Function(C, D);
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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

  void test_typedef_equals_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T = var a;
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef class A {}
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
//      ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.missingTypedefParameters] Typedefs must have an explicit list of parameters.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef const a = 0;
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
//      ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.missingTypedefParameters] Typedefs must have an explicit list of parameters.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef enum E { v }
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
//      ^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.missingTypedefParameters] Typedefs must have an explicit list of parameters.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
//     ^
// [diag.missingIdentifier][column 8][length 0] Expected an identifier.
// [diag.missingTypedefParameters][column 8][length 0] Typedefs must have an explicit list of parameters.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef final a = 0;
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
//      ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.missingTypedefParameters] Typedefs must have an explicit list of parameters.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef int f() {}
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef void f() {}
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef int get a => 0;
//      ^^^
// [diag.expectedToken] Expected to find ';'.
//          ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.missingTypedefParameters] Typedefs must have an explicit list of parameters.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef mixin M {}
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
//      ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.missingTypedefParameters] Typedefs must have an explicit list of parameters.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef set a(b) {}
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
//      ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.missingTypedefParameters] Typedefs must have an explicit list of parameters.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_typedef_keyword_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef typedef A = B Function(C, D);
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
//      ^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.missingTypedefParameters] Typedefs must have an explicit list of parameters.
''');
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

  void test_typedef_keyword_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef var a;
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
//      ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.missingTypedefParameters] Typedefs must have an explicit list of parameters.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef = class A {}
//      ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ';'.
//        ^^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef = const a = 0;
//      ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ';'.
//        ^^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef = enum E { v }
//      ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ';'.
//        ^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef =
//      ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ';'.
//       ^
// [diag.expectedTypeName][column 10][length 0] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef = final a = 0;
//      ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ';'.
//        ^^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef = int f() {}
//      ^
// [diag.missingIdentifier] Expected an identifier.
//        ^^^
// [diag.expectedToken] Expected to find ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef = void f() {}
//      ^
// [diag.missingIdentifier] Expected an identifier.
//        ^^^^
// [diag.expectedToken] Expected to find ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef = int get a => 0;
//      ^
// [diag.missingIdentifier] Expected an identifier.
//        ^^^
// [diag.expectedToken] Expected to find ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef = mixin M {}
//      ^
// [diag.missingIdentifier] Expected an identifier.
//        ^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'mixin' can't be used as a type.
// [diag.expectedToken] Expected to find ';'.
//              ^
// [diag.missingFunctionParameters] Functions must have an explicit list of parameters.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef = set a(b) {}
//      ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ';'.
//        ^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_typedef_keywordEquals_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef = typedef A = B Function(C, D);
//      ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ';'.
//        ^^^^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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

  void test_typedef_keywordEquals_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef = var a;
//      ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ';'.
//        ^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T class A {}
//      ^
// [diag.expectedToken] Expected to find ';'.
//        ^^^^^
// [diag.missingTypedefParameters] Typedefs must have an explicit list of parameters.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T const a = 0;
//      ^
// [diag.expectedToken] Expected to find ';'.
//        ^^^^^
// [diag.missingTypedefParameters] Typedefs must have an explicit list of parameters.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T enum E { v }
//      ^
// [diag.expectedToken] Expected to find ';'.
//        ^^^^
// [diag.missingTypedefParameters] Typedefs must have an explicit list of parameters.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T
//      ^
// [diag.expectedToken] Expected to find ';'.
//       ^
// [diag.missingTypedefParameters][column 10][length 0] Typedefs must have an explicit list of parameters.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T final a = 0;
//      ^
// [diag.expectedToken] Expected to find ';'.
//        ^^^^^
// [diag.missingTypedefParameters] Typedefs must have an explicit list of parameters.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T int f() {}
//        ^^^
// [diag.expectedToken] Expected to find ';'.
//            ^
// [diag.missingTypedefParameters] Typedefs must have an explicit list of parameters.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T void f() {}
//      ^
// [diag.expectedToken] Expected to find ';'.
//        ^^^^
// [diag.missingTypedefParameters] Typedefs must have an explicit list of parameters.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T int get a => 0;
//        ^^^
// [diag.expectedToken] Expected to find ';'.
//            ^^^
// [diag.missingTypedefParameters] Typedefs must have an explicit list of parameters.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T mixin M {}
//      ^
// [diag.expectedToken] Expected to find ';'.
//        ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.missingTypedefParameters] Typedefs must have an explicit list of parameters.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T set a(b) {}
//      ^
// [diag.expectedToken] Expected to find ';'.
//        ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.missingTypedefParameters] Typedefs must have an explicit list of parameters.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_typedef_name_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T typedef A = B Function(C, D);
//      ^
// [diag.expectedToken] Expected to find ';'.
//        ^^^^^^^
// [diag.missingTypedefParameters] Typedefs must have an explicit list of parameters.
''');
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

  void test_typedef_name_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T var a;
//      ^
// [diag.expectedToken] Expected to find ';'.
//        ^^^
// [diag.missingTypedefParameters] Typedefs must have an explicit list of parameters.
''');
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
