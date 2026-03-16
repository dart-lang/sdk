// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportDirectivesTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ImportDirectivesTest extends ParserDiagnosticsTest {
  void test_import_directive_as_class() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' as class A {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 5),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      asKeyword: as
      prefix: SimpleIdentifier
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

  void test_import_directive_as_const() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' as const a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 5),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      asKeyword: as
      prefix: SimpleIdentifier
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

  void test_import_directive_as_enum() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' as enum E { v }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 4),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      asKeyword: as
      prefix: SimpleIdentifier
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

  void test_import_directive_as_eof() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' as
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 0),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      asKeyword: as
      prefix: SimpleIdentifier
        token: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_import_directive_as_export() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' as export 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 6),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      asKeyword: as
      prefix: SimpleIdentifier
        token: <empty> <synthetic>
      semicolon: ; <synthetic>
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_import_directive_as_final() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' as final a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 5),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      asKeyword: as
      prefix: SimpleIdentifier
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

  void test_import_directive_as_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' as int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 19, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      asKeyword: as
      prefix: SimpleIdentifier
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

  void test_import_directive_as_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' as void f() {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 4),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      asKeyword: as
      prefix: SimpleIdentifier
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

  void test_import_directive_as_getter() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' as int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 19, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      asKeyword: as
      prefix: SimpleIdentifier
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

  void test_import_directive_as_import() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' as import 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 6),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      asKeyword: as
      prefix: SimpleIdentifier
        token: <empty> <synthetic>
      semicolon: ; <synthetic>
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_import_directive_as_mixin() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' as mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 5),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      asKeyword: as
      prefix: SimpleIdentifier
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

  void test_import_directive_as_part() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' as part 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 4),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      asKeyword: as
      prefix: SimpleIdentifier
        token: <empty> <synthetic>
      semicolon: ; <synthetic>
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_import_directive_as_setter() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' as set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 3),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      asKeyword: as
      prefix: SimpleIdentifier
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

  void test_import_directive_as_typedef() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' as typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 7),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      asKeyword: as
      prefix: SimpleIdentifier
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

  void test_import_directive_as_var() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' as var a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 3),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      asKeyword: as
      prefix: SimpleIdentifier
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

  void test_import_directive_emptyUri_class() {
    var parseResult = parseStringWithErrors(r'''
import '' class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_emptyUri_const() {
    var parseResult = parseStringWithErrors(r'''
import '' const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_emptyUri_enum() {
    var parseResult = parseStringWithErrors(r'''
import '' enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_emptyUri_eof() {
    var parseResult = parseStringWithErrors(r'''
import ''
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: ''
      semicolon: ; <synthetic>
''');
  }

  void test_import_directive_emptyUri_export() {
    var parseResult = parseStringWithErrors(r'''
import '' export 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_emptyUri_final() {
    var parseResult = parseStringWithErrors(r'''
import '' final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_emptyUri_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
import '' int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_emptyUri_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
import '' void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_emptyUri_getter() {
    var parseResult = parseStringWithErrors(r'''
import '' int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_emptyUri_import() {
    var parseResult = parseStringWithErrors(r'''
import '' import 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_emptyUri_mixin() {
    var parseResult = parseStringWithErrors(r'''
import '' mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_emptyUri_part() {
    var parseResult = parseStringWithErrors(r'''
import '' part 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_emptyUri_setter() {
    var parseResult = parseStringWithErrors(r'''
import '' set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_emptyUri_typedef() {
    var parseResult = parseStringWithErrors(r'''
import '' typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_emptyUri_var() {
    var parseResult = parseStringWithErrors(r'''
import '' var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_fullUri_class() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' class A {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_fullUri_const() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_fullUri_enum() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_fullUri_eof() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart'
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ; <synthetic>
''');
  }

  void test_import_directive_fullUri_export() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' export 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_fullUri_final() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_fullUri_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_fullUri_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_fullUri_getter() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_fullUri_import() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' import 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_fullUri_mixin() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_fullUri_part() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' part 'a.dart';
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_fullUri_setter() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_fullUri_typedef() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_fullUri_var() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' var a;
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_if_class() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 5),
      error(diag.expectedStringLiteral, 19, 5),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: ( <synthetic>
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_if_const() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 5),
      error(diag.expectedStringLiteral, 19, 5),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: ( <synthetic>
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_if_enum() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 4),
      error(diag.expectedStringLiteral, 19, 4),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: ( <synthetic>
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_if_eof() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 0),
      error(diag.expectedStringLiteral, 19, 0),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: ( <synthetic>
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
      semicolon: ; <synthetic>
''');
  }

  void test_import_directive_if_export() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if export 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 6),
      error(diag.expectedStringLiteral, 19, 6),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: ( <synthetic>
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
      semicolon: ; <synthetic>
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_import_directive_if_final() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 5),
      error(diag.expectedStringLiteral, 19, 5),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: ( <synthetic>
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_if_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 3),
      error(diag.expectedStringLiteral, 19, 3),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: ( <synthetic>
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_if_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 4),
      error(diag.expectedStringLiteral, 19, 4),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: ( <synthetic>
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_if_getter() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 3),
      error(diag.expectedStringLiteral, 19, 3),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: ( <synthetic>
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_if_import() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if import 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 6),
      error(diag.expectedStringLiteral, 19, 6),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: ( <synthetic>
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
      semicolon: ; <synthetic>
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_import_directive_if_mixin() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if mixin M {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 5),
      error(diag.expectedStringLiteral, 19, 5),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: ( <synthetic>
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_if_part() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if part 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 4),
      error(diag.expectedStringLiteral, 19, 4),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: ( <synthetic>
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
      semicolon: ; <synthetic>
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_import_directive_if_setter() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 3),
      error(diag.expectedStringLiteral, 19, 3),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: ( <synthetic>
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_if_typedef() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 7),
      error(diag.expectedStringLiteral, 19, 7),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: ( <synthetic>
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_if_var() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if var a;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 3),
      error(diag.expectedStringLiteral, 19, 3),
      error(diag.expectedToken, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: ( <synthetic>
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifCondition_class() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b) class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 23, 5),
      error(diag.expectedToken, 21, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifCondition_const() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b) const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 23, 5),
      error(diag.expectedToken, 21, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifCondition_enum() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b) enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 23, 4),
      error(diag.expectedToken, 21, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifCondition_eof() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b)
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 23, 0),
      error(diag.expectedToken, 21, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
      semicolon: ; <synthetic>
''');
  }

  void test_import_directive_ifCondition_export() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b) export 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 23, 6),
      error(diag.expectedToken, 21, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
      semicolon: ; <synthetic>
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_import_directive_ifCondition_final() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b) final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 23, 5),
      error(diag.expectedToken, 21, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifCondition_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b) int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 23, 3),
      error(diag.expectedToken, 21, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifCondition_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b) void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 23, 4),
      error(diag.expectedToken, 21, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifCondition_getter() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b) int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 23, 3),
      error(diag.expectedToken, 21, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifCondition_import() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b) import 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 23, 6),
      error(diag.expectedToken, 21, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
      semicolon: ; <synthetic>
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_import_directive_ifCondition_mixin() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b) mixin M {}
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 23, 5),
      error(diag.expectedToken, 21, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifCondition_part() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b) part 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 23, 4),
      error(diag.expectedToken, 21, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
      semicolon: ; <synthetic>
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_import_directive_ifCondition_setter() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b) set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 23, 3),
      error(diag.expectedToken, 21, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifCondition_typedef() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b) typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 23, 7),
      error(diag.expectedToken, 21, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifCondition_var() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b) var a;
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 23, 3),
      error(diag.expectedToken, 21, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: )
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifEquals_class() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b == class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.expectedStringLiteral, 25, 5),
      error(diag.expectedToken, 22, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          equalToken: ==
          value: SimpleStringLiteral
            literal: "" <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifEquals_const() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b == const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 38, 1),
      error(diag.expectedStringLiteral, 25, 5),
      error(diag.expectedToken, 22, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          equalToken: ==
          value: SimpleStringLiteral
            literal: "" <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifEquals_enum() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b == enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 38, 1),
      error(diag.expectedStringLiteral, 25, 4),
      error(diag.expectedToken, 22, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          equalToken: ==
          value: SimpleStringLiteral
            literal: "" <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifEquals_eof() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b ==
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 25, 1),
      error(diag.expectedStringLiteral, 25, 0),
      error(diag.expectedToken, 22, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          equalToken: ==
          value: SimpleStringLiteral
            literal: "" <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
      semicolon: ; <synthetic>
''');
  }

  void test_import_directive_ifEquals_export() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b == export 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 42, 1),
      error(diag.expectedStringLiteral, 25, 6),
      error(diag.expectedToken, 22, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          equalToken: ==
          value: SimpleStringLiteral
            literal: "" <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
      semicolon: ; <synthetic>
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_import_directive_ifEquals_final() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b == final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 38, 1),
      error(diag.expectedStringLiteral, 25, 5),
      error(diag.expectedToken, 22, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          equalToken: ==
          value: SimpleStringLiteral
            literal: "" <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifEquals_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b == int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.expectedStringLiteral, 25, 3),
      error(diag.expectedToken, 22, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          equalToken: ==
          value: SimpleStringLiteral
            literal: "" <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifEquals_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b == void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.expectedStringLiteral, 25, 4),
      error(diag.expectedToken, 22, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          equalToken: ==
          value: SimpleStringLiteral
            literal: "" <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifEquals_getter() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b == int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 41, 1),
      error(diag.expectedStringLiteral, 25, 3),
      error(diag.expectedToken, 22, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          equalToken: ==
          value: SimpleStringLiteral
            literal: "" <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifEquals_import() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b == import 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 42, 1),
      error(diag.expectedStringLiteral, 25, 6),
      error(diag.expectedToken, 22, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          equalToken: ==
          value: SimpleStringLiteral
            literal: "" <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
      semicolon: ; <synthetic>
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_import_directive_ifEquals_mixin() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b == mixin M {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.expectedStringLiteral, 25, 5),
      error(diag.expectedToken, 22, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          equalToken: ==
          value: SimpleStringLiteral
            literal: "" <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifEquals_part() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b == part 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 40, 1),
      error(diag.expectedStringLiteral, 25, 4),
      error(diag.expectedToken, 22, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          equalToken: ==
          value: SimpleStringLiteral
            literal: "" <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
      semicolon: ; <synthetic>
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_import_directive_ifEquals_setter() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b == set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.expectedStringLiteral, 25, 3),
      error(diag.expectedToken, 22, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          equalToken: ==
          value: SimpleStringLiteral
            literal: "" <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifEquals_typedef() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b == typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 55, 1),
      error(diag.expectedStringLiteral, 25, 7),
      error(diag.expectedToken, 22, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          equalToken: ==
          value: SimpleStringLiteral
            literal: "" <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifEquals_var() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b == var a;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.expectedStringLiteral, 25, 3),
      error(diag.expectedToken, 22, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          equalToken: ==
          value: SimpleStringLiteral
            literal: "" <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifId_class() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.expectedStringLiteral, 22, 5),
      error(diag.expectedToken, 20, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifId_const() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.expectedStringLiteral, 22, 5),
      error(diag.expectedToken, 20, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifId_enum() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.expectedStringLiteral, 22, 4),
      error(diag.expectedToken, 20, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifId_eof() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.expectedStringLiteral, 22, 0),
      error(diag.expectedToken, 20, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
      semicolon: ; <synthetic>
''');
  }

  void test_import_directive_ifId_export() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b export 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 39, 1),
      error(diag.expectedStringLiteral, 22, 6),
      error(diag.expectedToken, 20, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
      semicolon: ; <synthetic>
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_import_directive_ifId_final() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.expectedStringLiteral, 22, 5),
      error(diag.expectedToken, 20, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifId_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.expectedStringLiteral, 22, 3),
      error(diag.expectedToken, 20, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifId_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.expectedStringLiteral, 22, 4),
      error(diag.expectedToken, 20, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifId_getter() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 38, 1),
      error(diag.expectedStringLiteral, 22, 3),
      error(diag.expectedToken, 20, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifId_import() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b import 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 39, 1),
      error(diag.expectedStringLiteral, 22, 6),
      error(diag.expectedToken, 20, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
      semicolon: ; <synthetic>
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_import_directive_ifId_mixin() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b mixin M {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.expectedStringLiteral, 22, 5),
      error(diag.expectedToken, 20, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifId_part() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b part 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.expectedStringLiteral, 22, 4),
      error(diag.expectedToken, 20, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
      semicolon: ; <synthetic>
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_import_directive_ifId_setter() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.expectedStringLiteral, 22, 3),
      error(diag.expectedToken, 20, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifId_typedef() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 52, 1),
      error(diag.expectedStringLiteral, 22, 7),
      error(diag.expectedToken, 20, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifId_var() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (b var a;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.expectedStringLiteral, 22, 3),
      error(diag.expectedToken, 20, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              b
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifParen_class() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if ( class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.missingIdentifier, 21, 5),
      error(diag.expectedStringLiteral, 21, 5),
      error(diag.expectedToken, 19, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifParen_const() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if ( const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.missingIdentifier, 21, 5),
      error(diag.expectedStringLiteral, 21, 5),
      error(diag.expectedToken, 19, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifParen_enum() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if ( enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.missingIdentifier, 21, 4),
      error(diag.expectedStringLiteral, 21, 4),
      error(diag.expectedToken, 19, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifParen_eof() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if (
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 1),
      error(diag.missingIdentifier, 21, 0),
      error(diag.expectedStringLiteral, 21, 0),
      error(diag.expectedToken, 19, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
      semicolon: ; <synthetic>
''');
  }

  void test_import_directive_ifParen_export() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if ( export 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 38, 1),
      error(diag.missingIdentifier, 21, 6),
      error(diag.expectedStringLiteral, 21, 6),
      error(diag.expectedToken, 19, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
      semicolon: ; <synthetic>
    ExportDirective
      exportKeyword: export
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_import_directive_ifParen_final() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if ( final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.missingIdentifier, 21, 5),
      error(diag.expectedStringLiteral, 21, 5),
      error(diag.expectedToken, 19, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifParen_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if ( int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.expectedStringLiteral, 25, 1),
      error(diag.expectedToken, 21, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              int
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifParen_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if ( void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.missingIdentifier, 21, 4),
      error(diag.expectedStringLiteral, 21, 4),
      error(diag.expectedToken, 19, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifParen_getter() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if ( int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.expectedStringLiteral, 25, 3),
      error(diag.expectedToken, 21, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              int
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifParen_import() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if ( import 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 38, 1),
      error(diag.missingIdentifier, 21, 6),
      error(diag.expectedStringLiteral, 21, 6),
      error(diag.expectedToken, 19, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
      semicolon: ; <synthetic>
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_import_directive_ifParen_mixin() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if ( mixin M {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.missingIdentifier, 21, 5),
      error(diag.expectedStringLiteral, 21, 5),
      error(diag.expectedToken, 19, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifParen_part() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if ( part 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.missingIdentifier, 21, 4),
      error(diag.expectedStringLiteral, 21, 4),
      error(diag.expectedToken, 19, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
      semicolon: ; <synthetic>
    PartDirective
      partKeyword: part
      uri: SimpleStringLiteral
        literal: 'a.dart'
      semicolon: ;
''');
  }

  void test_import_directive_ifParen_setter() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if ( set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.expectedStringLiteral, 25, 1),
      error(diag.expectedToken, 21, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              set
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
      semicolon: ; <synthetic>
  declarations
    FunctionDeclaration
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

  void test_import_directive_ifParen_typedef() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if ( typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 51, 1),
      error(diag.missingIdentifier, 21, 7),
      error(diag.expectedStringLiteral, 21, 7),
      error(diag.expectedToken, 19, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_ifParen_var() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' if ( var a;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.missingIdentifier, 21, 3),
      error(diag.expectedStringLiteral, 21, 3),
      error(diag.expectedToken, 19, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: 'a.dart'
      configurations
        Configuration
          ifKeyword: if
          leftParenthesis: (
          name: DottedName
            tokens
              <empty> <synthetic>
          rightParenthesis: ) <synthetic>
          uri: SimpleStringLiteral
            literal: "" <synthetic>
          resolvedUri: <null>
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

  void test_import_directive_keyword_class() {
    var parseResult = parseStringWithErrors(r'''
import class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 5),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_keyword_const() {
    var parseResult = parseStringWithErrors(r'''
import const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 5),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_keyword_enum() {
    var parseResult = parseStringWithErrors(r'''
import enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 4),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_keyword_eof() {
    var parseResult = parseStringWithErrors(r'''
import
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 0),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
      uri: SimpleStringLiteral
        literal: "" <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_import_directive_keyword_export() {
    var parseResult = parseStringWithErrors(r'''
import export 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 6),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_keyword_final() {
    var parseResult = parseStringWithErrors(r'''
import final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 5),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_keyword_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
import int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 3),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_keyword_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
import void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 4),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_keyword_getter() {
    var parseResult = parseStringWithErrors(r'''
import int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 3),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_keyword_import() {
    var parseResult = parseStringWithErrors(r'''
import import 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 6),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_keyword_mixin() {
    var parseResult = parseStringWithErrors(r'''
import mixin M {}
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 5),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_keyword_part() {
    var parseResult = parseStringWithErrors(r'''
import part 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 4),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_keyword_setter() {
    var parseResult = parseStringWithErrors(r'''
import set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 3),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_keyword_typedef() {
    var parseResult = parseStringWithErrors(r'''
import typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 7),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_keyword_var() {
    var parseResult = parseStringWithErrors(r'''
import var a;
''');
    parseResult.assertErrors([
      error(diag.expectedStringLiteral, 7, 3),
      error(diag.expectedToken, 0, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_show_class() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' show class A {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 5),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_show_const() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' show const a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 5),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_show_enum() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' show enum E { v }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 4),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_show_eof() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' show
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 0),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_show_export() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' show export 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 6),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_show_final() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' show final a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 5),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_show_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' show int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_show_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' show void f() {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 4),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_show_getter() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' show int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_show_import() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' show import 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 6),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_show_mixin() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' show mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 5),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_show_part() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' show part 'a.dart';
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 4),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_show_setter() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' show set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 3),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_show_typedef() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' show typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 7),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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

  void test_import_directive_show_var() {
    var parseResult = parseStringWithErrors(r'''
import 'a.dart' show var a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 21, 3),
      error(diag.expectedToken, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  directives
    ImportDirective
      importKeyword: import
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
}
