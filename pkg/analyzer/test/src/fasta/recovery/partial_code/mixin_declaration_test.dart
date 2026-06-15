// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinDeclarationTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MixinDeclarationTest extends ParserDiagnosticsTest {
  void test_mixin_declaration_extend_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A extend class A {}
//      ^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//             ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extend
        superclassConstraints
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

  void test_mixin_declaration_extend_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A extend const a = 0;
//      ^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//             ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extend
        superclassConstraints
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

  void test_mixin_declaration_extend_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A extend enum E { v }
//      ^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//             ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extend
        superclassConstraints
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

  void test_mixin_declaration_extend_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A extend
//      ^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//            ^
// [diag.expectedTypeName][column 15][length 0] Expected a type name.
// [diag.expectedMixinBody][column 15][length 0] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extend
        superclassConstraints
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_mixin_declaration_extend_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A extend final a = 0;
//      ^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//             ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extend
        superclassConstraints
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

  void test_mixin_declaration_extend_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A extend int f() {}
//      ^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//             ^^^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extend
        superclassConstraints
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

  void test_mixin_declaration_extend_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A extend void f() {}
//      ^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//             ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extend
        superclassConstraints
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

  void test_mixin_declaration_extend_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A extend int get a => 0;
//      ^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//             ^^^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extend
        superclassConstraints
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

  void test_mixin_declaration_extend_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A extend mixin M {}
//      ^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//             ^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'mixin' can't be used as a type.
//                   ^
// [diag.unexpectedToken] Unexpected text 'M'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extend
        superclassConstraints
          NamedType
            name: mixin
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_mixin_declaration_extend_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A extend set a(b) {}
//      ^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//             ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extend
        superclassConstraints
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

  void test_mixin_declaration_extend_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A extend typedef A = B Function(C, D);
//      ^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//             ^^^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extend
        superclassConstraints
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

  void test_mixin_declaration_extend_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A extend var a;
//      ^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//             ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extend
        superclassConstraints
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

  void test_mixin_declaration_extends_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A extends class A {}
//      ^^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//              ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extends
        superclassConstraints
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

  void test_mixin_declaration_extends_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A extends const a = 0;
//      ^^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//              ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extends
        superclassConstraints
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

  void test_mixin_declaration_extends_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A extends enum E { v }
//      ^^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//              ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extends
        superclassConstraints
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

  void test_mixin_declaration_extends_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A extends
//      ^^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//             ^
// [diag.expectedTypeName][column 16][length 0] Expected a type name.
// [diag.expectedMixinBody][column 16][length 0] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extends
        superclassConstraints
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_mixin_declaration_extends_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A extends final a = 0;
//      ^^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//              ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extends
        superclassConstraints
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

  void test_mixin_declaration_extends_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A extends int f() {}
//      ^^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//              ^^^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extends
        superclassConstraints
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

  void test_mixin_declaration_extends_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A extends void f() {}
//      ^^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//              ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extends
        superclassConstraints
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

  void test_mixin_declaration_extends_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A extends int get a => 0;
//      ^^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//              ^^^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extends
        superclassConstraints
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

  void test_mixin_declaration_extends_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A extends mixin M {}
//      ^^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//              ^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'mixin' can't be used as a type.
//                    ^
// [diag.unexpectedToken] Unexpected text 'M'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extends
        superclassConstraints
          NamedType
            name: mixin
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_mixin_declaration_extends_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A extends set a(b) {}
//      ^^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//              ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extends
        superclassConstraints
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

  void test_mixin_declaration_extends_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A extends typedef A = B Function(C, D);
//      ^^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//              ^^^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extends
        superclassConstraints
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

  void test_mixin_declaration_extends_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A extends var a;
//      ^^^^^^^
// [diag.expectedInstead] Expected 'on' instead of this.
//              ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: extends
        superclassConstraints
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

  void test_mixin_declaration_implements_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements class A {}
//                 ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implements_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements const a = 0;
//                 ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implements_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements enum E { v }
//                 ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implements_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements
//                ^
// [diag.expectedTypeName][column 19][length 0] Expected a type name.
// [diag.expectedMixinBody][column 19][length 0] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implements_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements final a = 0;
//                 ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implements_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements int f() {}
//                 ^^^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implements_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements void f() {}
//                 ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implements_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements int get a => 0;
//                 ^^^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implements_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements mixin M {}
//                 ^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'mixin' can't be used as a type.
//                       ^
// [diag.unexpectedToken] Unexpected text 'M'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implements_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements set a(b) {}
//                 ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implements_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements typedef A = B Function(C, D);
//                 ^^^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implements_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements var a;
//                 ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsBody_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements {} class A {}
//                 ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsBody_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements {} const a = 0;
//                 ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsBody_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements {} enum E { v }
//                 ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsBody_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements {}
//                 ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsBody_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements {} final a = 0;
//                 ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsBody_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements {} int f() {}
//                 ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsBody_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements {} void f() {}
//                 ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsBody_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements {} int get a => 0;
//                 ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsBody_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements {} mixin M {}
//                 ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsBody_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements {} set a(b) {}
//                 ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsBody_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements {} typedef A = B Function(C, D);
//                 ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsBody_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements {} var a;
//                 ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsNameComma_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B, class A {}
//                    ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsNameComma_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B, const a = 0;
//                    ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsNameComma_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B, enum E { v }
//                    ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsNameComma_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B,
//                   ^
// [diag.expectedTypeName][column 22][length 0] Expected a type name.
// [diag.expectedMixinBody][column 22][length 0] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsNameComma_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B, final a = 0;
//                    ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsNameComma_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B, int f() {}
//                    ^^^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsNameComma_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B, void f() {}
//                    ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsNameComma_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B, int get a => 0;
//                    ^^^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsNameComma_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B, mixin M {}
//                    ^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'mixin' can't be used as a type.
//                          ^
// [diag.unexpectedToken] Unexpected text 'M'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsNameComma_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B, set a(b) {}
//                    ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsNameComma_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B, typedef A = B Function(C, D);
//                    ^^^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsNameComma_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B, var a;
//                    ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsNameCommaBody_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B, {} class A {}
//                    ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsNameCommaBody_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B, {} const a = 0;
//                    ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsNameCommaBody_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B, {} enum E { v }
//                    ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsNameCommaBody_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B, {}
//                    ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsNameCommaBody_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B, {} final a = 0;
//                    ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsNameCommaBody_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B, {} int f() {}
//                    ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsNameCommaBody_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B, {} void f() {}
//                    ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsNameCommaBody_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B, {} int get a => 0;
//                    ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsNameCommaBody_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B, {} mixin M {}
//                    ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsNameCommaBody_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B, {} set a(b) {}
//                    ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsNameCommaBody_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B, {} typedef A = B Function(C, D);
//                    ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_implementsNameCommaBody_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A implements B, {} var a;
//                    ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_keyword_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin class A {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      mixinKeyword: mixin
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_mixin_declaration_keyword_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin const a = 0;
//    ^^^^^
// [diag.mixinPrimaryConstructor] Mixins can't have primary constructors.
//          ^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
//            ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//              ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//               ^
// [diag.unexpectedToken] Unexpected text ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: a
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_mixin_declaration_keyword_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin enum E { v }
//    ^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
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

  void test_mixin_declaration_keyword_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin
//   ^
// [diag.missingIdentifier][column 6][length 0] Expected an identifier.
// [diag.expectedMixinBody][column 6][length 0] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_mixin_declaration_keyword_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin final a = 0;
//    ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
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

  void test_mixin_declaration_keyword_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin int f() {}
//    ^^^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
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

  void test_mixin_declaration_keyword_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin void f() {}
//    ^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: <empty> <synthetic>
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

  void test_mixin_declaration_keyword_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin int get a => 0;
//    ^^^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
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

  void test_mixin_declaration_keyword_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin mixin M {}
//    ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: <empty> <synthetic>
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

  void test_mixin_declaration_keyword_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin set a(b) {}
//    ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
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

  void test_mixin_declaration_keyword_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin typedef A = B Function(C, D);
//    ^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
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

  void test_mixin_declaration_keyword_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin var a;
//    ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
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

  void test_mixin_declaration_named_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A class A {}
//    ^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_named_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A const a = 0;
//    ^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_named_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A enum E { v }
//    ^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_named_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A
//    ^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_mixin_declaration_named_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A final a = 0;
//    ^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_named_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A int f() {}
//    ^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_named_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A void f() {}
//    ^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_named_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A int get a => 0;
//    ^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_named_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A mixin M {}
//    ^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_named_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A set a(b) {}
//    ^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_named_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A typedef A = B Function(C, D);
//    ^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_named_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A var a;
//    ^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
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

  void test_mixin_declaration_on_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on class A {}
//         ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_on_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on const a = 0;
//         ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_on_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on enum E { v }
//         ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_on_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on
//        ^
// [diag.expectedTypeName][column 11][length 0] Expected a type name.
// [diag.expectedMixinBody][column 11][length 0] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_mixin_declaration_on_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on final a = 0;
//         ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_on_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on int f() {}
//         ^^^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_on_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on void f() {}
//         ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_on_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on int get a => 0;
//         ^^^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_on_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on mixin M {}
//         ^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'mixin' can't be used as a type.
//               ^
// [diag.unexpectedToken] Unexpected text 'M'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: mixin
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_mixin_declaration_on_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on set a(b) {}
//         ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_on_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on typedef A = B Function(C, D);
//         ^^^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_on_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on var a;
//         ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onBody_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on {} class A {}
//         ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onBody_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on {} const a = 0;
//         ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onBody_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on {} enum E { v }
//         ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onBody_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on {}
//         ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_mixin_declaration_onBody_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on {} final a = 0;
//         ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onBody_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on {} int f() {}
//         ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onBody_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on {} void f() {}
//         ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onBody_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on {} int get a => 0;
//         ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onBody_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on {} mixin M {}
//         ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onBody_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on {} set a(b) {}
//         ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onBody_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on {} typedef A = B Function(C, D);
//         ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onBody_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on {} var a;
//         ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onImplementsNameBody_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on implements B {} class A {}
//         ^^^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'implements' can't be used as a type.
//                    ^
// [diag.unexpectedToken] Unexpected text 'B'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onImplementsNameBody_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on implements B {} const a = 0;
//         ^^^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'implements' can't be used as a type.
//                    ^
// [diag.unexpectedToken] Unexpected text 'B'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onImplementsNameBody_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on implements B {} enum E { v }
//         ^^^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'implements' can't be used as a type.
//                    ^
// [diag.unexpectedToken] Unexpected text 'B'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onImplementsNameBody_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on implements B {}
//         ^^^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'implements' can't be used as a type.
//                    ^
// [diag.unexpectedToken] Unexpected text 'B'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: implements
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_mixin_declaration_onImplementsNameBody_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on implements B {} final a = 0;
//         ^^^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'implements' can't be used as a type.
//                    ^
// [diag.unexpectedToken] Unexpected text 'B'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onImplementsNameBody_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on implements B {} int f() {}
//         ^^^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'implements' can't be used as a type.
//                    ^
// [diag.unexpectedToken] Unexpected text 'B'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onImplementsNameBody_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on implements B {} void f() {}
//         ^^^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'implements' can't be used as a type.
//                    ^
// [diag.unexpectedToken] Unexpected text 'B'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onImplementsNameBody_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on implements B {} int get a => 0;
//         ^^^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'implements' can't be used as a type.
//                    ^
// [diag.unexpectedToken] Unexpected text 'B'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onImplementsNameBody_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on implements B {} mixin M {}
//         ^^^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'implements' can't be used as a type.
//                    ^
// [diag.unexpectedToken] Unexpected text 'B'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onImplementsNameBody_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on implements B {} set a(b) {}
//         ^^^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'implements' can't be used as a type.
//                    ^
// [diag.unexpectedToken] Unexpected text 'B'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onImplementsNameBody_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on implements B {} typedef A = B Function(C, D);
//         ^^^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'implements' can't be used as a type.
//                    ^
// [diag.unexpectedToken] Unexpected text 'B'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onImplementsNameBody_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on implements B {} var a;
//         ^^^^^^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'implements' can't be used as a type.
//                    ^
// [diag.unexpectedToken] Unexpected text 'B'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onNameComma_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B, class A {}
//            ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onNameComma_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B, const a = 0;
//            ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onNameComma_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B, enum E { v }
//            ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onNameComma_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B,
//           ^
// [diag.expectedTypeName][column 14][length 0] Expected a type name.
// [diag.expectedMixinBody][column 14][length 0] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_mixin_declaration_onNameComma_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B, final a = 0;
//            ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onNameComma_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B, int f() {}
//            ^^^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onNameComma_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B, void f() {}
//            ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onNameComma_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B, int get a => 0;
//            ^^^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onNameComma_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B, mixin M {}
//            ^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'mixin' can't be used as a type.
//                  ^
// [diag.unexpectedToken] Unexpected text 'M'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
            name: mixin
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_mixin_declaration_onNameComma_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B, set a(b) {}
//            ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onNameComma_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B, typedef A = B Function(C, D);
//            ^^^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onNameComma_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B, var a;
//            ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onNameCommaBody_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B, {} class A {}
//            ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onNameCommaBody_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B, {} const a = 0;
//            ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onNameCommaBody_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B, {} enum E { v }
//            ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onNameCommaBody_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B, {}
//            ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
            name: B
          NamedType
            name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_mixin_declaration_onNameCommaBody_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B, {} final a = 0;
//            ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onNameCommaBody_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B, {} int f() {}
//            ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onNameCommaBody_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B, {} void f() {}
//            ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onNameCommaBody_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B, {} int get a => 0;
//            ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onNameCommaBody_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B, {} mixin M {}
//            ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onNameCommaBody_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B, {} set a(b) {}
//            ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onNameCommaBody_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B, {} typedef A = B Function(C, D);
//            ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onNameCommaBody_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B, {} var a;
//            ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
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

  void test_mixin_declaration_onNameImplements_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements class A {}
//                      ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onNameImplements_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements const a = 0;
//                      ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onNameImplements_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements enum E { v }
//                      ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onNameImplements_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements
//                     ^
// [diag.expectedTypeName][column 24][length 0] Expected a type name.
// [diag.expectedMixinBody][column 24][length 0] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onNameImplements_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements final a = 0;
//                      ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onNameImplements_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements int f() {}
//                      ^^^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onNameImplements_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements void f() {}
//                      ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onNameImplements_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements int get a => 0;
//                      ^^^
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onNameImplements_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements mixin M {}
//                      ^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'mixin' can't be used as a type.
//                            ^
// [diag.unexpectedToken] Unexpected text 'M'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onNameImplements_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements set a(b) {}
//                      ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onNameImplements_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements typedef A = B Function(C, D);
//                      ^^^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onNameImplements_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements var a;
//                      ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedMixinBody] A mixin declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onNameImplementsBody_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements {} class A {}
//                      ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onNameImplementsBody_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements {} const a = 0;
//                      ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onNameImplementsBody_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements {} enum E { v }
//                      ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onNameImplementsBody_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements {}
//                      ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onNameImplementsBody_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements {} final a = 0;
//                      ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onNameImplementsBody_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements {} int f() {}
//                      ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onNameImplementsBody_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements {} void f() {}
//                      ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onNameImplementsBody_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements {} int get a => 0;
//                      ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onNameImplementsBody_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements {} mixin M {}
//                      ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onNameImplementsBody_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements {} set a(b) {}
//                      ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onNameImplementsBody_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements {} typedef A = B Function(C, D);
//                      ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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

  void test_mixin_declaration_onNameImplementsBody_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin A on B implements {} var a;
//                      ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    MixinDeclaration
      mixinKeyword: mixin
      name: A
      onClause: MixinOnClause
        onKeyword: on
        superclassConstraints
          NamedType
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
}
