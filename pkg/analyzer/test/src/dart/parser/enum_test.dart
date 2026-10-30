// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  test_augment_blockBody_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment enum E {}
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    rightBracket: }
V1: EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_augment_constant_add() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment enum E {
  v
}
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment enum E {
  augment v
}
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        augmentKeyword: augment
        name: v
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment enum E {
  augment v.foo()
}
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        augmentKeyword: augment
        name: v
        arguments: EnumConstantArguments
          constructorSelector: ConstructorSelector
            period: .
            name2: foo
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
    rightBracket: }
V1: EnumDeclaration
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

  test_augment_emptyBody() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment enum E;
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: SemicolonEnumDeclarationBody
    semicolon: ;
V1: EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: EmptyEnumBody
    semicolon: ;
''');
  }

  test_augment_implementsClause() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment enum E implements B {}
''');
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration2
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  implementsClause: ImplementsClause
    implementsKeyword: implements
    interfaces
      NamedType
        name: B
  body: BlockEnumDeclarationBody
    leftBracket: {
    rightBracket: }
V1: EnumDeclaration
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

  test_augment_noConstants_semicolon() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment enum E {;}
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    membersSeparator: ;
    rightBracket: }
V1: EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumBody
    leftBracket: {
    semicolon: ;
    rightBracket: }
''');
  }

  test_augment_noConstants_semicolon_method() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment enum E {;
  void foo() {}
}
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    membersSeparator: ;
    members
      MethodDeclaration2
        returnType: NamedType
          name: void
        name: foo
        formalParameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment enum E<T extends int> {}
''');
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration2
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
  body: BlockEnumDeclarationBody
    leftBracket: {
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment enum E with M {}
''');
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration2
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  withClause: WithClause
    withKeyword: with
    mixinTypes
      NamedType
        name: M
  body: BlockEnumDeclarationBody
    leftBracket: {
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {}
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    rightBracket: }
V1: EnumDeclaration
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_constant_name_dot() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v.
}
// [diag.missingIdentifier][column 1][length 1] Expected an identifier.
// [diag.expectedToken][column 1][length 1] Expected to find '('.
''');

    var node = parseResult.findNode.enumConstantDeclaration('v.');
    assertParsedNodeText(node, r'''
EnumConstantDeclaration2
  name: v
  arguments: EnumConstantArguments
    constructorSelector: ConstructorSelector
      period: .
      name2: <empty> <synthetic>
    argumentList: ArgumentList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
V1: EnumConstantDeclaration
  name: v
  arguments: EnumConstantArguments
    constructorSelector: ConstructorSelector
      period: .
      name: SimpleIdentifier
        token: <empty> <synthetic>
    argumentList: ArgumentList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
''');
  }

  void test_constant_name_dot_identifier_semicolon() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v.named;
//  ^^^^^
// [diag.expectedToken] Expected to find '('.
}
''');

    var node = parseResult.findNode.enumConstantDeclaration('v.');
    assertParsedNodeText(node, r'''
EnumConstantDeclaration2
  name: v
  arguments: EnumConstantArguments
    constructorSelector: ConstructorSelector
      period: .
      name2: named
    argumentList: ArgumentList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
V1: EnumConstantDeclaration
  name: v
  arguments: EnumConstantArguments
    constructorSelector: ConstructorSelector
      period: .
      name: SimpleIdentifier
        token: named
    argumentList: ArgumentList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
''');
  }

  void test_constant_name_dot_semicolon() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v.;
//  ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find '('.
}
''');

    var node = parseResult.findNode.enumConstantDeclaration('v.');
    assertParsedNodeText(node, r'''
EnumConstantDeclaration2
  name: v
  arguments: EnumConstantArguments
    constructorSelector: ConstructorSelector
      period: .
      name2: <empty> <synthetic>
    argumentList: ArgumentList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
V1: EnumConstantDeclaration
  name: v
  arguments: EnumConstantArguments
    constructorSelector: ConstructorSelector
      period: .
      name: SimpleIdentifier
        token: <empty> <synthetic>
    argumentList: ArgumentList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
''');
  }

  void test_constant_name_typeArguments_dot() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v<int>.
}
// [diag.missingIdentifier][column 1][length 1] Expected an identifier.
// [diag.expectedToken][column 1][length 1] Expected to find '('.
''');

    var node = parseResult.findNode.enumConstantDeclaration('v<int>.');
    assertParsedNodeText(node, r'''
EnumConstantDeclaration2
  name: v
  arguments: EnumConstantArguments
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
      rightBracket: >
    constructorSelector: ConstructorSelector
      period: .
      name2: <empty> <synthetic>
    argumentList: ArgumentList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
V1: EnumConstantDeclaration
  name: v
  arguments: EnumConstantArguments
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
      rightBracket: >
    constructorSelector: ConstructorSelector
      period: .
      name: SimpleIdentifier
        token: <empty> <synthetic>
    argumentList: ArgumentList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
''');
  }

  void test_constant_name_typeArguments_dot_semicolon() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v<int>.;
//       ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find '('.
}
''');

    var node = parseResult.findNode.enumConstantDeclaration('v<int>');
    assertParsedNodeText(node, r'''
EnumConstantDeclaration2
  name: v
  arguments: EnumConstantArguments
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
      rightBracket: >
    constructorSelector: ConstructorSelector
      period: .
      name2: <empty> <synthetic>
    argumentList: ArgumentList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
V1: EnumConstantDeclaration
  name: v
  arguments: EnumConstantArguments
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
      rightBracket: >
    constructorSelector: ConstructorSelector
      period: .
      name: SimpleIdentifier
        token: <empty> <synthetic>
    argumentList: ArgumentList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
''');
  }

  void test_constant_withoutSemicolon() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v
}
''');

    var node = parseResult.findNode.enumDeclaration('enum E');
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    rightBracket: }
V1: EnumDeclaration
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

  void test_constant_withSemicolon() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v;
}
''');

    var node = parseResult.findNode.enumDeclaration('enum E');
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    membersSeparator: ;
    rightBracket: }
V1: EnumDeclaration
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    semicolon: ;
    rightBracket: }
''');
  }

  void test_constant_withTypeArgumentsWithoutArguments() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E<T> {
  v<int>;
//     ^
// [diag.expectedToken] Expected to find '('.
}
''');

    var node = parseResult.findNode.enumConstantDeclaration('v<int>');
    assertParsedNodeText(node, r'''
EnumConstantDeclaration2
  name: v
  arguments: EnumConstantArguments
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
V1: EnumConstantDeclaration
  name: v
  arguments: EnumConstantArguments
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
''');
  }

  test_constructor_factoryHead_named() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v;
  factory named() {}
}
''');

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration2
  factoryKeyword: factory
  name: named
  formalParameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
V1: ConstructorDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v;
  const factory named() = B;
}
''');

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration2
  constKeyword: const
  factoryKeyword: factory
  name: named
  formalParameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: =
  factoryRedirectionTarget: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: B
  body: EmptyFunctionBody
    semicolon: ;
V1: ConstructorDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v;
  factory () {}
}
''');

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration2
  factoryKeyword: factory
  formalParameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
V1: ConstructorDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v;
  const factory () = B;
}
''');

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration2
  constKeyword: const
  factoryKeyword: factory
  formalParameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: =
  factoryRedirectionTarget: ConstructorReference2
    typeReference: ConstructorTypeReference
      name: B
  body: EmptyFunctionBody
    semicolon: ;
V1: ConstructorDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v;
  new named();
}
''');

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration2
  newKeyword: new
  name: named
  formalParameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
V1: ConstructorDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v;
  const new named();
}
''');

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration2
  constKeyword: const
  newKeyword: new
  name: named
  formalParameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
V1: ConstructorDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v;
  new ();
}
''');

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration2
  newKeyword: new
  formalParameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
V1: ConstructorDeclaration
  newKeyword: new
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_newHead_unnamed_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v;
  const new ();
}
''');

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration2
  constKeyword: const
  newKeyword: new
  formalParameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
V1: ConstructorDeclaration
  constKeyword: const
  newKeyword: new
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_typeName_augment_factory_unnamed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment enum E {
  v;
  augment factory E() {}
}
''');

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration2
  augmentKeyword: augment
  factoryKeyword: factory
  typeName: E
  formalParameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
V1: ConstructorDeclaration
  augmentKeyword: augment
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

  test_constructor_typeName_factory_named() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v;
  factory E.named() {}
}
''');

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration2
  factoryKeyword: factory
  typeName: E
  period: .
  name: named
  formalParameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
V1: ConstructorDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v;
  factory E() {}
}
''');

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration2
  factoryKeyword: factory
  typeName: E
  formalParameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
V1: ConstructorDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v;
  E.named();
}
''');

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration2
  typeName: E
  period: .
  name: named
  formalParameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
V1: ConstructorDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v;
  E();
}
''');

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration2
  typeName: E
  formalParameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
V1: ConstructorDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {;}
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    membersSeparator: ;
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {;
  void foo() {}
}
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    membersSeparator: ;
    members
      MethodDeclaration2
        returnType: NamedType
          name: void
        name: foo
        formalParameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E;
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: SemicolonEnumDeclarationBody
    semicolon: ;
V1: EnumDeclaration
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: EmptyEnumBody
    semicolon: ;
''');
  }

  test_emptyBody_beforePrimaryConstructors() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// %before-language-feature: primary-constructors
enum E;
//    ^
// [diag.experimentNotEnabled] This requires the 'primary-constructors' language feature to be enabled.
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: SemicolonEnumDeclarationBody
    semicolon: ;
V1: EnumDeclaration
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: EmptyEnumBody
    semicolon: ;
''');
  }

  test_field_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment enum E {;
  augment int x = 0;
}
''');
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration2
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    membersSeparator: ;
    members
      FieldsDeclaration
        augmentKeyword: augment
        type: NamedType
          name: int
        fields
          Field
            name: x
            equals: =
            initializer: IntegerLiteral
              literal: 0
        semicolon: ;
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment enum E {;
  augment static int x = 0;
}
''');
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration2
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    membersSeparator: ;
    members
      FieldsDeclaration
        augmentKeyword: augment
        staticKeyword: static
        type: NamedType
          name: int
        fields
          Field
            name: x
            equals: =
            initializer: IntegerLiteral
              literal: 0
        semicolon: ;
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment enum E {;
  augment static final int x = 0;
}
''');
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration2
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    membersSeparator: ;
    members
      FieldsDeclaration
        augmentKeyword: augment
        staticKeyword: static
        constFinalOrVarKeyword: final
        type: NamedType
          name: int
        fields
          Field
            name: x
            equals: =
            initializer: IntegerLiteral
              literal: 0
        semicolon: ;
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment enum E {;
  augment int get foo => 0;
}
''');
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration2
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    membersSeparator: ;
    members
      GetterDeclaration
        augmentKeyword: augment
        returnType: NamedType
          name: int
        getKeyword: get
        name: foo
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression2: IntegerLiteral
            literal: 0
          semicolon: ;
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment enum E {;
  augment static int get foo => 0;
}
''');
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration2
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    membersSeparator: ;
    members
      GetterDeclaration
        augmentKeyword: augment
        staticKeyword: static
        returnType: NamedType
          name: int
        getKeyword: get
        name: foo
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression2: IntegerLiteral
            literal: 0
          semicolon: ;
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment enum E {;
  augment void foo() {}
}
''');
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration2
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    membersSeparator: ;
    members
      MethodDeclaration2
        augmentKeyword: augment
        returnType: NamedType
          name: void
        name: foo
        formalParameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment enum E {;
  augment static void foo() {}
}
''');
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration2
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    membersSeparator: ;
    members
      MethodDeclaration2
        augmentKeyword: augment
        staticKeyword: static
        returnType: NamedType
          name: void
        name: foo
        formalParameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
V1: EnumDeclaration
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

  void test_modifiers_base() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
base enum E { v }
// [diag.baseEnum][column 1][length 4] Enums can't be declared to be 'base'.
''');

    var node = parseResult.findNode.enumDeclaration('enum E');
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    rightBracket: }
V1: EnumDeclaration
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

  void test_modifiers_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final enum E { v }
// [diag.finalEnum][column 1][length 5] Enums can't be declared to be 'final'.
''');

    var node = parseResult.findNode.enumDeclaration('enum E');
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    rightBracket: }
V1: EnumDeclaration
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

  void test_modifiers_interface() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
interface enum E { v }
// [diag.interfaceEnum][column 1][length 9] Enums can't be declared to be 'interface'.
''');

    var node = parseResult.findNode.enumDeclaration('enum E');
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    rightBracket: }
V1: EnumDeclaration
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

  void test_modifiers_sealed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
sealed enum E { v }
// [diag.sealedEnum][column 1][length 6] Enums can't be declared to be 'sealed'.
''');

    var node = parseResult.findNode.enumDeclaration('enum E');
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    rightBracket: }
V1: EnumDeclaration
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

  test_nameWithTypeParameters_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment enum E<T> {}
''');
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration2
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
  body: BlockEnumDeclarationBody
    leftBracket: {
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E<T, U> {v}
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
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
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {v}
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment enum E {;
  augment int operator+(int other) => 0;
}
''');
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration2
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    membersSeparator: ;
    members
      OperatorDeclaration
        augmentKeyword: augment
        returnType: NamedType
          name: int
        operatorKeyword: operator
        operator: +
        formalParameters: FormalParameterList
          leftParenthesis: (
          requiredPositionalFormalParameters
            RegularFormalParameter
              type: NamedType
                name: int
              name: other
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression2: IntegerLiteral
            literal: 0
          semicolon: ;
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum const E<T, U>.named() {v}
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
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
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum const E<T, U>() {v}
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
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
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum const E.named() {v}
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
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
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum const E() {v}
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: E
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum const E {v}
//   ^^^^^
// [diag.constWithoutPrimaryConstructor] 'const' can only be used together with a primary constructor declaration.
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    rightBracket: }
V1: EnumDeclaration
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

  test_primaryConstructor_const_typeName_noFormalParameters_beforePrimaryConstructors() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// %before-language-feature: primary-constructors
enum const E {v}
//   ^^^^^
// [diag.unexpectedToken] Unexpected text 'const'.
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    rightBracket: }
V1: EnumDeclaration
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

  test_primaryConstructor_const_typeName_periodName_noFormalParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum const E.named {v}
//           ^^^^^
// [diag.missingPrimaryConstructorParameters] A primary constructor declaration must have formal parameters.
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum @0
  namePart: PrimaryConstructorDeclaration
    constKeyword: const @5
    typeName: E @11
    constructorName: PrimaryConstructorName
      period: . @12
      name: named @13
    formalParameters: FormalParameterList
      leftParenthesis: ( @19 <synthetic>
      rightParenthesis: ) @19 <synthetic>
  body: BlockEnumDeclarationBody
    leftBracket: { @19
    constants
      EnumConstantDeclaration2
        name: v @20
    rightBracket: } @21
V1: EnumDeclaration
  enumKeyword: enum @0
  namePart: PrimaryConstructorDeclaration
    constKeyword: const @5
    typeName: E @11
    constructorName: PrimaryConstructorName
      period: . @12
      name: named @13
    formalParameters: FormalParameterList
      leftParenthesis: ( @19 <synthetic>
      rightParenthesis: ) @19 <synthetic>
  body: BlockEnumBody
    leftBracket: { @19
    constants
      EnumConstantDeclaration
        name: v @20
    rightBracket: } @21
''', withOffsets: true);
  }

  test_primaryConstructor_declaringFormalParameter_default_namedRequired_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum const E({required final int a = 0}) {v}
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: E
    formalParameters: FormalParameterList
      leftParenthesis: (
      delimitedFormalParameters: DelimitedFormalParameters
        leftDelimiter: {
        formalParameters
          RegularFormalParameter
            requiredKeyword: required
            constFinalOrVarKeyword: final
            type: NamedType
              name: int
            name: a
            defaultClause: FormalParameterDefaultClause
              separator: =
              value2: IntegerLiteral
                literal: 0
        rightDelimiter: }
      rightParenthesis: )
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum const E({
  /// aaa
  required final int a = 0,
}) {v}
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: E
    formalParameters: FormalParameterList
      leftParenthesis: (
      delimitedFormalParameters: DelimitedFormalParameters
        leftDelimiter: {
        formalParameters
          RegularFormalParameter
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
              value2: IntegerLiteral
                literal: 0
        rightDelimiter: }
      rightParenthesis: )
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum const E(
  /// aaa
  final int a(String x)
) {v}
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: E
    formalParameters: FormalParameterList
      leftParenthesis: (
      requiredPositionalFormalParameters
        RegularFormalParameter
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
              requiredPositionalFormalParameters
                RegularFormalParameter
                  type: NamedType
                    name: String
                  name: x
              rightParenthesis: )
      rightParenthesis: )
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum const E(final int a) {v}
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: E
    formalParameters: FormalParameterList
      leftParenthesis: (
      requiredPositionalFormalParameters
        RegularFormalParameter
          constFinalOrVarKeyword: final
          type: NamedType
            name: int
          name: a
      rightParenthesis: )
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum const E(
  /// aaa
  final int a
) {v}
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: E
    formalParameters: FormalParameterList
      leftParenthesis: (
      requiredPositionalFormalParameters
        RegularFormalParameter
          documentationComment: Comment
            tokens
              /// aaa
          constFinalOrVarKeyword: final
          type: NamedType
            name: int
          name: a
      rightParenthesis: )
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum A(covariant int it) { a(0) }
//     ^^^^^^^^^
// [diag.invalidCovariantModifierInPrimaryConstructor] The 'covariant' modifier can only be used on non-final declaring parameters.
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      requiredPositionalFormalParameters
        RegularFormalParameter
          covariantKeyword: covariant
          type: NamedType
            name: int
          name: it
      rightParenthesis: )
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: a
        arguments: EnumConstantArguments
          argumentList: ArgumentList
            leftParenthesis: (
            arguments2
              IntegerLiteral
                literal: 0
            rightParenthesis: )
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum A(covariant final int it) { a(0) }
//     ^^^^^^^^^
// [diag.invalidCovariantModifierInPrimaryConstructor] The 'covariant' modifier can only be used on non-final declaring parameters.
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      requiredPositionalFormalParameters
        RegularFormalParameter
          covariantKeyword: covariant
          constFinalOrVarKeyword: final
          type: NamedType
            name: int
          name: it
      rightParenthesis: )
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: a
        arguments: EnumConstantArguments
          argumentList: ArgumentList
            leftParenthesis: (
            arguments2
              IntegerLiteral
                literal: 0
            rightParenthesis: )
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum A(covariant var int it) { a(0) }
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      requiredPositionalFormalParameters
        RegularFormalParameter
          covariantKeyword: covariant
          constFinalOrVarKeyword: var
          type: NamedType
            name: int
          name: it
      rightParenthesis: )
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: a
        arguments: EnumConstantArguments
          argumentList: ArgumentList
            leftParenthesis: (
            arguments2
              IntegerLiteral
                literal: 0
            rightParenthesis: )
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E<T, U>.named() {v}
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
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
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E<T, U>() {v}
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
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
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E.named() {v}
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: E
    constructorName: PrimaryConstructorName
      period: .
      name: named
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E() {v}
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: E
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  body: BlockEnumDeclarationBody
    leftBracket: {
    constants
      EnumConstantDeclaration2
        name: v
    rightBracket: }
V1: EnumDeclaration
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

  test_primaryConstructor_notConst_typeName_periodName_noFormalParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E.named {v}
//     ^^^^^
// [diag.missingPrimaryConstructorParameters] A primary constructor declaration must have formal parameters.
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum @0
  namePart: PrimaryConstructorDeclaration
    typeName: E @5
    constructorName: PrimaryConstructorName
      period: . @6
      name: named @7
    formalParameters: FormalParameterList
      leftParenthesis: ( @13 <synthetic>
      rightParenthesis: ) @13 <synthetic>
  body: BlockEnumDeclarationBody
    leftBracket: { @13
    constants
      EnumConstantDeclaration2
        name: v @14
    rightBracket: } @15
V1: EnumDeclaration
  enumKeyword: enum @0
  namePart: PrimaryConstructorDeclaration
    typeName: E @5
    constructorName: PrimaryConstructorName
      period: . @6
      name: named @7
    formalParameters: FormalParameterList
      leftParenthesis: ( @13 <synthetic>
      rightParenthesis: ) @13 <synthetic>
  body: BlockEnumBody
    leftBracket: { @13
    constants
      EnumConstantDeclaration
        name: v @14
    rightBracket: } @15
''', withOffsets: true);
  }

  test_primaryConstructor_notConst_typeName_periodName_noFormalParameters_implementsClause() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E.named implements I {v}
//     ^^^^^
// [diag.missingPrimaryConstructorParameters] A primary constructor declaration must have formal parameters.
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum @0
  namePart: PrimaryConstructorDeclaration
    typeName: E @5
    constructorName: PrimaryConstructorName
      period: . @6
      name: named @7
    formalParameters: FormalParameterList
      leftParenthesis: ( @13 <synthetic>
      rightParenthesis: ) @13 <synthetic>
  implementsClause: ImplementsClause
    implementsKeyword: implements @13
    interfaces
      NamedType
        name: I @24
  body: BlockEnumDeclarationBody
    leftBracket: { @26
    constants
      EnumConstantDeclaration2
        name: v @27
    rightBracket: } @28
V1: EnumDeclaration
  enumKeyword: enum @0
  namePart: PrimaryConstructorDeclaration
    typeName: E @5
    constructorName: PrimaryConstructorName
      period: . @6
      name: named @7
    formalParameters: FormalParameterList
      leftParenthesis: ( @13 <synthetic>
      rightParenthesis: ) @13 <synthetic>
  implementsClause: ImplementsClause
    implementsKeyword: implements @13
    interfaces
      NamedType
        name: I @24
  body: BlockEnumBody
    leftBracket: { @26
    constants
      EnumConstantDeclaration
        name: v @27
    rightBracket: } @28
''', withOffsets: true);
  }

  test_primaryConstructor_notConst_typeName_typeParameters_periodName_noFormalParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E<T>.named {v}
//        ^^^^^
// [diag.missingPrimaryConstructorParameters] A primary constructor declaration must have formal parameters.
''');

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration2
  enumKeyword: enum @0
  namePart: PrimaryConstructorDeclaration
    typeName: E @5
    typeParameters: TypeParameterList
      leftBracket: < @6
      typeParameters
        TypeParameter
          name: T @7
      rightBracket: > @8
    constructorName: PrimaryConstructorName
      period: . @9
      name: named @10
    formalParameters: FormalParameterList
      leftParenthesis: ( @16 <synthetic>
      rightParenthesis: ) @16 <synthetic>
  body: BlockEnumDeclarationBody
    leftBracket: { @16
    constants
      EnumConstantDeclaration2
        name: v @17
    rightBracket: } @18
V1: EnumDeclaration
  enumKeyword: enum @0
  namePart: PrimaryConstructorDeclaration
    typeName: E @5
    typeParameters: TypeParameterList
      leftBracket: < @6
      typeParameters
        TypeParameter
          name: T @7
      rightBracket: > @8
    constructorName: PrimaryConstructorName
      period: . @9
      name: named @10
    formalParameters: FormalParameterList
      leftParenthesis: ( @16 <synthetic>
      rightParenthesis: ) @16 <synthetic>
  body: BlockEnumBody
    leftBracket: { @16
    constants
      EnumConstantDeclaration
        name: v @17
    rightBracket: } @18
''', withOffsets: true);
  }

  test_primaryConstructorBody() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E() {
  v;
  this;
}
''');

    var node = parseResult.findNode.singlePrimaryConstructorBody;
    assertParsedNodeText(node, r'''
PrimaryConstructorBody2
  thisKeyword: this
  body: EmptyFunctionBody
    semicolon: ;
V1: PrimaryConstructorBody
  thisKeyword: this
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_setter_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment enum E {;
  augment set foo(int x) {}
}
''');
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration2
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    membersSeparator: ;
    members
      SetterDeclaration
        augmentKeyword: augment
        setKeyword: set
        name: foo
        formalParameters: FormalParameterList
          leftParenthesis: (
          requiredPositionalFormalParameters
            RegularFormalParameter
              type: NamedType
                name: int
              name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
V1: EnumDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment enum E {;
  augment static set foo(int x) {}
}
''');
    assertParsedNodeText(parseResult.findNode.singleEnumDeclaration, r'''
EnumDeclaration2
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockEnumDeclarationBody
    leftBracket: {
    membersSeparator: ;
    members
      SetterDeclaration
        augmentKeyword: augment
        staticKeyword: static
        setKeyword: set
        name: foo
        formalParameters: FormalParameterList
          leftParenthesis: (
          requiredPositionalFormalParameters
            RegularFormalParameter
              type: NamedType
                name: int
              name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
V1: EnumDeclaration
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
