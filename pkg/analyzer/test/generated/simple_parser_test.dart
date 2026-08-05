// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'complex_parser_test.dart';
library;

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/node_text_expectations.dart';
import '../src/diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SimpleParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

/// Parser tests that test individual parsing methods. The code fragments should
/// be as minimal as possible in order to test the method, but should not test
/// the interactions between the method under test and other methods.
///
/// More complex tests should be defined in the class [ComplexParserTest].
@reflectiveTest
class SimpleParserTest extends ParserDiagnosticsTest {
  void test_classDeclaration_complexTypeParam() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C<@Foo.bar(const [], const [1], const {"": r""}, 0xFF + 2, .3, 4.5) T> {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              metadata
                Annotation
                  atSign: @
                  name: PrefixedIdentifier
                    prefix: SimpleIdentifier
                      token: Foo
                    period: .
                    identifier: SimpleIdentifier
                      token: bar
                  arguments: ArgumentList
                    leftParenthesis: (
                    arguments
                      ListLiteral
                        constKeyword: const
                        leftBracket: [
                        rightBracket: ]
                      ListLiteral
                        constKeyword: const
                        leftBracket: [
                        elements
                          IntegerLiteral
                            literal: 1
                        rightBracket: ]
                      SetOrMapLiteral
                        constKeyword: const
                        leftBracket: {
                        elements
                          MapLiteralEntry
                            key: SimpleStringLiteral
                              literal: ""
                            separator: :
                            value: SimpleStringLiteral
                              literal: r""
                        rightBracket: }
                        isMap: false
                      BinaryExpression
                        leftOperand: IntegerLiteral
                          literal: 0xFF
                        operator: +
                        rightOperand: IntegerLiteral
                          literal: 2
                      DoubleLiteral
                        literal: .3
                      DoubleLiteral
                        literal: 4.5
                    rightParenthesis: )
              name: T
          rightBracket: >
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_classDeclaration_invalid_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  C() : super.const();
//      ^^^^^
// [diag.invalidSuperInInitializer] Can only use 'super' in an initializer for calling the superclass constructor (e.g. 'super()' or 'super.namedConstructor()')
//            ^^^^^
// [diag.expectedIdentifierButGotKeyword] 'const' can't be used as an identifier because it's a keyword.
// [diag.missingIdentifier] Expected an identifier.
}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                argumentList: ArgumentList
                  leftParenthesis: ( <synthetic>
                  rightParenthesis: ) <synthetic>
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_classDeclaration_invalid_this() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  C() : this.const();
//      ^^^^
// [diag.missingAssignmentInInitializer] Expected an assignment after the field name.
//           ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.missingFunctionBody] A function body must be provided.
// [diag.constMethod] Getters, setters and methods can't be declared to be 'const'.
//                ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              ConstructorFieldInitializer
                fieldName: SimpleIdentifier
                  token: <empty> <synthetic>
                equals: = <synthetic>
                expression: PropertyAccess
                  target: ThisExpression
                    thisKeyword: this
                  operator: .
                  propertyName: SimpleIdentifier
                    token: <empty> <synthetic>
            body: BlockFunctionBody
              block: Block
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
          MethodDeclaration
            name: <empty> <synthetic>
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_method_name_notNull_37733() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  f(<T>());
//  ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          MethodDeclaration
            name: f
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                name: <empty> <synthetic>
                functionTypedSuffix: FunctionTypedFormalParameterSuffix
                  typeParameters: TypeParameterList
                    leftBracket: <
                    typeParameters
                      TypeParameter
                        name: T
                    rightBracket: >
                  formalParameters: FormalParameterList
                    leftParenthesis: (
                    rightParenthesis: )
              rightParenthesis: )
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_parseAnnotation_n1() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@A
class C {}
''');
    var node = parseResult.findNode.singleAnnotation;
    assertParsedNodeText(node, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
''');
  }

  void test_parseAnnotation_n1_a() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@A(x, y)
class C {}
''');
    var node = parseResult.findNode.singleAnnotation;
    assertParsedNodeText(node, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: x
      SimpleIdentifier
        token: y
    rightParenthesis: )
''');
  }

  void test_parseAnnotation_n2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@A.B
class C {}
''');
    var node = parseResult.findNode.singleAnnotation;
    assertParsedNodeText(node, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
    period: .
    identifier: SimpleIdentifier
      token: B
''');
  }

  void test_parseAnnotation_n2_a() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@A.B(x, y)
class C {}
''');
    var node = parseResult.findNode.singleAnnotation;
    assertParsedNodeText(node, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
    period: .
    identifier: SimpleIdentifier
      token: B
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: x
      SimpleIdentifier
        token: y
    rightParenthesis: )
''');
  }

  void test_parseAnnotation_n3() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@A.B.C
class C {}
''');
    var node = parseResult.findNode.singleAnnotation;
    assertParsedNodeText(node, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
    period: .
    identifier: SimpleIdentifier
      token: B
  period: .
  constructorName: SimpleIdentifier
    token: C
''');
  }

  void test_parseAnnotation_n3_a() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@A.B.C(x, y)
class C {}
''');
    var node = parseResult.findNode.singleAnnotation;
    assertParsedNodeText(node, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
    period: .
    identifier: SimpleIdentifier
      token: B
  period: .
  constructorName: SimpleIdentifier
    token: C
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: x
      SimpleIdentifier
        token: y
    rightParenthesis: )
''');
  }

  test_parseArgument() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = m(3);
''');
    var node =
        parseResult.findNode.singleMethodInvocation.argumentList.arguments[0];
    assertParsedNodeText(node, r'''
IntegerLiteral
  literal: 3
''');
  }

  test_parseArgument_named() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = m(foo: "a");
''');
    var node =
        parseResult.findNode.singleMethodInvocation.argumentList.arguments[0];
    assertParsedNodeText(node, r'''
NamedArgument
  name: foo
  colon: :
  argumentExpression: SimpleStringLiteral
    literal: "a"
''');
  }

  void test_parseArgumentList_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = m();
''');
    var node = parseResult.findNode.methodInvocation('m(').argumentList;
    assertParsedNodeText(node, r'''
ArgumentList
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  void test_parseArgumentList_mixed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = m(w, x, y: y, z: z);
''');
    var node = parseResult.findNode.methodInvocation('m(').argumentList;
    assertParsedNodeText(node, r'''
ArgumentList
  leftParenthesis: (
  arguments
    SimpleIdentifier
      token: w
    SimpleIdentifier
      token: x
    NamedArgument
      name: y
      colon: :
      argumentExpression: SimpleIdentifier
        token: y
    NamedArgument
      name: z
      colon: :
      argumentExpression: SimpleIdentifier
        token: z
  rightParenthesis: )
''');
  }

  void test_parseArgumentList_noNamed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = m(x, y, z);
''');
    var node = parseResult.findNode.methodInvocation('m(').argumentList;
    assertParsedNodeText(node, r'''
ArgumentList
  leftParenthesis: (
  arguments
    SimpleIdentifier
      token: x
    SimpleIdentifier
      token: y
    SimpleIdentifier
      token: z
  rightParenthesis: )
''');
  }

  void test_parseArgumentList_onlyNamed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = m(x: x, y: y);
''');
    var node = parseResult.findNode.methodInvocation('m(').argumentList;
    assertParsedNodeText(node, r'''
ArgumentList
  leftParenthesis: (
  arguments
    NamedArgument
      name: x
      colon: :
      argumentExpression: SimpleIdentifier
        token: x
    NamedArgument
      name: y
      colon: :
      argumentExpression: SimpleIdentifier
        token: y
  rightParenthesis: )
''');
  }

  void test_parseArgumentList_trailing_comma() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = m(x, y, z);
''');
    var node = parseResult.findNode.methodInvocation('m(').argumentList;
    assertParsedNodeText(node, r'''
ArgumentList
  leftParenthesis: (
  arguments
    SimpleIdentifier
      token: x
    SimpleIdentifier
      token: y
    SimpleIdentifier
      token: z
  rightParenthesis: )
''');
  }

  void test_parseArgumentList_typeArguments() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = m(a<b, c>(d));
''');
    var node = parseResult.findNode.methodInvocation('m(').argumentList;
    assertParsedNodeText(node, r'''
ArgumentList
  leftParenthesis: (
  arguments
    MethodInvocation
      methodName: SimpleIdentifier
        token: a
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: b
          NamedType
            name: c
        rightBracket: >
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: d
        rightParenthesis: )
  rightParenthesis: )
''');
  }

  void test_parseArgumentList_typeArguments_none() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = m(a < b, p.q.c > (d));
''');
    var node = parseResult.findNode.methodInvocation('m(').argumentList;
    assertParsedNodeText(node, r'''
ArgumentList
  leftParenthesis: (
  arguments
    BinaryExpression
      leftOperand: SimpleIdentifier
        token: a
      operator: <
      rightOperand: SimpleIdentifier
        token: b
    BinaryExpression
      leftOperand: PropertyAccess
        target: PrefixedIdentifier
          prefix: SimpleIdentifier
            token: p
          period: .
          identifier: SimpleIdentifier
            token: q
        operator: .
        propertyName: SimpleIdentifier
          token: c
      operator: >
      rightOperand: ParenthesizedExpression
        leftParenthesis: (
        expression: SimpleIdentifier
          token: d
        rightParenthesis: )
  rightParenthesis: )
''');
  }

  void test_parseArgumentList_typeArguments_prefixed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = m(a<b, p.c>(d));
''');
    var node = parseResult.findNode.methodInvocation('m(').argumentList;
    assertParsedNodeText(node, r'''
ArgumentList
  leftParenthesis: (
  arguments
    MethodInvocation
      methodName: SimpleIdentifier
        token: a
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: b
          NamedType
            importPrefix: ImportPrefixReference
              name: p
              period: .
            name: c
        rightBracket: >
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: d
        rightParenthesis: )
  rightParenthesis: )
''');
  }

  void test_parseCombinators_h() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'a.dart' hide a;
''');
    var node = parseResult.findNode.singleImportDirective;
    assertParsedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: SimpleStringLiteral
    literal: 'a.dart'
  combinators
    HideCombinator
      keyword: hide
      hiddenNames
        SimpleIdentifier
          token: a
  semicolon: ;
''');
  }

  void test_parseCombinators_hs() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'a.dart' hide a show b;
''');
    var node = parseResult.findNode.singleImportDirective;
    assertParsedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: SimpleStringLiteral
    literal: 'a.dart'
  combinators
    HideCombinator
      keyword: hide
      hiddenNames
        SimpleIdentifier
          token: a
    ShowCombinator
      keyword: show
      shownNames
        SimpleIdentifier
          token: b
  semicolon: ;
''');
  }

  void test_parseCombinators_hshs() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'a.dart' hide a show b hide c show d;
''');
    var node = parseResult.findNode.singleImportDirective;
    assertParsedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: SimpleStringLiteral
    literal: 'a.dart'
  combinators
    HideCombinator
      keyword: hide
      hiddenNames
        SimpleIdentifier
          token: a
    ShowCombinator
      keyword: show
      shownNames
        SimpleIdentifier
          token: b
    HideCombinator
      keyword: hide
      hiddenNames
        SimpleIdentifier
          token: c
    ShowCombinator
      keyword: show
      shownNames
        SimpleIdentifier
          token: d
  semicolon: ;
''');
  }

  void test_parseCombinators_s() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'a.dart' show a;
''');
    var node = parseResult.findNode.singleImportDirective;
    assertParsedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: SimpleStringLiteral
    literal: 'a.dart'
  combinators
    ShowCombinator
      keyword: show
      shownNames
        SimpleIdentifier
          token: a
  semicolon: ;
''');
  }

  void test_parseCommentAndMetadata_c() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/** 1 */
class C {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      documentationComment: Comment
        tokens
          /** 1 */
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseCommentAndMetadata_cmc() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/** 1 */
@A
/** 2 */
class C {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      documentationComment: Comment
        tokens
          /** 2 */
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: A
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseCommentAndMetadata_cmcm() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/** 1 */
@A
/** 2 */
@B
class C {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      documentationComment: Comment
        tokens
          /** 2 */
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: A
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: B
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseCommentAndMetadata_cmm() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/** 1 */
@A
@B
class C {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      documentationComment: Comment
        tokens
          /** 1 */
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: A
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: B
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseCommentAndMetadata_m() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@A
class C {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: A
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseCommentAndMetadata_mcm() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@A
/** 1 */
@B
class C {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      documentationComment: Comment
        tokens
          /** 1 */
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: A
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: B
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseCommentAndMetadata_mcmc() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@A
/** 1 */
@B
/** 2 */
class C {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      documentationComment: Comment
        tokens
          /** 2 */
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: A
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: B
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseCommentAndMetadata_mix1() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/**
 * aaa
 */
/**
 * bbb
 */
class A {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      documentationComment: Comment
        tokens
          /**
 * bbb
 */
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseCommentAndMetadata_mix2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/**
 * aaa
 */
/// bbb
/// ccc
class B {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      documentationComment: Comment
        tokens
          /// bbb
          /// ccc
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: B
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseCommentAndMetadata_mix3() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// aaa
/// bbb
/**
 * ccc
 */
class C {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      documentationComment: Comment
        tokens
          /**
 * ccc
 */
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  test_parseCommentAndMetadata_mix4() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// aaa
/// bbb
/**
 * ccc
 */
/// ddd
class D {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      documentationComment: Comment
        tokens
          /// ddd
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: D
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  test_parseCommentAndMetadata_mix5() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/**
 * aaa
 */
// bbb
class E {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      documentationComment: Comment
        tokens
          /**
 * aaa
 */
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: E
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseCommentAndMetadata_mm() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@A
@B(x)
class C {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: A
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: B
          arguments: ArgumentList
            leftParenthesis: (
            arguments
              SimpleIdentifier
                token: x
            rightParenthesis: )
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseCommentAndMetadata_none() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseCommentAndMetadata_singleLine() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/// 1
/// 2
class C {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      documentationComment: Comment
        tokens
          /// 1
          /// 2
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseCommentReferences_notClosed_noIdentifier() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/** [ some text */
class C {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  documentationComment: Comment
    references
      CommentReference
        expression: SimpleIdentifier
          token: <empty> <synthetic>
    tokens
      /** [ some text */
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: C
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_parseConfiguration_noOperator_dottedIdentifier() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'a.dart' if (a.b) 'c.dart';
''');
    var node = parseResult.findNode.singleConfiguration;
    assertParsedNodeText(node, r'''
Configuration
  ifKeyword: if
  leftParenthesis: (
  name: DottedName
    tokens
      a
      .
      b
  rightParenthesis: )
  uri: SimpleStringLiteral
    literal: 'c.dart'
  resolvedUri: <null>
''');
  }

  void test_parseConfiguration_noOperator_simpleIdentifier() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'a.dart' if (a) 'b.dart';
''');
    var node = parseResult.findNode.singleConfiguration;
    assertParsedNodeText(node, r'''
Configuration
  ifKeyword: if
  leftParenthesis: (
  name: DottedName
    tokens
      a
  rightParenthesis: )
  uri: SimpleStringLiteral
    literal: 'b.dart'
  resolvedUri: <null>
''');
  }

  void test_parseConfiguration_operator_dottedIdentifier() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'a.dart' if (a.b == 'c') 'd.dart';
''');
    var node = parseResult.findNode.singleConfiguration;
    assertParsedNodeText(node, r'''
Configuration
  ifKeyword: if
  leftParenthesis: (
  name: DottedName
    tokens
      a
      .
      b
  equalToken: ==
  value: SimpleStringLiteral
    literal: 'c'
  rightParenthesis: )
  uri: SimpleStringLiteral
    literal: 'd.dart'
  resolvedUri: <null>
''');
  }

  void test_parseConfiguration_operator_simpleIdentifier() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'a.dart' if (a == 'b') 'c.dart';
''');
    var node = parseResult.findNode.singleConfiguration;
    assertParsedNodeText(node, r'''
Configuration
  ifKeyword: if
  leftParenthesis: (
  name: DottedName
    tokens
      a
  equalToken: ==
  value: SimpleStringLiteral
    literal: 'b'
  rightParenthesis: )
  uri: SimpleStringLiteral
    literal: 'c.dart'
  resolvedUri: <null>
''');
  }

  void test_parseConstructorName_named_noPrefix() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = new A.n();
''');
    var node =
        parseResult.findNode.singleInstanceCreationExpression.constructorName;
    assertParsedNodeText(node, r'''
ConstructorName
  type: NamedType
    importPrefix: ImportPrefixReference
      name: A
      period: .
    name: n
''');
  }

  void test_parseConstructorName_named_prefixed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = new p.A.n();
''');
    var node =
        parseResult.findNode.singleInstanceCreationExpression.constructorName;
    assertParsedNodeText(node, r'''
ConstructorName
  type: NamedType
    importPrefix: ImportPrefixReference
      name: p
      period: .
    name: A
  period: .
  name: SimpleIdentifier
    token: n
''');
  }

  void test_parseConstructorName_unnamed_noPrefix() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = new A();
''');
    var node =
        parseResult.findNode.singleInstanceCreationExpression.constructorName;
    assertParsedNodeText(node, r'''
ConstructorName
  type: NamedType
    name: A
''');
  }

  void test_parseConstructorName_unnamed_prefixed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var v = new p.A();
''');
    var node =
        parseResult.findNode.singleInstanceCreationExpression.constructorName;
    assertParsedNodeText(node, r'''
ConstructorName
  type: NamedType
    importPrefix: ImportPrefixReference
      name: p
      period: .
    name: A
''');
  }

  void test_parseDocumentationComment_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/** */
class C {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      documentationComment: Comment
        tokens
          /** */
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseDocumentationComment_block_withReference() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
/** [a] */
class C {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      documentationComment: Comment
        references
          CommentReference
            expression: SimpleIdentifier
              token: a
        tokens
          /** [a] */
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseDocumentationComment_endOfLine() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
///
///
class C {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      documentationComment: Comment
        tokens
          ///
          ///
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseExtendsClause() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class TestClass extends B {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: TestClass
  extendsClause: ExtendsClause
    extendsKeyword: extends
    superclass: NamedType
      name: B
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_parseFunctionBody_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {}
''');
    var node =
        parseResult.findNode.singleFunctionDeclaration.functionExpression.body;
    assertParsedNodeText(node, r'''
BlockFunctionBody
  block: Block
    leftBracket: {
    rightBracket: }
''');
  }

  void test_parseFunctionBody_block_async() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() async {}
''');
    var node =
        parseResult.findNode.singleFunctionDeclaration.functionExpression.body;
    assertParsedNodeText(node, r'''
BlockFunctionBody
  keyword: async
  block: Block
    leftBracket: {
    rightBracket: }
''');
  }

  void test_parseFunctionBody_block_asyncGenerator() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() async* {}
''');
    var node =
        parseResult.findNode.singleFunctionDeclaration.functionExpression.body;
    assertParsedNodeText(node, r'''
BlockFunctionBody
  keyword: async
  star: *
  block: Block
    leftBracket: {
    rightBracket: }
''');
  }

  void test_parseFunctionBody_block_syncGenerator() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() sync* {}
''');
    var node =
        parseResult.findNode.singleFunctionDeclaration.functionExpression.body;
    assertParsedNodeText(node, r'''
BlockFunctionBody
  keyword: sync
  star: *
  block: Block
    leftBracket: {
    rightBracket: }
''');
  }

  void test_parseFunctionBody_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() ;
''');
    var node = parseResult.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      returnType: NamedType
        name: void
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: EmptyFunctionBody
          semicolon: ;
''');
  }

  void test_parseFunctionBody_empty_language305() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.5
void f() ;
//       ^
// [diag.missingFunctionBody] A function body must be provided.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      returnType: NamedType
        name: void
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: EmptyFunctionBody
          semicolon: ;
''');
  }

  void test_parseFunctionBody_expression() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() => y;
''');
    var node =
        parseResult.findNode.singleFunctionDeclaration.functionExpression.body;
    assertParsedNodeText(node, r'''
ExpressionFunctionBody
  functionDefinition: =>
  expression: SimpleIdentifier
    token: y
  semicolon: ;
''');
  }

  void test_parseFunctionBody_expression_async() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() async => y;
''');
    var node =
        parseResult.findNode.singleFunctionDeclaration.functionExpression.body;
    assertParsedNodeText(node, r'''
ExpressionFunctionBody
  keyword: async
  functionDefinition: =>
  expression: SimpleIdentifier
    token: y
  semicolon: ;
''');
  }

  void test_parseIdentifierList_multiple() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'a.dart' show a, b, c;
''');
    var node = parseResult.findNode.singleImportDirective;
    assertParsedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: SimpleStringLiteral
    literal: 'a.dart'
  combinators
    ShowCombinator
      keyword: show
      shownNames
        SimpleIdentifier
          token: a
        SimpleIdentifier
          token: b
        SimpleIdentifier
          token: c
  semicolon: ;
''');
  }

  void test_parseIdentifierList_single() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
import 'a.dart' show a;
''');
    var node = parseResult.findNode.singleImportDirective;
    assertParsedNodeText(node, r'''
ImportDirective
  importKeyword: import
  uri: SimpleStringLiteral
    literal: 'a.dart'
  combinators
    ShowCombinator
      keyword: show
      shownNames
        SimpleIdentifier
          token: a
  semicolon: ;
''');
  }

  void test_parseImplementsClause_multiple() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class TestClass implements A, B, C {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: TestClass
  implementsClause: ImplementsClause
    implementsKeyword: implements
    interfaces
      NamedType
        name: A
      NamedType
        name: B
      NamedType
        name: C
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_parseImplementsClause_single() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class TestClass implements A {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: TestClass
  implementsClause: ImplementsClause
    implementsKeyword: implements
    interfaces
      NamedType
        name: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_parseInstanceCreation_keyword_33647() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var c = new Future<int>.sync(() => 3).then<int>((e) => e);
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: c
            equals: =
            initializer: MethodInvocation
              target: InstanceCreationExpression
                keyword: new
                constructorName: ConstructorName
                  type: NamedType
                    name: Future
                    typeArguments: TypeArgumentList
                      leftBracket: <
                      arguments
                        NamedType
                          name: int
                      rightBracket: >
                  period: .
                  name: SimpleIdentifier
                    token: sync
                argumentList: ArgumentList
                  leftParenthesis: (
                  arguments
                    FunctionExpression
                      parameters: FormalParameterList
                        leftParenthesis: (
                        rightParenthesis: )
                      body: ExpressionFunctionBody
                        functionDefinition: =>
                        expression: IntegerLiteral
                          literal: 3
                  rightParenthesis: )
              operator: .
              methodName: SimpleIdentifier
                token: then
              typeArguments: TypeArgumentList
                leftBracket: <
                arguments
                  NamedType
                    name: int
                rightBracket: >
              argumentList: ArgumentList
                leftParenthesis: (
                arguments
                  FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      parameter: RegularFormalParameter
                        name: e
                      rightParenthesis: )
                    body: ExpressionFunctionBody
                      functionDefinition: =>
                      expression: SimpleIdentifier
                        token: e
                rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseInstanceCreation_noKeyword_33647() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var c = Future<int>.sync(() => 3).then<int>((e) => e);
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: c
            equals: =
            initializer: MethodInvocation
              target: InstanceCreationExpression
                constructorName: ConstructorName
                  type: NamedType
                    name: Future
                    typeArguments: TypeArgumentList
                      leftBracket: <
                      arguments
                        NamedType
                          name: int
                      rightBracket: >
                  period: .
                  name: SimpleIdentifier
                    token: sync
                argumentList: ArgumentList
                  leftParenthesis: (
                  arguments
                    FunctionExpression
                      parameters: FormalParameterList
                        leftParenthesis: (
                        rightParenthesis: )
                      body: ExpressionFunctionBody
                        functionDefinition: =>
                        expression: IntegerLiteral
                          literal: 3
                  rightParenthesis: )
              operator: .
              methodName: SimpleIdentifier
                token: then
              typeArguments: TypeArgumentList
                leftBracket: <
                arguments
                  NamedType
                    name: int
                rightBracket: >
              argumentList: ArgumentList
                leftParenthesis: (
                arguments
                  FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      parameter: RegularFormalParameter
                        name: e
                      rightParenthesis: )
                    body: ExpressionFunctionBody
                      functionDefinition: =>
                      expression: SimpleIdentifier
                        token: e
                rightParenthesis: )
      semicolon: ;
''');
  }

  void test_parseInstanceCreation_noKeyword_noPrefix() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() => C<E>.n();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: InstanceCreationExpression
            constructorName: ConstructorName
              type: NamedType
                name: C
                typeArguments: TypeArgumentList
                  leftBracket: <
                  arguments
                    NamedType
                      name: E
                  rightBracket: >
              period: .
              name: SimpleIdentifier
                token: n
            argumentList: ArgumentList
              leftParenthesis: (
              rightParenthesis: )
          semicolon: ;
''');
  }

  void test_parseInstanceCreation_noKeyword_noPrefix_34403() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() => C<E>.n<B>();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: MethodInvocation
            target: FunctionReference
              function: SimpleIdentifier
                token: C
              typeArguments: TypeArgumentList
                leftBracket: <
                arguments
                  NamedType
                    name: E
                rightBracket: >
            operator: .
            methodName: SimpleIdentifier
              token: n
            typeArguments: TypeArgumentList
              leftBracket: <
              arguments
                NamedType
                  name: B
              rightBracket: >
            argumentList: ArgumentList
              leftParenthesis: (
              rightParenthesis: )
          semicolon: ;
''');
  }

  void test_parseInstanceCreation_noKeyword_prefix() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() => p.C<E>.n();
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: InstanceCreationExpression
            constructorName: ConstructorName
              type: NamedType
                importPrefix: ImportPrefixReference
                  name: p
                  period: .
                name: C
                typeArguments: TypeArgumentList
                  leftBracket: <
                  arguments
                    NamedType
                      name: E
                  rightBracket: >
              period: .
              name: SimpleIdentifier
                token: n
            argumentList: ArgumentList
              leftParenthesis: (
              rightParenthesis: )
          semicolon: ;
''');
  }

  void test_parseInstanceCreation_noKeyword_varInit() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C<T, S> {}

void main() {
  final c = C<int, int Function(String)>();
}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: T
            TypeParameter
              name: S
          rightBracket: >
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
    FunctionDeclaration
      returnType: NamedType
        name: void
      name: main
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
                      name: c
                      equals: =
                      initializer: MethodInvocation
                        methodName: SimpleIdentifier
                          token: C
                        typeArguments: TypeArgumentList
                          leftBracket: <
                          arguments
                            NamedType
                              name: int
                            GenericFunctionType
                              returnType: NamedType
                                name: int
                              functionKeyword: Function
                              parameters: FormalParameterList
                                leftParenthesis: (
                                parameter: RegularFormalParameter
                                  type: NamedType
                                    name: String
                                rightParenthesis: )
                          rightBracket: >
                        argumentList: ArgumentList
                          leftParenthesis: (
                          rightParenthesis: )
                semicolon: ;
            rightBracket: }
''');
  }

  void test_parseLibraryIdentifier_builtin() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library $name;
''');
    var node = parseResult.findNode.singleLibraryDirective;
    assertParsedNodeText(node, r'''
LibraryDirective
  libraryKeyword: library
  name: DottedName
    tokens
      $name
  semicolon: ;
''');
  }

  void test_parseLibraryIdentifier_invalid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library <myLibId>;
// [diag.missingFunctionParameters][column 1][length 7] Functions must have an explicit list of parameters.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: library
      functionExpression: FunctionExpression
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: myLibId
          rightBracket: >
        parameters: FormalParameterList
          leftParenthesis: ( <synthetic>
          rightParenthesis: ) <synthetic>
        body: EmptyFunctionBody
          semicolon: ;
''');
  }

  void test_parseLibraryIdentifier_multiple() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library $name;
''');
    var node = parseResult.findNode.singleLibraryDirective;
    assertParsedNodeText(node, r'''
LibraryDirective
  libraryKeyword: library
  name: DottedName
    tokens
      $name
  semicolon: ;
''');
  }

  void test_parseLibraryIdentifier_pseudo() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library $name;
''');
    var node = parseResult.findNode.singleLibraryDirective;
    assertParsedNodeText(node, r'''
LibraryDirective
  libraryKeyword: library
  name: DottedName
    tokens
      $name
  semicolon: ;
''');
  }

  void test_parseLibraryIdentifier_single() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library $name;
''');
    var node = parseResult.findNode.singleLibraryDirective;
    assertParsedNodeText(node, r'''
LibraryDirective
  libraryKeyword: library
  name: DottedName
    tokens
      $name
  semicolon: ;
''');
  }

  void test_parseOptionalReturnType() {
    // TODO(brianwilkerson): Implement tests for this method.
  }

  void test_parseReturnStatement_noValue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return;
}
''');
    var node = parseResult.findNode.firstBlock.statements[0];
    assertParsedNodeText(node, r'''
ReturnStatement
  returnKeyword: return
  semicolon: ;
''');
  }

  void test_parseReturnStatement_value() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return x;
}
''');
    var node = parseResult.findNode.firstBlock.statements[0];
    assertParsedNodeText(node, r'''
ReturnStatement
  returnKeyword: return
  expression: SimpleIdentifier
    token: x
  semicolon: ;
''');
  }

  void test_parseStatement_function_noReturnType() {
    var parseResult = parseTestCodeWithDiagnostics('''
void f() {
  Function<A>(core.List<core.int> x) m() => null;
}
''');
    var node = parseResult.findNode.firstBlock.statements[0];
    assertParsedNodeText(node, '''
FunctionDeclarationStatement
  functionDeclaration: FunctionDeclaration
    returnType: GenericFunctionType
      functionKeyword: Function
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: A
        rightBracket: >
      parameters: FormalParameterList
        leftParenthesis: (
        parameter: RegularFormalParameter
          type: NamedType
            importPrefix: ImportPrefixReference
              name: core
              period: .
            name: List
            typeArguments: TypeArgumentList
              leftBracket: <
              arguments
                NamedType
                  importPrefix: ImportPrefixReference
                    name: core
                    period: .
                  name: int
              rightBracket: >
          name: x
        rightParenthesis: )
    name: m
    functionExpression: FunctionExpression
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

  void test_parseStatements_multiple() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return;
  return;
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ReturnStatement
      returnKeyword: return
      semicolon: ;
    ReturnStatement
      returnKeyword: return
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseStatements_single() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  return;
}
''');
    var node = parseResult.findNode.firstBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ReturnStatement
      returnKeyword: return
      semicolon: ;
  rightBracket: }
''');
  }

  void test_parseTypeAnnotation_function_noReturnType_noParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(Function() x) {}
''');
    var node = parseResult.findNode.firstFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: GenericFunctionType
    functionKeyword: Function
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  name: x
''');
  }

  void test_parseTypeAnnotation_function_noReturnType_parameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(Function(int, int) x) {}
''');
    var node = parseResult.findNode.firstFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: GenericFunctionType
    functionKeyword: Function
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: int
      parameter: RegularFormalParameter
        type: NamedType
          name: int
      rightParenthesis: )
  name: x
''');
  }

  void test_parseTypeAnnotation_function_noReturnType_typeParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(Function<S, T>() x) {}
''');
    var node = parseResult.findNode.firstFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: GenericFunctionType
    functionKeyword: Function
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: S
        TypeParameter
          name: T
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  name: x
''');
  }

  void
  test_parseTypeAnnotation_function_noReturnType_typeParameters_parameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(Function<T>(String, {T t}) x) {}
''');
    var node = parseResult.findNode.firstFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: GenericFunctionType
    functionKeyword: Function
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: String
      leftDelimiter: {
      parameter: RegularFormalParameter
        type: NamedType
          name: T
        name: t
      rightDelimiter: }
      rightParenthesis: )
  name: x
''');
  }

  void test_parseTypeAnnotation_function_returnType_classFunction() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(Function x) {}
''');
    var node = parseResult.findNode.firstFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: NamedType
    name: Function
  name: x
''');
  }

  void test_parseTypeAnnotation_function_returnType_function() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(A Function(B, C) Function(D) x) {}
''');
    var node = parseResult.findNode.firstFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: GenericFunctionType
    returnType: GenericFunctionType
      returnType: NamedType
        name: A
      functionKeyword: Function
      parameters: FormalParameterList
        leftParenthesis: (
        parameter: RegularFormalParameter
          type: NamedType
            name: B
        parameter: RegularFormalParameter
          type: NamedType
            name: C
        rightParenthesis: )
    functionKeyword: Function
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: D
      rightParenthesis: )
  name: x
''');
  }

  void test_parseTypeAnnotation_function_returnType_noParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(List<int> Function() x) {}
''');
    var node = parseResult.findNode.firstFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: GenericFunctionType
    returnType: NamedType
      name: List
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
    functionKeyword: Function
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  name: x
''');
  }

  void test_parseTypeAnnotation_function_returnType_parameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(List<int> Function(String s, int i) x) {}
''');
    var node = parseResult.findNode.firstFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: GenericFunctionType
    returnType: NamedType
      name: List
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
    functionKeyword: Function
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: String
        name: s
      parameter: RegularFormalParameter
        type: NamedType
          name: int
        name: i
      rightParenthesis: )
  name: x
''');
  }

  void test_parseTypeAnnotation_function_returnType_simple() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(A Function(B, C) x) {}
''');
    var node = parseResult.findNode.firstFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: GenericFunctionType
    returnType: NamedType
      name: A
    functionKeyword: Function
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: B
      parameter: RegularFormalParameter
        type: NamedType
          name: C
      rightParenthesis: )
  name: x
''');
  }

  void test_parseTypeAnnotation_function_returnType_typeParameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(List<T> Function<T>() x) {}
''');
    var node = parseResult.findNode.firstFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: GenericFunctionType
    returnType: NamedType
      name: List
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: T
        rightBracket: >
    functionKeyword: Function
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  name: x
''');
  }

  void
  test_parseTypeAnnotation_function_returnType_typeParameters_parameters() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(List<T> Function<T>(String s, [T]) x) {}
''');
    var node = parseResult.findNode.firstFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: GenericFunctionType
    returnType: NamedType
      name: List
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: T
        rightBracket: >
    functionKeyword: Function
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: String
        name: s
      leftDelimiter: [
      parameter: RegularFormalParameter
        type: NamedType
          name: T
      rightDelimiter: ]
      rightParenthesis: )
  name: x
''');
  }

  void test_parseTypeAnnotation_function_returnType_withArguments() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(A<B> Function(C) x) {}
''');
    var node = parseResult.findNode.firstFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: GenericFunctionType
    returnType: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: B
        rightBracket: >
    functionKeyword: Function
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: C
      rightParenthesis: )
  name: x
''');
  }

  void test_parseTypeAnnotation_named() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(A<B> x) {}
''');
    var node = parseResult.findNode.firstFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: NamedType
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: B
      rightBracket: >
  name: x
''');
  }

  void test_parseTypeArgumentList_empty() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(
  C<> x,
//  ^
// [diag.expectedTypeName] Expected a type name.
) {}
''');
    var node = parseResult.findNode.firstFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: <empty> <synthetic>
      rightBracket: >
  name: x
''');
  }

  void test_parseTypeArgumentList_multiple() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(C<int, int, int> x) {}
''');
    var node = parseResult.findNode.firstFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
        NamedType
          name: int
        NamedType
          name: int
      rightBracket: >
  name: x
''');
  }

  void test_parseTypeArgumentList_nested() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(C<A<B>> x) {}
''');
    var node = parseResult.findNode.firstFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: A
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: B
            rightBracket: >
      rightBracket: >
  name: x
''');
  }

  void test_parseTypeArgumentList_nested_withComment_double() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(C<A<B /* 0 */>> x) {}
''');
    var node = parseResult.findNode.firstFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: A
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: B
            rightBracket: >
      rightBracket: >
  name: x
''');
  }

  void test_parseTypeArgumentList_nested_withComment_tripple() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(C<A<B<C /* 0 */>>> x) {}
''');
    var node = parseResult.findNode.firstFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: A
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: B
                typeArguments: TypeArgumentList
                  leftBracket: <
                  arguments
                    NamedType
                      name: C
                  rightBracket: >
            rightBracket: >
      rightBracket: >
  name: x
''');
  }

  void test_parseTypeArgumentList_single() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(C<int> x) {}
''');
    var node = parseResult.findNode.firstFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
      rightBracket: >
  name: x
''');
  }

  void test_parseTypeName_parameterized() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(List<int> x) {}
''');
    var node = parseResult.findNode.firstFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: NamedType
    name: List
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
      rightBracket: >
  name: x
''');
  }

  void test_parseTypeName_simple() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f(int x) {}
''');
    var node = parseResult.findNode.firstFormalParameter;
    assertParsedNodeText(node, r'''
RegularFormalParameter
  type: NamedType
    name: int
  name: x
''');
  }

  void test_parseTypeParameter_bounded_functionType_noReturn() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C<A extends Function(int)> {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: C
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: A
          extendsKeyword: extends
          bound: GenericFunctionType
            functionKeyword: Function
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: int
              rightParenthesis: )
      rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_parseTypeParameter_bounded_functionType_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C<A extends String Function(int)> {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: C
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: A
          extendsKeyword: extends
          bound: GenericFunctionType
            returnType: NamedType
              name: String
            functionKeyword: Function
            parameters: FormalParameterList
              leftParenthesis: (
              parameter: RegularFormalParameter
                type: NamedType
                  name: int
              rightParenthesis: )
      rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_parseTypeParameter_bounded_generic() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C<A extends B<C>> {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: C
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: A
          extendsKeyword: extends
          bound: NamedType
            name: B
            typeArguments: TypeArgumentList
              leftBracket: <
              arguments
                NamedType
                  name: C
              rightBracket: >
      rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_parseTypeParameter_bounded_simple() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C<A extends B> {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: C
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: A
          extendsKeyword: extends
          bound: NamedType
            name: B
      rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_parseTypeParameter_simple() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C<A> {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: C
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: A
      rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_parseTypeParameterList_multiple() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C<A, B extends C, D> {}
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: A
            TypeParameter
              name: B
              extendsKeyword: extends
              bound: NamedType
                name: C
            TypeParameter
              name: D
          rightBracket: >
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parseTypeParameterList_parameterizedWithTrailingEquals() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C<A extends B<E>>= {}
//                     ^
// [diag.expectedToken] Expected to find ';'.
//                       ^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedToken] Expected to find 'with'.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: C
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: A
            extendsKeyword: extends
            bound: NamedType
              name: B
              typeArguments: TypeArgumentList
                leftBracket: <
                arguments
                  NamedType
                    name: E
                rightBracket: >
        rightBracket: >
      equals: =
      superclass: NamedType
        name: <empty> <synthetic>
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_parseTypeParameterList_parameterizedWithTrailingEquals2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C<A extends B<E /* foo */ >>= {}
//                                ^
// [diag.expectedToken] Expected to find ';'.
//                                  ^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedToken] Expected to find 'with'.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: C
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: A
            extendsKeyword: extends
            bound: NamedType
              name: B
              typeArguments: TypeArgumentList
                leftBracket: <
                arguments
                  NamedType
                    name: E
                rightBracket: >
        rightBracket: >
      equals: =
      superclass: NamedType
        name: <empty> <synthetic>
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_parseTypeParameterList_single() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C<<A> {}
//    ^
// [diag.expectedClassBody] A class declaration must have a body, even if it is empty.
//     ^^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//       ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
//        ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//          ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: { <synthetic>
        rightBracket: } <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: A
      semicolon: ; <synthetic>
''');
  }

  void test_parseTypeParameterList_withTrailingEquals() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C<A>= {}
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedToken] Expected to find 'with'.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassTypeAlias
      typedefKeyword: class
      name: C
      typeParameters: TypeParameterList
        leftBracket: <
        typeParameters
          TypeParameter
            name: A
        rightBracket: >
      equals: =
      superclass: NamedType
        name: <empty> <synthetic>
      withClause: WithClause
        withKeyword: with <synthetic>
        mixinTypes
          NamedType
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_parseVariableDeclaration_equals() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var a = b;
''');
    var node = parseResult.findNode.singleVariableDeclaration;
    assertParsedNodeText(node, r'''
VariableDeclaration
  name: a
  equals: =
  initializer: SimpleIdentifier
    token: b
''');
  }

  void test_parseVariableDeclaration_final_late() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  final late a;
//      ^^^^
// [diag.modifierOutOfOrder] The modifier 'late' should be before the modifier 'final'.
}
''');
    var node = parseResult.findNode.firstBlock.statements[0];
    assertParsedNodeText(node, r'''
VariableDeclarationStatement
  variables: VariableDeclarationList
    lateKeyword: late
    keyword: final
    variables
      VariableDeclaration
        name: a
  semicolon: ;
''');
  }

  void test_parseVariableDeclaration_late() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  late a;
//     ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
}
''');
    var node = parseResult.findNode.firstBlock.statements[0];
    assertParsedNodeText(node, r'''
VariableDeclarationStatement
  variables: VariableDeclarationList
    lateKeyword: late
    variables
      VariableDeclaration
        name: a
  semicolon: ;
''');
  }

  void test_parseVariableDeclaration_late_final() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  late final a;
}
''');
    var node = parseResult.findNode.firstBlock.statements[0];
    assertParsedNodeText(node, r'''
VariableDeclarationStatement
  variables: VariableDeclarationList
    lateKeyword: late
    keyword: final
    variables
      VariableDeclaration
        name: a
  semicolon: ;
''');
  }

  void test_parseVariableDeclaration_late_init() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  late a = 0;
//     ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
}
''');
    var node = parseResult.findNode.firstBlock.statements[0];
    assertParsedNodeText(node, r'''
VariableDeclarationStatement
  variables: VariableDeclarationList
    lateKeyword: late
    variables
      VariableDeclaration
        name: a
        equals: =
        initializer: IntegerLiteral
          literal: 0
  semicolon: ;
''');
  }

  void test_parseVariableDeclaration_late_type() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  late A a;
}
''');
    var node = parseResult.findNode.firstBlock.statements[0];
    assertParsedNodeText(node, r'''
VariableDeclarationStatement
  variables: VariableDeclarationList
    lateKeyword: late
    type: NamedType
      name: A
    variables
      VariableDeclaration
        name: a
  semicolon: ;
''');
  }

  void test_parseVariableDeclaration_late_var() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  late var a;
}
''');
    var node = parseResult.findNode.firstBlock.statements[0];
    assertParsedNodeText(node, r'''
VariableDeclarationStatement
  variables: VariableDeclarationList
    lateKeyword: late
    keyword: var
    variables
      VariableDeclaration
        name: a
  semicolon: ;
''');
  }

  void test_parseVariableDeclaration_late_var_init() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  late var a = 0;
}
''');
    var node = parseResult.findNode.firstBlock.statements[0];
    assertParsedNodeText(node, r'''
VariableDeclarationStatement
  variables: VariableDeclarationList
    lateKeyword: late
    keyword: var
    variables
      VariableDeclaration
        name: a
        equals: =
        initializer: IntegerLiteral
          literal: 0
  semicolon: ;
''');
  }

  void test_parseVariableDeclaration_noEquals() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
var a;
''');
    var node = parseResult.findNode.singleVariableDeclaration;
    assertParsedNodeText(node, r'''
VariableDeclaration
  name: a
''');
  }

  void test_parseWithClause_multiple() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class TestClass extends Object with A, B, C {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: TestClass
  extendsClause: ExtendsClause
    extendsKeyword: extends
    superclass: NamedType
      name: Object
  withClause: WithClause
    withKeyword: with
    mixinTypes
      NamedType
        name: A
      NamedType
        name: B
      NamedType
        name: C
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_parseWithClause_single() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class TestClass extends Object with M {}
''');
    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: TestClass
  extendsClause: ExtendsClause
    extendsKeyword: extends
    superclass: NamedType
      name: Object
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

  void test_typeAlias_37733() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef K=Function(<>($
//                 ^
// [diag.invalidInlineFunctionType] Inline function types can't be used for parameters in a generic function type.
// [diag.missingIdentifier] Expected an identifier.
//                  ^
// [diag.missingIdentifier] Expected an identifier.
//                    ^
// [diag.expectedToken] Expected to find ';'.
// [diag.expectedToken][column 24][length 1] Expected to find ')'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: K
      equals: =
      type: GenericFunctionType
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: <empty> <synthetic>
            functionTypedSuffix: FunctionTypedFormalParameterSuffix
              typeParameters: TypeParameterList
                leftBracket: <
                typeParameters
                  TypeParameter
                    name: <empty> <synthetic>
                rightBracket: >
              formalParameters: FormalParameterList
                leftParenthesis: (
                parameter: RegularFormalParameter
                  name: $
                rightParenthesis: ) <synthetic>
          rightParenthesis: ) <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_typeAlias_parameter_missingIdentifier_37733() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
typedef T=Function(<S>());
//                 ^
// [diag.invalidInlineFunctionType] Inline function types can't be used for parameters in a generic function type.
// [diag.missingIdentifier] Expected an identifier.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    GenericTypeAlias
      typedefKeyword: typedef
      name: T
      equals: =
      type: GenericFunctionType
        functionKeyword: Function
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: <empty> <synthetic>
            functionTypedSuffix: FunctionTypedFormalParameterSuffix
              typeParameters: TypeParameterList
                leftBracket: <
                typeParameters
                  TypeParameter
                    name: S
                rightBracket: >
              formalParameters: FormalParameterList
                leftParenthesis: (
                rightParenthesis: )
          rightParenthesis: )
      semicolon: ;
''');
  }
}
