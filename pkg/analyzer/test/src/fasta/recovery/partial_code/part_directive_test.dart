// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PartDirectivesTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PartDirectivesTest extends ParserDiagnosticsTest {
  void test_part_directive_emptyUri_class() {
    var parseResult = parseStringWithErrors(r'''
part '' class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_emptyUri_const() {
    var parseResult = parseStringWithErrors(r'''
part '' const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_emptyUri_enum() {
    var parseResult = parseStringWithErrors(r'''
part '' enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_emptyUri_eof() {
    var parseResult = parseStringWithErrors(r'''
part ''
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: ''
      semicolon: ; <synthetic>
''');
  }

  void test_part_directive_emptyUri_final() {
    var parseResult = parseStringWithErrors(r'''
part '' final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_emptyUri_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
part '' int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_emptyUri_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
part '' void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_emptyUri_getter() {
    var parseResult = parseStringWithErrors(r'''
part '' int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_emptyUri_mixin() {
    var parseResult = parseStringWithErrors(r'''
part '' mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_emptyUri_part() {
    var parseResult = parseStringWithErrors(r'''
part '' part 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: ''
      semicolon: ; <synthetic>
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_part_directive_emptyUri_setter() {
    var parseResult = parseStringWithErrors(r'''
part '' set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_emptyUri_typedef() {
    var parseResult = parseStringWithErrors(r'''
part '' typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_emptyUri_var() {
    var parseResult = parseStringWithErrors(r'''
part '' var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_keyword_class() {
    var parseResult = parseStringWithErrors(r'''
part class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 5, 5),
      error(diag.expectedToken, 0, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_keyword_const() {
    var parseResult = parseStringWithErrors(r'''
part const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 5, 5),
      error(diag.expectedToken, 0, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_keyword_enum() {
    var parseResult = parseStringWithErrors(r'''
part enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 5, 4),
      error(diag.expectedToken, 0, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_keyword_eof() {
    var parseResult = parseStringWithErrors(r'''
part
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 5, 0),
      error(diag.expectedToken, 0, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: "" <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_part_directive_keyword_final() {
    var parseResult = parseStringWithErrors(r'''
part final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 5, 5),
      error(diag.expectedToken, 0, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_keyword_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
part int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 5, 3),
      error(diag.expectedToken, 0, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: "" <synthetic>
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

  void test_part_directive_keyword_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
part void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 5, 4),
      error(diag.expectedToken, 0, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_keyword_getter() {
    var parseResult = parseStringWithErrors(r'''
part int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 5, 3),
      error(diag.expectedToken, 0, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: "" <synthetic>
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

  void test_part_directive_keyword_mixin() {
    var parseResult = parseStringWithErrors(r'''
part mixin M {}
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 5, 5),
      error(diag.expectedToken, 0, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: "" <synthetic>
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

  void test_part_directive_keyword_part() {
    var parseResult = parseStringWithErrors(r'''
part part 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 5, 4),
      error(diag.expectedToken, 0, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: "" <synthetic>
      semicolon: ; <synthetic>
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_part_directive_keyword_setter() {
    var parseResult = parseStringWithErrors(r'''
part set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 5, 3),
      error(diag.expectedToken, 0, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: "" <synthetic>
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

  void test_part_directive_keyword_typedef() {
    var parseResult = parseStringWithErrors(r'''
part typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 5, 7),
      error(diag.expectedToken, 0, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: "" <synthetic>
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

  void test_part_directive_keyword_var() {
    var parseResult = parseStringWithErrors(r'''
part var a;
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 5, 3),
      error(diag.expectedToken, 0, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_uri_class() {
    var parseResult = parseStringWithErrors(r'''
part 'a.dart' class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_uri_const() {
    var parseResult = parseStringWithErrors(r'''
part 'a.dart' const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_uri_enum() {
    var parseResult = parseStringWithErrors(r'''
part 'a.dart' enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_uri_eof() {
    var parseResult = parseStringWithErrors(r'''
part 'a.dart'
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ; <synthetic>
''');
  }

  void test_part_directive_uri_final() {
    var parseResult = parseStringWithErrors(r'''
part 'a.dart' final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_uri_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
part 'a.dart' int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_uri_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
part 'a.dart' void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_uri_getter() {
    var parseResult = parseStringWithErrors(r'''
part 'a.dart' int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_uri_mixin() {
    var parseResult = parseStringWithErrors(r'''
part 'a.dart' mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_uri_part() {
    var parseResult = parseStringWithErrors(r'''
part 'a.dart' part 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ; <synthetic>
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_part_directive_uri_setter() {
    var parseResult = parseStringWithErrors(r'''
part 'a.dart' set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_uri_typedef() {
    var parseResult = parseStringWithErrors(r'''
part 'a.dart' typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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

  void test_part_directive_uri_var() {
    var parseResult = parseStringWithErrors(r'''
part 'a.dart' var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    PartDirective
      partKeyword: part
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
