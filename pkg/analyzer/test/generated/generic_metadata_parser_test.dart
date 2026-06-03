// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
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
    var parseResult = testFeatureSet.isEnabled(Feature.generic_metadata)
        ? parseTestCodeWithDiagnostics(r'''
@p.A<B>()
class C {}
''')
        : parseTestCodeWithDiagnostics(r'''
@p.A<B>()
//  ^
// [diag.experimentNotEnabled] This requires the 'generic-metadata' language feature to be enabled.
class C {}
''');

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
    var parseResult = testFeatureSet.isEnabled(Feature.generic_metadata)
        ? parseTestCodeWithDiagnostics(r'''
@p.A<B>.ctor()
class C {}
''')
        : parseTestCodeWithDiagnostics(r'''
@p.A<B>.ctor()
//  ^
// [diag.experimentNotEnabled] This requires the 'generic-metadata' language feature to be enabled.
class C {}
''');

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
    var parseResult = testFeatureSet.isEnabled(Feature.generic_metadata)
        ? parseTestCodeWithDiagnostics(r'''
@A<B>()
class C {}
''')
        : parseTestCodeWithDiagnostics(r'''
@A<B>()
//^
// [diag.experimentNotEnabled] This requires the 'generic-metadata' language feature to be enabled.
class C {}
''');

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
    var parseResult = testFeatureSet.isEnabled(Feature.generic_metadata)
        ? parseTestCodeWithDiagnostics(r'''
@A<B>.ctor()
class C {}
''')
        : parseTestCodeWithDiagnostics(r'''
@A<B>.ctor()
//^
// [diag.experimentNotEnabled] This requires the 'generic-metadata' language feature to be enabled.
class C {}
''');

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
    var parseResult = testFeatureSet.isEnabled(Feature.generic_metadata)
        ? parseTestCodeWithDiagnostics(r'''
@p.x<A> class C {}
//    ^
// [diag.annotationWithTypeArgumentsUninstantiated] An annotation with type arguments must be followed by an argument list.
''')
        : parseTestCodeWithDiagnostics(r'''
@p.x<A> class C {}
//  ^
// [diag.experimentNotEnabled] This requires the 'generic-metadata' language feature to be enabled.
//    ^
// [diag.annotationWithTypeArgumentsUninstantiated] An annotation with type arguments must be followed by an argument list.
''');

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
    var parseResult = testFeatureSet.isEnabled(Feature.generic_metadata)
        ? parseTestCodeWithDiagnostics(r'''
@x<A> class C {}
//  ^
// [diag.annotationWithTypeArgumentsUninstantiated] An annotation with type arguments must be followed by an argument list.
''')
        : parseTestCodeWithDiagnostics(r'''
@x<A> class C {}
//^
// [diag.experimentNotEnabled] This requires the 'generic-metadata' language feature to be enabled.
//  ^
// [diag.annotationWithTypeArgumentsUninstantiated] An annotation with type arguments must be followed by an argument list.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
@p.A.ctor<B>() class C {}
//       ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//        ^
// [diag.missingConstFinalVarOrType] Variables must be declared using the keywords 'const', 'final', 'var' or a type name.
// [diag.expectedToken] Expected to find ';'.
//         ^
// [diag.topLevelOperator] Operators must be declared within a class.
//             ^^^^^
// [diag.missingFunctionBody] A function body must be provided.
''');

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
    var parseResult = testFeatureSet.isEnabled(Feature.generic_metadata)
        ? parseTestCodeWithDiagnostics(r'''
@p<A>.B.ctor() class C {}
//    ^
// [diag.annotationWithTypeArgumentsUninstantiated] An annotation with type arguments must be followed by an argument list.
//     ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//             ^^^^^
// [diag.missingFunctionBody] A function body must be provided.
''')
        : parseTestCodeWithDiagnostics(r'''
@p<A>.B.ctor() class C {}
//^
// [diag.experimentNotEnabled] This requires the 'generic-metadata' language feature to be enabled.
//    ^
// [diag.annotationWithTypeArgumentsUninstantiated] An annotation with type arguments must be followed by an argument list.
//     ^
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//             ^^^^^
// [diag.missingFunctionBody] A function body must be provided.
''');

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
