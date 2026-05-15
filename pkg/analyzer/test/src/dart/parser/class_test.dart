// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  test_augment() {
    var parseResult = parseStringWithErrors(r'''
augment class A {}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_augment_abstract() {
    var parseResult = parseStringWithErrors(r'''
augment abstract class A {}
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  augmentKeyword: augment
  abstractKeyword: abstract
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_augment_abstract_base() {
    var parseResult = parseStringWithErrors(r'''
augment abstract base class A {}
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  augmentKeyword: augment
  abstractKeyword: abstract
  baseKeyword: base
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_augment_base() {
    var parseResult = parseStringWithErrors(r'''
augment base class A {}
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  augmentKeyword: augment
  baseKeyword: base
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_augment_extendsClause() {
    var parseResult = parseStringWithErrors(r'''
augment class A extends B {}
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  extendsClause: ExtendsClause
    extendsKeyword: extends
    superclass: NamedType
      name: B
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_augment_final() {
    var parseResult = parseStringWithErrors(r'''
augment final class A {}
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  augmentKeyword: augment
  finalKeyword: final
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_augment_implementsClause() {
    var parseResult = parseStringWithErrors(r'''
augment class A implements B {}
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
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

  test_augment_interface() {
    var parseResult = parseStringWithErrors(r'''
augment interface class A {}
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  augmentKeyword: augment
  interfaceKeyword: interface
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_augment_mixin() {
    var parseResult = parseStringWithErrors(r'''
augment mixin class A {}
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  augmentKeyword: augment
  mixinKeyword: mixin
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_augment_namedMixinApplication() {
    var parseResult = parseStringWithErrors(r'''
augment class A = B with M;
// [diag.mixinApplicationClassAugmentation][column 1][length 7] A mixin application class can't be augmented.
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.unit, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      augmentKeyword: augment
      typedefKeyword: class
      name: A
      equals: =
      superclass: NamedType
        name: B
      withClause: WithClause
        withKeyword: with
        mixinTypes
          NamedType
            name: M
      semicolon: ;
''');
  }

  test_augment_sealed() {
    var parseResult = parseStringWithErrors(r'''
augment sealed class A {}
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  augmentKeyword: augment
  sealedKeyword: sealed
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_augment_typeParameters_withBound() {
    var parseResult = parseStringWithErrors(r'''
augment class A<T extends int> {}
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
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

  test_augment_withClause() {
    var parseResult = parseStringWithErrors(r'''
augment class A with M {}
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  withClause: WithClause
    withKeyword: with
    mixinTypes
      NamedType
        name: M
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_body_empty() {
    var parseResult = parseStringWithErrors(r'''
class A;
''');
    parseResult.assertExpectedDiagnostics();

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

  test_constructor_factoryHead_named() {
    var parseResult = parseStringWithErrors(r'''
class A {
  factory named() {}
}
''');
    parseResult.assertExpectedDiagnostics();

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
    parseResult.assertExpectedDiagnostics();

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

  test_constructor_factoryHead_new() {
    var parseResult = parseStringWithErrors(r'''
class A {
  factory new() {}
//        ^^^
// [diag.factoryConstructorNewName] Factory constructors can't be named 'new'.
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  name: new
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  test_constructor_factoryHead_unnamed() {
    var parseResult = parseStringWithErrors(r'''
class A {
  factory () {}
}
''');
    parseResult.assertExpectedDiagnostics();

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
    parseResult.assertExpectedDiagnostics();

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
    parseResult.assertExpectedDiagnostics();

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
    parseResult.assertExpectedDiagnostics();

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
    parseResult.assertExpectedDiagnostics();

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
    parseResult.assertExpectedDiagnostics();

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

  test_constructor_newHead_new() {
    var parseResult = parseStringWithErrors(r'''
class A {
  new new();
//    ^^^
// [diag.newConstructorNewName] Constructors declared with the 'new' keyword can't be named 'new'.
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  newKeyword: new
  name: new
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
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
    parseResult.assertExpectedDiagnostics();

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
    parseResult.assertExpectedDiagnostics();

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
    parseResult.assertExpectedDiagnostics();

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
    parseResult.assertExpectedDiagnostics();

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
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  newKeyword: new
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: int
      name: x
    leftDelimiter: {
    parameter: RegularFormalParameter
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

  test_constructor_typeName_augment_factory_unnamed() {
    var parseResult = parseStringWithErrors(r'''
augment class A {
  augment factory A() {}
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  augmentKeyword: augment
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

  test_constructor_typeName_augment_named() {
    var parseResult = parseStringWithErrors(r'''
augment class A {
  augment A.named();
}
''');
    parseResult.assertExpectedDiagnostics();

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
//            ^^^^
// [diag.externalConstructorWithFieldInitializers] An external constructor can't initialize fields.
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  externalKeyword: external
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: [
    parameter: FieldFormalParameter
      thisKeyword: this
      period: .
      name: f
      defaultClause: FormalParameterDefaultClause
        separator: =
        value: IntegerLiteral
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
//           ^^^^
// [diag.externalConstructorWithFieldInitializers] An external constructor can't initialize fields.
}
''');
    parseResult.assertExpectedDiagnostics();

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
//             ^
// [diag.externalConstructorWithInitializer] An external constructor can't have any initializers.
}
''');
    parseResult.assertExpectedDiagnostics();

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

  test_constructor_typeName_factory_named() {
    var parseResult = parseStringWithErrors(r'''
class A {
  factory A.named() {}
}
''');
    parseResult.assertExpectedDiagnostics();

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

  test_constructor_typeName_factory_named_withoutPrimaryConstructors() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
class A {
  factory A.named() {}
}
''');
    parseResult.assertExpectedDiagnostics();

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

  test_constructor_typeName_factory_unnamed() {
    var parseResult = parseStringWithErrors(r'''
class A {
  factory A() {}
}
''');
    parseResult.assertExpectedDiagnostics();

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

  test_constructor_typeName_factory_unnamed_noBody() {
    var parseResult = parseStringWithErrors(r'''
class A {
  factory A();
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_typeName_factory_unnamed_noBody_language305() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.5
class A {
  factory A();
//           ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_typeName_factory_unnamed_withoutPrimaryConstructors() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
class A {
  factory A() {}
}
''');
    parseResult.assertExpectedDiagnostics();

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

  test_constructor_typeName_factory_unnamed_withoutPrimaryConstructors_notEnclosingClass() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
class A {
  factory B() {}
}
''');
    parseResult.assertExpectedDiagnostics();

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

  test_constructor_typeName_formalParameter_functionTyped_const() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(const int a(String x));
//  ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
// [diag.functionTypedParameterVar] Function-typed parameters can't specify 'const', 'final' or 'var' in place of a return type.
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      constFinalOrVarKeyword: const
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
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_typeName_formalParameter_functionTyped_documentationComment() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(
    /// aaa
    int a(String x),
  );
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      documentationComment: Comment
        tokens
          /// aaa
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
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_typeName_formalParameter_functionTyped_final() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(final int a(String x));
//  ^^^^^
// [diag.functionTypedParameterVar] Function-typed parameters can't specify 'const', 'final' or 'var' in place of a return type.
// [diag.extraneousModifier] Can't have modifier 'final' here.
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
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
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_typeName_formalParameter_simple_const() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(const int a);
//  ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      constFinalOrVarKeyword: const
      type: NamedType
        name: int
      name: a
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_typeName_formalParameter_simple_documentationComment() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(
    /// aaa
    int a,
  );
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      documentationComment: Comment
        tokens
          /// aaa
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
//  ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      constFinalOrVarKeyword: final
      type: NamedType
        name: int
      name: a
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_typeName_named() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A.named();
}
''');
    parseResult.assertExpectedDiagnostics();

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

  test_constructor_typeName_named_missingName() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A.();
//  ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
    parseResult.assertExpectedDiagnostics();

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

  test_constructor_typeName_unnamed() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A();
}
''');
    parseResult.assertExpectedDiagnostics();

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

  test_field_augment() {
    var parseResult = parseStringWithErrors(r'''
augment class A {
  augment int x = 0;
}
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
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

  test_field_augment_covariant() {
    var parseResult = parseStringWithErrors(r'''
augment class A {
  augment covariant int x = 0;
}
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    members
      FieldDeclaration
        augmentKeyword: augment
        covariantKeyword: covariant
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

  test_field_augment_late() {
    var parseResult = parseStringWithErrors(r'''
augment class A {
  augment late int x;
}
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    members
      FieldDeclaration
        augmentKeyword: augment
        fields: VariableDeclarationList
          lateKeyword: late
          type: NamedType
            name: int
          variables
            VariableDeclaration
              name: x
        semicolon: ;
    rightBracket: }
''');
  }

  test_field_augment_static() {
    var parseResult = parseStringWithErrors(r'''
augment class A {
  augment static int x = 0;
}
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
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
augment class A {
  augment static final int x = 0;
}
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
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
augment class A {
  augment int get foo => 0;
}
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
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
augment class A {
  augment static int get foo => 0;
}
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
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

  test_getter_static_body_empty() {
    var parseResult = parseStringWithErrors(r'''
class A {
  static int get foo;
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  modifierKeyword: static
  returnType: NamedType
    name: int
  propertyKeyword: get
  name: foo
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_getter_static_body_empty_language305() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.5
class A {
  static int get foo;
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  modifierKeyword: static
  returnType: NamedType
    name: int
  propertyKeyword: get
  name: foo
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_method_augment() {
    var parseResult = parseStringWithErrors(r'''
augment class A {
  augment void foo() {}
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
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

  test_method_augment_abstract() {
    var parseResult = parseStringWithErrors(r'''
augment class A {
  augment abstract void foo();
//        ^^^^^^^^
// [diag.abstractClassMember] Members of classes can't be declared to be 'abstract'.
}
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
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
        body: EmptyFunctionBody
          semicolon: ;
    rightBracket: }
''');
  }

  test_method_augment_static() {
    var parseResult = parseStringWithErrors(r'''
augment class A {
  augment static void foo() {}
}
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
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

  test_method_static_body_empty() {
    var parseResult = parseStringWithErrors(r'''
class A {
  static int foo();
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  modifierKeyword: static
  returnType: NamedType
    name: int
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_method_static_body_empty_language305() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.5
class A {
  static int foo();
//                ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  modifierKeyword: static
  returnType: NamedType
    name: int
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_nameWithTypeParameters_augment() {
    var parseResult = parseStringWithErrors(r'''
augment class A<T> {}
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
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

  test_nameWithTypeParameters_hasTypeParameters() {
    var parseResult = parseStringWithErrors(r'''
class A<T, U> {}
''');
    parseResult.assertExpectedDiagnostics();

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
    parseResult.assertExpectedDiagnostics();

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

  test_operator_augment() {
    var parseResult = parseStringWithErrors(r'''
augment class A {
  augment int operator+(int other) => 0;
}
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
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

  test_primaryConstructor_const_hasTypeParameters_named() {
    var parseResult = parseStringWithErrors(r'''
class const A<T, U>.named() {}
''');
    parseResult.assertExpectedDiagnostics();

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
    parseResult.assertExpectedDiagnostics();

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
//    ^^^^^
// [diag.constWithoutPrimaryConstructor] 'const' can only be used together with a primary constructor declaration.
''');
    parseResult.assertExpectedDiagnostics();
  }

  test_primaryConstructor_const_noTypeParameters_named() {
    var parseResult = parseStringWithErrors(r'''
class const A.named() {}
''');
    parseResult.assertExpectedDiagnostics();

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
    parseResult.assertExpectedDiagnostics();

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
//    ^^^^^
// [diag.constWithoutPrimaryConstructor] 'const' can only be used together with a primary constructor declaration.
''');
    parseResult.assertExpectedDiagnostics();

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

  test_primaryConstructor_const_typeName_noFormalParameters_language310() {
    var parseResult = parseStringWithErrors(r'''
// @dart=3.10
class const A {}
//    ^^^^^
// [diag.unexpectedToken] Unexpected text 'const'.
''');
    parseResult.assertExpectedDiagnostics();

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
    parseResult.assertExpectedDiagnostics();

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
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: RegularFormalParameter
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
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_default_namedOptional_var() {
    var parseResult = parseStringWithErrors(r'''
class A({var int a = 0}) {}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: RegularFormalParameter
        constFinalOrVarKeyword: var
        type: NamedType
          name: int
        name: a
        defaultClause: FormalParameterDefaultClause
          separator: =
          value: IntegerLiteral
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
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
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
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_default_namedRequired_final_documentationComment() {
    var parseResult = parseStringWithErrors(r'''
class A({
  /// aaa
  required final int a = 0,
}) {}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
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
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_default_namedRequired_var() {
    var parseResult = parseStringWithErrors(r'''
class A({required var int a = 0}) {}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: RegularFormalParameter
        requiredKeyword: required
        constFinalOrVarKeyword: var
        type: NamedType
          name: int
        name: a
        defaultClause: FormalParameterDefaultClause
          separator: =
          value: IntegerLiteral
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
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: [
      parameter: RegularFormalParameter
        constFinalOrVarKeyword: final
        type: NamedType
          name: int
        name: a
        defaultClause: FormalParameterDefaultClause
          separator: =
          value: IntegerLiteral
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
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: [
      parameter: RegularFormalParameter
        constFinalOrVarKeyword: var
        type: NamedType
          name: int
        name: a
        defaultClause: FormalParameterDefaultClause
          separator: =
          value: IntegerLiteral
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
//      ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        constFinalOrVarKeyword: const
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
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_functionTyped_final() {
    var parseResult = parseStringWithErrors(r'''
class A(final int a(String x)) {}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_functionTyped_final_documentationComment() {
    var parseResult = parseStringWithErrors(r'''
class A(
  /// aaa
  final int a(String x)
) {}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
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
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_functionTyped_var() {
    var parseResult = parseStringWithErrors(r'''
class A(var int a(String x)) {}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        constFinalOrVarKeyword: var
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
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_simple_const() {
    var parseResult = parseStringWithErrors(r'''
class A(const int a) {}
//      ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        constFinalOrVarKeyword: const
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
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        constFinalOrVarKeyword: final
        type: NamedType
          name: int
        name: a
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_simple_final_documentationComment() {
    var parseResult = parseStringWithErrors(r'''
class A(
  /// aaa
  final int a
) {}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
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
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_declaringFormalParameter_simple_var() {
    var parseResult = parseStringWithErrors(r'''
class A(var int a) {}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        constFinalOrVarKeyword: var
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
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: FieldFormalParameter
        constFinalOrVarKeyword: final
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
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: FieldFormalParameter
        constFinalOrVarKeyword: var
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

  test_primaryConstructor_formalParameters_named_keyword_required_covariant() {
    var parseResult = parseStringWithErrors(r'''
class A({required covariant int it}) {}
//                ^^^^^^^^^
// [diag.invalidCovariantModifierInPrimaryConstructor] The 'covariant' modifier can only be used on non-final declaring parameters.
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: RegularFormalParameter
        covariantKeyword: covariant
        requiredKeyword: required
        type: NamedType
          name: int
        name: it
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_named_keyword_required_covariant_final() {
    var parseResult = parseStringWithErrors(r'''
class A({required covariant final int it}) {}
//                ^^^^^^^^^
// [diag.invalidCovariantModifierInPrimaryConstructor] The 'covariant' modifier can only be used on non-final declaring parameters.
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: RegularFormalParameter
        covariantKeyword: covariant
        requiredKeyword: required
        constFinalOrVarKeyword: final
        type: NamedType
          name: int
        name: it
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_named_keyword_required_covariant_var() {
    var parseResult = parseStringWithErrors(r'''
class A({required covariant var int it}) {}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: RegularFormalParameter
        covariantKeyword: covariant
        requiredKeyword: required
        constFinalOrVarKeyword: var
        type: NamedType
          name: int
        name: it
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_named_keyword_required_required() {
    var parseResult = parseStringWithErrors(r'''
class A({required required int a}) {}
//                ^^^^^^^^
// [diag.duplicatedModifier] The modifier 'required' was already specified.
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: RegularFormalParameter
        requiredKeyword: required
        type: NamedType
          name: int
        name: a
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_named_keyword_required_required_covariant_var() {
    var parseResult = parseStringWithErrors(r'''
class A({required required covariant var int a}) {}
//                ^^^^^^^^
// [diag.duplicatedModifier] The modifier 'required' was already specified.
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: RegularFormalParameter
        covariantKeyword: covariant
        requiredKeyword: required
        constFinalOrVarKeyword: var
        type: NamedType
          name: int
        name: a
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_positional_keyword_covariant() {
    var parseResult = parseStringWithErrors(r'''
class A(covariant int it) {}
//      ^^^^^^^^^
// [diag.invalidCovariantModifierInPrimaryConstructor] The 'covariant' modifier can only be used on non-final declaring parameters.
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
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
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_positional_keyword_covariant_final() {
    var parseResult = parseStringWithErrors(r'''
class A(covariant final int it) {}
//      ^^^^^^^^^
// [diag.invalidCovariantModifierInPrimaryConstructor] The 'covariant' modifier can only be used on non-final declaring parameters.
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
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
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_positional_keyword_covariant_var() {
    var parseResult = parseStringWithErrors(r'''
class A(covariant var int it) {}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
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
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_positional_keyword_required() {
    var parseResult = parseStringWithErrors(r'''
class A(required int a) {}
//      ^^^^^^^^
// [diag.extraneousModifier] Can't have modifier 'required' here.
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        requiredKeyword: required
        type: NamedType
          name: int
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
    parseResult.assertExpectedDiagnostics();

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
    parseResult.assertExpectedDiagnostics();

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
    parseResult.assertExpectedDiagnostics();

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
    parseResult.assertExpectedDiagnostics();

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
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SuperFormalParameter
        constFinalOrVarKeyword: final
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
//      ^^^
// [diag.extraneousModifier] Can't have modifier 'var' here.
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SuperFormalParameter
        constFinalOrVarKeyword: var
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

  test_primaryConstructorBody_assertInitializer() {
    var parseResult = parseStringWithErrors(r'''
class A(final int x) {
  this : assert(x > 0);
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singlePrimaryConstructorBody;
    assertParsedNodeText(node, r'''
PrimaryConstructorBody
  thisKeyword: this
  colon: :
  initializers
    AssertInitializer
      assertKeyword: assert
      leftParenthesis: (
      condition: BinaryExpression
        leftOperand: SimpleIdentifier
          token: x
        operator: >
        rightOperand: IntegerLiteral
          literal: 0
      rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
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
    parseResult.assertExpectedDiagnostics();

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
    parseResult.assertExpectedDiagnostics();

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
    parseResult.assertExpectedDiagnostics();

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
    parseResult.assertExpectedDiagnostics();

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

  test_primaryConstructorBody_modifier_const() {
    var parseResult = parseStringWithErrors(r'''
class A() {
  const this;
//^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
}
''');
    parseResult.assertExpectedDiagnostics();

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
augment class A {
  augment set foo(int x) {}
}
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
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
augment class A {
  augment static set foo(int x) {}
}
''');
    parseResult.assertExpectedDiagnostics();
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
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

  test_setter_formalParameters_absent() {
    var parseResult = parseStringWithErrors(r'''
class A {
  set foo {}
//    ^^^
// [diag.missingMethodParameters] Methods must have an explicit list of parameters.
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, withOffsets: true, r'''
MethodDeclaration
  propertyKeyword: set @12
  name: foo @16
  parameters: FormalParameterList
    leftParenthesis: ( @20 <synthetic>
    parameter: RegularFormalParameter
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
//    ^^^
// [diag.wrongNumberOfParametersForSetter] Setters must declare exactly one required positional parameter.
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, withOffsets: true, r'''
MethodDeclaration
  propertyKeyword: set @12
  name: foo @16
  parameters: FormalParameterList
    leftParenthesis: ( @19
    parameter: RegularFormalParameter
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
//    ^^^
// [diag.wrongNumberOfParametersForSetter] Setters must declare exactly one required positional parameter.
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, withOffsets: true, r'''
MethodDeclaration
  propertyKeyword: set @12
  name: foo @16
  parameters: FormalParameterList
    leftParenthesis: ( @19
    parameter: RegularFormalParameter
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
//    ^^^
// [diag.wrongNumberOfParametersForSetter] Setters must declare exactly one required positional parameter.
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, withOffsets: true, r'''
MethodDeclaration
  propertyKeyword: set @12
  name: foo @16
  parameters: FormalParameterList
    leftParenthesis: ( @19
    parameter: RegularFormalParameter
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
//    ^^^
// [diag.wrongNumberOfParametersForSetter] Setters must declare exactly one required positional parameter.
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, withOffsets: true, r'''
MethodDeclaration
  propertyKeyword: set @12
  name: foo @16
  parameters: FormalParameterList
    leftParenthesis: ( @19
    parameter: RegularFormalParameter
      name: <empty> @20 <synthetic>
    rightParenthesis: ) @20
  body: BlockFunctionBody
    block: Block
      leftBracket: { @22
      rightBracket: } @23
''');
  }

  test_setter_static_body_empty() {
    var parseResult = parseStringWithErrors(r'''
class A {
  static set foo(int _);
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  modifierKeyword: static
  propertyKeyword: set
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: int
      name: _
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_setter_static_body_empty_language305() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.5
class A {
  static set foo(int _);
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
    parseResult.assertExpectedDiagnostics();

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  modifierKeyword: static
  propertyKeyword: set
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: int
      name: _
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }
}
