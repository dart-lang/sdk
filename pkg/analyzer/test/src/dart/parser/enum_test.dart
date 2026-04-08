// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumDeclarationParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class EnumDeclarationParserTest extends ParserDiagnosticsTest {
  test_augment_constant_add() {
    var parseResult = parseStringWithErrors(r'''
augment enum E {
  v
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  augmentKeyword: augment
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

  test_augment_constant_augment_noConstructor() {
    var parseResult = parseStringWithErrors(r'''
augment enum E {
  augment v
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        augmentKeyword: augment
        name: v
    rightBracket: }
''');
  }

  test_augment_constant_augment_withConstructor() {
    var parseResult = parseStringWithErrors(r'''
augment enum E {
  augment v.foo()
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        augmentKeyword: augment
        name: v
        arguments: EnumConstantArguments
          constructorSelector: ConstructorSelector
            period: .
            name: SimpleIdentifier
              token: foo
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
    rightBracket: }
''');
  }

  test_augment_implementsClause() {
    var parseResult = parseStringWithErrors(r'''
augment enum E implements B {}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  implementsClause: ImplementsClause
    implementsKeyword: implements
    interfaces
      NamedType
        name: B
  body: BlockEnumBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_augment_noConstants_semicolon_method() {
    var parseResult = parseStringWithErrors(r'''
augment enum E {;
  void foo() {}
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumBody
    leftBracket: {
    semicolon: ;
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

  test_augment_typeParameters_withBound() {
    var parseResult = parseStringWithErrors(r'''
augment enum E<T extends int> {}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          extendsKeyword: extends
          bound: NamedType
            name: int
      rightBracket: >
  body: BlockEnumBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_augment_withClause() {
    var parseResult = parseStringWithErrors(r'''
augment enum E with M {}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  withClause: WithClause
    withKeyword: with
    mixinTypes
      NamedType
        name: M
  body: BlockEnumBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_blockBody_empty() {
    var parseResult = parseStringWithErrors(r'''
enum E {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_constructor_factoryHead_named() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v;
  factory named() {}
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  name: named
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_constructor_factoryHead_named_const() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v;
  const factory named() = B;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  constKeyword: const
  factoryKeyword: factory
  name: named
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: =
  redirectedConstructor: ConstructorName
    type: NamedType
      name: B
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_factoryHead_unnamed() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v;
  factory () {}
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_constructor_factoryHead_unnamed_const() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v;
  const factory () = B;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  constKeyword: const
  factoryKeyword: factory
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: =
  redirectedConstructor: ConstructorName
    type: NamedType
      name: B
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_newHead_named() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v;
  new named();
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  newKeyword: new
  name: named
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_newHead_named_const() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v;
  const new named();
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  constKeyword: const
  newKeyword: new
  name: named
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_newHead_unnamed() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v;
  new ();
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  newKeyword: new
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_newHead_unnamed_const() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v;
  const new ();
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  constKeyword: const
  newKeyword: new
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_typeName_factory_named() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v;
  factory E.named() {}
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: E
  period: .
  name: named
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_constructor_typeName_factory_unnamed() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v;
  factory E() {}
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: E
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_constructor_typeName_named() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v;
  E.named();
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: E
  period: .
  name: named
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_typeName_unnamed() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v;
  E();
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: E
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_declaration_noConstants_semicolon() {
    var parseResult = parseStringWithErrors(r'''
enum E {;}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumBody
    leftBracket: {
    semicolon: ;
    rightBracket: }
''');
  }

  test_declaration_noConstants_semicolon_method() {
    var parseResult = parseStringWithErrors(r'''
enum E {;
  void foo() {}
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumBody
    leftBracket: {
    semicolon: ;
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

  test_emptyBody() {
    var parseResult = parseStringWithErrors(r'''
enum E;
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: EmptyEnumBody
    semicolon: ;
''');
  }

  test_emptyBody_language310() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
enum E;
''');
    parseResult.assertErrors([
      error(diag.experimentNotEnabledOffByDefault, 22, 1),
    ]);

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: EmptyEnumBody
    semicolon: ;
''');
  }

  test_field_augment() {
    var parseResult = parseStringWithErrors(r'''
augment enum E {;
  augment int x = 0;
}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumBody
    leftBracket: {
    semicolon: ;
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
augment enum E {;
  augment static int x = 0;
}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumBody
    leftBracket: {
    semicolon: ;
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
augment enum E {;
  augment static final int x = 0;
}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumBody
    leftBracket: {
    semicolon: ;
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
augment enum E {;
  augment int get foo => 0;
}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumBody
    leftBracket: {
    semicolon: ;
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
augment enum E {;
  augment static int get foo => 0;
}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumBody
    leftBracket: {
    semicolon: ;
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
augment enum E {;
  augment void foo() {}
}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumBody
    leftBracket: {
    semicolon: ;
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
augment enum E {;
  augment static void foo() {}
}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumBody
    leftBracket: {
    semicolon: ;
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
augment enum E<T> {}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
      rightBracket: >
  body: BlockEnumBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_nameWithTypeParameters_hasTypeParameters() {
    var parseResult = parseStringWithErrors(r'''
enum E<T, U> {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
        TypeParameter
          name: U
      rightBracket: >
  body: BlockEnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');
  }

  test_nameWithTypeParameters_noTypeParameters() {
    var parseResult = parseStringWithErrors(r'''
enum E {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
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

  test_operator_augment() {
    var parseResult = parseStringWithErrors(r'''
augment enum E {;
  augment int operator+(int other) => 0;
}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumBody
    leftBracket: {
    semicolon: ;
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

  test_primaryConstructor_const_hasTypeParameters_named() {
    var parseResult = parseStringWithErrors(r'''
enum const E<T, U>.named() {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: E
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
        TypeParameter
          name: U
      rightBracket: >
    constructorName: PrimaryConstructorName
      period: .
      name: named
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  body: BlockEnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');
  }

  test_primaryConstructor_const_hasTypeParameters_unnamed() {
    var parseResult = parseStringWithErrors(r'''
enum const E<T, U>() {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: E
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
        TypeParameter
          name: U
      rightBracket: >
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  body: BlockEnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');
  }

  test_primaryConstructor_const_noTypeParameters_named() {
    var parseResult = parseStringWithErrors(r'''
enum const E.named() {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: E
    constructorName: PrimaryConstructorName
      period: .
      name: named
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  body: BlockEnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');
  }

  test_primaryConstructor_const_noTypeParameters_unnamed() {
    var parseResult = parseStringWithErrors(r'''
enum const E() {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: E
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  body: BlockEnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');
  }

  test_primaryConstructor_const_typeName_noFormalParameters() {
    var parseResult = parseStringWithErrors(r'''
enum const E {v}
''');
    parseResult.assertErrors([
      error(diag.constWithoutPrimaryConstructor, 5, 5),
    ]);

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
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

  test_primaryConstructor_declaringFormalParameter_default_namedRequired_final() {
    var parseResult = parseStringWithErrors(r'''
enum const E({required final int a = 0}) {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: E
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: RegularFormalParameter
        requiredKeyword: required
        constFinalOrVarKeyword: final
        type: NamedType
          name: int
        name: a
        defaultClause: FormalParameterDefaultClause
          separator: =
          value: IntegerLiteral
            literal: 0
      rightDelimiter: }
      rightParenthesis: )
  body: BlockEnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_default_namedRequired_final_documentationComment() {
    var parseResult = parseStringWithErrors(r'''
enum const E({
  /// aaa
  required final int a = 0,
}) {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: E
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: RegularFormalParameter
        documentationComment: Comment
          tokens
            /// aaa
        requiredKeyword: required
        constFinalOrVarKeyword: final
        type: NamedType
          name: int
        name: a
        defaultClause: FormalParameterDefaultClause
          separator: =
          value: IntegerLiteral
            literal: 0
      rightDelimiter: }
      rightParenthesis: )
  body: BlockEnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_functionTyped_final_documentationComment() {
    var parseResult = parseStringWithErrors(r'''
enum const E(
  /// aaa
  final int a(String x)
) {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: E
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        documentationComment: Comment
          tokens
            /// aaa
        constFinalOrVarKeyword: final
        type: NamedType
          name: int
        name: a
        functionTypedSuffix: FunctionTypedFormalParameterSuffix
          formalParameters: FormalParameterList
            leftParenthesis: (
            parameter: RegularFormalParameter
              type: NamedType
                name: String
              name: x
            rightParenthesis: )
      rightParenthesis: )
  body: BlockEnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_simple_final() {
    var parseResult = parseStringWithErrors(r'''
enum const E(final int a) {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: E
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        constFinalOrVarKeyword: final
        type: NamedType
          name: int
        name: a
      rightParenthesis: )
  body: BlockEnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_simple_final_documentationComment() {
    var parseResult = parseStringWithErrors(r'''
enum const E(
  /// aaa
  final int a
) {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: E
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        documentationComment: Comment
          tokens
            /// aaa
        constFinalOrVarKeyword: final
        type: NamedType
          name: int
        name: a
      rightParenthesis: )
  body: BlockEnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_keyword_covariant() {
    var parseResult = parseStringWithErrors(r'''
enum A(covariant int it) { a(0) }
''');
    parseResult.assertErrors([
      error(diag.invalidCovariantModifierInPrimaryConstructor, 7, 9),
    ]);

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        covariantKeyword: covariant
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockEnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: a
        arguments: EnumConstantArguments
          argumentList: ArgumentList
            leftParenthesis: (
            arguments
              IntegerLiteral
                literal: 0
            rightParenthesis: )
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_keyword_covariant_final() {
    var parseResult = parseStringWithErrors(r'''
enum A(covariant final int it) { a(0) }
''');
    parseResult.assertErrors([
      error(diag.invalidCovariantModifierInPrimaryConstructor, 7, 9),
    ]);

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        covariantKeyword: covariant
        constFinalOrVarKeyword: final
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockEnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: a
        arguments: EnumConstantArguments
          argumentList: ArgumentList
            leftParenthesis: (
            arguments
              IntegerLiteral
                literal: 0
            rightParenthesis: )
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_keyword_covariant_var() {
    var parseResult = parseStringWithErrors(r'''
enum A(covariant var int it) { a(0) }
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        covariantKeyword: covariant
        constFinalOrVarKeyword: var
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockEnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: a
        arguments: EnumConstantArguments
          argumentList: ArgumentList
            leftParenthesis: (
            arguments
              IntegerLiteral
                literal: 0
            rightParenthesis: )
    rightBracket: }
''');
  }

  test_primaryConstructor_notConst_hasTypeParameters_named() {
    var parseResult = parseStringWithErrors(r'''
enum E<T, U>.named() {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: E
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
        TypeParameter
          name: U
      rightBracket: >
    constructorName: PrimaryConstructorName
      period: .
      name: named
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  body: BlockEnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');
  }

  test_primaryConstructor_notConst_hasTypeParameters_unnamed() {
    var parseResult = parseStringWithErrors(r'''
enum E<T, U>() {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: E
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
        TypeParameter
          name: U
      rightBracket: >
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  body: BlockEnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');
  }

  test_primaryConstructor_notConst_noTypeParameters_named() {
    var parseResult = parseStringWithErrors(r'''
enum E.named() {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: E
    constructorName: PrimaryConstructorName
      period: .
      name: named
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  body: BlockEnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');
  }

  test_primaryConstructor_notConst_noTypeParameters_unnamed() {
    var parseResult = parseStringWithErrors(r'''
enum E() {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: E
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  body: BlockEnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');
  }

  test_primaryConstructorBody() {
    var parseResult = parseStringWithErrors(r'''
enum E() {
  v;
  this;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singlePrimaryConstructorBody;
    assertParsedNodeText(node, r'''
PrimaryConstructorBody
  thisKeyword: this
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_setter_augment() {
    var parseResult = parseStringWithErrors(r'''
augment enum E {;
  augment set foo(int x) {}
}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumBody
    leftBracket: {
    semicolon: ;
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
augment enum E {;
  augment static set foo(int x) {}
}
''');
    parseResult.assertNoErrors();
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumBody
    leftBracket: {
    semicolon: ;
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
