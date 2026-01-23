// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumDeclarationParserTest);
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
  body: EnumBody
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
  body: EnumBody
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
  body: EnumBody
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
  body: EnumBody
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

  test_declaration_empty() {
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
  body: EnumBody
    leftBracket: {
    rightBracket: }
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
  body: EnumBody
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
  body: EnumBody
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
  body: EnumBody
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
  body: EnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
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
  body: EnumBody
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
  body: EnumBody
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
  body: EnumBody
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
  body: EnumBody
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
  body: EnumBody
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
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          requiredKeyword: required
          keyword: final
          type: NamedType
            name: int
          name: a
        separator: =
        defaultValue: IntegerLiteral
          literal: 0
      rightDelimiter: }
      rightParenthesis: )
  body: EnumBody
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
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          documentationComment: Comment
            tokens
              /// aaa
          requiredKeyword: required
          keyword: final
          type: NamedType
            name: int
          name: a
        separator: =
        defaultValue: IntegerLiteral
          literal: 0
      rightDelimiter: }
      rightParenthesis: )
  body: EnumBody
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
      parameter: FunctionTypedFormalParameter
        documentationComment: Comment
          tokens
            /// aaa
        keyword: final
        returnType: NamedType
          name: int
        name: a
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            type: NamedType
              name: String
            name: x
          rightParenthesis: )
      rightParenthesis: )
  body: EnumBody
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
      parameter: SimpleFormalParameter
        keyword: final
        type: NamedType
          name: int
        name: a
      rightParenthesis: )
  body: EnumBody
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
      parameter: SimpleFormalParameter
        documentationComment: Comment
          tokens
            /// aaa
        keyword: final
        type: NamedType
          name: int
        name: a
      rightParenthesis: )
  body: EnumBody
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
      parameter: SimpleFormalParameter
        covariantKeyword: covariant
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: EnumBody
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
      parameter: SimpleFormalParameter
        covariantKeyword: covariant
        keyword: final
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: EnumBody
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
      parameter: SimpleFormalParameter
        covariantKeyword: covariant
        keyword: var
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: EnumBody
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
  body: EnumBody
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
  body: EnumBody
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
  body: EnumBody
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
  body: EnumBody
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
}
