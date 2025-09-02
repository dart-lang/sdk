// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'parser_test_base.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VarianceParserTest);
  });
}

@reflectiveTest
class VarianceParserTest extends FastaParserTestCase {
  final FeatureSet _disabledFeatureSet = FeatureSet.latestLanguageVersion();

  final FeatureSet _enabledFeatureSet = FeatureSet.fromEnableFlags2(
    sdkLanguageVersion: ExperimentStatus.currentVersion,
    flags: [Feature.variance.enableString],
  );

  @override
  CompilationUnitImpl parseCompilationUnit(
    String content, {
    List<DiagnosticCode>? codes,
    List<ExpectedError>? errors,
    FeatureSet? featureSet,
  }) {
    return super.parseCompilationUnit(
      content,
      codes: codes,
      errors: errors,
      featureSet: featureSet ?? _enabledFeatureSet,
    );
  }

  void test_class_disabled_multiple() {
    parseCompilationUnit(
      'class A<in T, inout U, out V> { }',
      errors: [
        expectedError(ParserErrorCode.experimentNotEnabledOffByDefault, 8, 2),
        expectedError(ParserErrorCode.experimentNotEnabledOffByDefault, 14, 5),
        expectedError(ParserErrorCode.experimentNotEnabledOffByDefault, 23, 3),
      ],
      featureSet: _disabledFeatureSet,
    );
  }

  void test_class_disabled_single() {
    parseCompilationUnit(
      'class A<out T> { }',
      errors: [
        expectedError(ParserErrorCode.experimentNotEnabledOffByDefault, 8, 3),
      ],
      featureSet: _disabledFeatureSet,
    );
  }

  void test_class_enabled_multiple() {
    var unit = parseCompilationUnit('class A<in T, inout U, out V, W> { }');
    expect(unit.declarations, hasLength(1));
    var classDecl = unit.declarations[0] as ClassDeclaration;
    expect(classDecl.name.lexeme, 'A');

    var typeParameters = classDecl.typeParameters!;
    expect(typeParameters.typeParameters, hasLength(4));
    expect(typeParameters.typeParameters[0].name.lexeme, 'T');
    expect(typeParameters.typeParameters[1].name.lexeme, 'U');
    expect(typeParameters.typeParameters[2].name.lexeme, 'V');
    expect(typeParameters.typeParameters[3].name.lexeme, 'W');

    var typeParameterImplList = typeParameters.typeParameters;
    expect(
      (typeParameterImplList[0] as TypeParameterImpl).varianceKeyword,
      isNotNull,
    );
    expect(
      (typeParameterImplList[0] as TypeParameterImpl).varianceKeyword!.lexeme,
      "in",
    );
    expect(
      (typeParameterImplList[1] as TypeParameterImpl).varianceKeyword,
      isNotNull,
    );
    expect(
      (typeParameterImplList[1] as TypeParameterImpl).varianceKeyword!.lexeme,
      "inout",
    );
    expect(
      (typeParameterImplList[2] as TypeParameterImpl).varianceKeyword,
      isNotNull,
    );
    expect(
      (typeParameterImplList[2] as TypeParameterImpl).varianceKeyword!.lexeme,
      "out",
    );
    expect(
      (typeParameterImplList[3] as TypeParameterImpl).varianceKeyword,
      isNull,
    );
  }

  void test_class_enabled_multipleVariances() {
    var unit = parseCompilationUnit(
      'class A<in out inout T> { }',
      errors: [
        expectedError(ParserErrorCode.multipleVarianceModifiers, 11, 3),
        expectedError(ParserErrorCode.multipleVarianceModifiers, 15, 5),
      ],
    );
    expect(unit.declarations, hasLength(1));
    var classDecl = unit.declarations[0] as ClassDeclaration;
    expect(classDecl.name.lexeme, 'A');

    var typeParameters = classDecl.typeParameters!;
    expect(typeParameters.typeParameters, hasLength(1));
    expect(typeParameters.typeParameters[0].name.lexeme, 'T');
  }

  void test_class_enabled_single() {
    var unit = parseCompilationUnit('class A<in T> { }');
    expect(unit.declarations, hasLength(1));
    var classDecl = unit.declarations[0] as ClassDeclaration;
    expect(classDecl.name.lexeme, 'A');

    var typeParameters = classDecl.typeParameters!;
    expect(typeParameters.typeParameters, hasLength(1));
    expect(typeParameters.typeParameters[0].name.lexeme, 'T');

    var typeParameterImpl =
        typeParameters.typeParameters[0] as TypeParameterImpl;
    expect(typeParameterImpl.varianceKeyword, isNotNull);
    expect(typeParameterImpl.varianceKeyword!.lexeme, "in");
  }

  void test_function_disabled() {
    parseCompilationUnit(
      'void A(in int value) {}',
      errors: [
        expectedError(ParserErrorCode.expectedIdentifierButGotKeyword, 7, 2),
        expectedError(ParserErrorCode.expectedToken, 10, 3),
      ],
      featureSet: _disabledFeatureSet,
    );
  }

  void test_function_enabled() {
    parseCompilationUnit(
      'void A(in int value) {}',
      errors: [
        expectedError(ParserErrorCode.expectedIdentifierButGotKeyword, 7, 2),
        expectedError(ParserErrorCode.expectedToken, 10, 3),
      ],
    );
  }

  void test_list_disabled() {
    parseCompilationUnit(
      'List<out String> stringList = [];',
      errors: [expectedError(ParserErrorCode.expectedToken, 9, 6)],
      featureSet: _disabledFeatureSet,
    );
  }

  void test_list_enabled() {
    parseCompilationUnit(
      'List<out String> stringList = [];',
      errors: [expectedError(ParserErrorCode.expectedToken, 9, 6)],
    );
  }

  void test_mixin_disabled_multiple() {
    parseCompilationUnit(
      'mixin A<inout T, out U> { }',
      errors: [
        expectedError(ParserErrorCode.experimentNotEnabledOffByDefault, 8, 5),
        expectedError(ParserErrorCode.experimentNotEnabledOffByDefault, 17, 3),
      ],
      featureSet: _disabledFeatureSet,
    );
  }

  void test_mixin_disabled_single() {
    parseCompilationUnit(
      'mixin A<inout T> { }',
      errors: [
        expectedError(ParserErrorCode.experimentNotEnabledOffByDefault, 8, 5),
      ],
      featureSet: _disabledFeatureSet,
    );
  }

  void test_mixin_enabled_single() {
    var unit = parseCompilationUnit('mixin A<inout T> { }');
    expect(unit.declarations, hasLength(1));
    var mixinDecl = unit.declarations[0] as MixinDeclaration;
    expect(mixinDecl.name.lexeme, 'A');

    var typeParameters = mixinDecl.typeParameters!;
    expect(typeParameters.typeParameters, hasLength(1));
    expect(typeParameters.typeParameters[0].name.lexeme, 'T');
  }

  void test_typedef_disabled() {
    parseCompilationUnit(
      'typedef A<inout X> = X Function(X);',
      errors: [expectedError(ParserErrorCode.expectedToken, 16, 1)],
      featureSet: _disabledFeatureSet,
    );
  }

  void test_typedef_enabled() {
    parseCompilationUnit(
      'typedef A<inout X> = X Function(X);',
      errors: [expectedError(ParserErrorCode.expectedToken, 16, 1)],
    );
  }
}
