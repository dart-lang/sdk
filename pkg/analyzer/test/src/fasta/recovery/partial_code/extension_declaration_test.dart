// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionDeclarationTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ExtensionDeclarationTest extends ParserDiagnosticsTest {
  void test_extension_declaration_extendedType_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on String class A {}
//             ^^^^^^
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
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

  void test_extension_declaration_extendedType_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on String const a = 0;
//             ^^^^^^
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
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

  void test_extension_declaration_extendedType_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on String enum E { v }
//             ^^^^^^
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
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

  void test_extension_declaration_extendedType_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on String
//             ^^^^^^
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_extendedType_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on String final a = 0;
//             ^^^^^^
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
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

  void test_extension_declaration_extendedType_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on String int f() {}
//             ^^^^^^
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
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

  void test_extension_declaration_extendedType_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on String void f() {}
//             ^^^^^^
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
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

  void test_extension_declaration_extendedType_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on String int get a => 0;
//             ^^^^^^
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
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

  void test_extension_declaration_extendedType_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on String mixin M {}
//             ^^^^^^
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
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

  void test_extension_declaration_extendedType_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on String set a(b) {}
//             ^^^^^^
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
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

  void test_extension_declaration_extendedType_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on String typedef A = B Function(C, D);
//             ^^^^^^
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
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

  void test_extension_declaration_extendedType_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on String var a;
//             ^^^^^^
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
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

  void test_extension_declaration_keyword_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension class A {}
// [diag.expectedToken][column 1][length 9] Expected to find 'on'.
//        ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
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

  void test_extension_declaration_keyword_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension const a = 0;
//        ^^^^^
// [diag.extensionPrimaryConstructor] Extensions can't have primary constructors.
//              ^
// [diag.expectedToken] Expected to find 'on'.
//                ^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//                  ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//                   ^
// [diag.unexpectedToken] Unexpected text ';'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: a
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_keyword_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension enum E { v }
// [diag.expectedToken][column 1][length 9] Expected to find 'on'.
//        ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
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

  void test_extension_declaration_keyword_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension
// [diag.expectedToken][column 1][length 9] Expected to find 'on'.
//       ^
// [diag.expectedTypeName][column 10][length 0] Expected a type name.
// [diag.expectedExtensionBody][column 10][length 0] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_keyword_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension final a = 0;
// [diag.expectedToken][column 1][length 9] Expected to find 'on'.
//        ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
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

  void test_extension_declaration_keyword_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension int f() {}
//        ^^^
// [diag.expectedToken] Expected to find 'on'.
//            ^
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
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
    ExtensionDeclaration
      extensionKeyword: extension
      name: int
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: f
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_keyword_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension void f() {}
// [diag.expectedToken][column 1][length 9] Expected to find 'on'.
//        ^^^^
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
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

  void test_extension_declaration_keyword_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension int get a => 0;
//        ^^^
// [diag.expectedToken] Expected to find 'on'.
//            ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: int
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: <empty> <synthetic>
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

  void test_extension_declaration_keyword_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension mixin M {}
//        ^^^^^
// [diag.expectedToken] Expected to find 'on'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: mixin
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: M
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_extension_declaration_keyword_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension set a(b) {}
//        ^^^
// [diag.expectedToken] Expected to find 'on'.
//            ^
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
//             ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//              ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
//               ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//                 ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: set
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: a
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: b
      semicolon: ; <synthetic>
''');
  }

  void test_extension_declaration_keyword_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension typedef A = B Function(C, D);
//        ^^^^^^^
// [diag.expectedToken] Expected to find 'on'.
//                ^
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
//                  ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: typedef
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: A
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    FunctionDeclaration
      returnType: NamedType
        name: B
      name: Function
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: C
          parameter: RegularFormalParameter
            name: D
          rightParenthesis: )
        body: EmptyFunctionBody
          semicolon: ;
''');
  }

  void test_extension_declaration_keyword_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension var a;
// [diag.expectedToken][column 1][length 9] Expected to find 'on'.
//        ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
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

  void test_extension_declaration_named_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E class A {}
//        ^
// [diag.expectedToken] Expected to find 'on'.
//          ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
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

  void test_extension_declaration_named_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E const a = 0;
//        ^
// [diag.expectedToken] Expected to find 'on'.
//          ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
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

  void test_extension_declaration_named_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E enum E { v }
//        ^
// [diag.expectedToken] Expected to find 'on'.
//          ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
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

  void test_extension_declaration_named_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E
//        ^
// [diag.expectedToken] Expected to find 'on'.
//         ^
// [diag.expectedTypeName][column 12][length 0] Expected a type name.
// [diag.expectedExtensionBody][column 12][length 0] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_named_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E final a = 0;
//        ^
// [diag.expectedToken] Expected to find 'on'.
//          ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
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

  void test_extension_declaration_named_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E int f() {}
//        ^
// [diag.expectedToken] Expected to find 'on'.
//          ^^^
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
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

  void test_extension_declaration_named_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E void f() {}
//        ^
// [diag.expectedToken] Expected to find 'on'.
//          ^^^^
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
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

  void test_extension_declaration_named_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E int get a => 0;
//        ^
// [diag.expectedToken] Expected to find 'on'.
//          ^^^
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
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

  void test_extension_declaration_named_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E mixin M {}
//        ^
// [diag.expectedToken] Expected to find 'on'.
//          ^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'mixin' can't be used as a type.
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
//                ^
// [diag.missingFunctionParameters] Functions must have an explicit list of parameters.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
          name: mixin
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
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

  void test_extension_declaration_named_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E set a(b) {}
//        ^
// [diag.expectedToken] Expected to find 'on'.
//          ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
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

  void test_extension_declaration_named_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E typedef A = B Function(C, D);
//        ^
// [diag.expectedToken] Expected to find 'on'.
//          ^^^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
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

  void test_extension_declaration_named_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E var a;
//        ^
// [diag.expectedToken] Expected to find 'on'.
//          ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on <synthetic>
        extendedType: NamedType
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

  void test_extension_declaration_on_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on class A {}
//             ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
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

  void test_extension_declaration_on_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on const a = 0;
//             ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
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

  void test_extension_declaration_on_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on enum E { v }
//             ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
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

  void test_extension_declaration_on_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on
//            ^
// [diag.expectedTypeName][column 15][length 0] Expected a type name.
// [diag.expectedExtensionBody][column 15][length 0] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: <empty> <synthetic>
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_on_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on final a = 0;
//             ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
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

  void test_extension_declaration_on_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on int f() {}
//             ^^^
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
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

  void test_extension_declaration_on_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on void f() {}
//             ^^^^
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
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

  void test_extension_declaration_on_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on int get a => 0;
//             ^^^
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
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

  void test_extension_declaration_on_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on mixin M {}
//             ^^^^^
// [diag.builtInIdentifierAsType] The built-in identifier 'mixin' can't be used as a type.
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
//                   ^
// [diag.missingFunctionParameters] Functions must have an explicit list of parameters.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: mixin
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
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

  void test_extension_declaration_on_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on set a(b) {}
//             ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
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

  void test_extension_declaration_on_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on typedef A = B Function(C, D);
//             ^^^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
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

  void test_extension_declaration_on_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on var a;
//             ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedExtensionBody] An extension declaration must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
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

  void test_extension_declaration_partialBody_class() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on String { class A {}
//                      ^^^^^
// [diag.classInClass] Classes can't be declared inside other classes.
// [diag.expectedToken][column 35][length 1] Expected to find '}'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: {
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_partialBody_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on String { const a = 0;
// [diag.expectedToken][column 37][length 1] Expected to find '}'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: const
              variables
                VariableDeclaration
                  name: a
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ;
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_partialBody_enum() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on String { enum E { v }
//                      ^^^^
// [diag.enumInClass] Enums can't be declared inside classes.
// [diag.expectedToken][column 37][length 1] Expected to find '}'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: {
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_partialBody_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on String {
// [diag.expectedToken][column 24][length 1] Expected to find '}'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: {
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_partialBody_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on String { final a = 0;
// [diag.expectedToken][column 37][length 1] Expected to find '}'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: final
              variables
                VariableDeclaration
                  name: a
                  equals: =
                  initializer: IntegerLiteral
                    literal: 0
            semicolon: ;
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_partialBody_functionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on String { int f() {}
// [diag.expectedToken][column 35][length 1] Expected to find '}'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: {
        members
          MethodDeclaration
            returnType: NamedType
              name: int
            name: f
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_partialBody_functionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on String { void f() {}
// [diag.expectedToken][column 36][length 1] Expected to find '}'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: {
        members
          MethodDeclaration
            returnType: NamedType
              name: void
            name: f
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_partialBody_getter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on String { int get a => 0;
// [diag.expectedToken][column 40][length 1] Expected to find '}'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: {
        members
          MethodDeclaration
            returnType: NamedType
              name: int
            propertyKeyword: get
            name: a
            body: ExpressionFunctionBody
              functionDefinition: =>
              expression: IntegerLiteral
                literal: 0
              semicolon: ;
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_partialBody_mixin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on String { mixin M {}
//                      ^^^^^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
//                            ^
// [diag.missingFunctionParameters] Functions must have an explicit list of parameters.
// [diag.expectedToken][column 35][length 1] Expected to find '}'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            fields: VariableDeclarationList
              variables
                VariableDeclaration
                  name: mixin
            semicolon: ; <synthetic>
          MethodDeclaration
            name: M
            parameters: FormalParameterList
              leftParenthesis: ( <synthetic>
              rightParenthesis: ) <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_partialBody_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on String { set a(b) {}
// [diag.expectedToken][column 36][length 1] Expected to find '}'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: {
        members
          MethodDeclaration
            propertyKeyword: set
            name: a
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: b
              rightParenthesis: )
            body: BlockFunctionBody
              block: Block
                leftBracket: {
                rightBracket: }
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_partialBody_typedef() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on String { typedef A = B Function(C, D);
//                      ^^^^^^^
// [diag.typedefInClass] Typedefs can't be declared inside classes.
//                              ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
//                                  ^
// [diag.expectedToken] Expected to find ';'.
// [diag.expectedToken][column 54][length 1] Expected to find '}'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            fields: VariableDeclarationList
              variables
                VariableDeclaration
                  name: A
                  equals: =
                  initializer: SimpleIdentifier
                    token: B
            semicolon: ; <synthetic>
          MethodDeclaration
            name: Function
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: C
              parameter: RegularFormalParameter
                name: D
              rightParenthesis: )
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: } <synthetic>
''');
  }

  void test_extension_declaration_partialBody_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on String { var a;
// [diag.expectedToken][column 31][length 1] Expected to find '}'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ExtensionDeclaration
      extensionKeyword: extension
      name: E
      onClause: ExtensionOnClause
        onKeyword: on
        extendedType: NamedType
          name: String
      body: BlockClassBody
        leftBracket: {
        members
          FieldDeclaration
            fields: VariableDeclarationList
              keyword: var
              variables
                VariableDeclaration
                  name: a
            semicolon: ;
        rightBracket: } <synthetic>
''');
  }
}
