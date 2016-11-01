// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.context.declared_variables_test;

import 'package:analyzer/context/declared_variables.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeclaredVariablesTest);
  });
}

@reflectiveTest
class DeclaredVariablesTest extends EngineTestCase {
  void test_getBool_false() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    variables.define(variableName, "false");
    DartObject object = variables.getBool(typeProvider, variableName);
    expect(object, isNotNull);
    expect(object.toBoolValue(), false);
  }

  void test_getBool_invalid() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    variables.define(variableName, "not true");
    _assertNullDartObject(
        typeProvider, variables.getBool(typeProvider, variableName));
  }

  void test_getBool_true() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    variables.define(variableName, "true");
    DartObject object = variables.getBool(typeProvider, variableName);
    expect(object, isNotNull);
    expect(object.toBoolValue(), true);
  }

  void test_getBool_undefined() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    _assertUnknownDartObject(
        typeProvider.boolType, variables.getBool(typeProvider, variableName));
  }

  void test_getInt_invalid() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    variables.define(variableName, "four score and seven years");
    _assertNullDartObject(
        typeProvider, variables.getInt(typeProvider, variableName));
  }

  void test_getInt_undefined() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    _assertUnknownDartObject(
        typeProvider.intType, variables.getInt(typeProvider, variableName));
  }

  void test_getInt_valid() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    variables.define(variableName, "23");
    DartObject object = variables.getInt(typeProvider, variableName);
    expect(object, isNotNull);
    expect(object.toIntValue(), 23);
  }

  void test_getString_defined() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    String value = "value";
    DeclaredVariables variables = new DeclaredVariables();
    variables.define(variableName, value);
    DartObject object = variables.getString(typeProvider, variableName);
    expect(object, isNotNull);
    expect(object.toStringValue(), value);
  }

  void test_getString_undefined() {
    TestTypeProvider typeProvider = new TestTypeProvider();
    String variableName = "var";
    DeclaredVariables variables = new DeclaredVariables();
    _assertUnknownDartObject(typeProvider.stringType,
        variables.getString(typeProvider, variableName));
  }

  void _assertNullDartObject(TestTypeProvider typeProvider, DartObject result) {
    expect(result.type, typeProvider.nullType);
  }

  void _assertUnknownDartObject(
      ParameterizedType expectedType, DartObject result) {
    expect((result as DartObjectImpl).isUnknown, isTrue);
    expect(result.type, expectedType);
  }
}
