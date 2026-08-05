// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PartOfDirectivesTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PartOfDirectivesTest extends ParserDiagnosticsTest {
  void test_part_of_directive_emptyUri_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of '' class A {}
//      ^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: ''
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

  void test_part_of_directive_emptyUri_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of '' const a = 0;
//      ^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: ''
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

  void test_part_of_directive_emptyUri_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of '' enum E { v }
//      ^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: ''
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

  void test_part_of_directive_emptyUri_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of ''
//      ^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: ''
      semicolon: ; <synthetic>
''');
  }

  void test_part_of_directive_emptyUri_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of '' final a = 0;
//      ^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: ''
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

  void test_part_of_directive_emptyUri_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of '' int f() {}
//      ^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: ''
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

  void test_part_of_directive_emptyUri_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of '' void f() {}
//      ^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: ''
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

  void test_part_of_directive_emptyUri_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of '' int get a => 0;
//      ^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: ''
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

  void test_part_of_directive_emptyUri_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of '' mixin M {}
//      ^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: ''
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

  void test_part_of_directive_emptyUri_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of '' set a(b) {}
//      ^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: ''
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

  void test_part_of_directive_emptyUri_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of '' typedef A = B Function(C, D);
//      ^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: ''
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

  void test_part_of_directive_emptyUri_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of '' var a;
//      ^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: ''
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

  void test_part_of_directive_keyword_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of class A {}
//   ^^
// [diag.expectedToken] Expected to find ';'.
//      ^^^^^
// [diag.expectedStringLiteral] Expected a string literal.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: "" <synthetic>
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

  void test_part_of_directive_keyword_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of const a = 0;
//   ^^
// [diag.expectedToken] Expected to find ';'.
//      ^^^^^
// [diag.expectedStringLiteral] Expected a string literal.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: "" <synthetic>
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

  void test_part_of_directive_keyword_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of enum E { v }
//   ^^
// [diag.expectedToken] Expected to find ';'.
//      ^^^^
// [diag.expectedStringLiteral] Expected a string literal.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: "" <synthetic>
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

  void test_part_of_directive_keyword_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of
//   ^^
// [diag.expectedToken] Expected to find ';'.
//     ^
// [diag.expectedStringLiteral][column 8][length 0] Expected a string literal.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: "" <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_part_of_directive_keyword_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of final a = 0;
//   ^^
// [diag.expectedToken] Expected to find ';'.
//      ^^^^^
// [diag.expectedStringLiteral] Expected a string literal.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: "" <synthetic>
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

  void test_part_of_directive_keyword_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of int f() {}
//      ^^^
// [diag.expectedToken] Expected to find ';'.
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_keyword_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of void f() {}
//   ^^
// [diag.expectedToken] Expected to find ';'.
//      ^^^^
// [diag.expectedStringLiteral] Expected a string literal.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: "" <synthetic>
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

  void test_part_of_directive_keyword_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of int get a => 0;
//      ^^^
// [diag.expectedToken] Expected to find ';'.
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_keyword_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of mixin M {}
//   ^^
// [diag.expectedToken] Expected to find ';'.
//      ^^^^^
// [diag.missingIdentifier] Expected an identifier.
//      ^
// [diag.partOfName][column 9][length 0] The 'part of' directive can't use a name with the enhanced-parts feature.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_keyword_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of set a(b) {}
//   ^^
// [diag.expectedToken] Expected to find ';'.
//      ^^^
// [diag.missingIdentifier] Expected an identifier.
//      ^
// [diag.partOfName][column 9][length 0] The 'part of' directive can't use a name with the enhanced-parts feature.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_keyword_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of typedef A = B Function(C, D);
//   ^^
// [diag.expectedToken] Expected to find ';'.
//      ^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
//      ^
// [diag.partOfName][column 9][length 0] The 'part of' directive can't use a name with the enhanced-parts feature.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_keyword_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of var a;
//   ^^
// [diag.expectedToken] Expected to find ';'.
//      ^^^
// [diag.expectedStringLiteral] Expected a string literal.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: "" <synthetic>
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

  void test_part_of_directive_name_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib class A {}
//      ^^^
// [diag.expectedToken] Expected to find ';'.
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_name_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib const a = 0;
//      ^^^
// [diag.expectedToken] Expected to find ';'.
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_name_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib enum E { v }
//      ^^^
// [diag.expectedToken] Expected to find ';'.
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_name_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib
//      ^^^
// [diag.expectedToken] Expected to find ';'.
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
        tokens
          lib
      semicolon: ; <synthetic>
''');
  }

  void test_part_of_directive_name_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib final a = 0;
//      ^^^
// [diag.expectedToken] Expected to find ';'.
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_name_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib int f() {}
//      ^^^
// [diag.expectedToken] Expected to find ';'.
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_name_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib void f() {}
//      ^^^
// [diag.expectedToken] Expected to find ';'.
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_name_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib int get a => 0;
//      ^^^
// [diag.expectedToken] Expected to find ';'.
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_name_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib mixin M {}
//      ^^^
// [diag.expectedToken] Expected to find ';'.
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_name_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib set a(b) {}
//      ^^^
// [diag.expectedToken] Expected to find ';'.
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_name_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib typedef A = B Function(C, D);
//      ^^^
// [diag.expectedToken] Expected to find ';'.
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_name_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib var a;
//      ^^^
// [diag.expectedToken] Expected to find ';'.
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_nameDot_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib. class A {}
//      ^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//         ^
// [diag.expectedToken] Expected to find ';'.
//           ^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_nameDot_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib. const a = 0;
//      ^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//         ^
// [diag.expectedToken] Expected to find ';'.
//           ^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_nameDot_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib. enum E { v }
//      ^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//         ^
// [diag.expectedToken] Expected to find ';'.
//           ^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_nameDot_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib.
//      ^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//         ^
// [diag.expectedToken] Expected to find ';'.
//          ^
// [diag.missingIdentifier][column 13][length 0] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
        tokens
          lib
          .
          <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_part_of_directive_nameDot_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib. final a = 0;
//      ^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//         ^
// [diag.expectedToken] Expected to find ';'.
//           ^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_nameDot_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib. int f() {}
//      ^^^^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//           ^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_nameDot_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib. void f() {}
//      ^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//         ^
// [diag.expectedToken] Expected to find ';'.
//           ^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_nameDot_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib. int get a => 0;
//      ^^^^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//           ^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_nameDot_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib. mixin M {}
//      ^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//         ^
// [diag.expectedToken] Expected to find ';'.
//           ^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_nameDot_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib. set a(b) {}
//      ^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//         ^
// [diag.expectedToken] Expected to find ';'.
//           ^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_nameDot_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib. typedef A = B Function(C, D);
//      ^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//         ^
// [diag.expectedToken] Expected to find ';'.
//           ^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_nameDot_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib. var a;
//      ^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//         ^
// [diag.expectedToken] Expected to find ';'.
//           ^^^
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_nameDotName_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib.a class A {}
//      ^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_nameDotName_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib.a const a = 0;
//      ^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_nameDotName_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib.a enum E { v }
//      ^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_nameDotName_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib.a
//      ^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
        tokens
          lib
          .
          a
      semicolon: ; <synthetic>
''');
  }

  void test_part_of_directive_nameDotName_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib.a final a = 0;
//      ^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_nameDotName_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib.a int f() {}
//      ^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_nameDotName_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib.a void f() {}
//      ^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_nameDotName_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib.a int get a => 0;
//      ^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_nameDotName_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib.a mixin M {}
//      ^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_nameDotName_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib.a set a(b) {}
//      ^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_nameDotName_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib.a typedef A = B Function(C, D);
//      ^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_nameDotName_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of lib.a var a;
//      ^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
//          ^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: DottedName
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

  void test_part_of_directive_uri_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of 'a.dart' class A {}
//      ^^^^^^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: 'a.dart'
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

  void test_part_of_directive_uri_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of 'a.dart' const a = 0;
//      ^^^^^^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: 'a.dart'
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

  void test_part_of_directive_uri_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of 'a.dart' enum E { v }
//      ^^^^^^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: 'a.dart'
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

  void test_part_of_directive_uri_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of 'a.dart'
//      ^^^^^^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ; <synthetic>
''');
  }

  void test_part_of_directive_uri_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of 'a.dart' final a = 0;
//      ^^^^^^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: 'a.dart'
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

  void test_part_of_directive_uri_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of 'a.dart' int f() {}
//      ^^^^^^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: 'a.dart'
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

  void test_part_of_directive_uri_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of 'a.dart' void f() {}
//      ^^^^^^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: 'a.dart'
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

  void test_part_of_directive_uri_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of 'a.dart' int get a => 0;
//      ^^^^^^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: 'a.dart'
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

  void test_part_of_directive_uri_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of 'a.dart' mixin M {}
//      ^^^^^^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: 'a.dart'
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

  void test_part_of_directive_uri_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of 'a.dart' set a(b) {}
//      ^^^^^^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: 'a.dart'
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

  void test_part_of_directive_uri_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of 'a.dart' typedef A = B Function(C, D);
//      ^^^^^^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: 'a.dart'
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

  void test_part_of_directive_uri_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of 'a.dart' var a;
//      ^^^^^^^^
// [diag.expectedToken] Expected to find ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      uri: SimpleStringLiteral
        literal: 'a.dart'
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
