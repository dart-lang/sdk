// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = class A {}
//      ^
// [diag.expectedToken] Expected to find ';'.
//        ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedToken] Expected to find 'with'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = const a = 0;
//      ^
// [diag.expectedToken] Expected to find ';'.
//        ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedToken] Expected to find 'with'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = enum E { v }
//      ^
// [diag.expectedToken] Expected to find ';'.
//        ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedToken] Expected to find 'with'.
''');
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
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_equals_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A =
//      ^
// [diag.expectedToken] Expected to find ';'.
//       ^
// [diag.expectedTypeName][column 10][length 0] Expected a type name.
// [diag.expectedToken][column 10][length 0] Expected to find 'with'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = final a = 0;
//      ^
// [diag.expectedToken] Expected to find ';'.
//        ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedToken] Expected to find 'with'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = int f() {}
//            ^
// [diag.expectedToken] Expected to find 'with'.
// [diag.expectedToken] Expected to find ';'.
//             ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//              ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//                ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = void f() {}
//        ^^^^
// [diag.expectedTypeName] Expected a type name.
//             ^
// [diag.expectedToken] Expected to find 'with'.
// [diag.expectedToken] Expected to find ';'.
//              ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//               ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//                 ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = int get a => 0;
//        ^^^
// [diag.expectedToken] Expected to find ';'.
//            ^^^
// [diag.expectedToken] Expected to find 'with'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = mixin M {}
//        ^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'mixin' can't be used as a type.
//              ^
// [diag.expectedToken] Expected to find 'with'.
// [diag.expectedToken] Expected to find ';'.
//                ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = set a(b) {}
//      ^
// [diag.expectedToken] Expected to find ';'.
//        ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedToken] Expected to find 'with'.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_equals_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = typedef A = B Function(C, D);
//      ^
// [diag.expectedToken] Expected to find ';'.
//        ^^^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedToken] Expected to find 'with'.
''');
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

  void test_class_declaration_equals_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = var a;
//      ^
// [diag.expectedToken] Expected to find ';'.
//        ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedToken] Expected to find 'with'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B class A {}
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^^^
// [diag.expectedToken] Expected to find 'with'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B const a = 0;
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^^^
// [diag.expectedToken] Expected to find 'with'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B enum E { v }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^^
// [diag.expectedToken] Expected to find 'with'.
''');
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
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_equalsName_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B
//        ^
// [diag.expectedToken] Expected to find ';'.
//         ^
// [diag.expectedToken][column 12][length 0] Expected to find 'with'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B final a = 0;
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^^^
// [diag.expectedToken] Expected to find 'with'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B int f() {}
//          ^^^
// [diag.expectedToken] Expected to find 'with'.
// [diag.expectedToken] Expected to find ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B void f() {}
//          ^^^^
// [diag.expectedToken] Expected to find 'with'.
// [diag.expectedToken] Expected to find ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B int get a => 0;
//          ^^^
// [diag.expectedToken] Expected to find 'with'.
// [diag.expectedToken] Expected to find ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B mixin M {}
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^^^
// [diag.expectedToken] Expected to find 'with'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B set a(b) {}
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^
// [diag.expectedToken] Expected to find 'with'.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_equalsName_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B typedef A = B Function(C, D);
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^^^^^
// [diag.expectedToken] Expected to find 'with'.
''');
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

  void test_class_declaration_equalsName_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B var a;
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^
// [diag.expectedToken] Expected to find 'with'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B C class A {}
//          ^
// [diag.expectedToken] Expected to find 'with'.
// [diag.expectedToken] Expected to find ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B C const a = 0;
//          ^
// [diag.expectedToken] Expected to find 'with'.
// [diag.expectedToken] Expected to find ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B C enum E { v }
//          ^
// [diag.expectedToken] Expected to find 'with'.
// [diag.expectedToken] Expected to find ';'.
''');
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
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_equalsNameName_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B C
//          ^
// [diag.expectedToken] Expected to find 'with'.
// [diag.expectedToken] Expected to find ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B C final a = 0;
//          ^
// [diag.expectedToken] Expected to find 'with'.
// [diag.expectedToken] Expected to find ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B C int f() {}
//          ^
// [diag.expectedToken] Expected to find 'with'.
// [diag.expectedToken] Expected to find ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B C void f() {}
//          ^
// [diag.expectedToken] Expected to find 'with'.
// [diag.expectedToken] Expected to find ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B C int get a => 0;
//          ^
// [diag.expectedToken] Expected to find 'with'.
// [diag.expectedToken] Expected to find ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B C mixin M {}
//          ^
// [diag.expectedToken] Expected to find 'with'.
// [diag.expectedToken] Expected to find ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B C set a(b) {}
//          ^
// [diag.expectedToken] Expected to find 'with'.
// [diag.expectedToken] Expected to find ';'.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_equalsNameName_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B C typedef A = B Function(C, D);
//          ^
// [diag.expectedToken] Expected to find 'with'.
// [diag.expectedToken] Expected to find ';'.
''');
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

  void test_class_declaration_equalsNameName_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B C var a;
//          ^
// [diag.expectedToken] Expected to find 'with'.
// [diag.expectedToken] Expected to find ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B with class A {}
//          ^^^^
// [diag.expectedToken] Expected to find ';'.
//               ^^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B with const a = 0;
//          ^^^^
// [diag.expectedToken] Expected to find ';'.
//               ^^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B with enum E { v }
//          ^^^^
// [diag.expectedToken] Expected to find ';'.
//               ^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_equalsNameWith_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B with
//          ^^^^
// [diag.expectedToken] Expected to find ';'.
//              ^
// [diag.expectedTypeName][column 17][length 0] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B with final a = 0;
//          ^^^^
// [diag.expectedToken] Expected to find ';'.
//               ^^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B with int f() {}
//               ^^^
// [diag.expectedToken] Expected to find ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B with void f() {}
//               ^^^^
// [diag.expectedToken] Expected to find ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B with int get a => 0;
//               ^^^
// [diag.expectedToken] Expected to find ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B with mixin M {}
//               ^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'mixin' can't be used as a type.
// [diag.expectedToken] Expected to find ';'.
//                     ^
// [diag.missingFunctionParameters] Functions must have an explicit list of parameters.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B with set a(b) {}
//          ^^^^
// [diag.expectedToken] Expected to find ';'.
//               ^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_equalsNameWith_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B with typedef A = B Function(C, D);
//          ^^^^
// [diag.expectedToken] Expected to find ';'.
//               ^^^^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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

  void test_class_declaration_equalsNameWith_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A = B with var a;
//          ^^^^
// [diag.expectedToken] Expected to find ';'.
//               ^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extend class A {}
//      ^^^^^^
// [diag.expectedInstead] Expected 'extends' instead of this.
//             ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extend const a = 0;
//      ^^^^^^
// [diag.expectedInstead] Expected 'extends' instead of this.
//             ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extend enum E { v }
//      ^^^^^^
// [diag.expectedInstead] Expected 'extends' instead of this.
//             ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_extend_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extend
//      ^^^^^^
// [diag.expectedInstead] Expected 'extends' instead of this.
//            ^
// [diag.expectedTypeName][column 15][length 0] Expected a type name.
// [diag.expectedClassBody][column 15][length 0] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extend final a = 0;
//      ^^^^^^
// [diag.expectedInstead] Expected 'extends' instead of this.
//             ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extend int f() {}
//      ^^^^^^
// [diag.expectedInstead] Expected 'extends' instead of this.
//             ^^^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extend void f() {}
//      ^^^^^^
// [diag.expectedInstead] Expected 'extends' instead of this.
//             ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extend int get a => 0;
//      ^^^^^^
// [diag.expectedInstead] Expected 'extends' instead of this.
//             ^^^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extend mixin M {}
//      ^^^^^^
// [diag.expectedInstead] Expected 'extends' instead of this.
//             ^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'mixin' can't be used as a type.
//                   ^
// [diag.unexpectedToken] Unexpected text 'M'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extend set a(b) {}
//      ^^^^^^
// [diag.expectedInstead] Expected 'extends' instead of this.
//             ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_extend_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extend typedef A = B Function(C, D);
//      ^^^^^^
// [diag.expectedInstead] Expected 'extends' instead of this.
//             ^^^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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

  void test_class_declaration_extend_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extend var a;
//      ^^^^^^
// [diag.expectedInstead] Expected 'extends' instead of this.
//             ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends class A {}
//              ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends const a = 0;
//              ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends enum E { v }
//              ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_extends_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends
//             ^
// [diag.expectedTypeName][column 16][length 0] Expected a type name.
// [diag.expectedClassBody][column 16][length 0] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends final a = 0;
//              ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends int f() {}
//              ^^^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends void f() {}
//              ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends int get a => 0;
//              ^^^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends mixin M {}
//              ^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'mixin' can't be used as a type.
//                    ^
// [diag.unexpectedToken] Unexpected text 'M'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends set a(b) {}
//              ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_extends_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends typedef A = B Function(C, D);
//              ^^^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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

  void test_class_declaration_extends_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends var a;
//              ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends {} class A {}
//              ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends {} const a = 0;
//              ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends {} enum E { v }
//              ^
// [diag.expectedTypeName] Expected a type name.
''');
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
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_extendsBody_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends {}
//              ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends {} final a = 0;
//              ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends {} int f() {}
//              ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends {} void f() {}
//              ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends {} int get a => 0;
//              ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends {} mixin M {}
//              ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends {} set a(b) {}
//              ^
// [diag.expectedTypeName] Expected a type name.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_extendsBody_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends {} typedef A = B Function(C, D);
//              ^
// [diag.expectedTypeName] Expected a type name.
''');
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

  void test_class_declaration_extendsBody_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends {} var a;
//              ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends implements B {} class A {}
//              ^^^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'implements' can't be used as a type.
//                         ^
// [diag.unexpectedToken] Unexpected text 'B'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends implements B {} const a = 0;
//              ^^^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'implements' can't be used as a type.
//                         ^
// [diag.unexpectedToken] Unexpected text 'B'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends implements B {} enum E { v }
//              ^^^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'implements' can't be used as a type.
//                         ^
// [diag.unexpectedToken] Unexpected text 'B'.
''');
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
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_extendsImplementsNameBody_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends implements B {}
//              ^^^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'implements' can't be used as a type.
//                         ^
// [diag.unexpectedToken] Unexpected text 'B'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends implements B {} final a = 0;
//              ^^^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'implements' can't be used as a type.
//                         ^
// [diag.unexpectedToken] Unexpected text 'B'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends implements B {} int f() {}
//              ^^^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'implements' can't be used as a type.
//                         ^
// [diag.unexpectedToken] Unexpected text 'B'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends implements B {} void f() {}
//              ^^^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'implements' can't be used as a type.
//                         ^
// [diag.unexpectedToken] Unexpected text 'B'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends implements B {} int get a => 0;
//              ^^^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'implements' can't be used as a type.
//                         ^
// [diag.unexpectedToken] Unexpected text 'B'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends implements B {} mixin M {}
//              ^^^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'implements' can't be used as a type.
//                         ^
// [diag.unexpectedToken] Unexpected text 'B'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends implements B {} set a(b) {}
//              ^^^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'implements' can't be used as a type.
//                         ^
// [diag.unexpectedToken] Unexpected text 'B'.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_extendsImplementsNameBody_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends implements B {} typedef A = B Function(C, D);
//              ^^^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'implements' can't be used as a type.
//                         ^
// [diag.unexpectedToken] Unexpected text 'B'.
''');
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

  void test_class_declaration_extendsImplementsNameBody_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends implements B {} var a;
//              ^^^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'implements' can't be used as a type.
//                         ^
// [diag.unexpectedToken] Unexpected text 'B'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements class A {}
//                           ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements const a = 0;
//                           ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements enum E { v }
//                           ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_extendsNameImplements_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements
//                          ^
// [diag.expectedTypeName][column 29][length 0] Expected a type name.
// [diag.expectedClassBody][column 29][length 0] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements final a = 0;
//                           ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements int f() {}
//                           ^^^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements void f() {}
//                           ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements int get a => 0;
//                           ^^^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements mixin M {}
//                           ^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'mixin' can't be used as a type.
//                                 ^
// [diag.unexpectedToken] Unexpected text 'M'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements set a(b) {}
//                           ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_extendsNameImplements_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements typedef A = B Function(C, D);
//                           ^^^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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

  void test_class_declaration_extendsNameImplements_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements var a;
//                           ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements {} class A {}
//                           ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements {} const a = 0;
//                           ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements {} enum E { v }
//                           ^
// [diag.expectedTypeName] Expected a type name.
''');
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
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_extendsNameImplementsBody_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements {}
//                           ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements {} final a = 0;
//                           ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements {} int f() {}
//                           ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements {} void f() {}
//                           ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements {} int get a => 0;
//                           ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements {} mixin M {}
//                           ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements {} set a(b) {}
//                           ^
// [diag.expectedTypeName] Expected a type name.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_extendsNameImplementsBody_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements {} typedef A = B Function(C, D);
//                           ^
// [diag.expectedTypeName] Expected a type name.
''');
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

  void test_class_declaration_extendsNameImplementsBody_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B implements {} var a;
//                           ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with class A {}
//                     ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with const a = 0;
//                     ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with enum E { v }
//                     ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_extendsNameWith_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with
//                    ^
// [diag.expectedTypeName][column 23][length 0] Expected a type name.
// [diag.expectedClassBody][column 23][length 0] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with final a = 0;
//                     ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with int f() {}
//                     ^^^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with void f() {}
//                     ^^^^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with int get a => 0;
//                     ^^^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with mixin M {}
//                     ^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'mixin' can't be used as a type.
//                           ^
// [diag.unexpectedToken] Unexpected text 'M'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with set a(b) {}
//                     ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_extendsNameWith_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with typedef A = B Function(C, D);
//                     ^^^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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

  void test_class_declaration_extendsNameWith_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with var a;
//                     ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with {} class A {}
//                     ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with {} const a = 0;
//                     ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with {} enum E { v }
//                     ^
// [diag.expectedTypeName] Expected a type name.
''');
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
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_extendsNameWithBody_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with {}
//                     ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with {} final a = 0;
//                     ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with {} int f() {}
//                     ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with {} void f() {}
//                     ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with {} int get a => 0;
//                     ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with {} mixin M {}
//                     ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with {} set a(b) {}
//                     ^
// [diag.expectedTypeName] Expected a type name.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_extendsNameWithBody_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with {} typedef A = B Function(C, D);
//                     ^
// [diag.expectedTypeName] Expected a type name.
''');
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

  void test_class_declaration_extendsNameWithBody_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with {} var a;
//                     ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements class A {}
//                                  ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements const a = 0;
//                                  ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements enum E { v }
//                                  ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_extendsNameWithNameImplements_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements
//                                 ^
// [diag.expectedTypeName][column 36][length 0] Expected a type name.
// [diag.expectedClassBody][column 36][length 0] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements final a = 0;
//                                  ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements int f() {}
//                                  ^^^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements void f() {}
//                                  ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements int get a => 0;
//                                  ^^^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements mixin M {}
//                                  ^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'mixin' can't be used as a type.
//                                        ^
// [diag.unexpectedToken] Unexpected text 'M'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements set a(b) {}
//                                  ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_extendsNameWithNameImplements_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements typedef A = B Function(C, D);
//                                  ^^^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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

  void test_class_declaration_extendsNameWithNameImplements_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements var a;
//                                  ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements {} class A {}
//                                  ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements {} const a = 0;
//                                  ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements {} enum E { v }
//                                  ^
// [diag.expectedTypeName] Expected a type name.
''');
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
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_extendsNameWithNameImplementsBody_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements {}
//                                  ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements {} final a = 0;
//                                  ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements {} int f() {}
//                                  ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements {} void f() {}
//                                  ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements {} int get a => 0;
//                                  ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements {} mixin M {}
//                                  ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements {} set a(b) {}
//                                  ^
// [diag.expectedTypeName] Expected a type name.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_extendsNameWithNameImplementsBody_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements {} typedef A = B Function(C, D);
//                                  ^
// [diag.expectedTypeName] Expected a type name.
''');
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

  void test_class_declaration_extendsNameWithNameImplementsBody_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends B with C implements {} var a;
//                                  ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends with B {} class A {}
//              ^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends with B {} const a = 0;
//              ^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends with B {} enum E { v }
//              ^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_extendsWithNameBody_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends with B {}
//              ^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends with B {} final a = 0;
//              ^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends with B {} int f() {}
//              ^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends with B {} void f() {}
//              ^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends with B {} int get a => 0;
//              ^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends with B {} mixin M {}
//              ^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends with B {} set a(b) {}
//              ^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_extendsWithNameBody_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends with B {} typedef A = B Function(C, D);
//              ^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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

  void test_class_declaration_extendsWithNameBody_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A extends with B {} var a;
//              ^^^^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements class A {}
//                 ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements const a = 0;
//                 ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements enum E { v }
//                 ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_implements_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements
//                ^
// [diag.expectedTypeName][column 19][length 0] Expected a type name.
// [diag.expectedClassBody][column 19][length 0] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements final a = 0;
//                 ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements int f() {}
//                 ^^^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements void f() {}
//                 ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements int get a => 0;
//                 ^^^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements mixin M {}
//                 ^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'mixin' can't be used as a type.
//                       ^
// [diag.unexpectedToken] Unexpected text 'M'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements set a(b) {}
//                 ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_implements_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements typedef A = B Function(C, D);
//                 ^^^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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

  void test_class_declaration_implements_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements var a;
//                 ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements {} class A {}
//                 ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements {} const a = 0;
//                 ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements {} enum E { v }
//                 ^
// [diag.expectedTypeName] Expected a type name.
''');
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
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_implementsBody_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements {}
//                 ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements {} final a = 0;
//                 ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements {} int f() {}
//                 ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements {} void f() {}
//                 ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements {} int get a => 0;
//                 ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements {} mixin M {}
//                 ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements {} set a(b) {}
//                 ^
// [diag.expectedTypeName] Expected a type name.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_implementsBody_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements {} typedef A = B Function(C, D);
//                 ^
// [diag.expectedTypeName] Expected a type name.
''');
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

  void test_class_declaration_implementsBody_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements {} var a;
//                 ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B, class A {}
//                    ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B, const a = 0;
//                    ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B, enum E { v }
//                    ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_implementsNameComma_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B,
//                   ^
// [diag.expectedTypeName][column 22][length 0] Expected a type name.
// [diag.expectedClassBody][column 22][length 0] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B, final a = 0;
//                    ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B, int f() {}
//                    ^^^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B, void f() {}
//                    ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B, int get a => 0;
//                    ^^^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B, mixin M {}
//                    ^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'mixin' can't be used as a type.
//                          ^
// [diag.unexpectedToken] Unexpected text 'M'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B, set a(b) {}
//                    ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_implementsNameComma_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B, typedef A = B Function(C, D);
//                    ^^^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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

  void test_class_declaration_implementsNameComma_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B, var a;
//                    ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B, {} class A {}
//                    ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B, {} const a = 0;
//                    ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B, {} enum E { v }
//                    ^
// [diag.expectedTypeName] Expected a type name.
''');
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
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_implementsNameCommaBody_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B, {}
//                    ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B, {} final a = 0;
//                    ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B, {} int f() {}
//                    ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B, {} void f() {}
//                    ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B, {} int get a => 0;
//                    ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B, {} mixin M {}
//                    ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B, {} set a(b) {}
//                    ^
// [diag.expectedTypeName] Expected a type name.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_implementsNameCommaBody_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B, {} typedef A = B Function(C, D);
//                    ^
// [diag.expectedTypeName] Expected a type name.
''');
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

  void test_class_declaration_implementsNameCommaBody_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A implements B, {} var a;
//                    ^
// [diag.expectedTypeName] Expected a type name.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class class A {}
//    ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class const a = 0;
//    ^^^^^
// [diag.constWithoutPrimaryConstructor] 'const' can only be used together with a primary constructor declaration.
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedToken] Expected to find 'with'.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//               ^
// [diag.unexpectedToken] Unexpected text ';'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class enum E { v }
//    ^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_keyword_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class
//   ^
// [diag.missingIdentifier][column 6][length 0] Expected an identifier.
// [diag.expectedClassBody][column 6][length 0] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class final a = 0;
//    ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class int f() {}
//    ^^^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class void f() {}
//    ^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class int get a => 0;
//    ^^^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class mixin M {}
//    ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class set a(b) {}
//    ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_keyword_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class typedef A = B Function(C, D);
//    ^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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

  void test_class_declaration_keyword_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class var a;
//    ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A class A {}
//    ^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A const a = 0;
//    ^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A enum E { v }
//    ^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_named_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A
//    ^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A final a = 0;
//    ^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A int f() {}
//    ^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A void f() {}
//    ^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A int get a => 0;
//    ^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A mixin M {}
//    ^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A set a(b) {}
//    ^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_named_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A typedef A = B Function(C, D);
//    ^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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

  void test_class_declaration_named_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A var a;
//    ^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A on class A {}
//      ^^
// [diag.expectedInstead] Expected 'extends' instead of this.
//         ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A on const a = 0;
//      ^^
// [diag.expectedInstead] Expected 'extends' instead of this.
//         ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A on enum E { v }
//      ^^
// [diag.expectedInstead] Expected 'extends' instead of this.
//         ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
      body: BlockEnumBody
        leftBracket: {
        constants
          EnumConstantDeclaration
            name: v
        rightBracket: }
''');
  }

  void test_class_declaration_on_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A on
//      ^^
// [diag.expectedInstead] Expected 'extends' instead of this.
//        ^
// [diag.expectedTypeName][column 11][length 0] Expected a type name.
// [diag.expectedClassBody][column 11][length 0] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A on final a = 0;
//      ^^
// [diag.expectedInstead] Expected 'extends' instead of this.
//         ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A on int f() {}
//      ^^
// [diag.expectedInstead] Expected 'extends' instead of this.
//         ^^^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A on void f() {}
//      ^^
// [diag.expectedInstead] Expected 'extends' instead of this.
//         ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A on int get a => 0;
//      ^^
// [diag.expectedInstead] Expected 'extends' instead of this.
//         ^^^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A on mixin M {}
//      ^^
// [diag.expectedInstead] Expected 'extends' instead of this.
//         ^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'mixin' can't be used as a type.
//               ^
// [diag.unexpectedToken] Unexpected text 'M'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A on set a(b) {}
//      ^^
// [diag.expectedInstead] Expected 'extends' instead of this.
//         ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
          parameter: RegularFormalParameter
            name: b
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }

  void test_class_declaration_on_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A on typedef A = B Function(C, D);
//      ^^
// [diag.expectedInstead] Expected 'extends' instead of this.
//         ^^^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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

  void test_class_declaration_on_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A on var a;
//      ^^
// [diag.expectedInstead] Expected 'extends' instead of this.
//         ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
''');
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
