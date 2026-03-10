// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/node_text_expectations.dart';
import '../src/diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VarianceParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class VarianceParserTest extends ParserDiagnosticsTest {
  final FeatureSet _disabledFeatureSet = FeatureSet.latestLanguageVersion();

  final FeatureSet _enabledFeatureSet = FeatureSet.fromEnableFlags2(
    sdkLanguageVersion: ExperimentStatus.currentVersion,
    flags: [Feature.variance.enableString],
  );

  void test_class_disabled_multiple() {
    var parseResult = parseStringWithErrors(
      'class A<in T, inout U, out V> { }',
      featureSet: _disabledFeatureSet,
    );
    parseResult.assertErrors([
      error(diag.experimentNotEnabledOffByDefault, 8, 2),
      error(diag.experimentNotEnabledOffByDefault, 14, 5),
      error(diag.experimentNotEnabledOffByDefault, 23, 3),
    ]);

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
          varianceKeyword: in
          name: T
        TypeParameter
          varianceKeyword: inout
          name: U
        TypeParameter
          varianceKeyword: out
          name: V
      rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_class_disabled_single() {
    var parseResult = parseStringWithErrors(
      'class A<out T> { }',
      featureSet: _disabledFeatureSet,
    );
    parseResult.assertErrors([
      error(diag.experimentNotEnabledOffByDefault, 8, 3),
    ]);

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
          varianceKeyword: out
          name: T
      rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_class_enabled_multiple() {
    var parseResult = parseStringWithErrors(
      'class A<in T, inout U, out V, W> { }',
      featureSet: _enabledFeatureSet,
    );
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
          varianceKeyword: in
          name: T
        TypeParameter
          varianceKeyword: inout
          name: U
        TypeParameter
          varianceKeyword: out
          name: V
        TypeParameter
          name: W
      rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_class_enabled_multipleVariances() {
    var parseResult = parseStringWithErrors(
      'class A<in out inout T> { }',
      featureSet: _enabledFeatureSet,
    );
    parseResult.assertErrors([
      error(diag.multipleVarianceModifiers, 11, 3),
      error(diag.multipleVarianceModifiers, 15, 5),
    ]);

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
          varianceKeyword: in
          name: T
      rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_class_enabled_single() {
    var parseResult = parseStringWithErrors(
      'class A<in T> { }',
      featureSet: _enabledFeatureSet,
    );
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
          varianceKeyword: in
          name: T
      rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_function_disabled() {
    var parseResult = parseStringWithErrors(
      'void A(in int value) {}',
      featureSet: _disabledFeatureSet,
    );
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 7, 2),
      error(diag.expectedToken, 10, 3),
    ]);

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: void
  name: A
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        name: in
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: value
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
''');
  }

  void test_function_enabled() {
    var parseResult = parseStringWithErrors(
      'void A(in int value) {}',
      featureSet: _enabledFeatureSet,
    );
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 7, 2),
      error(diag.expectedToken, 10, 3),
    ]);

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: void
  name: A
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        name: in
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: value
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
''');
  }

  void test_list_disabled() {
    var parseResult = parseStringWithErrors(
      'List<out String> stringList = [];',
      featureSet: _disabledFeatureSet,
    );
    parseResult.assertErrors([error(diag.expectedToken, 9, 6)]);

    var node = parseResult.findNode.singleTopLevelVariableDeclaration;
    assertParsedNodeText(node, r'''
TopLevelVariableDeclaration
  variables: VariableDeclarationList
    type: NamedType
      name: List
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: out
          NamedType
            name: String
        rightBracket: >
    variables
      VariableDeclaration
        name: stringList
        equals: =
        initializer: ListLiteral
          leftBracket: [
          rightBracket: ]
  semicolon: ;
''');
  }

  void test_list_enabled() {
    var parseResult = parseStringWithErrors(
      'List<out String> stringList = [];',
      featureSet: _enabledFeatureSet,
    );
    parseResult.assertErrors([error(diag.expectedToken, 9, 6)]);

    var node = parseResult.findNode.singleTopLevelVariableDeclaration;
    assertParsedNodeText(node, r'''
TopLevelVariableDeclaration
  variables: VariableDeclarationList
    type: NamedType
      name: List
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: out
          NamedType
            name: String
        rightBracket: >
    variables
      VariableDeclaration
        name: stringList
        equals: =
        initializer: ListLiteral
          leftBracket: [
          rightBracket: ]
  semicolon: ;
''');
  }

  void test_mixin_disabled_multiple() {
    var parseResult = parseStringWithErrors(
      'mixin A<inout T, out U> { }',
      featureSet: _disabledFeatureSet,
    );
    parseResult.assertErrors([
      error(diag.experimentNotEnabledOffByDefault, 8, 5),
      error(diag.experimentNotEnabledOffByDefault, 17, 3),
    ]);

    var node = parseResult.findNode.singleMixinDeclaration;
    assertParsedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: A
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        varianceKeyword: inout
        name: T
      TypeParameter
        varianceKeyword: out
        name: U
    rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_mixin_disabled_single() {
    var parseResult = parseStringWithErrors(
      'mixin A<inout T> { }',
      featureSet: _disabledFeatureSet,
    );
    parseResult.assertErrors([
      error(diag.experimentNotEnabledOffByDefault, 8, 5),
    ]);

    var node = parseResult.findNode.singleMixinDeclaration;
    assertParsedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: A
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        varianceKeyword: inout
        name: T
    rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_mixin_enabled_single() {
    var parseResult = parseStringWithErrors(
      'mixin A<inout T> { }',
      featureSet: _enabledFeatureSet,
    );
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleMixinDeclaration;
    assertParsedNodeText(node, r'''
MixinDeclaration
  mixinKeyword: mixin
  name: A
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        varianceKeyword: inout
        name: T
    rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_typedef_disabled() {
    var parseResult = parseStringWithErrors(
      'typedef A<inout X> = X Function(X);',
      featureSet: _disabledFeatureSet,
    );
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);

    var node = parseResult.findNode.singleGenericTypeAlias;
    assertParsedNodeText(node, r'''
GenericTypeAlias
  typedefKeyword: typedef
  name: A
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: inout
      TypeParameter
        name: X
    rightBracket: >
  equals: =
  type: GenericFunctionType
    returnType: NamedType
      name: X
    functionKeyword: Function
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: X
      rightParenthesis: )
  semicolon: ;
''');
  }

  void test_typedef_enabled() {
    var parseResult = parseStringWithErrors(
      'typedef A<inout X> = X Function(X);',
      featureSet: _enabledFeatureSet,
    );
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);

    var node = parseResult.findNode.singleGenericTypeAlias;
    assertParsedNodeText(node, r'''
GenericTypeAlias
  typedefKeyword: typedef
  name: A
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: inout
      TypeParameter
        name: X
    rightBracket: >
  equals: =
  type: GenericFunctionType
    returnType: NamedType
      name: X
    functionKeyword: Function
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: X
      rightParenthesis: )
  semicolon: ;
''');
  }
}
