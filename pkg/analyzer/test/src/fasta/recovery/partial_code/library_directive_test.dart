// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    var parseResult = parseStringWithErrors(r'''
library class A {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 5),
      error(diag.expectedToken, 0, 7),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library const a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 5),
      error(diag.expectedToken, 0, 7),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library enum E { v }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 4),
      error(diag.expectedToken, 0, 7),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 0),
      error(diag.expectedToken, 0, 7),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library export 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 6),
      error(diag.expectedToken, 0, 7),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library final a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 5),
      error(diag.expectedToken, 0, 7),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 3)]);
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
    var parseResult = parseStringWithErrors(r'''
library void f() {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 4),
      error(diag.expectedToken, 0, 7),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 3)]);
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
    var parseResult = parseStringWithErrors(r'''
library import 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 6),
      error(diag.expectedToken, 0, 7),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 5),
      error(diag.expectedToken, 0, 7),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library part 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 4),
      error(diag.expectedToken, 0, 7),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 3),
      error(diag.expectedToken, 0, 7),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 7),
      error(diag.expectedToken, 0, 7),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library var a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 3),
      error(diag.expectedToken, 0, 7),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library lib class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 3)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 3)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 3)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 3)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib export 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 3)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 3)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 3)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 3)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 3)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib import 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 3)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 3)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib part 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 3)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 3)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 3)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 3)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib. class A {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 5),
      error(diag.expectedToken, 11, 1),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library lib. const a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 5),
      error(diag.expectedToken, 11, 1),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library lib. enum E { v }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 4),
      error(diag.expectedToken, 11, 1),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library lib.
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 0),
      error(diag.expectedToken, 11, 1),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library lib. export 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 6),
      error(diag.expectedToken, 11, 1),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library lib. final a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 5),
      error(diag.expectedToken, 11, 1),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library lib. int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 3)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib. void f() {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 4),
      error(diag.expectedToken, 11, 1),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library lib. int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 3)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib. import 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 6),
      error(diag.expectedToken, 11, 1),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library lib. mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 5),
      error(diag.expectedToken, 11, 1),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library lib. part 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 4),
      error(diag.expectedToken, 11, 1),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library lib. set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 3),
      error(diag.expectedToken, 11, 1),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library lib. typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 7),
      error(diag.expectedToken, 11, 1),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library lib. var a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 3),
      error(diag.expectedToken, 11, 1),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
library lib.a class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib.a const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib.a enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib.a
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib.a export 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib.a final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib.a int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib.a void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib.a int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib.a import 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib.a mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib.a part 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib.a set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib.a typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
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
    var parseResult = parseStringWithErrors(r'''
library lib.a var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
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
