// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../util/feature_sets.dart';
import 'parser_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GenericMetadataEnabledParserTest);
    defineReflectiveTests(GenericMetadataDisabledParserTest);
  });
}

@reflectiveTest
class GenericMetadataDisabledParserTest extends FastaParserTestCase
    with GenericMetadataParserTest {
  @override
  CompilationUnit _parseCompilationUnit(
    String content, {
    List<ExpectedDiagnostic>? diagnostics,
    required ExpectedDiagnostic? disabledDiagnostics,
  }) {
    var combinedDiagnostics = disabledDiagnostics == null
        ? diagnostics
        : [disabledDiagnostics, ...?diagnostics];
    return parseCompilationUnit(
      content,
      diagnostics: combinedDiagnostics,
      featureSet: FeatureSets.language_2_12,
    );
  }
}

@reflectiveTest
class GenericMetadataEnabledParserTest extends FastaParserTestCase
    with GenericMetadataParserTest {
  @override
  CompilationUnit _parseCompilationUnit(
    String content, {
    List<ExpectedError>? diagnostics,
    required ExpectedError? disabledDiagnostics,
  }) => parseCompilationUnit(content, diagnostics: diagnostics);
}

mixin GenericMetadataParserTest on FastaParserTestCase {
  void test_className_prefixed_constructorName_absent() {
    var compilationUnit = _parseCompilationUnit(
      '@p.A<B>() class C {}',
      disabledDiagnostics: expectedError(diag.experimentNotEnabled, 4, 1),
    );
    var classDeclaration =
        compilationUnit.declarations.single as ClassDeclaration;
    var annotation = classDeclaration.metadata.single;
    var className = annotation.name as PrefixedIdentifier;
    expect(className.prefix.name, 'p');
    expect(className.identifier.name, 'A');
    var typeArgument = annotation.typeArguments!.arguments.single as NamedType;
    expect(typeArgument.name.lexeme, 'B');
    expect(annotation.constructorName, isNull);
  }

  void test_className_prefixed_constructorName_present() {
    var compilationUnit = _parseCompilationUnit(
      '@p.A<B>.ctor() class C {}',
      disabledDiagnostics: expectedError(diag.experimentNotEnabled, 4, 1),
    );
    var classDeclaration =
        compilationUnit.declarations.single as ClassDeclaration;
    var annotation = classDeclaration.metadata.single;
    var className = annotation.name as PrefixedIdentifier;
    expect(className.prefix.name, 'p');
    expect(className.identifier.name, 'A');
    var typeArgument = annotation.typeArguments!.arguments.single as NamedType;
    expect(typeArgument.name.lexeme, 'B');
    expect(annotation.constructorName!.name, 'ctor');
  }

  void test_className_unprefixed_constructorName_absent() {
    var compilationUnit = _parseCompilationUnit(
      '@A<B>() class C {}',
      disabledDiagnostics: expectedError(diag.experimentNotEnabled, 2, 1),
    );
    var classDeclaration =
        compilationUnit.declarations.single as ClassDeclaration;
    var annotation = classDeclaration.metadata.single;
    var className = annotation.name as SimpleIdentifier;
    expect(className.name, 'A');
    var typeArgument = annotation.typeArguments!.arguments.single as NamedType;
    expect(typeArgument.name.lexeme, 'B');
    expect(annotation.constructorName, isNull);
  }

  void test_className_unprefixed_constructorName_present() {
    var compilationUnit = _parseCompilationUnit(
      '@A<B>.ctor() class C {}',
      disabledDiagnostics: expectedError(diag.experimentNotEnabled, 2, 1),
    );
    var classDeclaration =
        compilationUnit.declarations.single as ClassDeclaration;
    var annotation = classDeclaration.metadata.single;
    var className = annotation.name as SimpleIdentifier;
    expect(className.name, 'A');
    var typeArgument = annotation.typeArguments!.arguments.single as NamedType;
    expect(typeArgument.name.lexeme, 'B');
    expect(annotation.constructorName!.name, 'ctor');
  }

  void test_reference_prefixed() {
    var compilationUnit = _parseCompilationUnit(
      '@p.x<A> class C {}',
      diagnostics: [
        expectedError(diag.annotationWithTypeArgumentsUninstantiated, 6, 1),
      ],
      disabledDiagnostics: expectedError(diag.experimentNotEnabled, 4, 1),
    );
    var classDeclaration =
        compilationUnit.declarations.single as ClassDeclaration;
    var annotation = classDeclaration.metadata.single;
    var name = annotation.name as PrefixedIdentifier;
    expect(name.prefix.name, 'p');
    expect(name.identifier.name, 'x');
    var typeArgument = annotation.typeArguments!.arguments.single as NamedType;
    expect(typeArgument.name.lexeme, 'A');
    expect(annotation.constructorName, isNull);
  }

  void test_reference_unprefixed() {
    var compilationUnit = _parseCompilationUnit(
      '@x<A> class C {}',
      diagnostics: [
        expectedError(diag.annotationWithTypeArgumentsUninstantiated, 4, 1),
      ],
      disabledDiagnostics: expectedError(diag.experimentNotEnabled, 2, 1),
    );
    var classDeclaration =
        compilationUnit.declarations.single as ClassDeclaration;
    var annotation = classDeclaration.metadata.single;
    var name = annotation.name as SimpleIdentifier;
    expect(name.name, 'x');
    var typeArgument = annotation.typeArguments!.arguments.single as NamedType;
    expect(typeArgument.name.lexeme, 'A');
    expect(annotation.constructorName, isNull);
  }

  test_typeArguments_after_constructorName() {
    _parseCompilationUnit(
      '@p.A.ctor<B>() class C {}',
      diagnostics: [
        expectedError(diag.expectedExecutable, 9, 1),
        expectedError(diag.missingConstFinalVarOrType, 10, 1),
        expectedError(diag.expectedToken, 10, 1),
        expectedError(diag.topLevelOperator, 11, 1),
        expectedError(diag.missingFunctionBody, 15, 5),
      ],
      disabledDiagnostics: null,
    );
  }

  test_typeArguments_after_prefix() {
    _parseCompilationUnit(
      '@p<A>.B.ctor() class C {}',
      diagnostics: [
        expectedError(diag.annotationWithTypeArgumentsUninstantiated, 6, 1),
        expectedError(diag.expectedExecutable, 7, 1),
        expectedError(diag.missingFunctionBody, 15, 5),
      ],
      disabledDiagnostics: expectedError(diag.experimentNotEnabled, 2, 1),
    );
  }

  CompilationUnit _parseCompilationUnit(
    String content, {
    List<ExpectedError>? diagnostics,
    required ExpectedError? disabledDiagnostics,
  });
}
