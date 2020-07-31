// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/constant/from_environment_evaluator.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_analysis_context.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FromEnvironmentEvaluatorTest);
  });
}

@reflectiveTest
class FromEnvironmentEvaluatorTest {
  TypeProvider typeProvider;
  TypeSystemImpl typeSystem;

  void setUp() {
    var analysisContext = TestAnalysisContext();
    typeProvider = analysisContext.typeProviderLegacy;
    typeSystem = analysisContext.typeSystemLegacy;
  }

  @deprecated
  void test_getBool_false() {
    String variableName = "var";
    var variables = FromEnvironmentEvaluator(
      typeSystem,
      DeclaredVariables.fromMap({variableName: 'false'}),
    );
    DartObject object = variables.getBool(variableName);
    expect(object, isNotNull);
    expect(object.toBoolValue(), false);
  }

  @deprecated
  void test_getBool_invalid() {
    String variableName = "var";
    var variables = FromEnvironmentEvaluator(
      typeSystem,
      DeclaredVariables.fromMap({variableName: 'not true'}),
    );
    _assertNullDartObject(
      variables.getBool(variableName),
    );
  }

  @deprecated
  void test_getBool_true() {
    String variableName = "var";
    var variables = FromEnvironmentEvaluator(
      typeSystem,
      DeclaredVariables.fromMap({variableName: 'true'}),
    );
    DartObject object = variables.getBool(variableName);
    expect(object, isNotNull);
    expect(object.toBoolValue(), true);
  }

  @deprecated
  void test_getBool_undefined() {
    String variableName = "var";
    var variables = FromEnvironmentEvaluator(
      typeSystem,
      DeclaredVariables(),
    );
    _assertUnknownDartObject(
      typeProvider.boolType,
      variables.getBool(variableName),
    );
  }

  @deprecated
  void test_getInt_invalid() {
    String variableName = "var";
    var variables = FromEnvironmentEvaluator(
      typeSystem,
      DeclaredVariables.fromMap({variableName: 'four score and seven years'}),
    );
    _assertNullDartObject(
      variables.getInt(variableName),
    );
  }

  @deprecated
  void test_getInt_undefined() {
    String variableName = "var";
    var variables = FromEnvironmentEvaluator(
      typeSystem,
      DeclaredVariables(),
    );
    _assertUnknownDartObject(
      typeProvider.intType,
      variables.getInt(variableName),
    );
  }

  @deprecated
  void test_getInt_valid() {
    String variableName = "var";
    var variables = FromEnvironmentEvaluator(
      typeSystem,
      DeclaredVariables.fromMap({variableName: '23'}),
    );
    DartObject object = variables.getInt(variableName);
    expect(object, isNotNull);
    expect(object.toIntValue(), 23);
  }

  @deprecated
  void test_getString_defined() {
    String variableName = "var";
    String value = "value";
    var variables = FromEnvironmentEvaluator(
      typeSystem,
      DeclaredVariables.fromMap({variableName: value}),
    );
    DartObject object = variables.getString(variableName);
    expect(object, isNotNull);
    expect(object.toStringValue(), value);
  }

  @deprecated
  void test_getString_undefined() {
    String variableName = "var";
    var variables = FromEnvironmentEvaluator(
      typeSystem,
      DeclaredVariables(),
    );
    _assertUnknownDartObject(
      typeProvider.stringType,
      variables.getString(variableName),
    );
  }

  void _assertNullDartObject(DartObject result) {
    expect(result.type, typeProvider.nullType);
  }

  void _assertUnknownDartObject(DartType expectedType, DartObject result) {
    expect((result as DartObjectImpl).isUnknown, isTrue);
    expect(result.type, expectedType);
  }
}
