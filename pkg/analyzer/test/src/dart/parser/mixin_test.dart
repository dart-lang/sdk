// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinDeclarationParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MixinDeclarationParserTest extends ParserDiagnosticsTest {
  test_augment_implementsClause() {
    var parseResult = parseStringWithErrors(r'''
augment mixin M implements B {}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleMixinDeclaration, r'''
MixinDeclaration
  augmentKeyword: augment
  mixinKeyword: mixin
  name: M
  implementsClause: ImplementsClause
    implementsKeyword: implements
    interfaces
      NamedType
        name: B
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_augment_typeParameters_withBound() {
    var parseResult = parseStringWithErrors(r'''
augment mixin M<T extends int> {}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleMixinDeclaration, r'''
MixinDeclaration
  augmentKeyword: augment
  mixinKeyword: mixin
  name: M
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        extendsKeyword: extends
        bound: NamedType
          name: int
    rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_blockBody_constructor_named() {
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
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_blockBody_field() {
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
  }

  test_blockBody_getter() {
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
  }

  test_blockBody_method() {
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
  }

  test_blockBody_primaryConstructorBody() {
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

  test_blockBody_setter() {
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
          parameter: RegularFormalParameter
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

  test_emptyBody() {
    var parseResult = parseStringWithErrors(r'''
mixin M;
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleMixinDeclaration;
    assertParsedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: M
  body: EmptyClassBody
    semicolon: ;
''');
  }

  test_emptyBody_language310() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
mixin M;
''');
    parseResult.assertErrors([
      error(diag.experimentNotEnabledOffByDefault, 23, 1),
    ]);

    var node = parseResult.findNode.singleMixinDeclaration;
    assertParsedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: M
  body: EmptyClassBody
    semicolon: ;
''');
  }

  test_field_augment() {
    var parseResult = parseStringWithErrors(r'''
augment mixin M {
  augment int x = 0;
}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleMixinDeclaration, r'''
MixinDeclaration
  augmentKeyword: augment
  mixinKeyword: mixin
  name: M
  body: BlockClassBody
    leftBracket: {
    members
      FieldDeclaration
        augmentKeyword: augment
        fields: VariableDeclarationList
          type: NamedType
            name: int
          variables
            VariableDeclaration
              name: x
              equals: =
              initializer: IntegerLiteral
                literal: 0
        semicolon: ;
    rightBracket: }
''');
  }

  test_field_augment_static() {
    var parseResult = parseStringWithErrors(r'''
augment mixin M {
  augment static int x = 0;
}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleMixinDeclaration, r'''
MixinDeclaration
  augmentKeyword: augment
  mixinKeyword: mixin
  name: M
  body: BlockClassBody
    leftBracket: {
    members
      FieldDeclaration
        augmentKeyword: augment
        staticKeyword: static
        fields: VariableDeclarationList
          type: NamedType
            name: int
          variables
            VariableDeclaration
              name: x
              equals: =
              initializer: IntegerLiteral
                literal: 0
        semicolon: ;
    rightBracket: }
''');
  }

  test_field_augment_static_final() {
    var parseResult = parseStringWithErrors(r'''
augment mixin M {
  augment static final int x = 0;
}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleMixinDeclaration, r'''
MixinDeclaration
  augmentKeyword: augment
  mixinKeyword: mixin
  name: M
  body: BlockClassBody
    leftBracket: {
    members
      FieldDeclaration
        augmentKeyword: augment
        staticKeyword: static
        fields: VariableDeclarationList
          keyword: final
          type: NamedType
            name: int
          variables
            VariableDeclaration
              name: x
              equals: =
              initializer: IntegerLiteral
                literal: 0
        semicolon: ;
    rightBracket: }
''');
  }

  test_getter_augment() {
    var parseResult = parseStringWithErrors(r'''
augment mixin M {
  augment int get foo => 0;
}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleMixinDeclaration, r'''
MixinDeclaration
  augmentKeyword: augment
  mixinKeyword: mixin
  name: M
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        augmentKeyword: augment
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

  test_getter_augment_static() {
    var parseResult = parseStringWithErrors(r'''
augment mixin M {
  augment static int get foo => 0;
}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleMixinDeclaration, r'''
MixinDeclaration
  augmentKeyword: augment
  mixinKeyword: mixin
  name: M
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        augmentKeyword: augment
        modifierKeyword: static
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

  test_method_augment() {
    var parseResult = parseStringWithErrors(r'''
augment mixin M {
  augment void foo() {}
}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleMixinDeclaration, r'''
MixinDeclaration
  augmentKeyword: augment
  mixinKeyword: mixin
  name: M
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        augmentKeyword: augment
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

  test_method_augment_static() {
    var parseResult = parseStringWithErrors(r'''
augment mixin M {
  augment static void foo() {}
}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleMixinDeclaration, r'''
MixinDeclaration
  augmentKeyword: augment
  mixinKeyword: mixin
  name: M
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        augmentKeyword: augment
        modifierKeyword: static
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

  test_nameWithTypeParameters_augment() {
    var parseResult = parseStringWithErrors(r'''
augment mixin M<T> {}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleMixinDeclaration, r'''
MixinDeclaration
  augmentKeyword: augment
  mixinKeyword: mixin
  name: M
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
    rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_operator_augment() {
    var parseResult = parseStringWithErrors(r'''
augment mixin M {
  augment int operator+(int other) => 0;
}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleMixinDeclaration, r'''
MixinDeclaration
  augmentKeyword: augment
  mixinKeyword: mixin
  name: M
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        augmentKeyword: augment
        returnType: NamedType
          name: int
        operatorKeyword: operator
        name: +
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: int
            name: other
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IntegerLiteral
            literal: 0
          semicolon: ;
    rightBracket: }
''');
  }

  test_setter_augment() {
    var parseResult = parseStringWithErrors(r'''
augment mixin M {
  augment set foo(int x) {}
}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleMixinDeclaration, r'''
MixinDeclaration
  augmentKeyword: augment
  mixinKeyword: mixin
  name: M
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        augmentKeyword: augment
        propertyKeyword: set
        name: foo
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: int
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
''');
  }

  test_setter_augment_static() {
    var parseResult = parseStringWithErrors(r'''
augment mixin M {
  augment static set foo(int x) {}
}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleMixinDeclaration, r'''
MixinDeclaration
  augmentKeyword: augment
  mixinKeyword: mixin
  name: M
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        augmentKeyword: augment
        modifierKeyword: static
        propertyKeyword: set
        name: foo
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: int
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
''');
  }
}
