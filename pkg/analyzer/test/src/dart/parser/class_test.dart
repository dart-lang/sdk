// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassDeclarationParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ClassDeclarationParserTest extends ParserDiagnosticsTest {
  test_body_empty() {
    var parseResult = parseStringWithErrors(r'''
class A;
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: EmptyClassBody
    semicolon: ;
''');
  }

  test_constructor_factory_typeName_named() {
    var parseResult = parseStringWithErrors(r'''
class A {
  factory A.named() {}
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: A
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

  test_constructor_factory_typeName_named_withoutPrimaryConstructors() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
class A {
  factory A.named() {}
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: A
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

  test_constructor_factory_typeName_unnamed() {
    var parseResult = parseStringWithErrors(r'''
class A {
  factory A() {}
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_constructor_factory_typeName_unnamed_withoutPrimaryConstructors() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
class A {
  factory A() {}
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_constructor_factory_typeName_unnamed_withoutPrimaryConstructors_notEnclosingClass() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
class A {
  factory B() {}
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: B
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_constructor_factoryHead_named() {
    var parseResult = parseStringWithErrors(r'''
class A {
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
class A {
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
class A {
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
class A {
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
class A {
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

  test_constructor_newHead_named_blockBody() {
    var parseResult = parseStringWithErrors(r'''
class A {
  new named() {}
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
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_constructor_newHead_named_const() {
    var parseResult = parseStringWithErrors(r'''
class A {
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

  test_constructor_newHead_named_fieldInitializer() {
    var parseResult = parseStringWithErrors(r'''
class A {
  new named() : x = 0;
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
  separator: :
  initializers
    ConstructorFieldInitializer
      fieldName: SimpleIdentifier
        token: x
      equals: =
      expression: IntegerLiteral
        literal: 0
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_newHead_unnamed() {
    var parseResult = parseStringWithErrors(r'''
class A {
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

  test_constructor_newHead_unnamed_blockBody() {
    var parseResult = parseStringWithErrors(r'''
class A {
  new () {}
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
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_constructor_newHead_unnamed_const() {
    var parseResult = parseStringWithErrors(r'''
class A {
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

  test_constructor_newHead_unnamed_fieldInitializer() {
    var parseResult = parseStringWithErrors(r'''
class A {
  new () : x = 0;
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
  separator: :
  initializers
    ConstructorFieldInitializer
      fieldName: SimpleIdentifier
        token: x
      equals: =
      expression: IntegerLiteral
        literal: 0
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_newHead_unnamed_formalParameters() {
    var parseResult = parseStringWithErrors(r'''
class A {
  new (int x, {required String y});
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  newKeyword: new
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: int
      name: x
    leftDelimiter: {
    parameter: DefaultFormalParameter
      parameter: SimpleFormalParameter
        requiredKeyword: required
        type: NamedType
          name: String
        name: y
    rightDelimiter: }
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_notFactory_typeName_named() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A.named();
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  period: .
  name: named
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_notFactory_typeName_named_missingName() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A.();
}
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 14, 1)]);

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  period: .
  name: <empty> <synthetic>
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_notFactory_typeName_unnamed() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A();
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_typeName_augment_named() {
    var parseResult = parseStringWithErrors(r'''
augment class A {
  augment A.named();
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  augmentKeyword: augment
  typeName: SimpleIdentifier
    token: A
  period: .
  name: named
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_typeName_external_fieldFormalParameter_optionalPositional() {
    var parseResult = parseStringWithErrors(r'''
class A {
  final int f;
  external A([this.f = 0]);
}
''');
    parseResult.assertErrors([
      error(diag.externalConstructorWithFieldInitializers, 39, 4),
    ]);

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  externalKeyword: external
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: [
    parameter: DefaultFormalParameter
      parameter: FieldFormalParameter
        thisKeyword: this
        period: .
        name: f
      separator: =
      defaultValue: IntegerLiteral
        literal: 0
    rightDelimiter: ]
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_typeName_external_fieldFormalParameter_requiredPositional() {
    var parseResult = parseStringWithErrors(r'''
class A {
  final int f;
  external A(this.f);
}
''');
    parseResult.assertErrors([
      error(diag.externalConstructorWithFieldInitializers, 38, 4),
    ]);

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  externalKeyword: external
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: FieldFormalParameter
      thisKeyword: this
      period: .
      name: f
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_typeName_external_fieldInitializer() {
    var parseResult = parseStringWithErrors(r'''
class A {
  final int f;
  external A() : f = 0;
}
''');
    parseResult.assertErrors([
      error(diag.externalConstructorWithInitializer, 40, 1),
    ]);

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  externalKeyword: external
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: :
  initializers
    ConstructorFieldInitializer
      fieldName: SimpleIdentifier
        token: f
      equals: =
      expression: IntegerLiteral
        literal: 0
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_typeName_formalParameter_functionTyped_const() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(const int a(String x));
}
''');
    parseResult.assertErrors([
      error(diag.extraneousModifier, 14, 5),
      error(diag.functionTypedParameterVar, 14, 5),
    ]);

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: FunctionTypedFormalParameter
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
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_typeName_formalParameter_functionTyped_final() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(final int a(String x));
}
''');
    parseResult.assertErrors([error(diag.functionTypedParameterVar, 14, 5)]);

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: FunctionTypedFormalParameter
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
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_typeName_formalParameter_simple_const() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(const int a);
}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 14, 5)]);

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      keyword: const
      type: NamedType
        name: int
      name: a
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_typeName_formalParameter_simple_final() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(final int a);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      keyword: final
      type: NamedType
        name: int
      name: a
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_nameWithTypeParameters_hasTypeParameters() {
    var parseResult = parseStringWithErrors(r'''
class A<T, U> {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
        TypeParameter
          name: U
      rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_nameWithTypeParameters_noTypeParameters() {
    var parseResult = parseStringWithErrors(r'''
class A {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_const_hasTypeParameters_named() {
    var parseResult = parseStringWithErrors(r'''
class const A<T, U>.named() {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: A
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
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_const_hasTypeParameters_unnamed() {
    var parseResult = parseStringWithErrors(r'''
class const A<T, U>() {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: A
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
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_const_namedMixinApplication() {
    var parseResult = parseStringWithErrors(r'''
mixin M {}
class const C = Object with M;
''');
    parseResult.assertErrors([
      error(diag.constWithoutPrimaryConstructor, 17, 5),
    ]);
  }

  test_primaryConstructor_const_noTypeParameters_named() {
    var parseResult = parseStringWithErrors(r'''
class const A.named() {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: A
    constructorName: PrimaryConstructorName
      period: .
      name: named
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_const_noTypeParameters_unnamed() {
    var parseResult = parseStringWithErrors(r'''
class const A() {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_const_typeName_noFormalParameters() {
    var parseResult = parseStringWithErrors(r'''
class const A {}
''');
    parseResult.assertErrors([
      error(diag.constWithoutPrimaryConstructor, 6, 5),
    ]);

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_const_typeName_periodName_noFormalParameters() {
    var parseResult = parseStringWithErrors(r'''
class const A.named {}
''');
    // TODO(scheglov): this is wrong.
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: A
    constructorName: PrimaryConstructorName
      period: .
      name: named
    formalParameters: FormalParameterList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_default_namedOptional_final() {
    var parseResult = parseStringWithErrors(r'''
class A({final int a = 0}) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          keyword: final
          type: NamedType
            name: int
          name: a
        separator: =
        defaultValue: IntegerLiteral
          literal: 0
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_default_namedOptional_var() {
    var parseResult = parseStringWithErrors(r'''
class A({var int a = 0}) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          keyword: var
          type: NamedType
            name: int
          name: a
        separator: =
        defaultValue: IntegerLiteral
          literal: 0
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_default_namedRequired_final() {
    var parseResult = parseStringWithErrors(r'''
class A({required final int a = 0}) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
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
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_default_namedRequired_var() {
    var parseResult = parseStringWithErrors(r'''
class A({required var int a = 0}) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          requiredKeyword: required
          keyword: var
          type: NamedType
            name: int
          name: a
        separator: =
        defaultValue: IntegerLiteral
          literal: 0
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_default_positional_final() {
    var parseResult = parseStringWithErrors(r'''
class A([final int a = 0]) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: [
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          keyword: final
          type: NamedType
            name: int
          name: a
        separator: =
        defaultValue: IntegerLiteral
          literal: 0
      rightDelimiter: ]
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_default_positional_var() {
    var parseResult = parseStringWithErrors(r'''
class A([var int a = 0]) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: [
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          keyword: var
          type: NamedType
            name: int
          name: a
        separator: =
        defaultValue: IntegerLiteral
          literal: 0
      rightDelimiter: ]
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_functionTyped_const() {
    var parseResult = parseStringWithErrors(r'''
class A(const int a(String x)) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 8, 5)]);

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: FunctionTypedFormalParameter
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
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_functionTyped_final() {
    var parseResult = parseStringWithErrors(r'''
class A(final int a(String x)) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: FunctionTypedFormalParameter
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
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_functionTyped_var() {
    var parseResult = parseStringWithErrors(r'''
class A(var int a(String x)) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: FunctionTypedFormalParameter
        keyword: var
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
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_simple_const() {
    var parseResult = parseStringWithErrors(r'''
class A(const int a) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 8, 5)]);

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        keyword: const
        type: NamedType
          name: int
        name: a
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_simple_final() {
    var parseResult = parseStringWithErrors(r'''
class A(final int a) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        keyword: final
        type: NamedType
          name: int
        name: a
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_simple_var() {
    var parseResult = parseStringWithErrors(r'''
class A(var int a) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        keyword: var
        type: NamedType
          name: int
        name: a
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_fieldFormalParameter_final() {
    var parseResult = parseStringWithErrors(r'''
class A(final int this.a) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: FieldFormalParameter
        keyword: final
        type: NamedType
          name: int
        thisKeyword: this
        period: .
        name: a
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_fieldFormalParameter_var() {
    var parseResult = parseStringWithErrors(r'''
class A(var int this.a) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: FieldFormalParameter
        keyword: var
        type: NamedType
          name: int
        thisKeyword: this
        period: .
        name: a
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_notConst_hasTypeParameters_named() {
    var parseResult = parseStringWithErrors(r'''
class A<T, U>.named() {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
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
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_notConst_hasTypeParameters_unnamed() {
    var parseResult = parseStringWithErrors(r'''
class A<T, U>() {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
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
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_notConst_noTypeParameters_named() {
    var parseResult = parseStringWithErrors(r'''
class A.named() {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    constructorName: PrimaryConstructorName
      period: .
      name: named
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_notConst_noTypeParameters_unnamed() {
    var parseResult = parseStringWithErrors(r'''
class A() {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_superFormalParameter_final_namedType() {
    var parseResult = parseStringWithErrors(r'''
class A(final int super.a) {}
''');
    // TODO(scheglov): this is wrong.
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SuperFormalParameter
        keyword: final
        type: NamedType
          name: int
        superKeyword: super
        period: .
        name: a
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_superFormalParameter_var_namedType() {
    var parseResult = parseStringWithErrors(r'''
class A(var int super.a) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 8, 3)]);

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SuperFormalParameter
        keyword: var
        type: NamedType
          name: int
        superKeyword: super
        period: .
        name: a
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructorBody_body_blockFunctionBody() {
    var parseResult = parseStringWithErrors(r'''
class A() {
  this {
    0;
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singlePrimaryConstructorBody;
    assertParsedNodeText(node, r'''
PrimaryConstructorBody
  thisKeyword: this
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      statements
        ExpressionStatement
          expression: IntegerLiteral
            literal: 0
          semicolon: ;
      rightBracket: }
''');
  }

  test_primaryConstructorBody_comment() {
    var parseResult = parseStringWithErrors(r'''
class A() {
  /// foo
  /// bar
  this;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singlePrimaryConstructorBody;
    assertParsedNodeText(node, r'''
PrimaryConstructorBody
  documentationComment: Comment
    tokens
      /// foo
      /// bar
  thisKeyword: this
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_primaryConstructorBody_fieldInitializer() {
    var parseResult = parseStringWithErrors(r'''
class A() {
  final int x;
  this : x = 0;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singlePrimaryConstructorBody;
    assertParsedNodeText(node, r'''
PrimaryConstructorBody
  thisKeyword: this
  colon: :
  initializers
    ConstructorFieldInitializer
      fieldName: SimpleIdentifier
        token: x
      equals: =
      expression: IntegerLiteral
        literal: 0
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_primaryConstructorBody_metadata() {
    var parseResult = parseStringWithErrors(r'''
class A() {
  @deprecated
  this;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singlePrimaryConstructorBody;
    assertParsedNodeText(node, r'''
PrimaryConstructorBody
  metadata
    Annotation
      atSign: @
      name: SimpleIdentifier
        token: deprecated
  thisKeyword: this
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_setter_formalParameters_absent() {
    var parseResult = parseStringWithErrors(r'''
class A {
  set foo {}
}
''');
    parseResult.assertErrors([error(diag.missingMethodParameters, 16, 3)]);

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, withOffsets: true, r'''
MethodDeclaration
  propertyKeyword: set @12
  name: foo @16
  parameters: FormalParameterList
    leftParenthesis: ( @20 <synthetic>
    parameter: SimpleFormalParameter
      name: <empty> @20 <synthetic>
    rightParenthesis: ) @20 <synthetic>
  body: BlockFunctionBody
    block: Block
      leftBracket: { @20
      rightBracket: } @21
''');
  }

  test_setter_formalParameters_optionalNamed() {
    var parseResult = parseStringWithErrors(r'''
class A {
  set foo({a}) {}
}
''');
    parseResult.assertErrors([
      error(diag.wrongNumberOfParametersForSetter, 16, 3),
    ]);

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, withOffsets: true, r'''
MethodDeclaration
  propertyKeyword: set @12
  name: foo @16
  parameters: FormalParameterList
    leftParenthesis: ( @19
    parameter: SimpleFormalParameter
      name: a @21
    rightParenthesis: ) @23
  body: BlockFunctionBody
    block: Block
      leftBracket: { @25
      rightBracket: } @26
''');
  }

  test_setter_formalParameters_optionalPositional() {
    var parseResult = parseStringWithErrors(r'''
class A {
  set foo([a]) {}
}
''');
    parseResult.assertErrors([
      error(diag.wrongNumberOfParametersForSetter, 16, 3),
    ]);

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, withOffsets: true, r'''
MethodDeclaration
  propertyKeyword: set @12
  name: foo @16
  parameters: FormalParameterList
    leftParenthesis: ( @19
    parameter: SimpleFormalParameter
      name: a @21
    rightParenthesis: ) @23
  body: BlockFunctionBody
    block: Block
      leftBracket: { @25
      rightBracket: } @26
''');
  }

  test_setter_formalParameters_requiredPositional_three() {
    var parseResult = parseStringWithErrors(r'''
class A {
  set foo(a, b, c) {}
}
''');
    parseResult.assertErrors([
      error(diag.wrongNumberOfParametersForSetter, 16, 3),
    ]);

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, withOffsets: true, r'''
MethodDeclaration
  propertyKeyword: set @12
  name: foo @16
  parameters: FormalParameterList
    leftParenthesis: ( @19
    parameter: SimpleFormalParameter
      name: a @20
    rightParenthesis: ) @27
  body: BlockFunctionBody
    block: Block
      leftBracket: { @29
      rightBracket: } @30
''');
  }

  test_setter_formalParameters_zero() {
    var parseResult = parseStringWithErrors(r'''
class A {
  set foo() {}
}
''');
    parseResult.assertErrors([
      error(diag.wrongNumberOfParametersForSetter, 16, 3),
    ]);

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, withOffsets: true, r'''
MethodDeclaration
  propertyKeyword: set @12
  name: foo @16
  parameters: FormalParameterList
    leftParenthesis: ( @19
    parameter: SimpleFormalParameter
      name: <empty> @20 <synthetic>
    rightParenthesis: ) @20
  body: BlockFunctionBody
    block: Block
      leftBracket: { @22
      rightBracket: } @23
''');
  }
}
