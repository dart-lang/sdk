// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    var parseResult = parseStringWithErrors(r'''
part of '' class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 2)]);
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
    var parseResult = parseStringWithErrors(r'''
part of '' const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 2)]);
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
    var parseResult = parseStringWithErrors(r'''
part of '' enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 2)]);
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
      body: EnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_part_of_directive_emptyUri_eof() {
    var parseResult = parseStringWithErrors(r'''
part of ''
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 2)]);
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
    var parseResult = parseStringWithErrors(r'''
part of '' final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 2)]);
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
    var parseResult = parseStringWithErrors(r'''
part of '' int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 2)]);
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
    var parseResult = parseStringWithErrors(r'''
part of '' void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 2)]);
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
    var parseResult = parseStringWithErrors(r'''
part of '' int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 2)]);
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
    var parseResult = parseStringWithErrors(r'''
part of '' mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 2)]);
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
    var parseResult = parseStringWithErrors(r'''
part of '' set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 2)]);
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
          parameter: SimpleFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_part_of_directive_emptyUri_typedef() {
    var parseResult = parseStringWithErrors(r'''
part of '' typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 2)]);
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

  void test_part_of_directive_emptyUri_var() {
    var parseResult = parseStringWithErrors(r'''
part of '' var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 2)]);
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
    var parseResult = parseStringWithErrors(r'''
part of class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 8, 5),
      error(diag.expectedToken, 5, 2),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
part of const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 8, 5),
      error(diag.expectedToken, 5, 2),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
part of enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 8, 4),
      error(diag.expectedToken, 5, 2),
    ]);
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
      body: EnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_part_of_directive_keyword_eof() {
    var parseResult = parseStringWithErrors(r'''
part of
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 8, 0),
      error(diag.expectedToken, 5, 2),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
part of final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 8, 5),
      error(diag.expectedToken, 5, 2),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
part of int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 3),
      error(diag.partOfName, 8, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: int
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
    var parseResult = parseStringWithErrors(r'''
part of void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 8, 4),
      error(diag.expectedToken, 5, 2),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
part of int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 3),
      error(diag.partOfName, 8, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: int
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
    var parseResult = parseStringWithErrors(r'''
part of mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 5),
      error(diag.expectedToken, 5, 2),
      error(diag.partOfName, 8, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: <empty> <synthetic>
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
    var parseResult = parseStringWithErrors(r'''
part of set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 3),
      error(diag.expectedToken, 5, 2),
      error(diag.partOfName, 8, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: <empty> <synthetic>
      semicolon: ; <synthetic>
  declarations
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

  void test_part_of_directive_keyword_typedef() {
    var parseResult = parseStringWithErrors(r'''
part of typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 7),
      error(diag.expectedToken, 5, 2),
      error(diag.partOfName, 8, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: <empty> <synthetic>
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

  void test_part_of_directive_keyword_var() {
    var parseResult = parseStringWithErrors(r'''
part of var a;
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 8, 3),
      error(diag.expectedToken, 5, 2),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
part of lib class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 3),
      error(diag.partOfName, 8, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
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
    var parseResult = parseStringWithErrors(r'''
part of lib const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 3),
      error(diag.partOfName, 8, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
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
    var parseResult = parseStringWithErrors(r'''
part of lib enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 3),
      error(diag.partOfName, 8, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
      semicolon: ; <synthetic>
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: EnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_part_of_directive_name_eof() {
    var parseResult = parseStringWithErrors(r'''
part of lib
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 3),
      error(diag.partOfName, 8, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
      semicolon: ; <synthetic>
''');
  }

  void test_part_of_directive_name_final() {
    var parseResult = parseStringWithErrors(r'''
part of lib final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 3),
      error(diag.partOfName, 8, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
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
    var parseResult = parseStringWithErrors(r'''
part of lib int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 3),
      error(diag.partOfName, 8, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
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
    var parseResult = parseStringWithErrors(r'''
part of lib void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 3),
      error(diag.partOfName, 8, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
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
    var parseResult = parseStringWithErrors(r'''
part of lib int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 3),
      error(diag.partOfName, 8, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
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
    var parseResult = parseStringWithErrors(r'''
part of lib mixin M {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 3),
      error(diag.partOfName, 8, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
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
    var parseResult = parseStringWithErrors(r'''
part of lib set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 3),
      error(diag.partOfName, 8, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
      semicolon: ; <synthetic>
  declarations
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

  void test_part_of_directive_name_typedef() {
    var parseResult = parseStringWithErrors(r'''
part of lib typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 3),
      error(diag.partOfName, 8, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
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

  void test_part_of_directive_name_var() {
    var parseResult = parseStringWithErrors(r'''
part of lib var a;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 3),
      error(diag.partOfName, 8, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
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
    var parseResult = parseStringWithErrors(r'''
part of lib. class A {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 5),
      error(diag.expectedToken, 11, 1),
      error(diag.partOfName, 8, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
          SimpleIdentifier
            token: <empty> <synthetic>
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
    var parseResult = parseStringWithErrors(r'''
part of lib. const a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 5),
      error(diag.expectedToken, 11, 1),
      error(diag.partOfName, 8, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
          SimpleIdentifier
            token: <empty> <synthetic>
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
    var parseResult = parseStringWithErrors(r'''
part of lib. enum E { v }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 4),
      error(diag.expectedToken, 11, 1),
      error(diag.partOfName, 8, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
          SimpleIdentifier
            token: <empty> <synthetic>
      semicolon: ; <synthetic>
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: EnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_part_of_directive_nameDot_eof() {
    var parseResult = parseStringWithErrors(r'''
part of lib.
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 0),
      error(diag.expectedToken, 11, 1),
      error(diag.partOfName, 8, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
          SimpleIdentifier
            token: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_part_of_directive_nameDot_final() {
    var parseResult = parseStringWithErrors(r'''
part of lib. final a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 5),
      error(diag.expectedToken, 11, 1),
      error(diag.partOfName, 8, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
          SimpleIdentifier
            token: <empty> <synthetic>
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
    var parseResult = parseStringWithErrors(r'''
part of lib. int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 3),
      error(diag.partOfName, 8, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
          SimpleIdentifier
            token: int
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
    var parseResult = parseStringWithErrors(r'''
part of lib. void f() {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 4),
      error(diag.expectedToken, 11, 1),
      error(diag.partOfName, 8, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
          SimpleIdentifier
            token: <empty> <synthetic>
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
    var parseResult = parseStringWithErrors(r'''
part of lib. int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 3),
      error(diag.partOfName, 8, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
          SimpleIdentifier
            token: int
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
    var parseResult = parseStringWithErrors(r'''
part of lib. mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 5),
      error(diag.expectedToken, 11, 1),
      error(diag.partOfName, 8, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
          SimpleIdentifier
            token: <empty> <synthetic>
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
    var parseResult = parseStringWithErrors(r'''
part of lib. set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 3),
      error(diag.expectedToken, 11, 1),
      error(diag.partOfName, 8, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
          SimpleIdentifier
            token: <empty> <synthetic>
      semicolon: ; <synthetic>
  declarations
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

  void test_part_of_directive_nameDot_typedef() {
    var parseResult = parseStringWithErrors(r'''
part of lib. typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 7),
      error(diag.expectedToken, 11, 1),
      error(diag.partOfName, 8, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
          SimpleIdentifier
            token: <empty> <synthetic>
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

  void test_part_of_directive_nameDot_var() {
    var parseResult = parseStringWithErrors(r'''
part of lib. var a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 3),
      error(diag.expectedToken, 11, 1),
      error(diag.partOfName, 8, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
          SimpleIdentifier
            token: <empty> <synthetic>
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
    var parseResult = parseStringWithErrors(r'''
part of lib.a class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.partOfName, 8, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
          SimpleIdentifier
            token: a
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
    var parseResult = parseStringWithErrors(r'''
part of lib.a const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.partOfName, 8, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
          SimpleIdentifier
            token: a
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
    var parseResult = parseStringWithErrors(r'''
part of lib.a enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.partOfName, 8, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
          SimpleIdentifier
            token: a
      semicolon: ; <synthetic>
  declarations
    EnumDeclaration
      enumKeyword: enum
      namePart: NameWithTypeParameters
        typeName: E
      body: EnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_part_of_directive_nameDotName_eof() {
    var parseResult = parseStringWithErrors(r'''
part of lib.a
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.partOfName, 8, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
          SimpleIdentifier
            token: a
      semicolon: ; <synthetic>
''');
  }

  void test_part_of_directive_nameDotName_final() {
    var parseResult = parseStringWithErrors(r'''
part of lib.a final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.partOfName, 8, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
          SimpleIdentifier
            token: a
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
    var parseResult = parseStringWithErrors(r'''
part of lib.a int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.partOfName, 8, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
          SimpleIdentifier
            token: a
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
    var parseResult = parseStringWithErrors(r'''
part of lib.a void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.partOfName, 8, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
          SimpleIdentifier
            token: a
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
    var parseResult = parseStringWithErrors(r'''
part of lib.a int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.partOfName, 8, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
          SimpleIdentifier
            token: a
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
    var parseResult = parseStringWithErrors(r'''
part of lib.a mixin M {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.partOfName, 8, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
          SimpleIdentifier
            token: a
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
    var parseResult = parseStringWithErrors(r'''
part of lib.a set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.partOfName, 8, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
          SimpleIdentifier
            token: a
      semicolon: ; <synthetic>
  declarations
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

  void test_part_of_directive_nameDotName_typedef() {
    var parseResult = parseStringWithErrors(r'''
part of lib.a typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.partOfName, 8, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
          SimpleIdentifier
            token: a
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

  void test_part_of_directive_nameDotName_var() {
    var parseResult = parseStringWithErrors(r'''
part of lib.a var a;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.partOfName, 8, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartOfDirective
      partKeyword: part
      ofKeyword: of
      libraryName: LibraryIdentifier
        components
          SimpleIdentifier
            token: lib
          SimpleIdentifier
            token: a
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
    var parseResult = parseStringWithErrors(r'''
part of 'a.dart' class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 8)]);
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
    var parseResult = parseStringWithErrors(r'''
part of 'a.dart' const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 8)]);
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
    var parseResult = parseStringWithErrors(r'''
part of 'a.dart' enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 8)]);
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
      body: EnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_part_of_directive_uri_eof() {
    var parseResult = parseStringWithErrors(r'''
part of 'a.dart'
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 8)]);
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
    var parseResult = parseStringWithErrors(r'''
part of 'a.dart' final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 8)]);
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
    var parseResult = parseStringWithErrors(r'''
part of 'a.dart' int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 8)]);
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
    var parseResult = parseStringWithErrors(r'''
part of 'a.dart' void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 8)]);
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
    var parseResult = parseStringWithErrors(r'''
part of 'a.dart' int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 8)]);
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
    var parseResult = parseStringWithErrors(r'''
part of 'a.dart' mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 8)]);
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
    var parseResult = parseStringWithErrors(r'''
part of 'a.dart' set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 8)]);
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
          parameter: SimpleFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_part_of_directive_uri_typedef() {
    var parseResult = parseStringWithErrors(r'''
part of 'a.dart' typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 8)]);
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

  void test_part_of_directive_uri_var() {
    var parseResult = parseStringWithErrors(r'''
part of 'a.dart' var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 8, 8)]);
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
