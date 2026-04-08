// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/node_text_expectations.dart';
import '../src/diagnostics/parser_diagnostics.dart';
import '../util/feature_sets.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GenericMetadataEnabledParserTest);
    defineReflectiveTests(GenericMetadataDisabledParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class GenericMetadataDisabledParserTest extends ParserDiagnosticsTest
    with GenericMetadataParserTest {
  @override
  FeatureSet get testFeatureSet => FeatureSets.language_2_12;
}

@reflectiveTest
class GenericMetadataEnabledParserTest extends ParserDiagnosticsTest
    with GenericMetadataParserTest {}

mixin GenericMetadataParserTest on ParserDiagnosticsTest {
  void test_className_prefixed_constructorName_absent() {
    var parseResult = parseStringWithErrors(r'''
@p.A<B>()
class C {}
''');
    if (testFeatureSet.isEnabled(Feature.generic_metadata)) {
      parseResult.assertNoErrors();
    } else {
      parseResult.assertErrors([error(diag.experimentNotEnabled, 4, 1)]);
    }

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  metadata
    Annotation
      atSign: @
      name: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: p
        period: .
        identifier: SimpleIdentifier
          token: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: B
        rightBracket: >
      arguments: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: C
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_className_prefixed_constructorName_present() {
    var parseResult = parseStringWithErrors(r'''
@p.A<B>.ctor()
class C {}
''');
    if (testFeatureSet.isEnabled(Feature.generic_metadata)) {
      parseResult.assertNoErrors();
    } else {
      parseResult.assertErrors([error(diag.experimentNotEnabled, 4, 1)]);
    }

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  metadata
    Annotation
      atSign: @
      name: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: p
        period: .
        identifier: SimpleIdentifier
          token: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: B
        rightBracket: >
      period: .
      constructorName: SimpleIdentifier
        token: ctor
      arguments: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: C
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_className_unprefixed_constructorName_absent() {
    var parseResult = parseStringWithErrors(r'''
@A<B>()
class C {}
''');
    if (testFeatureSet.isEnabled(Feature.generic_metadata)) {
      parseResult.assertNoErrors();
    } else {
      parseResult.assertErrors([error(diag.experimentNotEnabled, 2, 1)]);
    }

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  metadata
    Annotation
      atSign: @
      name: SimpleIdentifier
        token: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: B
        rightBracket: >
      arguments: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: C
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_className_unprefixed_constructorName_present() {
    var parseResult = parseStringWithErrors(r'''
@A<B>.ctor()
class C {}
''');
    if (testFeatureSet.isEnabled(Feature.generic_metadata)) {
      parseResult.assertNoErrors();
    } else {
      parseResult.assertErrors([error(diag.experimentNotEnabled, 2, 1)]);
    }

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  metadata
    Annotation
      atSign: @
      name: SimpleIdentifier
        token: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: B
        rightBracket: >
      period: .
      constructorName: SimpleIdentifier
        token: ctor
      arguments: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: C
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_reference_prefixed() {
    var parseResult = parseStringWithErrors(r'''
@p.x<A> class C {}
''');
    if (testFeatureSet.isEnabled(Feature.generic_metadata)) {
      parseResult.assertErrors([
        error(diag.annotationWithTypeArgumentsUninstantiated, 6, 1),
      ]);
    } else {
      parseResult.assertErrors([
        error(diag.experimentNotEnabled, 4, 1),
        error(diag.annotationWithTypeArgumentsUninstantiated, 6, 1),
      ]);
    }

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  metadata
    Annotation
      atSign: @
      name: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: p
        period: .
        identifier: SimpleIdentifier
          token: x
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: A
        rightBracket: >
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: C
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_reference_unprefixed() {
    var parseResult = parseStringWithErrors(r'''
@x<A> class C {}
''');
    if (testFeatureSet.isEnabled(Feature.generic_metadata)) {
      parseResult.assertErrors([
        error(diag.annotationWithTypeArgumentsUninstantiated, 4, 1),
      ]);
    } else {
      parseResult.assertErrors([
        error(diag.experimentNotEnabled, 2, 1),
        error(diag.annotationWithTypeArgumentsUninstantiated, 4, 1),
      ]);
    }

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  metadata
    Annotation
      atSign: @
      name: SimpleIdentifier
        token: x
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: A
        rightBracket: >
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: C
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_typeArguments_after_constructorName() {
    var parseResult = parseStringWithErrors(r'''
@p.A.ctor<B>() class C {}
''');
    parseResult.assertErrors([
      error(diag.expectedExecutable, 9, 1),
      error(diag.missingConstFinalVarOrType, 10, 1),
      error(diag.expectedToken, 10, 1),
      error(diag.topLevelOperator, 11, 1),
      error(diag.missingFunctionBody, 15, 5),
    ]);

    var node = parseResult.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: B
      semicolon: ; <synthetic>
    FunctionDeclaration
      name: #synthetic_function_11 <synthetic>
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  test_typeArguments_after_prefix() {
    var parseResult = parseStringWithErrors(r'''
@p<A>.B.ctor() class C {}
''');
    if (testFeatureSet.isEnabled(Feature.generic_metadata)) {
      parseResult.assertErrors([
        error(diag.annotationWithTypeArgumentsUninstantiated, 6, 1),
        error(diag.expectedExecutable, 7, 1),
        error(diag.missingFunctionBody, 15, 5),
      ]);
    } else {
      parseResult.assertErrors([
        error(diag.experimentNotEnabled, 2, 1),
        error(diag.annotationWithTypeArgumentsUninstantiated, 6, 1),
        error(diag.expectedExecutable, 7, 1),
        error(diag.missingFunctionBody, 15, 5),
      ]);
    }

    var node = parseResult.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: ctor
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }
}
