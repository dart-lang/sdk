// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExportDirectivesTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ExportDirectivesTest extends ParserDiagnosticsTest {
  void test_export_directive_emptyUri_class() {
    var parseResult = parseStringWithErrors(r'''
export '' class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_emptyUri_const() {
    var parseResult = parseStringWithErrors(r'''
export '' const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_emptyUri_enum() {
    var parseResult = parseStringWithErrors(r'''
export '' enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_emptyUri_eof() {
    var parseResult = parseStringWithErrors(r'''
export ''
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: ''
      semicolon: ; <synthetic>
''');
  }

  void test_export_directive_emptyUri_export() {
    var parseResult = parseStringWithErrors(r'''
export '' export 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: ''
      semicolon: ; <synthetic>
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_emptyUri_final() {
    var parseResult = parseStringWithErrors(r'''
export '' final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_emptyUri_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
export '' int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_emptyUri_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
export '' void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_emptyUri_getter() {
    var parseResult = parseStringWithErrors(r'''
export '' int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_emptyUri_import() {
    var parseResult = parseStringWithErrors(r'''
export '' import 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: ''
      semicolon: ; <synthetic>
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_emptyUri_mixin() {
    var parseResult = parseStringWithErrors(r'''
export '' mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_emptyUri_part() {
    var parseResult = parseStringWithErrors(r'''
export '' part 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_emptyUri_setter() {
    var parseResult = parseStringWithErrors(r'''
export '' set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_emptyUri_typedef() {
    var parseResult = parseStringWithErrors(r'''
export '' typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_emptyUri_var() {
    var parseResult = parseStringWithErrors(r'''
export '' var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_hide_class() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide class A {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 5),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
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

  void test_export_directive_hide_const() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide const a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 5),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
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

  void test_export_directive_hide_enum() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide enum E { v }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 4),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: <empty> <synthetic>
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

  void test_export_directive_hide_eof() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 0),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_export_directive_hide_export() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide export 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 6),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_hide_final() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide final a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 5),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
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

  void test_export_directive_hide_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
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

  void test_export_directive_hide_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide void f() {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 4),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
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

  void test_export_directive_hide_getter() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
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

  void test_export_directive_hide_import() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide import 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 6),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_hide_mixin() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 5),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
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

  void test_export_directive_hide_part() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide part 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 4),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_hide_setter() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 3),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
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

  void test_export_directive_hide_typedef() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 7),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
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

  void test_export_directive_hide_var() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide var a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 3),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
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

  void test_export_directive_hideComma_class() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, class A {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 5),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_hideComma_const() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, const a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 5),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_hideComma_enum() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, enum E { v }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 4),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: <empty> <synthetic>
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

  void test_export_directive_hideComma_eof() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A,
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 0),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_export_directive_hideComma_export() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, export 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 6),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_hideComma_final() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, final a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 5),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_hideComma_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_hideComma_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, void f() {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 4),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_hideComma_getter() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_hideComma_import() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, import 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 6),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_hideComma_mixin() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 5),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_hideComma_part() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, part 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 4),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_hideComma_setter() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 3),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_hideComma_typedef() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 7),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_hideComma_var() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, var a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 3),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_hideCommaName_class() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, B class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
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

  void test_export_directive_hideCommaName_const() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, B const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
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

  void test_export_directive_hideCommaName_enum() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, B enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
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

  void test_export_directive_hideCommaName_eof() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, B
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
      semicolon: ; <synthetic>
''');
  }

  void test_export_directive_hideCommaName_export() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, B export 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
      semicolon: ; <synthetic>
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_hideCommaName_final() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, B final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
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

  void test_export_directive_hideCommaName_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, B int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
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

  void test_export_directive_hideCommaName_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, B void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
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

  void test_export_directive_hideCommaName_getter() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, B int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
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

  void test_export_directive_hideCommaName_import() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, B import 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
      semicolon: ; <synthetic>
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_hideCommaName_mixin() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, B mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
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

  void test_export_directive_hideCommaName_part() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, B part 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
      semicolon: ; <synthetic>
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_hideCommaName_setter() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, B set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
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

  void test_export_directive_hideCommaName_typedef() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, B typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
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

  void test_export_directive_hideCommaName_var() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A, B var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
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

  void test_export_directive_hideName_class() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_hideName_const() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_hideName_enum() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_hideName_eof() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
      semicolon: ; <synthetic>
''');
  }

  void test_export_directive_hideName_export() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A export 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
      semicolon: ; <synthetic>
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_hideName_final() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_hideName_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_hideName_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_hideName_getter() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_hideName_import() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A import 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
      semicolon: ; <synthetic>
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_hideName_mixin() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_hideName_part() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A part 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
      semicolon: ; <synthetic>
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_hideName_setter() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_hideName_typedef() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_hideName_var() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_hideShow_class() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A show class A {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 5),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
        ShowCombinator
          keyword: show
          shownNames
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

  void test_export_directive_hideShow_const() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A show const a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 5),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
        ShowCombinator
          keyword: show
          shownNames
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

  void test_export_directive_hideShow_enum() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A show enum E { v }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 4),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: <empty> <synthetic>
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

  void test_export_directive_hideShow_eof() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A show
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 0),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_export_directive_hideShow_export() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A show export 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 6),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_hideShow_final() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A show final a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 5),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
        ShowCombinator
          keyword: show
          shownNames
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

  void test_export_directive_hideShow_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A show int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 28, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
        ShowCombinator
          keyword: show
          shownNames
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

  void test_export_directive_hideShow_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A show void f() {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 4),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
        ShowCombinator
          keyword: show
          shownNames
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

  void test_export_directive_hideShow_getter() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A show int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 28, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
        ShowCombinator
          keyword: show
          shownNames
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

  void test_export_directive_hideShow_import() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A show import 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 6),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_hideShow_mixin() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A show mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 5),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
        ShowCombinator
          keyword: show
          shownNames
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

  void test_export_directive_hideShow_part() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A show part 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 4),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_hideShow_setter() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A show set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 3),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
        ShowCombinator
          keyword: show
          shownNames
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

  void test_export_directive_hideShow_typedef() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A show typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 7),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
        ShowCombinator
          keyword: show
          shownNames
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

  void test_export_directive_hideShow_var() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' hide A show var a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 3),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: A
        ShowCombinator
          keyword: show
          shownNames
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

  void test_export_directive_keyword_class() {
    var parseResult = parseStringWithErrors(r'''
export class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 5),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_keyword_const() {
    var parseResult = parseStringWithErrors(r'''
export const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 5),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_keyword_enum() {
    var parseResult = parseStringWithErrors(r'''
export enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 4),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_keyword_eof() {
    var parseResult = parseStringWithErrors(r'''
export
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 0),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: "" <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_export_directive_keyword_export() {
    var parseResult = parseStringWithErrors(r'''
export export 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 6),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: "" <synthetic>
      semicolon: ; <synthetic>
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_keyword_final() {
    var parseResult = parseStringWithErrors(r'''
export final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 5),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_keyword_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
export int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 3),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_keyword_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
export void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 4),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_keyword_getter() {
    var parseResult = parseStringWithErrors(r'''
export int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 3),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_keyword_import() {
    var parseResult = parseStringWithErrors(r'''
export import 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 6),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: "" <synthetic>
      semicolon: ; <synthetic>
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_keyword_mixin() {
    var parseResult = parseStringWithErrors(r'''
export mixin M {}
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 5),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_keyword_part() {
    var parseResult = parseStringWithErrors(r'''
export part 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 4),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_keyword_setter() {
    var parseResult = parseStringWithErrors(r'''
export set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 3),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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
          parameter: SimpleFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_export_directive_keyword_typedef() {
    var parseResult = parseStringWithErrors(r'''
export typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 7),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_keyword_var() {
    var parseResult = parseStringWithErrors(r'''
export var a;
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 3),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_show_class() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show class A {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 5),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
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

  void test_export_directive_show_const() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show const a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 5),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
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

  void test_export_directive_show_enum() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show enum E { v }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 4),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: <empty> <synthetic>
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

  void test_export_directive_show_eof() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 0),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_export_directive_show_export() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show export 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 6),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_show_final() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show final a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 5),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
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

  void test_export_directive_show_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
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

  void test_export_directive_show_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show void f() {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 4),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
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

  void test_export_directive_show_getter() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
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

  void test_export_directive_show_import() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show import 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 6),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_show_mixin() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 5),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
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

  void test_export_directive_show_part() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show part 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 4),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_show_setter() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 3),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
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

  void test_export_directive_show_typedef() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 7),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
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

  void test_export_directive_show_var() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show var a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 3),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
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

  void test_export_directive_showComma_class() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, class A {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 5),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_showComma_const() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, const a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 5),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_showComma_enum() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, enum E { v }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 4),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: <empty> <synthetic>
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

  void test_export_directive_showComma_eof() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A,
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 0),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_export_directive_showComma_export() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, export 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 6),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_showComma_final() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, final a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 5),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_showComma_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_showComma_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, void f() {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 4),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_showComma_getter() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_showComma_import() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, import 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 6),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_showComma_mixin() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 5),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_showComma_part() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, part 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 4),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_showComma_setter() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 3),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_showComma_typedef() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 7),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_showComma_var() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, var a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 24, 3),
      error(diag.expectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_showCommaName_class() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, B class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
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

  void test_export_directive_showCommaName_const() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, B const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
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

  void test_export_directive_showCommaName_enum() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, B enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
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

  void test_export_directive_showCommaName_eof() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, B
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
      semicolon: ; <synthetic>
''');
  }

  void test_export_directive_showCommaName_export() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, B export 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
      semicolon: ; <synthetic>
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_showCommaName_final() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, B final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
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

  void test_export_directive_showCommaName_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, B int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
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

  void test_export_directive_showCommaName_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, B void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
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

  void test_export_directive_showCommaName_getter() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, B int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
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

  void test_export_directive_showCommaName_import() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, B import 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
      semicolon: ; <synthetic>
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_showCommaName_mixin() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, B mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
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

  void test_export_directive_showCommaName_part() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, B part 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
      semicolon: ; <synthetic>
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_showCommaName_setter() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, B set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
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

  void test_export_directive_showCommaName_typedef() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, B typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
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

  void test_export_directive_showCommaName_var() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A, B var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
            SimpleIdentifier
              token: B
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

  void test_export_directive_showHide_class() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A hide class A {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 5),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
        HideCombinator
          keyword: hide
          hiddenNames
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

  void test_export_directive_showHide_const() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A hide const a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 5),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
        HideCombinator
          keyword: hide
          hiddenNames
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

  void test_export_directive_showHide_enum() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A hide enum E { v }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 4),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: <empty> <synthetic>
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

  void test_export_directive_showHide_eof() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A hide
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 0),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_export_directive_showHide_export() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A hide export 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 6),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_showHide_final() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A hide final a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 5),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
        HideCombinator
          keyword: hide
          hiddenNames
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

  void test_export_directive_showHide_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A hide int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 28, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
        HideCombinator
          keyword: hide
          hiddenNames
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

  void test_export_directive_showHide_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A hide void f() {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 4),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
        HideCombinator
          keyword: hide
          hiddenNames
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

  void test_export_directive_showHide_getter() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A hide int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 28, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
        HideCombinator
          keyword: hide
          hiddenNames
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

  void test_export_directive_showHide_import() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A hide import 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 6),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_showHide_mixin() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A hide mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 5),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
        HideCombinator
          keyword: hide
          hiddenNames
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

  void test_export_directive_showHide_part() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A hide part 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 4),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
        HideCombinator
          keyword: hide
          hiddenNames
            SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_showHide_setter() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A hide set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 3),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
        HideCombinator
          keyword: hide
          hiddenNames
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

  void test_export_directive_showHide_typedef() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A hide typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 7),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
        HideCombinator
          keyword: hide
          hiddenNames
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

  void test_export_directive_showHide_var() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A hide var a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 3),
      error(diag.expectedToken, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
        HideCombinator
          keyword: hide
          hiddenNames
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

  void test_export_directive_showName_class() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_showName_const() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_showName_enum() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_showName_eof() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
      semicolon: ; <synthetic>
''');
  }

  void test_export_directive_showName_export() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A export 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
      semicolon: ; <synthetic>
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_showName_final() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_showName_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_showName_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_showName_getter() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_showName_import() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A import 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
      semicolon: ; <synthetic>
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_showName_mixin() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_showName_part() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A part 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
      semicolon: ; <synthetic>
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_showName_setter() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_showName_typedef() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_showName_var() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' show A var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      combinators
        ShowCombinator
          keyword: show
          shownNames
            SimpleIdentifier
              token: A
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

  void test_export_directive_uri_class() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_uri_const() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_uri_enum() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_uri_eof() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart'
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ; <synthetic>
''');
  }

  void test_export_directive_uri_export() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' export 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ; <synthetic>
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_uri_final() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_uri_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_uri_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_uri_getter() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_uri_import() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' import 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ; <synthetic>
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_export_directive_uri_mixin() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_uri_part() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' part 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_uri_setter() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_uri_typedef() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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

  void test_export_directive_uri_var() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart' var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ExportDirective
      exportKeyword: export
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
