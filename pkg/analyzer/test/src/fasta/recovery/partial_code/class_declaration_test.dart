// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassDeclarationTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ClassDeclarationTest extends ParserDiagnosticsTest {
  void test_class_declaration_equals_class() {
    var parseResult = parseStringWithErrors(r'''
class A = class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 10, 5),
      error(diag.expectedToken, 10, 5),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: <empty> <synthetic>
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
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

  void test_class_declaration_equals_const() {
    var parseResult = parseStringWithErrors(r'''
class A = const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 10, 5),
      error(diag.expectedToken, 10, 5),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: <empty> <synthetic>
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
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

  void test_class_declaration_equals_enum() {
    var parseResult = parseStringWithErrors(r'''
class A = enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 10, 4),
      error(diag.expectedToken, 10, 4),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: <empty> <synthetic>
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
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

  void test_class_declaration_equals_eof() {
    var parseResult = parseStringWithErrors(r'''
class A =
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 10, 0),
      error(diag.expectedToken, 10, 0),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: <empty> <synthetic>
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_class_declaration_equals_final() {
    var parseResult = parseStringWithErrors(r'''
class A = final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 10, 5),
      error(diag.expectedToken, 10, 5),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: <empty> <synthetic>
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
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

  void test_class_declaration_equals_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class A = int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 14, 1),
      error(diag.expectedToken, 14, 1),
      error(diag.expectedExecutable, 15, 1),
      error(diag.expectedExecutable, 16, 1),
      error(diag.expectedExecutable, 18, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: int
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: f
      semicolon: ; <synthetic>
''');
  }

  void test_class_declaration_equals_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
class A = void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 10, 4),
      error(diag.expectedToken, 15, 1),
      error(diag.expectedToken, 15, 1),
      error(diag.expectedExecutable, 16, 1),
      error(diag.expectedExecutable, 17, 1),
      error(diag.expectedExecutable, 19, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: void
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: f
      semicolon: ; <synthetic>
''');
  }

  void test_class_declaration_equals_getter() {
    var parseResult = parseStringWithErrors(r'''
class A = int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 14, 3),
      error(diag.expectedToken, 10, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: int
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: <empty> <synthetic>
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

  void test_class_declaration_equals_mixin() {
    var parseResult = parseStringWithErrors(r'''
class A = mixin M {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 10, 5),
      error(diag.expectedToken, 16, 1),
      error(diag.expectedToken, 16, 1),
      error(diag.expectedExecutable, 18, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: mixin
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: M
      semicolon: ; <synthetic>
''');
  }

  void test_class_declaration_equals_setter() {
    var parseResult = parseStringWithErrors(r'''
class A = set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 10, 3),
      error(diag.expectedToken, 10, 3),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: <empty> <synthetic>
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
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

  void test_class_declaration_equals_typedef() {
    var parseResult = parseStringWithErrors(r'''
class A = typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 10, 7),
      error(diag.expectedToken, 10, 7),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: <empty> <synthetic>
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
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

  void test_class_declaration_equals_var() {
    var parseResult = parseStringWithErrors(r'''
class A = var a;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 10, 3),
      error(diag.expectedToken, 10, 3),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: <empty> <synthetic>
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
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

  void test_class_declaration_equalsName_class() {
    var parseResult = parseStringWithErrors(r'''
class A = B class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 5),
      error(diag.expectedToken, 10, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
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

  void test_class_declaration_equalsName_const() {
    var parseResult = parseStringWithErrors(r'''
class A = B const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 5),
      error(diag.expectedToken, 10, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
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

  void test_class_declaration_equalsName_enum() {
    var parseResult = parseStringWithErrors(r'''
class A = B enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 4),
      error(diag.expectedToken, 10, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
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

  void test_class_declaration_equalsName_eof() {
    var parseResult = parseStringWithErrors(r'''
class A = B
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 0),
      error(diag.expectedToken, 10, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_class_declaration_equalsName_final() {
    var parseResult = parseStringWithErrors(r'''
class A = B final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 5),
      error(diag.expectedToken, 10, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
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

  void test_class_declaration_equalsName_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class A = B int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 3),
      error(diag.expectedToken, 12, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
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

  void test_class_declaration_equalsName_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
class A = B void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 4),
      error(diag.expectedToken, 12, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
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

  void test_class_declaration_equalsName_getter() {
    var parseResult = parseStringWithErrors(r'''
class A = B int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 3),
      error(diag.expectedToken, 12, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
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

  void test_class_declaration_equalsName_mixin() {
    var parseResult = parseStringWithErrors(r'''
class A = B mixin M {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 5),
      error(diag.expectedToken, 10, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_class_declaration_equalsName_setter() {
    var parseResult = parseStringWithErrors(r'''
class A = B set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 3),
      error(diag.expectedToken, 10, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
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

  void test_class_declaration_equalsName_typedef() {
    var parseResult = parseStringWithErrors(r'''
class A = B typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 7),
      error(diag.expectedToken, 10, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
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

  void test_class_declaration_equalsName_var() {
    var parseResult = parseStringWithErrors(r'''
class A = B var a;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 3),
      error(diag.expectedToken, 10, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
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

  void test_class_declaration_equalsNameName_class() {
    var parseResult = parseStringWithErrors(r'''
class A = B C class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.expectedToken, 12, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_equalsNameName_const() {
    var parseResult = parseStringWithErrors(r'''
class A = B C const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.expectedToken, 12, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_equalsNameName_enum() {
    var parseResult = parseStringWithErrors(r'''
class A = B C enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.expectedToken, 12, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: C
      semicolon: ; <synthetic>
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

  void test_class_declaration_equalsNameName_eof() {
    var parseResult = parseStringWithErrors(r'''
class A = B C
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.expectedToken, 12, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: C
      semicolon: ; <synthetic>
''');
  }

  void test_class_declaration_equalsNameName_final() {
    var parseResult = parseStringWithErrors(r'''
class A = B C final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.expectedToken, 12, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_equalsNameName_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class A = B C int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.expectedToken, 12, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: C
      semicolon: ; <synthetic>
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

  void test_class_declaration_equalsNameName_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
class A = B C void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.expectedToken, 12, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_equalsNameName_getter() {
    var parseResult = parseStringWithErrors(r'''
class A = B C int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.expectedToken, 12, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: C
      semicolon: ; <synthetic>
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

  void test_class_declaration_equalsNameName_mixin() {
    var parseResult = parseStringWithErrors(r'''
class A = B C mixin M {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.expectedToken, 12, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: C
      semicolon: ; <synthetic>
    MixinDeclaration
      mixinKeyword: mixin
      name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_class_declaration_equalsNameName_setter() {
    var parseResult = parseStringWithErrors(r'''
class A = B C set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.expectedToken, 12, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_equalsNameName_typedef() {
    var parseResult = parseStringWithErrors(r'''
class A = B C typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.expectedToken, 12, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_equalsNameName_var() {
    var parseResult = parseStringWithErrors(r'''
class A = B C var a;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.expectedToken, 12, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_equalsNameWith_class() {
    var parseResult = parseStringWithErrors(r'''
class A = B with class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 17, 5),
      error(diag.expectedToken, 12, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
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

  void test_class_declaration_equalsNameWith_const() {
    var parseResult = parseStringWithErrors(r'''
class A = B with const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 17, 5),
      error(diag.expectedToken, 12, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
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

  void test_class_declaration_equalsNameWith_enum() {
    var parseResult = parseStringWithErrors(r'''
class A = B with enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 17, 4),
      error(diag.expectedToken, 12, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
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

  void test_class_declaration_equalsNameWith_eof() {
    var parseResult = parseStringWithErrors(r'''
class A = B with
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 17, 0),
      error(diag.expectedToken, 12, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_class_declaration_equalsNameWith_final() {
    var parseResult = parseStringWithErrors(r'''
class A = B with final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 17, 5),
      error(diag.expectedToken, 12, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
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

  void test_class_declaration_equalsNameWith_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class A = B with int f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 17, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
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

  void test_class_declaration_equalsNameWith_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
class A = B with void f() {}
''');
    parseResult.assertErrors([error(diag.expectedToken, 17, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
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

  void test_class_declaration_equalsNameWith_getter() {
    var parseResult = parseStringWithErrors(r'''
class A = B with int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 17, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
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

  void test_class_declaration_equalsNameWith_mixin() {
    var parseResult = parseStringWithErrors(r'''
class A = B with mixin M {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 17, 5),
      error(diag.expectedToken, 17, 5),
      error(diag.missingFunctionParameters, 23, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
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

  void test_class_declaration_equalsNameWith_setter() {
    var parseResult = parseStringWithErrors(r'''
class A = B with set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 17, 3),
      error(diag.expectedToken, 12, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
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

  void test_class_declaration_equalsNameWith_typedef() {
    var parseResult = parseStringWithErrors(r'''
class A = B with typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 17, 7),
      error(diag.expectedToken, 12, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
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

  void test_class_declaration_equalsNameWith_var() {
    var parseResult = parseStringWithErrors(r'''
class A = B with var a;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 17, 3),
      error(diag.expectedToken, 12, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
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

  void test_class_declaration_extend_class() {
    var parseResult = parseStringWithErrors(r'''
class A extend class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 6),
      error(diag.expectedTypeName, 15, 5),
      error(diag.expectedClassBody, 15, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extend
        superclass: NamedType
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

  void test_class_declaration_extend_const() {
    var parseResult = parseStringWithErrors(r'''
class A extend const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 6),
      error(diag.expectedTypeName, 15, 5),
      error(diag.expectedClassBody, 15, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extend
        superclass: NamedType
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

  void test_class_declaration_extend_enum() {
    var parseResult = parseStringWithErrors(r'''
class A extend enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 6),
      error(diag.expectedTypeName, 15, 4),
      error(diag.expectedClassBody, 15, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extend
        superclass: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
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

  void test_class_declaration_extend_eof() {
    var parseResult = parseStringWithErrors(r'''
class A extend
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 6),
      error(diag.expectedTypeName, 15, 0),
      error(diag.expectedClassBody, 15, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extend
        superclass: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_class_declaration_extend_final() {
    var parseResult = parseStringWithErrors(r'''
class A extend final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 6),
      error(diag.expectedTypeName, 15, 5),
      error(diag.expectedClassBody, 15, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extend
        superclass: NamedType
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

  void test_class_declaration_extend_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class A extend int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 6),
      error(diag.expectedClassBody, 15, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extend
        superclass: NamedType
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

  void test_class_declaration_extend_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
class A extend void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 6),
      error(diag.expectedTypeName, 15, 4),
      error(diag.expectedClassBody, 15, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extend
        superclass: NamedType
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

  void test_class_declaration_extend_getter() {
    var parseResult = parseStringWithErrors(r'''
class A extend int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 6),
      error(diag.expectedClassBody, 15, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extend
        superclass: NamedType
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

  void test_class_declaration_extend_mixin() {
    var parseResult = parseStringWithErrors(r'''
class A extend mixin M {}
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
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extend
        superclass: NamedType
          name: mixin
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_class_declaration_extend_setter() {
    var parseResult = parseStringWithErrors(r'''
class A extend set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 6),
      error(diag.expectedTypeName, 15, 3),
      error(diag.expectedClassBody, 15, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extend
        superclass: NamedType
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
          parameter: SimpleFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_extend_typedef() {
    var parseResult = parseStringWithErrors(r'''
class A extend typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 6),
      error(diag.expectedTypeName, 15, 7),
      error(diag.expectedClassBody, 15, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extend
        superclass: NamedType
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

  void test_class_declaration_extend_var() {
    var parseResult = parseStringWithErrors(r'''
class A extend var a;
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 6),
      error(diag.expectedTypeName, 15, 3),
      error(diag.expectedClassBody, 15, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extend
        superclass: NamedType
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

  void test_class_declaration_extends_class() {
    var parseResult = parseStringWithErrors(r'''
class A extends class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 16, 5),
      error(diag.expectedClassBody, 16, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extends_const() {
    var parseResult = parseStringWithErrors(r'''
class A extends const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 16, 5),
      error(diag.expectedClassBody, 16, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extends_enum() {
    var parseResult = parseStringWithErrors(r'''
class A extends enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 16, 4),
      error(diag.expectedClassBody, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
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

  void test_class_declaration_extends_eof() {
    var parseResult = parseStringWithErrors(r'''
class A extends
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 16, 0),
      error(diag.expectedClassBody, 16, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_class_declaration_extends_final() {
    var parseResult = parseStringWithErrors(r'''
class A extends final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 16, 5),
      error(diag.expectedClassBody, 16, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extends_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class A extends int f() {}
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 16, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extends_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
class A extends void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 16, 4),
      error(diag.expectedClassBody, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extends_getter() {
    var parseResult = parseStringWithErrors(r'''
class A extends int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 16, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extends_mixin() {
    var parseResult = parseStringWithErrors(r'''
class A extends mixin M {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 16, 5),
      error(diag.unexpectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: mixin
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_class_declaration_extends_setter() {
    var parseResult = parseStringWithErrors(r'''
class A extends set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 16, 3),
      error(diag.expectedClassBody, 16, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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
          parameter: SimpleFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_extends_typedef() {
    var parseResult = parseStringWithErrors(r'''
class A extends typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 16, 7),
      error(diag.expectedClassBody, 16, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extends_var() {
    var parseResult = parseStringWithErrors(r'''
class A extends var a;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 16, 3),
      error(diag.expectedClassBody, 16, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsBody_class() {
    var parseResult = parseStringWithErrors(r'''
class A extends {} class A {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsBody_const() {
    var parseResult = parseStringWithErrors(r'''
class A extends {} const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsBody_enum() {
    var parseResult = parseStringWithErrors(r'''
class A extends {} enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
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

  void test_class_declaration_extendsBody_eof() {
    var parseResult = parseStringWithErrors(r'''
class A extends {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_class_declaration_extendsBody_final() {
    var parseResult = parseStringWithErrors(r'''
class A extends {} final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsBody_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class A extends {} int f() {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsBody_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
class A extends {} void f() {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsBody_getter() {
    var parseResult = parseStringWithErrors(r'''
class A extends {} int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsBody_mixin() {
    var parseResult = parseStringWithErrors(r'''
class A extends {} mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsBody_setter() {
    var parseResult = parseStringWithErrors(r'''
class A extends {} set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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
          parameter: SimpleFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_extendsBody_typedef() {
    var parseResult = parseStringWithErrors(r'''
class A extends {} typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsBody_var() {
    var parseResult = parseStringWithErrors(r'''
class A extends {} var a;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsImplementsNameBody_class() {
    var parseResult = parseStringWithErrors(r'''
class A extends implements B {} class A {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 16, 10),
      error(diag.unexpectedToken, 27, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsImplementsNameBody_const() {
    var parseResult = parseStringWithErrors(r'''
class A extends implements B {} const a = 0;
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 16, 10),
      error(diag.unexpectedToken, 27, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsImplementsNameBody_enum() {
    var parseResult = parseStringWithErrors(r'''
class A extends implements B {} enum E { v }
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 16, 10),
      error(diag.unexpectedToken, 27, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: implements
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
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

  void test_class_declaration_extendsImplementsNameBody_eof() {
    var parseResult = parseStringWithErrors(r'''
class A extends implements B {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 16, 10),
      error(diag.unexpectedToken, 27, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: implements
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_class_declaration_extendsImplementsNameBody_final() {
    var parseResult = parseStringWithErrors(r'''
class A extends implements B {} final a = 0;
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 16, 10),
      error(diag.unexpectedToken, 27, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsImplementsNameBody_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class A extends implements B {} int f() {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 16, 10),
      error(diag.unexpectedToken, 27, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsImplementsNameBody_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
class A extends implements B {} void f() {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 16, 10),
      error(diag.unexpectedToken, 27, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsImplementsNameBody_getter() {
    var parseResult = parseStringWithErrors(r'''
class A extends implements B {} int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 16, 10),
      error(diag.unexpectedToken, 27, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsImplementsNameBody_mixin() {
    var parseResult = parseStringWithErrors(r'''
class A extends implements B {} mixin M {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 16, 10),
      error(diag.unexpectedToken, 27, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsImplementsNameBody_setter() {
    var parseResult = parseStringWithErrors(r'''
class A extends implements B {} set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 16, 10),
      error(diag.unexpectedToken, 27, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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
          parameter: SimpleFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_extendsImplementsNameBody_typedef() {
    var parseResult = parseStringWithErrors(r'''
class A extends implements B {} typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 16, 10),
      error(diag.unexpectedToken, 27, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsImplementsNameBody_var() {
    var parseResult = parseStringWithErrors(r'''
class A extends implements B {} var a;
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 16, 10),
      error(diag.unexpectedToken, 27, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsNameImplements_class() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 29, 5),
      error(diag.expectedClassBody, 29, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsNameImplements_const() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 29, 5),
      error(diag.expectedClassBody, 29, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsNameImplements_enum() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 29, 4),
      error(diag.expectedClassBody, 29, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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
      body: EnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_extendsNameImplements_eof() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 29, 0),
      error(diag.expectedClassBody, 29, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsNameImplements_final() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 29, 5),
      error(diag.expectedClassBody, 29, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsNameImplements_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements int f() {}
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 29, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsNameImplements_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 29, 4),
      error(diag.expectedClassBody, 29, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsNameImplements_getter() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 29, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsNameImplements_mixin() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements mixin M {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 29, 5),
      error(diag.unexpectedToken, 35, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsNameImplements_setter() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 29, 3),
      error(diag.expectedClassBody, 29, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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
          parameter: SimpleFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_extendsNameImplements_typedef() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 29, 7),
      error(diag.expectedClassBody, 29, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsNameImplements_var() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements var a;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 29, 3),
      error(diag.expectedClassBody, 29, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsNameImplementsBody_class() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements {} class A {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsNameImplementsBody_const() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements {} const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsNameImplementsBody_enum() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements {} enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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
      body: EnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_extendsNameImplementsBody_eof() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsNameImplementsBody_final() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements {} final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsNameImplementsBody_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements {} int f() {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsNameImplementsBody_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements {} void f() {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsNameImplementsBody_getter() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements {} int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsNameImplementsBody_mixin() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements {} mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsNameImplementsBody_setter() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements {} set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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
          parameter: SimpleFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_extendsNameImplementsBody_typedef() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements {} typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsNameImplementsBody_var() {
    var parseResult = parseStringWithErrors(r'''
class A extends B implements {} var a;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
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

  void test_class_declaration_extendsNameWith_class() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 23, 5),
      error(diag.expectedClassBody, 23, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
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

  void test_class_declaration_extendsNameWith_const() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 23, 5),
      error(diag.expectedClassBody, 23, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
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

  void test_class_declaration_extendsNameWith_enum() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 23, 4),
      error(diag.expectedClassBody, 23, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
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

  void test_class_declaration_extendsNameWith_eof() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 23, 0),
      error(diag.expectedClassBody, 23, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_class_declaration_extendsNameWith_final() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 23, 5),
      error(diag.expectedClassBody, 23, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
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

  void test_class_declaration_extendsNameWith_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with int f() {}
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 23, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
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

  void test_class_declaration_extendsNameWith_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with void f() {}
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 23, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
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

  void test_class_declaration_extendsNameWith_getter() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 23, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
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

  void test_class_declaration_extendsNameWith_mixin() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with mixin M {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 23, 5),
      error(diag.unexpectedToken, 29, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: mixin
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_class_declaration_extendsNameWith_setter() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 23, 3),
      error(diag.expectedClassBody, 23, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
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
          parameter: SimpleFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_extendsNameWith_typedef() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 23, 7),
      error(diag.expectedClassBody, 23, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
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

  void test_class_declaration_extendsNameWith_var() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with var a;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 23, 3),
      error(diag.expectedClassBody, 23, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
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

  void test_class_declaration_extendsNameWithBody_class() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with {} class A {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 23, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
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

  void test_class_declaration_extendsNameWithBody_const() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with {} const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 23, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
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

  void test_class_declaration_extendsNameWithBody_enum() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with {} enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 23, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
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

  void test_class_declaration_extendsNameWithBody_eof() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 23, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_class_declaration_extendsNameWithBody_final() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with {} final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 23, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
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

  void test_class_declaration_extendsNameWithBody_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with {} int f() {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 23, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
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

  void test_class_declaration_extendsNameWithBody_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with {} void f() {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 23, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
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

  void test_class_declaration_extendsNameWithBody_getter() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with {} int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 23, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
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

  void test_class_declaration_extendsNameWithBody_mixin() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with {} mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 23, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
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

  void test_class_declaration_extendsNameWithBody_setter() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with {} set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 23, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
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
          parameter: SimpleFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_extendsNameWithBody_typedef() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with {} typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 23, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
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

  void test_class_declaration_extendsNameWithBody_var() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with {} var a;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 23, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
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

  void test_class_declaration_extendsNameWithNameImplements_class() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C implements class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 36, 5),
      error(diag.expectedClassBody, 36, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_extendsNameWithNameImplements_const() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C implements const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 36, 5),
      error(diag.expectedClassBody, 36, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_extendsNameWithNameImplements_enum() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C implements enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 36, 4),
      error(diag.expectedClassBody, 36, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
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
      body: EnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_extendsNameWithNameImplements_eof() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C implements
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 36, 0),
      error(diag.expectedClassBody, 36, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_extendsNameWithNameImplements_final() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C implements final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 36, 5),
      error(diag.expectedClassBody, 36, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_extendsNameWithNameImplements_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C implements int f() {}
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 36, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_extendsNameWithNameImplements_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C implements void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 36, 4),
      error(diag.expectedClassBody, 36, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_extendsNameWithNameImplements_getter() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C implements int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 36, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_extendsNameWithNameImplements_mixin() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C implements mixin M {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 36, 5),
      error(diag.unexpectedToken, 42, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_extendsNameWithNameImplements_setter() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C implements set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 36, 3),
      error(diag.expectedClassBody, 36, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
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
          parameter: SimpleFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_extendsNameWithNameImplements_typedef() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C implements typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 36, 7),
      error(diag.expectedClassBody, 36, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_extendsNameWithNameImplements_var() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C implements var a;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 36, 3),
      error(diag.expectedClassBody, 36, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_extendsNameWithNameImplementsBody_class() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C implements {} class A {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 36, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_extendsNameWithNameImplementsBody_const() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C implements {} const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 36, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_extendsNameWithNameImplementsBody_enum() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C implements {} enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 36, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
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
      body: EnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_extendsNameWithNameImplementsBody_eof() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C implements {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 36, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_extendsNameWithNameImplementsBody_final() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C implements {} final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 36, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
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

  void
  test_class_declaration_extendsNameWithNameImplementsBody_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C implements {} int f() {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 36, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_extendsNameWithNameImplementsBody_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C implements {} void f() {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 36, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_extendsNameWithNameImplementsBody_getter() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C implements {} int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 36, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_extendsNameWithNameImplementsBody_mixin() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C implements {} mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 36, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_extendsNameWithNameImplementsBody_setter() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C implements {} set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 36, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
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
          parameter: SimpleFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_extendsNameWithNameImplementsBody_typedef() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C implements {} typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 36, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_extendsNameWithNameImplementsBody_var() {
    var parseResult = parseStringWithErrors(r'''
class A extends B with C implements {} var a;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 36, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: C
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

  void test_class_declaration_extendsWithNameBody_class() {
    var parseResult = parseStringWithErrors(r'''
class A extends with B {} class A {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: <empty> <synthetic>
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: B
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

  void test_class_declaration_extendsWithNameBody_const() {
    var parseResult = parseStringWithErrors(r'''
class A extends with B {} const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: <empty> <synthetic>
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: B
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

  void test_class_declaration_extendsWithNameBody_enum() {
    var parseResult = parseStringWithErrors(r'''
class A extends with B {} enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: <empty> <synthetic>
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: B
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
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

  void test_class_declaration_extendsWithNameBody_eof() {
    var parseResult = parseStringWithErrors(r'''
class A extends with B {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: <empty> <synthetic>
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: B
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_class_declaration_extendsWithNameBody_final() {
    var parseResult = parseStringWithErrors(r'''
class A extends with B {} final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: <empty> <synthetic>
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: B
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

  void test_class_declaration_extendsWithNameBody_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class A extends with B {} int f() {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: <empty> <synthetic>
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: B
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

  void test_class_declaration_extendsWithNameBody_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
class A extends with B {} void f() {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: <empty> <synthetic>
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: B
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

  void test_class_declaration_extendsWithNameBody_getter() {
    var parseResult = parseStringWithErrors(r'''
class A extends with B {} int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: <empty> <synthetic>
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: B
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

  void test_class_declaration_extendsWithNameBody_mixin() {
    var parseResult = parseStringWithErrors(r'''
class A extends with B {} mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: <empty> <synthetic>
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: B
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

  void test_class_declaration_extendsWithNameBody_setter() {
    var parseResult = parseStringWithErrors(r'''
class A extends with B {} set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: <empty> <synthetic>
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: B
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
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

  void test_class_declaration_extendsWithNameBody_typedef() {
    var parseResult = parseStringWithErrors(r'''
class A extends with B {} typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: <empty> <synthetic>
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: B
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

  void test_class_declaration_extendsWithNameBody_var() {
    var parseResult = parseStringWithErrors(r'''
class A extends with B {} var a;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: extends
        superclass: NamedType
          name: <empty> <synthetic>
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: B
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

  void test_class_declaration_implements_class() {
    var parseResult = parseStringWithErrors(r'''
class A implements class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 19, 5),
      error(diag.expectedClassBody, 19, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implements_const() {
    var parseResult = parseStringWithErrors(r'''
class A implements const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 19, 5),
      error(diag.expectedClassBody, 19, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implements_enum() {
    var parseResult = parseStringWithErrors(r'''
class A implements enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 19, 4),
      error(diag.expectedClassBody, 19, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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
      body: EnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_implements_eof() {
    var parseResult = parseStringWithErrors(r'''
class A implements
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 19, 0),
      error(diag.expectedClassBody, 19, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implements_final() {
    var parseResult = parseStringWithErrors(r'''
class A implements final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 19, 5),
      error(diag.expectedClassBody, 19, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implements_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class A implements int f() {}
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 19, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implements_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
class A implements void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 19, 4),
      error(diag.expectedClassBody, 19, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implements_getter() {
    var parseResult = parseStringWithErrors(r'''
class A implements int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 19, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implements_mixin() {
    var parseResult = parseStringWithErrors(r'''
class A implements mixin M {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 19, 5),
      error(diag.unexpectedToken, 25, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implements_setter() {
    var parseResult = parseStringWithErrors(r'''
class A implements set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 19, 3),
      error(diag.expectedClassBody, 19, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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
          parameter: SimpleFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_implements_typedef() {
    var parseResult = parseStringWithErrors(r'''
class A implements typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 19, 7),
      error(diag.expectedClassBody, 19, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implements_var() {
    var parseResult = parseStringWithErrors(r'''
class A implements var a;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 19, 3),
      error(diag.expectedClassBody, 19, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsBody_class() {
    var parseResult = parseStringWithErrors(r'''
class A implements {} class A {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsBody_const() {
    var parseResult = parseStringWithErrors(r'''
class A implements {} const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsBody_enum() {
    var parseResult = parseStringWithErrors(r'''
class A implements {} enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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
      body: EnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_implementsBody_eof() {
    var parseResult = parseStringWithErrors(r'''
class A implements {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsBody_final() {
    var parseResult = parseStringWithErrors(r'''
class A implements {} final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsBody_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class A implements {} int f() {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsBody_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
class A implements {} void f() {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsBody_getter() {
    var parseResult = parseStringWithErrors(r'''
class A implements {} int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsBody_mixin() {
    var parseResult = parseStringWithErrors(r'''
class A implements {} mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsBody_setter() {
    var parseResult = parseStringWithErrors(r'''
class A implements {} set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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
          parameter: SimpleFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_implementsBody_typedef() {
    var parseResult = parseStringWithErrors(r'''
class A implements {} typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsBody_var() {
    var parseResult = parseStringWithErrors(r'''
class A implements {} var a;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsNameComma_class() {
    var parseResult = parseStringWithErrors(r'''
class A implements B, class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 22, 5),
      error(diag.expectedClassBody, 22, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsNameComma_const() {
    var parseResult = parseStringWithErrors(r'''
class A implements B, const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 22, 5),
      error(diag.expectedClassBody, 22, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsNameComma_enum() {
    var parseResult = parseStringWithErrors(r'''
class A implements B, enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 22, 4),
      error(diag.expectedClassBody, 22, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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
      body: EnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_implementsNameComma_eof() {
    var parseResult = parseStringWithErrors(r'''
class A implements B,
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 22, 0),
      error(diag.expectedClassBody, 22, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsNameComma_final() {
    var parseResult = parseStringWithErrors(r'''
class A implements B, final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 22, 5),
      error(diag.expectedClassBody, 22, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsNameComma_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class A implements B, int f() {}
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 22, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsNameComma_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
class A implements B, void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 22, 4),
      error(diag.expectedClassBody, 22, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsNameComma_getter() {
    var parseResult = parseStringWithErrors(r'''
class A implements B, int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 22, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsNameComma_mixin() {
    var parseResult = parseStringWithErrors(r'''
class A implements B, mixin M {}
''');
    parseResult.assertErrors([
      error(diag.builtInIdentifierAsType, 22, 5),
      error(diag.unexpectedToken, 28, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsNameComma_setter() {
    var parseResult = parseStringWithErrors(r'''
class A implements B, set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 22, 3),
      error(diag.expectedClassBody, 22, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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
          parameter: SimpleFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_implementsNameComma_typedef() {
    var parseResult = parseStringWithErrors(r'''
class A implements B, typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 22, 7),
      error(diag.expectedClassBody, 22, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsNameComma_var() {
    var parseResult = parseStringWithErrors(r'''
class A implements B, var a;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 22, 3),
      error(diag.expectedClassBody, 22, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsNameCommaBody_class() {
    var parseResult = parseStringWithErrors(r'''
class A implements B, {} class A {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsNameCommaBody_const() {
    var parseResult = parseStringWithErrors(r'''
class A implements B, {} const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsNameCommaBody_enum() {
    var parseResult = parseStringWithErrors(r'''
class A implements B, {} enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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
      body: EnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_implementsNameCommaBody_eof() {
    var parseResult = parseStringWithErrors(r'''
class A implements B, {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsNameCommaBody_final() {
    var parseResult = parseStringWithErrors(r'''
class A implements B, {} final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsNameCommaBody_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class A implements B, {} int f() {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsNameCommaBody_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
class A implements B, {} void f() {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsNameCommaBody_getter() {
    var parseResult = parseStringWithErrors(r'''
class A implements B, {} int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsNameCommaBody_mixin() {
    var parseResult = parseStringWithErrors(r'''
class A implements B, {} mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsNameCommaBody_setter() {
    var parseResult = parseStringWithErrors(r'''
class A implements B, {} set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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
          parameter: SimpleFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_implementsNameCommaBody_typedef() {
    var parseResult = parseStringWithErrors(r'''
class A implements B, {} typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_implementsNameCommaBody_var() {
    var parseResult = parseStringWithErrors(r'''
class A implements B, {} var a;
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_keyword_class() {
    var parseResult = parseStringWithErrors(r'''
class class A {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 5),
      error(diag.expectedClassBody, 6, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
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

  void test_class_declaration_keyword_const() {
    var parseResult = parseStringWithErrors(r'''
class const a = 0;
''');
    parseResult.assertErrors([
      error(diag.constWithoutPrimaryConstructor, 6, 5),
      error(diag.expectedTypeName, 16, 1),
      error(diag.expectedToken, 16, 1),
      error(diag.expectedToken, 14, 1),
      error(diag.expectedExecutable, 16, 1),
      error(diag.unexpectedToken, 17, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: a
      equals: =
      superclass: NamedType
        name: <empty> <synthetic>
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_class_declaration_keyword_enum() {
    var parseResult = parseStringWithErrors(r'''
class enum E { v }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 4),
      error(diag.expectedClassBody, 6, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
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

  void test_class_declaration_keyword_eof() {
    var parseResult = parseStringWithErrors(r'''
class
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 0),
      error(diag.expectedClassBody, 6, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_class_declaration_keyword_final() {
    var parseResult = parseStringWithErrors(r'''
class final a = 0;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 5),
      error(diag.expectedClassBody, 6, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
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

  void test_class_declaration_keyword_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class int f() {}
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: int
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

  void test_class_declaration_keyword_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
class void f() {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 4),
      error(diag.expectedClassBody, 6, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
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

  void test_class_declaration_keyword_getter() {
    var parseResult = parseStringWithErrors(r'''
class int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: int
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

  void test_class_declaration_keyword_mixin() {
    var parseResult = parseStringWithErrors(r'''
class mixin M {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 5),
      error(diag.expectedClassBody, 6, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
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

  void test_class_declaration_keyword_setter() {
    var parseResult = parseStringWithErrors(r'''
class set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 3),
      error(diag.expectedClassBody, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
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

  void test_class_declaration_keyword_typedef() {
    var parseResult = parseStringWithErrors(r'''
class typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 7),
      error(diag.expectedClassBody, 6, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
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

  void test_class_declaration_keyword_var() {
    var parseResult = parseStringWithErrors(r'''
class var a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 6, 3),
      error(diag.expectedClassBody, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: <empty> <synthetic>
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

  void test_class_declaration_named_class() {
    var parseResult = parseStringWithErrors(r'''
class A class A {}
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_named_const() {
    var parseResult = parseStringWithErrors(r'''
class A const a = 0;
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_named_enum() {
    var parseResult = parseStringWithErrors(r'''
class A enum E { v }
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
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

  void test_class_declaration_named_eof() {
    var parseResult = parseStringWithErrors(r'''
class A
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_class_declaration_named_final() {
    var parseResult = parseStringWithErrors(r'''
class A final a = 0;
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_named_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class A int f() {}
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_named_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
class A void f() {}
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_named_getter() {
    var parseResult = parseStringWithErrors(r'''
class A int get a => 0;
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_named_mixin() {
    var parseResult = parseStringWithErrors(r'''
class A mixin M {}
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_named_setter() {
    var parseResult = parseStringWithErrors(r'''
class A set a(b) {}
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
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

  void test_class_declaration_named_typedef() {
    var parseResult = parseStringWithErrors(r'''
class A typedef A = B Function(C, D);
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_named_var() {
    var parseResult = parseStringWithErrors(r'''
class A var a;
''');
    parseResult.assertErrors([error(diag.expectedClassBody, 6, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
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

  void test_class_declaration_on_class() {
    var parseResult = parseStringWithErrors(r'''
class A on class A {}
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 2),
      error(diag.expectedTypeName, 11, 5),
      error(diag.expectedClassBody, 11, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: on
        superclass: NamedType
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

  void test_class_declaration_on_const() {
    var parseResult = parseStringWithErrors(r'''
class A on const a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 2),
      error(diag.expectedTypeName, 11, 5),
      error(diag.expectedClassBody, 11, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: on
        superclass: NamedType
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

  void test_class_declaration_on_enum() {
    var parseResult = parseStringWithErrors(r'''
class A on enum E { v }
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 2),
      error(diag.expectedTypeName, 11, 4),
      error(diag.expectedClassBody, 11, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: on
        superclass: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
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

  void test_class_declaration_on_eof() {
    var parseResult = parseStringWithErrors(r'''
class A on
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 2),
      error(diag.expectedTypeName, 11, 0),
      error(diag.expectedClassBody, 11, 0),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: on
        superclass: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_class_declaration_on_final() {
    var parseResult = parseStringWithErrors(r'''
class A on final a = 0;
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 2),
      error(diag.expectedTypeName, 11, 5),
      error(diag.expectedClassBody, 11, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: on
        superclass: NamedType
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

  void test_class_declaration_on_functionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
class A on int f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 2),
      error(diag.expectedClassBody, 11, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: on
        superclass: NamedType
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

  void test_class_declaration_on_functionVoid() {
    var parseResult = parseStringWithErrors(r'''
class A on void f() {}
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 2),
      error(diag.expectedTypeName, 11, 4),
      error(diag.expectedClassBody, 11, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: on
        superclass: NamedType
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

  void test_class_declaration_on_getter() {
    var parseResult = parseStringWithErrors(r'''
class A on int get a => 0;
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 2),
      error(diag.expectedClassBody, 11, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: on
        superclass: NamedType
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

  void test_class_declaration_on_mixin() {
    var parseResult = parseStringWithErrors(r'''
class A on mixin M {}
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 2),
      error(diag.builtInIdentifierAsType, 11, 5),
      error(diag.unexpectedToken, 17, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: on
        superclass: NamedType
          name: mixin
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_class_declaration_on_setter() {
    var parseResult = parseStringWithErrors(r'''
class A on set a(b) {}
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 2),
      error(diag.expectedTypeName, 11, 3),
      error(diag.expectedClassBody, 11, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: on
        superclass: NamedType
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
          parameter: SimpleFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_on_typedef() {
    var parseResult = parseStringWithErrors(r'''
class A on typedef A = B Function(C, D);
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 2),
      error(diag.expectedTypeName, 11, 7),
      error(diag.expectedClassBody, 11, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: on
        superclass: NamedType
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

  void test_class_declaration_on_var() {
    var parseResult = parseStringWithErrors(r'''
class A on var a;
''');
    parseResult.assertErrors([
      error(diag.expectedInstead, 8, 2),
      error(diag.expectedTypeName, 11, 3),
      error(diag.expectedClassBody, 11, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      extendsClause: ExtendsClause
        extendsKeyword: on
        superclass: NamedType
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
}
