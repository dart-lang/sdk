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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment abstract class A {}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment abstract base class A {}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment base class A {}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A extends B {}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment final class A {}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A implements B {}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment interface class A {}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment mixin class A {}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A = B with M;
// [diag.mixinApplicationClassAugmentation][column 1][length 7] A mixin application class can't be augmented.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment sealed class A {}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A<T extends int> {}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A with M {}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A;
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  factory named() {}
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  const factory named() = B;
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  factory new() {}
//        ^^^
// [diag.factoryConstructorNewName] Factory constructors can't be named 'new'.
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  factory () {}
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  const factory () = B;
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  new named();
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  new named() {}
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  const new named();
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  new named() : x = 0;
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  new new();
//    ^^^
// [diag.newConstructorNewName] Constructors declared with the 'new' keyword can't be named 'new'.
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  new ();
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  new () {}
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  const new ();
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  new () : x = 0;
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  new (int x, {required String y});
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A {
  augment factory A() {}
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A {
  augment A.named();
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  final int f;
  external A([this.f = 0]);
//            ^^^^
// [diag.externalConstructorWithFieldInitializers] An external constructor can't initialize fields.
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  final int f;
  external A(this.f);
//           ^^^^
// [diag.externalConstructorWithFieldInitializers] An external constructor can't initialize fields.
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  final int f;
  external A() : f = 0;
//             ^
// [diag.externalConstructorWithInitializer] An external constructor can't have any initializers.
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  factory A.named() {}
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.10
class A {
  factory A.named() {}
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  factory A() {}
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  factory A();
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.5
class A {
  factory A();
//           ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.10
class A {
  factory A() {}
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.10
class A {
  factory B() {}
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  A(const int a(String x));
//  ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
// [diag.functionTypedParameterVar] Function-typed parameters can't specify 'const', 'final' or 'var' in place of a return type.
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  A(
    /// aaa
    int a(String x),
  );
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  A(final int a(String x));
//  ^^^^^
// [diag.functionTypedParameterVar] Function-typed parameters can't specify 'const', 'final' or 'var' in place of a return type.
// [diag.extraneousModifier] Can't have modifier 'final' here.
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  A(const int a);
//  ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  A(
    /// aaa
    int a,
  );
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  A(final int a);
//  ^^^^^
// [diag.extraneousModifier] Can't have modifier 'final' here.
}
''');

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

  test_constructor_typeName_formalParameter_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  A(super.a);
}
''');

    var node = parseResult.findNode.superFormalParameter('super.a');
    assertParsedNodeText(node, r'''
SuperFormalParameter
  superKeyword: super
  period: .
  name: a
''');
  }

  test_constructor_typeName_formalParameter_super_withSuperInitializer() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
abstract class A {
  final int f1;
  final int f2;
  const A(this.f1, this.f2);
}

class B extends A {
  const B(super.f1): super(2);
}
''');

    var node = parseResult.findNode.constructor('B(');
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  constKeyword: const
  typeName: SimpleIdentifier
    token: B
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SuperFormalParameter
      superKeyword: super
      period: .
      name: f1
    rightParenthesis: )
  separator: :
  initializers
    SuperConstructorInvocation
      superKeyword: super
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 2
        rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_typeName_initializer_assignmentWithSuperCallAsTarget() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  A() : super() = 0;
//      ^^^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
//      ^^^^^^^^^^^
// [diag.invalidInitializer] Not a valid initializer.
}
''');

    var node = parseResult.findNode.constructor('A()');
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: :
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_typeName_named() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  A.named();
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  A.();
//  ^
// [diag.missingIdentifier] Expected an identifier.
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  A();
}
''');

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

  test_constructor_typeName_wrongName() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  B() : super();
//^
// [diag.invalidConstructorName] The name of a constructor must match the name of the enclosing class.
}
''');

    var node = parseResult.findNode.constructor('B()');
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: B
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: :
  initializers
    SuperConstructorInvocation
      superKeyword: super
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_extendsClause_recordType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C extends (int, int) {}
//              ^^^^^^^^^^
// [diag.expectedNamedTypeExtends] Expected a class name.
''');

    var node = parseResult.findNode.classDeclaration('class C');
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class @0
  namePart: NameWithTypeParameters
    typeName: C @6
  body: BlockClassBody
    leftBracket: { @27
    rightBracket: } @28
''', withOffsets: true);
  }

  test_field_abstract_static() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  abstract static int? foo;
//         ^^^^^^
// [diag.modifierOutOfOrder] The modifier 'static' should be before the modifier 'abstract'.
}
''');
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    members
      FieldDeclaration
        staticKeyword: static
        abstractKeyword: abstract
        fields: VariableDeclarationList
          type: NamedType
            name: int
            question: ?
          variables
            VariableDeclaration
              name: foo
        semicolon: ;
    rightBracket: }
''');
  }

  test_field_abstract_static_language305() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.5
class A {
  abstract static int? foo;
//^^^^^^^^
// [diag.abstractStaticField] Static fields can't be declared 'abstract'.
}
''');
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    members
      FieldDeclaration
        staticKeyword: static
        abstractKeyword: abstract
        fields: VariableDeclarationList
          type: NamedType
            name: int
            question: ?
          variables
            VariableDeclaration
              name: foo
        semicolon: ;
    rightBracket: }
''');
  }

  test_field_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A {
  augment int x = 0;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A {
  augment covariant int x = 0;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A {
  augment late int x;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A {
  augment static int x = 0;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A {
  augment static final int x = 0;
}
''');
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

  test_field_static_abstract() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  static abstract int? foo;
}
''');
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    members
      FieldDeclaration
        staticKeyword: static
        abstractKeyword: abstract
        fields: VariableDeclarationList
          type: NamedType
            name: int
            question: ?
          variables
            VariableDeclaration
              name: foo
        semicolon: ;
    rightBracket: }
''');
  }

  test_field_static_abstract_language305() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.5
class A {
  static abstract int? foo;
//       ^^^^^^^^
// [diag.abstractStaticField] Static fields can't be declared 'abstract'.
}
''');
    assertParsedNodeText(parseResult.findNode.singleClassDeclaration, r'''
ClassDeclaration
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    members
      FieldDeclaration
        staticKeyword: static
        abstractKeyword: abstract
        fields: VariableDeclarationList
          type: NamedType
            name: int
            question: ?
          variables
            VariableDeclaration
              name: foo
        semicolon: ;
    rightBracket: }
''');
  }

  test_getter_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A {
  augment int get foo => 0;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A {
  augment static int get foo => 0;
}
''');
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

  void test_getter_sameNameAsClass() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  get A => 0;
//    ^
// [diag.memberWithClassName] A class member can't have the same name as the enclosing class.
}
''');

    var node = parseResult.findNode.methodDeclaration('get A');
    assertParsedNodeText(node, r'''
MethodDeclaration
  propertyKeyword: get
  name: A
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: IntegerLiteral
      literal: 0
    semicolon: ;
''');
  }

  test_getter_static_body_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  static int get foo;
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.5
class A {
  static int get foo;
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');

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

  void test_implementsClause_recordType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C implements A, (int, int), B {}
//                    ^^^^^^^^^^
// [diag.expectedNamedTypeImplements] Expected the name of a class or mixin.
''');

    var node = parseResult.findNode.classDeclaration('class C');
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class @0
  namePart: NameWithTypeParameters
    typeName: C @6
  implementsClause: ImplementsClause
    implementsKeyword: implements @8
    interfaces
      NamedType
        name: A @19
      NamedType
        name: B @34
  body: BlockClassBody
    leftBracket: { @36
    rightBracket: } @37
''', withOffsets: true);
  }

  test_method_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A {
  augment void foo() {}
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A {
  augment abstract void foo();
//        ^^^^^^^^
// [diag.abstractClassMember] Members of classes can't be declared to be 'abstract'.
}
''');
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

  test_method_augment_external() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A {
  augment external void foo();
}
''');

    var node = parseResult.findNode.singleMethodDeclaration;
    assertParsedNodeText(node, r'''
MethodDeclaration
  augmentKeyword: augment
  externalKeyword: external
  returnType: NamedType
    name: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_method_augment_static() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A {
  augment static void foo() {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  static int foo();
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.5
class A {
  static int foo();
//                ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');

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

  void test_modifiers_abstract_final_base() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// text
abstract final base class A {}
//       ^^^^^^^^^^
// [diag.abstractFinalBaseClass] An 'abstract' class can't be declared as both 'final' and 'base'.
''');

    var node = parseResult.findNode.classDeclaration('class A {}');
    assertParsedNodeText(node, r'''
ClassDeclaration
  documentationComment: Comment
    tokens
      /// text
  abstractKeyword: abstract
  baseKeyword: base
  finalKeyword: final
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_modifiers_abstract_final_interface() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// text
abstract final interface class A {}
//       ^^^^^^^^^^^^^^^
// [diag.abstractFinalInterfaceClass] An 'abstract' class can't be declared as both 'final' and 'interface'.
''');

    var node = parseResult.findNode.classDeclaration('class A {}');
    assertParsedNodeText(node, r'''
ClassDeclaration
  documentationComment: Comment
    tokens
      /// text
  abstractKeyword: abstract
  interfaceKeyword: interface
  finalKeyword: final
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_modifiers_abstract_sealed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// text
abstract sealed class A {}
//       ^^^^^^
// [diag.abstractSealedClass] A 'sealed' class can't be marked 'abstract' because it's already implicitly abstract.
''');

    var node = parseResult.findNode.classDeclaration('class A {}');
    assertParsedNodeText(node, r'''
ClassDeclaration
  documentationComment: Comment
    tokens
      /// text
  abstractKeyword: abstract
  sealedKeyword: sealed
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_modifiers_base() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// text
base class A {}
''');

    var node = parseResult.findNode.classDeclaration('class A {}');
    assertParsedNodeText(node, r'''
ClassDeclaration
  documentationComment: Comment
    tokens
      /// text
  baseKeyword: base
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_modifiers_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// text
final class A {}
''');

    var node = parseResult.findNode.classDeclaration('class A {}');
    assertParsedNodeText(node, r'''
ClassDeclaration
  documentationComment: Comment
    tokens
      /// text
  finalKeyword: final
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_modifiers_final_mixinClass() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final mixin class A {}
// [diag.finalMixinClass][column 1][length 5] A mixin class can't be declared 'final'.
''');

    var node = parseResult.findNode.classDeclaration('class A {}');
    assertParsedNodeText(node, r'''
ClassDeclaration
  finalKeyword: final
  mixinKeyword: mixin
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_modifiers_interface() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// text
interface class A {}
''');

    var node = parseResult.findNode.classDeclaration('class A {}');
    assertParsedNodeText(node, r'''
ClassDeclaration
  documentationComment: Comment
    tokens
      /// text
  interfaceKeyword: interface
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_modifiers_interface_mixinClass() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
interface mixin class A {}
// [diag.interfaceMixinClass][column 1][length 9] A mixin class can't be declared 'interface'.
''');

    var node = parseResult.findNode.classDeclaration('class A {}');
    assertParsedNodeText(node, r'''
ClassDeclaration
  interfaceKeyword: interface
  mixinKeyword: mixin
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_modifiers_mixinClass() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// text
mixin class A {}
''');

    var node = parseResult.findNode.classDeclaration('class A {}');
    assertParsedNodeText(node, r'''
ClassDeclaration
  documentationComment: Comment
    tokens
      /// text
  mixinKeyword: mixin
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_modifiers_sealed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// text
sealed class A {}
''');

    var node = parseResult.findNode.classDeclaration('class A {}');
    assertParsedNodeText(node, r'''
ClassDeclaration
  documentationComment: Comment
    tokens
      /// text
  sealedKeyword: sealed
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_modifiers_sealed_abstract() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// text
sealed abstract class A {}
// [diag.abstractSealedClass][column 1][length 6] A 'sealed' class can't be marked 'abstract' because it's already implicitly abstract.
''');

    var node = parseResult.findNode.classDeclaration('class A {}');
    assertParsedNodeText(node, r'''
ClassDeclaration
  documentationComment: Comment
    tokens
      /// text
  abstractKeyword: abstract
  sealedKeyword: sealed
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_modifiers_sealed_mixinClass() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
sealed mixin class A {}
// [diag.sealedMixinClass][column 1][length 6] A mixin class can't be declared 'sealed'.
''');

    var node = parseResult.findNode.classDeclaration('class A {}');
    assertParsedNodeText(node, r'''
ClassDeclaration
  sealedKeyword: sealed
  mixinKeyword: mixin
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_nameWithTypeParameters_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A<T> {}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A<T, U> {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A {
  augment int operator+(int other) => 0;
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class const A<T, U>.named() {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class const A<T, U>() {}
''');

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
    parseTestCodeWithDiagnostics(r'''
mixin M {}
class const C = Object with M;
//    ^^^^^
// [diag.constWithoutPrimaryConstructor] 'const' can only be used together with a primary constructor declaration.
''');
  }

  test_primaryConstructor_const_noTypeParameters_named() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class const A.named() {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class const A() {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class const A {}
//    ^^^^^
// [diag.constWithoutPrimaryConstructor] 'const' can only be used together with a primary constructor declaration.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart=3.10
class const A {}
//    ^^^^^
// [diag.unexpectedToken] Unexpected text 'const'.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class const A.named {}
//            ^^^^^
// [diag.missingPrimaryConstructorParameters] A primary constructor declaration must have formal parameters.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A({final int a = 0}) {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A({var int a = 0}) {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A({required final int a = 0}) {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A({
  /// aaa
  required final int a = 0,
}) {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A({required var int a = 0}) {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A([final int a = 0]) {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A([var int a = 0]) {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A(const int a(String x)) {}
//      ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A(final int a(String x)) {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A(
  /// aaa
  final int a(String x)
) {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A(var int a(String x)) {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A(const int a) {}
//      ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A(final int a) {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A(
  /// aaa
  final int a
) {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A(var int a) {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A(final int this.a) {}
//                ^^^^
// [diag.initializingDeclaringParameter] Declaring parameters can't be initializing.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A(var int this.a) {}
//              ^^^^
// [diag.initializingDeclaringParameter] Declaring parameters can't be initializing.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A({required covariant int it}) {}
//                ^^^^^^^^^
// [diag.invalidCovariantModifierInPrimaryConstructor] The 'covariant' modifier can only be used on non-final declaring parameters.
''');

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
        covariantKeyword: covariant
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A({required covariant final int it}) {}
//                ^^^^^^^^^
// [diag.invalidCovariantModifierInPrimaryConstructor] The 'covariant' modifier can only be used on non-final declaring parameters.
''');

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
        covariantKeyword: covariant
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A({required covariant var int it}) {}
''');

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
        covariantKeyword: covariant
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A({required required int a}) {}
//                ^^^^^^^^
// [diag.duplicatedModifier] The modifier 'required' was already specified.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A({required required covariant var int a}) {}
//                ^^^^^^^^
// [diag.duplicatedModifier] The modifier 'required' was already specified.
''');

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
        covariantKeyword: covariant
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A(covariant int it) {}
//      ^^^^^^^^^
// [diag.invalidCovariantModifierInPrimaryConstructor] The 'covariant' modifier can only be used on non-final declaring parameters.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A(covariant final int it) {}
//      ^^^^^^^^^
// [diag.invalidCovariantModifierInPrimaryConstructor] The 'covariant' modifier can only be used on non-final declaring parameters.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A(covariant var int it) {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A(required int a) {}
//      ^^^^^^^^
// [diag.extraneousModifier] Can't have modifier 'required' here.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A<T, U>.named() {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A<T, U>() {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A.named() {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A() {}
''');

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

  test_primaryConstructor_notConst_typeName_periodName_noFormalParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A.named {}
//      ^^^^^
// [diag.missingPrimaryConstructorParameters] A primary constructor declaration must have formal parameters.
''');

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
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_superFormalParameter_final_namedType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A(final int super.a) {}
//                ^^^^^
// [diag.superInitializingDeclaringParameter] Declaring parameters can't be super parameters.
''');
    // TODO(scheglov): this is wrong.

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A(var int super.a) {}
//              ^^^^^
// [diag.superInitializingDeclaringParameter] Declaring parameters can't be super parameters.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A(final int x) {
  this : assert(x > 0);
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A() {
  this {
    0;
  }
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A() {
  /// foo
  /// bar
  this;
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A() {
  final int x;
  this : x = 0;
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A() {
  @deprecated
  this;
}
''');

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

  test_primaryConstructorBody_modifier_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A() {
  augment this;
}
''');

    var node = parseResult.findNode.singlePrimaryConstructorBody;
    assertParsedNodeText(node, r'''
PrimaryConstructorBody
  augmentKeyword: augment
  thisKeyword: this
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_primaryConstructorBody_modifier_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A() {
  const this;
//^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
}
''');

    var node = parseResult.findNode.singlePrimaryConstructorBody;
    assertParsedNodeText(node, r'''
PrimaryConstructorBody
  thisKeyword: this
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_setter_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A {
  augment set foo(int x) {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment class A {
  augment static set foo(int x) {}
}
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  set foo {}
//    ^^^
// [diag.missingMethodParameters] Methods must have an explicit list of parameters.
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  set foo({a}) {}
//    ^^^
// [diag.wrongNumberOfParametersForSetter] Setters must declare exactly one required positional parameter.
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  set foo([a]) {}
//    ^^^
// [diag.wrongNumberOfParametersForSetter] Setters must declare exactly one required positional parameter.
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  set foo(a, b, c) {}
//    ^^^
// [diag.wrongNumberOfParametersForSetter] Setters must declare exactly one required positional parameter.
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  set foo() {}
//    ^^^
// [diag.wrongNumberOfParametersForSetter] Setters must declare exactly one required positional parameter.
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  static set foo(int _);
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.5
class A {
  static set foo(int _);
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');

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

  void test_typeAlias_implementsClause_recordType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C = Object with M implements A, (int, int), B;
//                                    ^^^^^^^^^^
// [diag.expectedNamedTypeImplements] Expected the name of a class or mixin.
mixin M {}
''');

    var node = parseResult.findNode.classTypeAlias('class C');
    assertParsedNodeText(node, r'''
ClassTypeAlias
  typedefKeyword: class @0
  name: C @6
  equals: = @8
  superclass: NamedType
    name: Object @10
  withClause: WithClause
    withKeyword: with @17
    mixinTypes
      NamedType
        name: M @22
  implementsClause: ImplementsClause
    implementsKeyword: implements @24
    interfaces
      NamedType
        name: A @35
      NamedType
        name: B @50
  semicolon: ; @51
''', withOffsets: true);
  }

  void test_typeAlias_mixinClass() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin M {}
/// text
mixin class A = Object with M;
''');

    var node = parseResult.findNode.classTypeAlias('class A');
    assertParsedNodeText(node, r'''
ClassTypeAlias
  documentationComment: Comment
    tokens
      /// text
  mixinKeyword: mixin
  typedefKeyword: class
  name: A
  equals: =
  superclass: NamedType
    name: Object
  withClause: WithClause
    withKeyword: with
    mixinTypes
      NamedType
        name: M
  semicolon: ;
''');
  }

  void test_typeAlias_modifiers_base() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin M {}
/// text
base class A = Object with M;
''');

    var node = parseResult.findNode.classTypeAlias('class A');
    assertParsedNodeText(node, r'''
ClassTypeAlias
  documentationComment: Comment
    tokens
      /// text
  baseKeyword: base
  typedefKeyword: class
  name: A
  equals: =
  superclass: NamedType
    name: Object
  withClause: WithClause
    withKeyword: with
    mixinTypes
      NamedType
        name: M
  semicolon: ;
''');
  }

  void test_typeAlias_modifiers_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin M {}
/// text
final class A = Object with M;
''');

    var node = parseResult.findNode.classTypeAlias('class A');
    assertParsedNodeText(node, r'''
ClassTypeAlias
  documentationComment: Comment
    tokens
      /// text
  finalKeyword: final
  typedefKeyword: class
  name: A
  equals: =
  superclass: NamedType
    name: Object
  withClause: WithClause
    withKeyword: with
    mixinTypes
      NamedType
        name: M
  semicolon: ;
''');
  }

  void test_typeAlias_modifiers_interface() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin M {}
/// text
interface class A = Object with M;
''');

    var node = parseResult.findNode.classTypeAlias('class A');
    assertParsedNodeText(node, r'''
ClassTypeAlias
  documentationComment: Comment
    tokens
      /// text
  interfaceKeyword: interface
  typedefKeyword: class
  name: A
  equals: =
  superclass: NamedType
    name: Object
  withClause: WithClause
    withKeyword: with
    mixinTypes
      NamedType
        name: M
  semicolon: ;
''');
  }

  void test_typeAlias_modifiers_sealed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin M {}
/// text
sealed class A = Object with M;
''');

    var node = parseResult.findNode.classTypeAlias('class A');
    assertParsedNodeText(node, r'''
ClassTypeAlias
  documentationComment: Comment
    tokens
      /// text
  sealedKeyword: sealed
  typedefKeyword: class
  name: A
  equals: =
  superclass: NamedType
    name: Object
  withClause: WithClause
    withKeyword: with
    mixinTypes
      NamedType
        name: M
  semicolon: ;
''');
  }

  void test_typeAlias_notNamedType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C = A Function() with M;
//        ^^^^^^^^^^^^
// [diag.expectedNamedTypeExtends] Expected a class name.
''');
    var node = parseResult.findNode.classTypeAlias('class');
    assertParsedNodeText(node, r'''
ClassTypeAlias
  typedefKeyword: class
  name: C
  equals: =
  superclass: NamedType
    name: identifier <synthetic>
  withClause: WithClause
    withKeyword: with
    mixinTypes
      NamedType
        name: M
  semicolon: ;
''');
  }

  void test_typeAlias_withClause_recordType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C = Object with A, (int, int), B;
//                       ^^^^^^^^^^
// [diag.expectedNamedTypeWith] Expected a mixin name.
''');

    var node = parseResult.findNode.classTypeAlias('class C');
    assertParsedNodeText(node, r'''
ClassTypeAlias
  typedefKeyword: class @0
  name: C @6
  equals: = @8
  superclass: NamedType
    name: Object @10
  withClause: WithClause
    withKeyword: with @17
    mixinTypes
      NamedType
        name: A @22
      NamedType
        name: B @37
  semicolon: ; @38
''', withOffsets: true);
  }

  void test_withClause_recordType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C with A, (int, int), B {}
//              ^^^^^^^^^^
// [diag.expectedNamedTypeWith] Expected a mixin name.
''');

    var node = parseResult.findNode.classDeclaration('class C');
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: C
  withClause: WithClause
    withKeyword: with
    mixinTypes
      NamedType
        name: A
      NamedType
        name: B
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }
}
