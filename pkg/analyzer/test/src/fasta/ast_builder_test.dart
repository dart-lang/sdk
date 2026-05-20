// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../util/feature_sets.dart';
import '../dart/resolution/node_text_expectations.dart';
import '../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AstBuilderTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AstBuilderTest extends ParserDiagnosticsTest {
  void test_class_abstract_final_base() {
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

  void test_class_abstract_final_interface() {
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

  void test_class_abstract_sealed() {
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

  void test_class_base() {
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

  void test_class_commentReferences_beforeAbstract() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/** [String] */ abstract class A {}
''');

    var node = parseResult.findNode.classDeclaration('class A');
    assertParsedNodeText(node, r'''
ClassDeclaration
  documentationComment: Comment
    references
      CommentReference
        expression: SimpleIdentifier
          token: String @5
    tokens
      /** [String] */ @0
  abstractKeyword: abstract @16
  classKeyword: class @25
  namePart: NameWithTypeParameters
    typeName: A @31
  body: BlockClassBody
    leftBracket: { @33
    rightBracket: } @34
''', withOffsets: true);
  }

  void test_class_commentReferences_beforeAnnotation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// See [int] and [String]
/// and [Object].
@Annotation
abstract class A {}
''');

    var node = parseResult.findNode.classDeclaration('class A');
    assertParsedNodeText(node, r'''
ClassDeclaration
  documentationComment: Comment
    references
      CommentReference
        expression: SimpleIdentifier
          token: int @9
      CommentReference
        expression: SimpleIdentifier
          token: String @19
      CommentReference
        expression: SimpleIdentifier
          token: Object @36
    tokens
      /// See [int] and [String] @0
      /// and [Object]. @27
  metadata
    Annotation
      atSign: @ @45
      name: SimpleIdentifier
        token: Annotation @46
  abstractKeyword: abstract @57
  classKeyword: class @66
  namePart: NameWithTypeParameters
    typeName: A @72
  body: BlockClassBody
    leftBracket: { @74
    rightBracket: } @75
''', withOffsets: true);
  }

  void test_class_commentReferences_complex() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// This dartdoc comment [should] be ignored
@Annotation
/// This dartdoc comment is [included].
// a non dartdoc comment [inbetween]
/// See [int] and [String] but `not [a]`
/// ```
/// This [code] block should be ignored
/// ```
/// and [Object].
abstract class A {}
''');

    var node = parseResult.findNode.classDeclaration('class A');
    assertParsedNodeText(node, r'''
ClassDeclaration
  documentationComment: Comment
    references
      CommentReference
        expression: SimpleIdentifier
          token: included @86
      CommentReference
        expression: SimpleIdentifier
          token: int @143
      CommentReference
        expression: SimpleIdentifier
          token: String @153
      CommentReference
        expression: SimpleIdentifier
          token: Object @240
    tokens
      /// This dartdoc comment is [included]. @57
      /// See [int] and [String] but `not [a]` @134
      /// ``` @175
      /// This [code] block should be ignored @183
      /// ``` @223
      /// and [Object]. @231
    codeBlocks
      MdCodeBlock
        infoString: <empty>
        type: CodeBlockType.fenced
        lines
          MdCodeBlockLine
            offset: 178
            length: 4
          MdCodeBlockLine
            offset: 186
            length: 36
          MdCodeBlockLine
            offset: 226
            length: 4
  metadata
    Annotation
      atSign: @ @45
      name: SimpleIdentifier
        token: Annotation @46
  abstractKeyword: abstract @249
  classKeyword: class @258
  namePart: NameWithTypeParameters
    typeName: A @264
  body: BlockClassBody
    leftBracket: { @266
    rightBracket: } @267
''', withOffsets: true);
  }

  void test_class_constructor_named() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  A.named();
}
''');

    var node = parseResult.findNode.constructor('A.named()');
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

  void test_class_constructor_unnamed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  A();
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
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_class_extendsClause_recordType() {
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

  void test_class_final() {
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

  void test_class_final_mixin() {
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

  void test_class_implementsClause_recordType() {
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

  void test_class_interface() {
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

  void test_class_interface_mixin() {
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

  void test_class_mixin() {
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

  void test_class_sealed() {
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

  void test_class_sealed_abstract() {
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

  void test_class_sealed_mixin() {
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

  void test_class_withClause_recordType() {
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

  void test_classAlias_mixin() {
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

  void test_classAlias_notNamedType() {
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

  void test_classTypeAlias_base() {
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

  void test_classTypeAlias_final() {
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

  void test_classTypeAlias_implementsClause_recordType() {
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

  void test_classTypeAlias_interface() {
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

  void test_classTypeAlias_sealed() {
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

  void test_classTypeAlias_withClause_recordType() {
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

  void test_constructor_factory_misnamed_withoutPrimaryConstructors() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.10
class A {
  factory B() => null;
}
''');

    var node = parseResult.findNode.constructor('B()');
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: B
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: NullLiteral
      literal: null
    semicolon: ;
''');
  }

  void test_constructor_initilizer_assignmentWithSuperCallAsTarget() {
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

  void test_constructor_superParamAndSuperInitializer() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
abstract class A {
  final String f1;

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

  void test_constructor_wrongName() {
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

  void test_dotShorthand_invocation() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {}

void main() {
  C c = .new();
}
''');

    var node = parseResult.findNode.dotShorthandInvocation('.new()');
    assertParsedNodeText(node, r'''
DotShorthandInvocation
  period: .
  memberName: SimpleIdentifier
    token: new
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  isDotShorthand: true
''');
  }

  void test_dotShorthand_propertyAccess() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E { a }

void main() {
  E e = .a;
}
''');

    var node = parseResult.findNode.dotShorthandPropertyAccess('.a');
    assertParsedNodeText(node, r'''
DotShorthandPropertyAccess
  period: .
  propertyName: SimpleIdentifier
    token: a
  isDotShorthand: true
''');
  }

  void test_enum_base() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
base enum E { v }
// [diag.baseEnum][column 1][length 4] Enums can't be declared to be 'base'.
''');

    var node = parseResult.findNode.enumDeclaration('enum E');
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

  void test_enum_constant_name_dot() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v.
}
// [diag.missingIdentifier][column 1][length 1] Expected an identifier.
// [diag.expectedToken][column 1][length 1] Expected to find '('.
''');

    var node = parseResult.findNode.enumConstantDeclaration('v.');
    assertParsedNodeText(node, r'''
EnumConstantDeclaration
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

  void test_enum_constant_name_dot_identifier_semicolon() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v.named;
//  ^^^^^
// [diag.expectedToken] Expected to find '('.
}
''');

    var node = parseResult.findNode.enumConstantDeclaration('v.');
    assertParsedNodeText(node, r'''
EnumConstantDeclaration
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

  void test_enum_constant_name_dot_semicolon() {
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
EnumConstantDeclaration
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

  void test_enum_constant_name_typeArguments_dot() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v<int>.
}
// [diag.missingIdentifier][column 1][length 1] Expected an identifier.
// [diag.expectedToken][column 1][length 1] Expected to find '('.
''');

    var node = parseResult.findNode.enumConstantDeclaration('v<int>.');
    assertParsedNodeText(node, r'''
EnumConstantDeclaration
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

  void test_enum_constant_name_typeArguments_dot_semicolon() {
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
EnumConstantDeclaration
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

  void test_enum_constant_withTypeArgumentsWithoutArguments() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E<T> {
  v<int>;
//     ^
// [diag.expectedToken] Expected to find '('.
}
''');

    var node = parseResult.findNode.enumConstantDeclaration('v<int>');
    assertParsedNodeText(node, r'''
EnumConstantDeclaration
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

  void test_enum_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final enum E { v }
// [diag.finalEnum][column 1][length 5] Enums can't be declared to be 'final'.
''');

    var node = parseResult.findNode.enumDeclaration('enum E');
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

  void test_enum_interface() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
interface enum E { v }
// [diag.interfaceEnum][column 1][length 9] Enums can't be declared to be 'interface'.
''');

    var node = parseResult.findNode.enumDeclaration('enum E');
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

  void test_enum_sealed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
sealed enum E { v }
// [diag.sealedEnum][column 1][length 6] Enums can't be declared to be 'sealed'.
''');

    var node = parseResult.findNode.enumDeclaration('enum E');
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

  void test_enum_semicolon_null() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v
}
''');

    var node = parseResult.findNode.enumDeclaration('enum E');
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

  void test_enum_semicolon_optional() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
enum E {
  v;
}
''');

    var node = parseResult.findNode.enumDeclaration('enum E');
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
    semicolon: ;
    rightBracket: }
''');
  }

  void test_extension_onClause_recordType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension E on (int, int) {}
''');

    var node = parseResult.findNode.extensionDeclaration('extension E');
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension @0
  name: E @10
  onClause: ExtensionOnClause
    onKeyword: on @12
    extendedType: RecordTypeAnnotation
      leftParenthesis: ( @15
      positionalFields
        RecordTypeAnnotationPositionalField
          type: NamedType
            name: int @16
        RecordTypeAnnotationPositionalField
          type: NamedType
            name: int @21
      rightParenthesis: ) @24
  body: BlockClassBody
    leftBracket: { @26
    rightBracket: } @27
''', withOffsets: true);
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

  void test_library_with_name() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library name.and.dots;
''');

    var node = parseResult.findNode.library('library');
    assertParsedNodeText(node, r'''
LibraryDirective
  libraryKeyword: library
  name: DottedName
    tokens
      name
      .
      and
      .
      dots
  semicolon: ;
''');
  }

  void test_library_without_name() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library;
''');

    var node = parseResult.findNode.library('library');
    assertParsedNodeText(node, r'''
LibraryDirective
  libraryKeyword: library
  semicolon: ;
''');
  }

  void test_mixin_base() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// text
base mixin M {}
''');

    var node = parseResult.findNode.mixinDeclaration('mixin M');
    assertParsedNodeText(node, r'''
MixinDeclaration
  documentationComment: Comment
    tokens
      /// text
  baseKeyword: base
  mixinKeyword: mixin
  name: M
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_mixin_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final mixin M {}
// [diag.finalMixin][column 1][length 5] A mixin can't be declared 'final'.
''');

    var node = parseResult.findNode.mixinDeclaration('mixin M');
    assertParsedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: M
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_mixin_implementsClause_recordType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {}
mixin M on C implements A, (int, int), B {}
//                         ^^^^^^^^^^
// [diag.expectedNamedTypeImplements] Expected the name of a class or mixin.
''');

    var node = parseResult.findNode.mixinDeclaration('mixin M');
    assertParsedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin @11
  name: M @17
  onClause: MixinOnClause
    onKeyword: on @19
    superclassConstraints
      NamedType
        name: C @22
  implementsClause: ImplementsClause
    implementsKeyword: implements @24
    interfaces
      NamedType
        name: A @35
      NamedType
        name: B @50
  body: BlockClassBody
    leftBracket: { @52
    rightBracket: } @53
''', withOffsets: true);
  }

  void test_mixin_interface() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
interface mixin M {}
// [diag.interfaceMixin][column 1][length 9] A mixin can't be declared 'interface'.
''');

    var node = parseResult.findNode.mixinDeclaration('mixin M');
    assertParsedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: M
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_mixin_onClause_recordType() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
mixin M on A, (int, int), B {}
//            ^^^^^^^^^^
// [diag.expectedNamedTypeOn] Expected the name of a class or mixin.
''');

    var node = parseResult.findNode.mixinDeclaration('mixin M');
    assertParsedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin @0
  name: M @6
  onClause: MixinOnClause
    onKeyword: on @8
    superclassConstraints
      NamedType
        name: A @11
      NamedType
        name: B @26
  body: BlockClassBody
    leftBracket: { @28
    rightBracket: } @29
''', withOffsets: true);
  }

  void test_mixin_sealed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
sealed mixin M {}
// [diag.sealedMixin][column 1][length 6] A mixin can't be declared 'sealed'.
''');

    var node = parseResult.findNode.mixinDeclaration('mixin M');
    assertParsedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: M
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_recordLiteral() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final x = (0, a: 1);
''');

    var node = parseResult.findNode.recordLiteral('(0');
    assertParsedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    IntegerLiteral
      literal: 0
    RecordLiteralNamedField
      name: a
      colon: :
      fieldExpression: IntegerLiteral
        literal: 1
  rightParenthesis: )
''');
  }

  void test_recordLiteral_language219_namedFieldRecovery() {
    var parseResult = parseStringWithErrors(r'''
final x = (a: 0);
''', featureSet: FeatureSets.language_2_19);

    var node = parseResult.findNode.singleParenthesizedExpression;
    assertParsedNodeText(node, r'''
ParenthesizedExpression
  leftParenthesis: (
  expression: IntegerLiteral
    literal: 0
  rightParenthesis: )
''');
  }

  void test_recordLiteral_named_trailingComma() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final x = (0, a: 1,);
''');

    var node = parseResult.findNode.recordLiteral('(0');
    assertParsedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    IntegerLiteral
      literal: 0
    RecordLiteralNamedField
      name: a
      colon: :
      fieldExpression: IntegerLiteral
        literal: 1
  rightParenthesis: )
''');
  }

  void test_recordLiteral_positional_one_trailingComma() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final x = (0,);
''');

    var node = parseResult.findNode.recordLiteral('(0');
    assertParsedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    IntegerLiteral
      literal: 0
  rightParenthesis: )
''');
  }

  void test_recordLiteral_positional_trailingComma() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
final x = (0, 1,);
''');

    var node = parseResult.findNode.recordLiteral('(0');
    assertParsedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    IntegerLiteral
      literal: 0
    IntegerLiteral
      literal: 1
  rightParenthesis: )
''');
  }

  void test_recordTypeAnnotation_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
() f() {}
''');

    var node = parseResult.findNode.recordTypeAnnotation('() f');
    assertParsedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  void test_recordTypeAnnotation_mixed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f((int, bool, {int a, bool b}) r) {}
''');

    var node = parseResult.findNode.recordTypeAnnotation('(int');
    assertParsedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  positionalFields
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: int
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: bool
  namedFields: RecordTypeAnnotationNamedFields
    leftBracket: {
    fields
      RecordTypeAnnotationNamedField
        type: NamedType
          name: int
        name: a
      RecordTypeAnnotationNamedField
        type: NamedType
          name: bool
        name: b
    rightBracket: }
  rightParenthesis: )
''');
  }

  void test_recordTypeAnnotation_named() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(({int a, bool b}) r) {}
''');

    var node = parseResult.findNode.recordTypeAnnotation('({int');
    assertParsedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  namedFields: RecordTypeAnnotationNamedFields
    leftBracket: {
    fields
      RecordTypeAnnotationNamedField
        type: NamedType
          name: int
        name: a
      RecordTypeAnnotationNamedField
        type: NamedType
          name: bool
        name: b
    rightBracket: }
  rightParenthesis: )
''');
  }

  void test_recordTypeAnnotation_named_trailingComma() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(({int a, bool b,}) r) {}
''');

    var node = parseResult.findNode.recordTypeAnnotation('({int');
    assertParsedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  namedFields: RecordTypeAnnotationNamedFields
    leftBracket: {
    fields
      RecordTypeAnnotationNamedField
        type: NamedType
          name: int
        name: a
      RecordTypeAnnotationNamedField
        type: NamedType
          name: bool
        name: b
    rightBracket: }
  rightParenthesis: )
''');
  }

  void test_recordTypeAnnotation_nullable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f((int, bool)? r) {}
''');

    var node = parseResult.findNode.recordTypeAnnotation('(int');
    assertParsedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  positionalFields
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: int
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: bool
  rightParenthesis: )
  question: ?
''');
  }

  void test_recordTypeAnnotation_positional() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f((int, bool) r) {}
''');

    var node = parseResult.findNode.recordTypeAnnotation('(int');
    assertParsedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  positionalFields
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: int
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: bool
  rightParenthesis: )
''');
  }

  void test_recordTypeAnnotation_positional_one() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f((int) r) {}
//         ^
// [diag.recordTypeOnePositionalNoTrailingComma] A record type with exactly one positional field requires a trailing comma.
''');

    var node = parseResult.findNode.recordTypeAnnotation('(int');
    assertParsedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  positionalFields
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: int
  rightParenthesis: )
''');
  }

  void test_recordTypeAnnotation_positional_one_trailingComma() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f((int, ) r) {}
''');

    var node = parseResult.findNode.recordTypeAnnotation('(int');
    assertParsedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  positionalFields
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: int
  rightParenthesis: )
''');
  }

  void test_recordTypeAnnotation_positional_trailingComma() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f((int, bool,) r) {}
''');

    var node = parseResult.findNode.recordTypeAnnotation('(int');
    assertParsedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  positionalFields
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: int
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: bool
  rightParenthesis: )
''');
  }

  void test_recordTypeAnnotation_topFunction_returnType_withTypeParameter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
(int, T) f<T>() {}
''');

    var node = parseResult.findNode.recordTypeAnnotation('(int');
    assertParsedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  positionalFields
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: int
    RecordTypeAnnotationPositionalField
      type: NamedType
        name: T
  rightParenthesis: )
''');
  }

  void test_superFormalParameter() {
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

  void test_switchStatement_withPatternCase_whenDisabled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 2.19
void f(Object value) {
  switch (value) {
    case (int a,) when a == 0:
//            ^
// [diag.expectedToken] Expected to find ')'.
  }
}
''');

    var node = parseResult.findNode.switchCase('case');
    assertParsedNodeText(node, r'''
SwitchCase
  keyword: case
  expression: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: int
    rightParenthesis: )
  colon: :
''');
  }
}
