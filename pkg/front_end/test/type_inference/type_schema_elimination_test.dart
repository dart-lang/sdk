// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/type_inference/type_schema.dart';
import 'package:front_end/src/type_inference/type_schema_elimination.dart'
    as typeSchemaElimination;
import 'package:kernel/ast.dart';
import 'package:kernel/testing/type_parser_environment.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeSchemaEliminationTest);
  });
}

@reflectiveTest
class TypeSchemaEliminationTest {
  final Env env = new Env("");
  final Map<String, DartType Function()> additionalTypes = {
    "UNKNOWN": () => new UnknownType(),
  };

  DartType greatestClosure(DartType schema) {
    return typeSchemaElimination.greatestClosure(
      schema,
      topType: new DynamicType(),
    );
  }

  DartType leastClosure(DartType schema) {
    return typeSchemaElimination.leastClosure(schema, coreTypes: env.coreTypes);
  }

  void testGreatest(String type, String expectedClosure) {
    expect(
      greatestClosure(env.parseType(type, additionalTypes: additionalTypes)),
      env.parseType(expectedClosure, additionalTypes: additionalTypes),
    );
  }

  void testLeast(String type, String expectedClosure) {
    expect(
      leastClosure(env.parseType(type, additionalTypes: additionalTypes)),
      env.parseType(expectedClosure, additionalTypes: additionalTypes),
    );
  }

  void test_greatestClosure_contravariant() {
    testGreatest("(UNKNOWN) -> dynamic", "(Never) -> dynamic");
    testGreatest("({UNKNOWN foo}) -> dynamic", "({Never foo}) -> dynamic");
  }

  void test_greatestClosure_contravariant_contravariant() {
    testGreatest(
      "((UNKNOWN) -> dynamic) -> dynamic",
      "((dynamic) -> dynamic) -> dynamic",
    );
  }

  void test_greatestClosure_covariant() {
    testGreatest("() -> UNKNOWN", "() -> dynamic");
    testGreatest("List<UNKNOWN>", "List<dynamic>");
  }

  void test_greatestClosure_function_multipleUnknown() {
    testGreatest(
      "(UNKNOWN, UNKNOWN, {UNKNOWN a, UNKNOWN b}) -> UNKNOWN",
      "(Never, Never, {Never a, Never b}) -> dynamic",
    );
  }

  void test_greatestClosure_simple() {
    testGreatest("UNKNOWN", "dynamic");
  }

  void test_leastClosure_contravariant() {
    testLeast("(UNKNOWN) -> dynamic", "(Object?) -> dynamic");
    testLeast("({UNKNOWN foo}) -> dynamic", "({Object? foo}) -> dynamic");
  }

  void test_leastClosure_contravariant_contravariant() {
    testLeast(
      "((UNKNOWN) -> UNKNOWN) -> dynamic",
      "((Never) -> Object?) -> dynamic",
    );
  }

  void test_leastClosure_covariant() {
    testLeast("() -> UNKNOWN", "() -> Never");
    testLeast("List<UNKNOWN>", "List<Never>");
  }

  void test_leastClosure_function_multipleUnknown() {
    testLeast(
      "(UNKNOWN, UNKNOWN, {UNKNOWN a, UNKNOWN b}) -> UNKNOWN",
      "(Object?, Object?, {Object? a, Object? b}) -> Never",
    );
  }

  void test_leastClosure_simple() {
    testLeast("UNKNOWN", "Never");
  }
}
