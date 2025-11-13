// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinDeclarationParserTest);
  });
}

@reflectiveTest
class MixinDeclarationParserTest extends ParserDiagnosticsTest {
  test_body_field() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
mixin M {
  static final int F = 0;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleMixinDeclaration;
    assertParsedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: M
  body: BlockClassBody
    leftBracket: {
    members
      FieldDeclaration
        staticKeyword: static
        fields: VariableDeclarationList
          keyword: final
          type: NamedType
            name: int
          variables
            VariableDeclaration
              name: F
              equals: =
              initializer: IntegerLiteral
                literal: 0
        semicolon: ;
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
mixin M {
  static final int F = 0;
}
''');
      parseResult.assertNoErrors();
      var node = parseResult.findNode.singleMixinDeclaration;
      assertParsedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: M
  leftBracket: {
  members
    FieldDeclaration
      staticKeyword: static
      fields: VariableDeclarationList
        keyword: final
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: F
            equals: =
            initializer: IntegerLiteral
              literal: 0
      semicolon: ;
  rightBracket: }
''');
    }
  }

  test_body_getter() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
mixin M {
  int get foo => 0;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleMixinDeclaration;
    assertParsedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: M
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        returnType: NamedType
          name: int
        propertyKeyword: get
        name: foo
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IntegerLiteral
            literal: 0
          semicolon: ;
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
mixin M {
  int get foo => 0;
}
''');
      parseResult.assertNoErrors();
      var node = parseResult.findNode.singleMixinDeclaration;
      assertParsedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: M
  leftBracket: {
  members
    MethodDeclaration
      returnType: NamedType
        name: int
      propertyKeyword: get
      name: foo
      body: ExpressionFunctionBody
        functionDefinition: =>
        expression: IntegerLiteral
          literal: 0
        semicolon: ;
  rightBracket: }
''');
    }
  }

  test_body_method() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
mixin M {
  void foo() {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleMixinDeclaration;
    assertParsedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: M
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        returnType: NamedType
          name: void
        name: foo
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
mixin M {
  void foo() {}
}
''');
      parseResult.assertNoErrors();
      var node = parseResult.findNode.singleMixinDeclaration;
      assertParsedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: M
  leftBracket: {
  members
    MethodDeclaration
      returnType: NamedType
        name: void
      name: foo
      parameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      body: BlockFunctionBody
        block: Block
          leftBracket: {
          rightBracket: }
  rightBracket: }
''');
    }
  }

  test_body_setter() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
mixin M {
  set foo(int _) {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleMixinDeclaration;
    assertParsedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: M
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        propertyKeyword: set
        name: foo
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            type: NamedType
              name: int
            name: _
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
mixin M {
  set foo(int _) {}
}
''');
      parseResult.assertNoErrors();
      var node = parseResult.findNode.singleMixinDeclaration;
      assertParsedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: M
  leftBracket: {
  members
    MethodDeclaration
      propertyKeyword: set
      name: foo
      parameters: FormalParameterList
        leftParenthesis: (
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
          name: _
        rightParenthesis: )
      body: BlockFunctionBody
        block: Block
          leftBracket: {
          rightBracket: }
  rightBracket: }
''');
    }
  }

  test_constructor_named() {
    var parseResult = parseStringWithErrors(r'''
mixin A {
  A.named();
}
''');
    parseResult.assertErrors([error(diag.mixinDeclaresConstructor, 12, 1)]);

    // Mixins cannot have constructors.
    // So, we don't put them into AST at all.
    var node = parseResult.findNode.singleMixinDeclaration;
    assertParsedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: A
  leftBracket: {
  rightBracket: }
''');
  }

  test_primaryConstructorBody() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
mixin A {
  this;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleMixinDeclaration;
    assertParsedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: A
  body: BlockClassBody
    leftBracket: {
    members
      PrimaryConstructorBody
        thisKeyword: this
        body: EmptyFunctionBody
          semicolon: ;
    rightBracket: }
''');
  }
}
