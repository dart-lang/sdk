// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
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
    var parseResult = parseTestCodeWithDiagnostics(
      r'''class A<in T, inout U, out V> { }
//      ^^
// [diag.experimentNotEnabledOffByDefault] This requires the experimental 'variance' language feature to be enabled.
//            ^^^^^
// [diag.experimentNotEnabledOffByDefault] This requires the experimental 'variance' language feature to be enabled.
//                     ^^^
// [diag.experimentNotEnabledOffByDefault] This requires the experimental 'variance' language feature to be enabled.''',
      featureSet: _disabledFeatureSet,
    );

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
    var parseResult = parseTestCodeWithDiagnostics(
      r'''class A<out T> { }
//      ^^^
// [diag.experimentNotEnabledOffByDefault] This requires the experimental 'variance' language feature to be enabled.''',
      featureSet: _disabledFeatureSet,
    );

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
    var parseResult = parseTestCodeWithDiagnostics(
      'class A<in T, inout U, out V, W> { }',
      featureSet: _enabledFeatureSet,
    );

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
    var parseResult = parseTestCodeWithDiagnostics(
      r'''class A<in out inout T> { }
//         ^^^
// [diag.multipleVarianceModifiers] Each type parameter can have at most one variance modifier.
//             ^^^^^
// [diag.multipleVarianceModifiers] Each type parameter can have at most one variance modifier.''',
      featureSet: _enabledFeatureSet,
    );

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
    var parseResult = parseTestCodeWithDiagnostics(
      'class A<in T> { }',
      featureSet: _enabledFeatureSet,
    );

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
    var parseResult = parseTestCodeWithDiagnostics(
      r'''void A(in int value) {}
//     ^^
// [diag.expectedIdentifierButGotKeyword] 'in' can't be used as an identifier because it's a keyword.
//        ^^^
// [diag.expectedToken] Expected to find ','.''',
      featureSet: _disabledFeatureSet,
    );

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: void
  name: A
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        name: in
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(
      r'''void A(in int value) {}
//     ^^
// [diag.expectedIdentifierButGotKeyword] 'in' can't be used as an identifier because it's a keyword.
//        ^^^
// [diag.expectedToken] Expected to find ','.''',
      featureSet: _enabledFeatureSet,
    );

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: void
  name: A
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        name: in
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(
      r'''List<out String> stringList = [];
//       ^^^^^^
// [diag.expectedToken] Expected to find ','.''',
      featureSet: _disabledFeatureSet,
    );

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
    var parseResult = parseTestCodeWithDiagnostics(
      r'''List<out String> stringList = [];
//       ^^^^^^
// [diag.expectedToken] Expected to find ','.''',
      featureSet: _enabledFeatureSet,
    );

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
    var parseResult = parseTestCodeWithDiagnostics(
      r'''mixin A<inout T, out U> { }
//      ^^^^^
// [diag.experimentNotEnabledOffByDefault] This requires the experimental 'variance' language feature to be enabled.
//               ^^^
// [diag.experimentNotEnabledOffByDefault] This requires the experimental 'variance' language feature to be enabled.''',
      featureSet: _disabledFeatureSet,
    );

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
    var parseResult = parseTestCodeWithDiagnostics(
      r'''mixin A<inout T> { }
//      ^^^^^
// [diag.experimentNotEnabledOffByDefault] This requires the experimental 'variance' language feature to be enabled.''',
      featureSet: _disabledFeatureSet,
    );

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
    var parseResult = parseTestCodeWithDiagnostics(
      'mixin A<inout T> { }',
      featureSet: _enabledFeatureSet,
    );

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
    var parseResult = parseTestCodeWithDiagnostics(
      r'''typedef A<inout X> = X Function(X);
//              ^
// [diag.expectedToken] Expected to find ','.''',
      featureSet: _disabledFeatureSet,
    );

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
      parameter: RegularFormalParameter
        type: NamedType
          name: X
      rightParenthesis: )
  semicolon: ;
''');
  }

  void test_typedef_enabled() {
    var parseResult = parseTestCodeWithDiagnostics(
      r'''typedef A<inout X> = X Function(X);
//              ^
// [diag.expectedToken] Expected to find ','.''',
      featureSet: _enabledFeatureSet,
    );

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
      parameter: RegularFormalParameter
        type: NamedType
          name: X
      rightParenthesis: )
  semicolon: ;
''');
  }
}
