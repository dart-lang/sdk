// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

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
    var parseResult = parseStringWithErrors(r'''
/// text
abstract final base class A {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.abstractFinalBaseClass, 18, 10),
    ]);

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
  name: A
  leftBracket: {
  rightBracket: }
''');
  }

  void test_class_abstract_final_interface() {
    var parseResult = parseStringWithErrors(r'''
/// text
abstract final interface class A {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.abstractFinalInterfaceClass, 18, 15),
    ]);

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
  name: A
  leftBracket: {
  rightBracket: }
''');
  }

  void test_class_abstract_sealed() {
    var parseResult = parseStringWithErrors(r'''
/// text
abstract sealed class A {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.abstractSealedClass, 18, 6),
    ]);

    var node = parseResult.findNode.classDeclaration('class A {}');
    assertParsedNodeText(node, r'''
ClassDeclaration
  documentationComment: Comment
    tokens
      /// text
  abstractKeyword: abstract
  sealedKeyword: sealed
  classKeyword: class
  name: A
  leftBracket: {
  rightBracket: }
''');
  }

  void test_class_base() {
    var parseResult = parseStringWithErrors(r'''
/// text
base class A {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.classDeclaration('class A {}');
    assertParsedNodeText(node, r'''
ClassDeclaration
  documentationComment: Comment
    tokens
      /// text
  baseKeyword: base
  classKeyword: class
  name: A
  leftBracket: {
  rightBracket: }
''');
  }

  void test_class_commentReferences_beforeAbstract() {
    var parseResult = parseStringWithErrors(r'''
/** [String] */ abstract class A {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.classDeclaration('class A');
    assertParsedNodeText(node, r'''
ClassDeclaration
  documentationComment: Comment
    references
      CommentReference
        expression: SimpleIdentifier
          token: String @5
    tokens
      /** [String] */
        offset: 0
  abstractKeyword: abstract @16
  classKeyword: class @25
  name: A @31
  leftBracket: { @33
  rightBracket: } @34
''', withOffsets: true);
  }

  void test_class_commentReferences_beforeAnnotation() {
    var parseResult = parseStringWithErrors(r'''
/// See [int] and [String]
/// and [Object].
@Annotation
abstract class A {}
''');
    parseResult.assertNoErrors();

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
      /// See [int] and [String]
        offset: 0
      /// and [Object].
        offset: 27
  metadata
    Annotation
      atSign: @ @45
      name: SimpleIdentifier
        token: Annotation @46
  abstractKeyword: abstract @57
  classKeyword: class @66
  name: A @72
  leftBracket: { @74
  rightBracket: } @75
''', withOffsets: true);
  }

  void test_class_commentReferences_complex() {
    var parseResult = parseStringWithErrors(r'''
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
    parseResult.assertNoErrors();

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
      /// This dartdoc comment is [included].
        offset: 57
      /// See [int] and [String] but `not [a]`
        offset: 134
      /// ```
        offset: 175
      /// This [code] block should be ignored
        offset: 183
      /// ```
        offset: 223
      /// and [Object].
        offset: 231
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
  name: A @264
  leftBracket: { @266
  rightBracket: } @267
''', withOffsets: true);
  }

  void test_class_constructor_named() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A.named();
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.constructor('A.named()');
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  returnType: SimpleIdentifier
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
    var parseResult = parseStringWithErrors(r'''
class A {
  A();
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.constructor('A()');
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  returnType: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  void test_class_extendsClause_recordType() {
    var parseResult = parseStringWithErrors(r'''
class C extends (int, int) {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.expectedNamedTypeExtends, 16, 10),
    ]);

    var node = parseResult.findNode.classDeclaration('class C');
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class @0
  name: C @6
  leftBracket: { @27
  rightBracket: } @28
''', withOffsets: true);
  }

  void test_class_final() {
    var parseResult = parseStringWithErrors(r'''
/// text
final class A {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.classDeclaration('class A {}');
    assertParsedNodeText(node, r'''
ClassDeclaration
  documentationComment: Comment
    tokens
      /// text
  finalKeyword: final
  classKeyword: class
  name: A
  leftBracket: {
  rightBracket: }
''');
  }

  void test_class_final_mixin() {
    var parseResult = parseStringWithErrors(r'''
final mixin class A {}
''');
    parseResult.assertErrors([error(ParserErrorCode.finalMixinClass, 0, 5)]);

    var node = parseResult.findNode.classDeclaration('class A {}');
    assertParsedNodeText(node, r'''
ClassDeclaration
  finalKeyword: final
  mixinKeyword: mixin
  classKeyword: class
  name: A
  leftBracket: {
  rightBracket: }
''');
  }

  void test_class_implementsClause_recordType() {
    var parseResult = parseStringWithErrors(r'''
class C implements A, (int, int), B {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.expectedNamedTypeImplements, 22, 10),
    ]);

    var node = parseResult.findNode.classDeclaration('class C');
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class @0
  name: C @6
  implementsClause: ImplementsClause
    implementsKeyword: implements @8
    interfaces
      NamedType
        name: A @19
      NamedType
        name: B @34
  leftBracket: { @36
  rightBracket: } @37
''', withOffsets: true);
  }

  void test_class_interface() {
    var parseResult = parseStringWithErrors(r'''
/// text
interface class A {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.classDeclaration('class A {}');
    assertParsedNodeText(node, r'''
ClassDeclaration
  documentationComment: Comment
    tokens
      /// text
  interfaceKeyword: interface
  classKeyword: class
  name: A
  leftBracket: {
  rightBracket: }
''');
  }

  void test_class_interface_mixin() {
    var parseResult = parseStringWithErrors(r'''
interface mixin class A {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.interfaceMixinClass, 0, 9),
    ]);

    var node = parseResult.findNode.classDeclaration('class A {}');
    assertParsedNodeText(node, r'''
ClassDeclaration
  interfaceKeyword: interface
  mixinKeyword: mixin
  classKeyword: class
  name: A
  leftBracket: {
  rightBracket: }
''');
  }

  void test_class_mixin() {
    var parseResult = parseStringWithErrors(r'''
/// text
mixin class A {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.classDeclaration('class A {}');
    assertParsedNodeText(node, r'''
ClassDeclaration
  documentationComment: Comment
    tokens
      /// text
  mixinKeyword: mixin
  classKeyword: class
  name: A
  leftBracket: {
  rightBracket: }
''');
  }

  void test_class_sealed() {
    var parseResult = parseStringWithErrors(r'''
/// text
sealed class A {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.classDeclaration('class A {}');
    assertParsedNodeText(node, r'''
ClassDeclaration
  documentationComment: Comment
    tokens
      /// text
  sealedKeyword: sealed
  classKeyword: class
  name: A
  leftBracket: {
  rightBracket: }
''');
  }

  void test_class_sealed_abstract() {
    var parseResult = parseStringWithErrors(r'''
/// text
sealed abstract class A {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.abstractSealedClass, 9, 6),
    ]);

    var node = parseResult.findNode.classDeclaration('class A {}');
    assertParsedNodeText(node, r'''
ClassDeclaration
  documentationComment: Comment
    tokens
      /// text
  abstractKeyword: abstract
  sealedKeyword: sealed
  classKeyword: class
  name: A
  leftBracket: {
  rightBracket: }
''');
  }

  void test_class_sealed_mixin() {
    var parseResult = parseStringWithErrors(r'''
sealed mixin class A {}
''');
    parseResult.assertErrors([error(ParserErrorCode.sealedMixinClass, 0, 6)]);

    var node = parseResult.findNode.classDeclaration('class A {}');
    assertParsedNodeText(node, r'''
ClassDeclaration
  sealedKeyword: sealed
  mixinKeyword: mixin
  classKeyword: class
  name: A
  leftBracket: {
  rightBracket: }
''');
  }

  void test_class_withClause_recordType() {
    var parseResult = parseStringWithErrors(r'''
class C with A, (int, int), B {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.expectedNamedTypeWith, 16, 10),
    ]);

    var node = parseResult.findNode.classDeclaration('class C');
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  name: C
  withClause: WithClause
    withKeyword: with
    mixinTypes
      NamedType
        name: A
      NamedType
        name: B
  leftBracket: {
  rightBracket: }
''');
  }

  void test_classAlias_mixin() {
    var parseResult = parseStringWithErrors(r'''
mixin M {}
/// text
mixin class A = Object with M;
''');
    parseResult.assertNoErrors();

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
    var parseResult = parseStringWithErrors(r'''
class C = A Function() with M;
''');
    parseResult.assertErrors([
      error(ParserErrorCode.expectedNamedTypeExtends, 10, 12),
    ]);
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
    var parseResult = parseStringWithErrors(r'''
mixin M {}
/// text
base class A = Object with M;
''');
    parseResult.assertNoErrors();

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
    var parseResult = parseStringWithErrors(r'''
mixin M {}
/// text
final class A = Object with M;
''');
    parseResult.assertNoErrors();

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
    var parseResult = parseStringWithErrors(r'''
class C = Object with M implements A, (int, int), B;
mixin M {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.expectedNamedTypeImplements, 38, 10),
    ]);

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
    var parseResult = parseStringWithErrors(r'''
mixin M {}
/// text
interface class A = Object with M;
''');
    parseResult.assertNoErrors();

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
    var parseResult = parseStringWithErrors(r'''
mixin M {}
/// text
sealed class A = Object with M;
''');
    parseResult.assertNoErrors();

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
    var parseResult = parseStringWithErrors(r'''
class C = Object with A, (int, int), B;
''');
    parseResult.assertErrors([
      error(ParserErrorCode.expectedNamedTypeWith, 25, 10),
    ]);

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

  void test_constructor_factory_misnamed() {
    var parseResult = parseStringWithErrors(r'''
class A {
  factory B() => null;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.constructor('B()');
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  returnType: SimpleIdentifier
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
    var parseResult = parseStringWithErrors(r'''
class A {
  A() : super() = 0;
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.missingAssignableSelector, 18, 7),
      error(ParserErrorCode.invalidInitializer, 18, 11),
    ]);

    var node = parseResult.findNode.constructor('A()');
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  returnType: SimpleIdentifier
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
    var parseResult = parseStringWithErrors(r'''
abstract class A {
  final String f1;

  final int f2;

  const A(this.f1, this.f2);
}

class B extends A {
  const B(super.f1): super(2);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.constructor('B(');
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  constKeyword: const
  returnType: SimpleIdentifier
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
    var parseResult = parseStringWithErrors(r'''
class A {
  B() : super();
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.invalidConstructorName, 12, 1),
    ]);

    var node = parseResult.findNode.constructor('B()');
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  returnType: SimpleIdentifier
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
    var parseResult = parseStringWithErrors(r'''
class C {}

void main() {
  C c = .new();
}
''');
    parseResult.assertNoErrors();

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
    var parseResult = parseStringWithErrors(r'''
enum E { a }

void main() {
  E e = .a;
}
''');
    parseResult.assertNoErrors();

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
    var parseResult = parseStringWithErrors(r'''
base enum E { v }
''');
    parseResult.assertErrors([error(ParserErrorCode.baseEnum, 0, 4)]);

    var node = parseResult.findNode.enumDeclaration('enum E');
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  name: E
  leftBracket: {
  constants
    EnumConstantDeclaration
      name: v
  rightBracket: }
''');
  }

  void test_enum_constant_name_dot() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v.
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.missingIdentifier, 14, 1),
      error(ParserErrorCode.expectedToken, 14, 1),
    ]);

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
    var parseResult = parseStringWithErrors(r'''
enum E {
  v.named;
}
''');
    parseResult.assertErrors([error(ParserErrorCode.expectedToken, 13, 5)]);

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
    var parseResult = parseStringWithErrors(r'''
enum E {
  v.;
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.expectedToken, 13, 1),
      error(ParserErrorCode.missingIdentifier, 13, 1),
    ]);

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
    var parseResult = parseStringWithErrors(r'''
enum E {
  v<int>.
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.missingIdentifier, 19, 1),
      error(ParserErrorCode.expectedToken, 19, 1),
    ]);

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
    var parseResult = parseStringWithErrors(r'''
enum E {
  v<int>.;
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.missingIdentifier, 18, 1),
      error(ParserErrorCode.expectedToken, 18, 1),
    ]);

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
    var parseResult = parseStringWithErrors(r'''
enum E<T> {
  v<int>;
}
''');
    parseResult.assertErrors([error(ParserErrorCode.expectedToken, 19, 1)]);

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
    var parseResult = parseStringWithErrors(r'''
final enum E { v }
''');
    parseResult.assertErrors([error(ParserErrorCode.finalEnum, 0, 5)]);

    var node = parseResult.findNode.enumDeclaration('enum E');
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  name: E
  leftBracket: {
  constants
    EnumConstantDeclaration
      name: v
  rightBracket: }
''');
  }

  void test_enum_interface() {
    var parseResult = parseStringWithErrors(r'''
interface enum E { v }
''');
    parseResult.assertErrors([error(ParserErrorCode.interfaceEnum, 0, 9)]);

    var node = parseResult.findNode.enumDeclaration('enum E');
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  name: E
  leftBracket: {
  constants
    EnumConstantDeclaration
      name: v
  rightBracket: }
''');
  }

  void test_enum_sealed() {
    var parseResult = parseStringWithErrors(r'''
sealed enum E { v }
''');
    parseResult.assertErrors([error(ParserErrorCode.sealedEnum, 0, 6)]);

    var node = parseResult.findNode.enumDeclaration('enum E');
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  name: E
  leftBracket: {
  constants
    EnumConstantDeclaration
      name: v
  rightBracket: }
''');
  }

  void test_enum_semicolon_null() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.enumDeclaration('enum E');
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  name: E
  leftBracket: {
  constants
    EnumConstantDeclaration
      name: v
  rightBracket: }
''');
  }

  void test_enum_semicolon_optional() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.enumDeclaration('enum E');
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  name: E
  leftBracket: {
  constants
    EnumConstantDeclaration
      name: v
  semicolon: ;
  rightBracket: }
''');
  }

  void test_extension_onClause_recordType() {
    var parseResult = parseStringWithErrors(r'''
extension E on (int, int) {}
''');
    parseResult.assertNoErrors();

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
  leftBracket: { @26
  rightBracket: } @27
''', withOffsets: true);
  }

  void test_getter_sameNameAsClass() {
    var parseResult = parseStringWithErrors(r'''
class A {
  get A => 0;
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.memberWithClassName, 16, 1),
    ]);

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
    var parseResult = parseStringWithErrors(r'''
library name.and.dots;
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.library('library');
    assertParsedNodeText(node, r'''
LibraryDirective
  libraryKeyword: library
  name: LibraryIdentifier
    components
      SimpleIdentifier
        token: name
      SimpleIdentifier
        token: and
      SimpleIdentifier
        token: dots
  semicolon: ;
''');
  }

  void test_library_without_name() {
    var parseResult = parseStringWithErrors(r'''
library;
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.library('library');
    assertParsedNodeText(node, r'''
LibraryDirective
  libraryKeyword: library
  semicolon: ;
''');
  }

  void test_mixin_base() {
    var parseResult = parseStringWithErrors(r'''
/// text
base mixin M {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.mixinDeclaration('mixin M');
    assertParsedNodeText(node, r'''
MixinDeclaration
  documentationComment: Comment
    tokens
      /// text
  baseKeyword: base
  mixinKeyword: mixin
  name: M
  leftBracket: {
  rightBracket: }
''');
  }

  void test_mixin_final() {
    var parseResult = parseStringWithErrors(r'''
final mixin M {}
''');
    parseResult.assertErrors([error(ParserErrorCode.finalMixin, 0, 5)]);

    var node = parseResult.findNode.mixinDeclaration('mixin M');
    assertParsedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: M
  leftBracket: {
  rightBracket: }
''');
  }

  void test_mixin_implementsClause_recordType() {
    var parseResult = parseStringWithErrors(r'''
class C {}
mixin M on C implements A, (int, int), B {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.expectedNamedTypeImplements, 38, 10),
    ]);

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
  leftBracket: { @52
  rightBracket: } @53
''', withOffsets: true);
  }

  void test_mixin_interface() {
    var parseResult = parseStringWithErrors(r'''
interface mixin M {}
''');
    parseResult.assertErrors([error(ParserErrorCode.interfaceMixin, 0, 9)]);

    var node = parseResult.findNode.mixinDeclaration('mixin M');
    assertParsedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: M
  leftBracket: {
  rightBracket: }
''');
  }

  void test_mixin_onClause_recordType() {
    var parseResult = parseStringWithErrors(r'''
mixin M on A, (int, int), B {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.expectedNamedTypeOn, 14, 10),
    ]);

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
  leftBracket: { @28
  rightBracket: } @29
''', withOffsets: true);
  }

  void test_mixin_sealed() {
    var parseResult = parseStringWithErrors(r'''
sealed mixin M {}
''');
    parseResult.assertErrors([error(ParserErrorCode.sealedMixin, 0, 6)]);

    var node = parseResult.findNode.mixinDeclaration('mixin M');
    assertParsedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: M
  leftBracket: {
  rightBracket: }
''');
  }

  void test_recordLiteral() {
    var parseResult = parseStringWithErrors(r'''
final x = (0, a: 1);
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.recordLiteral('(0');
    assertParsedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    IntegerLiteral
      literal: 0
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: a
        colon: :
      expression: IntegerLiteral
        literal: 1
  rightParenthesis: )
''');
  }

  void test_recordLiteral_named_trailingComma() {
    var parseResult = parseStringWithErrors(r'''
final x = (0, a: 1,);
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.recordLiteral('(0');
    assertParsedNodeText(node, r'''
RecordLiteral
  leftParenthesis: (
  fields
    IntegerLiteral
      literal: 0
    NamedExpression
      name: Label
        label: SimpleIdentifier
          token: a
        colon: :
      expression: IntegerLiteral
        literal: 1
  rightParenthesis: )
''');
  }

  void test_recordLiteral_positional_one_trailingComma() {
    var parseResult = parseStringWithErrors(r'''
final x = (0,);
''');
    parseResult.assertNoErrors();

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
    var parseResult = parseStringWithErrors(r'''
final x = (0, 1,);
''');
    parseResult.assertNoErrors();

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
    var parseResult = parseStringWithErrors(r'''
() f() {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.recordTypeAnnotation('() f');
    assertParsedNodeText(node, r'''
RecordTypeAnnotation
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  void test_recordTypeAnnotation_mixed() {
    var parseResult = parseStringWithErrors(r'''
void f((int, bool, {int a, bool b}) r) {}
''');
    parseResult.assertNoErrors();

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
    var parseResult = parseStringWithErrors(r'''
void f(({int a, bool b}) r) {}
''');
    parseResult.assertNoErrors();

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
    var parseResult = parseStringWithErrors(r'''
void f(({int a, bool b,}) r) {}
''');
    parseResult.assertNoErrors();

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
    var parseResult = parseStringWithErrors(r'''
void f((int, bool)? r) {}
''');
    parseResult.assertNoErrors();

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
    var parseResult = parseStringWithErrors(r'''
void f((int, bool) r) {}
''');
    parseResult.assertNoErrors();

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
    var parseResult = parseStringWithErrors(r'''
void f((int) r) {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.recordTypeOnePositionalNoTrailingComma, 11, 1),
    ]);

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
    var parseResult = parseStringWithErrors(r'''
void f((int, ) r) {}
''');
    parseResult.assertNoErrors();

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
    var parseResult = parseStringWithErrors(r'''
void f((int, bool,) r) {}
''');
    parseResult.assertNoErrors();

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
    var parseResult = parseStringWithErrors(r'''
(int, T) f<T>() {}
''');
    parseResult.assertNoErrors();

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
    var parseResult = parseStringWithErrors(r'''
class A {
  A(super.a);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.superFormalParameter('super.a');
    assertParsedNodeText(node, r'''
SuperFormalParameter
  superKeyword: super
  period: .
  name: a
''');
  }

  void test_switchStatement_withPatternCase_whenDisabled() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 2.19
void f(Object value) {
  switch (value) {
    case (int a,) when a == 0:
  }
}
''');
    parseResult.assertErrors([error(ParserErrorCode.expectedToken, 72, 1)]);

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
