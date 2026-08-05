// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryDirectivesTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class LibraryDirectivesTest extends ParserDiagnosticsTest {
  void test_library_directive_keyword_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library class A {}
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
//      ^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          <empty> <synthetic>
      semicolon: ; <synthetic>
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

  void test_library_directive_keyword_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library const a = 0;
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
//      ^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          <empty> <synthetic>
      semicolon: ; <synthetic>
  declarations
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

  void test_library_directive_keyword_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library enum E { v }
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
//      ^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          <empty> <synthetic>
      semicolon: ; <synthetic>
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

  void test_library_directive_keyword_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
//     ^
// [diag.missingIdentifier][column 8][length 0] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_library_directive_keyword_export() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library export 'a.dart';
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
//      ^^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          <empty> <synthetic>
      semicolon: ; <synthetic>
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_library_directive_keyword_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library final a = 0;
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
//      ^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          <empty> <synthetic>
      semicolon: ; <synthetic>
  declarations
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

  void test_library_directive_keyword_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library int f() {}
//      ^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          int
      semicolon: ; <synthetic>
  declarations
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

  void test_library_directive_keyword_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library void f() {}
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
//      ^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          <empty> <synthetic>
      semicolon: ; <synthetic>
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

  void test_library_directive_keyword_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library int get a => 0;
//      ^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          int
      semicolon: ; <synthetic>
  declarations
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

  void test_library_directive_keyword_import() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library import 'a.dart';
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
//      ^^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          <empty> <synthetic>
      semicolon: ; <synthetic>
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_library_directive_keyword_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library mixin M {}
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
//      ^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          <empty> <synthetic>
      semicolon: ; <synthetic>
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_library_directive_keyword_part() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library part 'a.dart';
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
//      ^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          <empty> <synthetic>
      semicolon: ; <synthetic>
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_library_directive_keyword_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library set a(b) {}
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
//      ^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          <empty> <synthetic>
      semicolon: ; <synthetic>
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

  void test_library_directive_keyword_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library typedef A = B Function(C, D);
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
//      ^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          <empty> <synthetic>
      semicolon: ; <synthetic>
  declarations
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

  void test_library_directive_keyword_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library var a;
// [diag.expectedToken][column 1][length 7] Expected to find ';'.
//      ^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          <empty> <synthetic>
      semicolon: ; <synthetic>
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_library_directive_name_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib class A {}
//      ^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
      semicolon: ; <synthetic>
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

  void test_library_directive_name_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib const a = 0;
//      ^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
      semicolon: ; <synthetic>
  declarations
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

  void test_library_directive_name_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib enum E { v }
//      ^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
      semicolon: ; <synthetic>
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

  void test_library_directive_name_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib
//      ^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
      semicolon: ; <synthetic>
''');
  }

  void test_library_directive_name_export() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib export 'a.dart';
//      ^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
      semicolon: ; <synthetic>
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_library_directive_name_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib final a = 0;
//      ^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
      semicolon: ; <synthetic>
  declarations
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

  void test_library_directive_name_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib int f() {}
//      ^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
      semicolon: ; <synthetic>
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

  void test_library_directive_name_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib void f() {}
//      ^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
      semicolon: ; <synthetic>
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

  void test_library_directive_name_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib int get a => 0;
//      ^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
      semicolon: ; <synthetic>
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

  void test_library_directive_name_import() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib import 'a.dart';
//      ^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
      semicolon: ; <synthetic>
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_library_directive_name_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib mixin M {}
//      ^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
      semicolon: ; <synthetic>
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_library_directive_name_part() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib part 'a.dart';
//      ^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
      semicolon: ; <synthetic>
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_library_directive_name_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib set a(b) {}
//      ^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
      semicolon: ; <synthetic>
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

  void test_library_directive_name_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib typedef A = B Function(C, D);
//      ^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
      semicolon: ; <synthetic>
  declarations
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

  void test_library_directive_name_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib var a;
//      ^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
      semicolon: ; <synthetic>
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_library_directive_nameDot_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib. class A {}
//         ^
// [diag.expectedToken] Expected to find ';'.
//           ^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          <empty> <synthetic>
      semicolon: ; <synthetic>
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

  void test_library_directive_nameDot_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib. const a = 0;
//         ^
// [diag.expectedToken] Expected to find ';'.
//           ^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          <empty> <synthetic>
      semicolon: ; <synthetic>
  declarations
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

  void test_library_directive_nameDot_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib. enum E { v }
//         ^
// [diag.expectedToken] Expected to find ';'.
//           ^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          <empty> <synthetic>
      semicolon: ; <synthetic>
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

  void test_library_directive_nameDot_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib.
//         ^
// [diag.expectedToken] Expected to find ';'.
//          ^
// [diag.missingIdentifier][column 13][length 0] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_library_directive_nameDot_export() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib. export 'a.dart';
//         ^
// [diag.expectedToken] Expected to find ';'.
//           ^^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          <empty> <synthetic>
      semicolon: ; <synthetic>
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_library_directive_nameDot_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib. final a = 0;
//         ^
// [diag.expectedToken] Expected to find ';'.
//           ^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          <empty> <synthetic>
      semicolon: ; <synthetic>
  declarations
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

  void test_library_directive_nameDot_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib. int f() {}
//           ^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          int
      semicolon: ; <synthetic>
  declarations
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

  void test_library_directive_nameDot_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib. void f() {}
//         ^
// [diag.expectedToken] Expected to find ';'.
//           ^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          <empty> <synthetic>
      semicolon: ; <synthetic>
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

  void test_library_directive_nameDot_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib. int get a => 0;
//           ^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          int
      semicolon: ; <synthetic>
  declarations
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

  void test_library_directive_nameDot_import() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib. import 'a.dart';
//         ^
// [diag.expectedToken] Expected to find ';'.
//           ^^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          <empty> <synthetic>
      semicolon: ; <synthetic>
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_library_directive_nameDot_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib. mixin M {}
//         ^
// [diag.expectedToken] Expected to find ';'.
//           ^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          <empty> <synthetic>
      semicolon: ; <synthetic>
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_library_directive_nameDot_part() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib. part 'a.dart';
//         ^
// [diag.expectedToken] Expected to find ';'.
//           ^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          <empty> <synthetic>
      semicolon: ; <synthetic>
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_library_directive_nameDot_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib. set a(b) {}
//         ^
// [diag.expectedToken] Expected to find ';'.
//           ^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          <empty> <synthetic>
      semicolon: ; <synthetic>
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

  void test_library_directive_nameDot_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib. typedef A = B Function(C, D);
//         ^
// [diag.expectedToken] Expected to find ';'.
//           ^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          <empty> <synthetic>
      semicolon: ; <synthetic>
  declarations
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

  void test_library_directive_nameDot_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib. var a;
//         ^
// [diag.expectedToken] Expected to find ';'.
//           ^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          <empty> <synthetic>
      semicolon: ; <synthetic>
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_library_directive_nameDotName_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib.a class A {}
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          a
      semicolon: ; <synthetic>
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

  void test_library_directive_nameDotName_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib.a const a = 0;
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          a
      semicolon: ; <synthetic>
  declarations
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

  void test_library_directive_nameDotName_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib.a enum E { v }
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          a
      semicolon: ; <synthetic>
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

  void test_library_directive_nameDotName_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib.a
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          a
      semicolon: ; <synthetic>
''');
  }

  void test_library_directive_nameDotName_export() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib.a export 'a.dart';
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          a
      semicolon: ; <synthetic>
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_library_directive_nameDotName_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib.a final a = 0;
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          a
      semicolon: ; <synthetic>
  declarations
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

  void test_library_directive_nameDotName_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib.a int f() {}
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          a
      semicolon: ; <synthetic>
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

  void test_library_directive_nameDotName_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib.a void f() {}
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          a
      semicolon: ; <synthetic>
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

  void test_library_directive_nameDotName_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib.a int get a => 0;
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          a
      semicolon: ; <synthetic>
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

  void test_library_directive_nameDotName_import() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib.a import 'a.dart';
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          a
      semicolon: ; <synthetic>
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_library_directive_nameDotName_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib.a mixin M {}
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          a
      semicolon: ; <synthetic>
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_library_directive_nameDotName_part() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib.a part 'a.dart';
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          a
      semicolon: ; <synthetic>
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_library_directive_nameDotName_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib.a set a(b) {}
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          a
      semicolon: ; <synthetic>
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

  void test_library_directive_nameDotName_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib.a typedef A = B Function(C, D);
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          a
      semicolon: ; <synthetic>
  declarations
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

  void test_library_directive_nameDotName_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library lib.a var a;
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    LibraryDirective
      libraryKeyword: library
      name: DottedName
        tokens
          lib
          .
          a
      semicolon: ; <synthetic>
  declarations
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
