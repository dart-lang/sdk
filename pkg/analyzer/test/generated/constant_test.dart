// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@deprecated
library analyzer.test.constant_test;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'resolver_test_case.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantEvaluatorTest);
  });
}

@reflectiveTest
class ConstantEvaluatorTest extends ResolverTestCase {
  void fail_constructor() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_identifier_class() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_identifier_function() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_identifier_static() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_identifier_staticMethod() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_identifier_topLevel() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_identifier_typeParameter() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_prefixedIdentifier_invalid() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_prefixedIdentifier_valid() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_propertyAccess_invalid() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_propertyAccess_valid() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_simpleIdentifier_invalid() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void fail_simpleIdentifier_valid() {
    EvaluationResult result = _getExpressionValue("?");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value, null);
  }

  void test_bitAnd_int_int() {
    _assertValue3(74 & 42, "74 & 42");
  }

  void test_bitNot() {
    _assertValue3(~42, "~42");
  }

  void test_bitOr_int_int() {
    _assertValue3(74 | 42, "74 | 42");
  }

  void test_bitXor_int_int() {
    _assertValue3(74 ^ 42, "74 ^ 42");
  }

  void test_divide_double_double() {
    _assertValue2(3.2 / 2.3, "3.2 / 2.3");
  }

  void test_divide_double_double_byZero() {
    EvaluationResult result = _getExpressionValue("3.2 / 0.0");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value.type.name, "double");
    expect(value.toDoubleValue().isInfinite, isTrue);
  }

  void test_divide_int_int() {
    _assertValue2(1.5, "3 / 2");
  }

  void test_divide_int_int_byZero() {
    EvaluationResult result = _getExpressionValue("3 / 0");
    expect(result.isValid, isTrue);
  }

  void test_equal_boolean_boolean() {
    _assertValue(false, "true == false");
  }

  void test_equal_int_int() {
    _assertValue(false, "2 == 3");
  }

  void test_equal_invalidLeft() {
    EvaluationResult result = _getExpressionValue("a == 3");
    expect(result.isValid, isFalse);
  }

  void test_equal_invalidRight() {
    EvaluationResult result = _getExpressionValue("2 == a");
    expect(result.isValid, isFalse);
  }

  void test_equal_string_string() {
    _assertValue(false, "'a' == 'b'");
  }

  void test_greaterThan_int_int() {
    _assertValue(false, "2 > 3");
  }

  void test_greaterThanOrEqual_int_int() {
    _assertValue(false, "2 >= 3");
  }

  void test_leftShift_int_int() {
    _assertValue3(64, "16 << 2");
  }

  void test_lessThan_int_int() {
    _assertValue(true, "2 < 3");
  }

  void test_lessThanOrEqual_int_int() {
    _assertValue(true, "2 <= 3");
  }

  void test_literal_boolean_false() {
    _assertValue(false, "false");
  }

  void test_literal_boolean_true() {
    _assertValue(true, "true");
  }

  void test_literal_list() {
    EvaluationResult result = _getExpressionValue("const ['a', 'b', 'c']");
    expect(result.isValid, isTrue);
  }

  void test_literal_map() {
    EvaluationResult result =
        _getExpressionValue("const {'a' : 'm', 'b' : 'n', 'c' : 'o'}");
    expect(result.isValid, isTrue);
    Map<DartObject, DartObject> map = result.value.toMapValue();
    expect(map.keys.map((k) => k.toStringValue()), ['a', 'b', 'c']);
  }

  void test_literal_null() {
    EvaluationResult result = _getExpressionValue("null");
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value.isNull, isTrue);
  }

  void test_literal_number_double() {
    _assertValue2(3.45, "3.45");
  }

  void test_literal_number_integer() {
    _assertValue3(42, "42");
  }

  void test_literal_string_adjacent() {
    _assertValue4("abcdef", "'abc' 'def'");
  }

  void test_literal_string_interpolation_invalid() {
    EvaluationResult result = _getExpressionValue("'a\${f()}c'");
    expect(result.isValid, isFalse);
  }

  void test_literal_string_interpolation_valid() {
    _assertValue4("a3c", "'a\${3}c'");
  }

  void test_literal_string_simple() {
    _assertValue4("abc", "'abc'");
  }

  void test_logicalAnd() {
    _assertValue(false, "true && false");
  }

  void test_logicalNot() {
    _assertValue(false, "!true");
  }

  void test_logicalOr() {
    _assertValue(true, "true || false");
  }

  void test_minus_double_double() {
    _assertValue2(3.2 - 2.3, "3.2 - 2.3");
  }

  void test_minus_int_int() {
    _assertValue3(1, "3 - 2");
  }

  void test_negated_boolean() {
    EvaluationResult result = _getExpressionValue("-true");
    expect(result.isValid, isFalse);
  }

  void test_negated_double() {
    _assertValue2(-42.3, "-42.3");
  }

  void test_negated_integer() {
    _assertValue3(-42, "-42");
  }

  void test_notEqual_boolean_boolean() {
    _assertValue(true, "true != false");
  }

  void test_notEqual_int_int() {
    _assertValue(true, "2 != 3");
  }

  void test_notEqual_invalidLeft() {
    EvaluationResult result = _getExpressionValue("a != 3");
    expect(result.isValid, isFalse);
  }

  void test_notEqual_invalidRight() {
    EvaluationResult result = _getExpressionValue("2 != a");
    expect(result.isValid, isFalse);
  }

  void test_notEqual_string_string() {
    _assertValue(true, "'a' != 'b'");
  }

  void test_parenthesizedExpression() {
    _assertValue4("a", "('a')");
  }

  void test_plus_double_double() {
    _assertValue2(2.3 + 3.2, "2.3 + 3.2");
  }

  void test_plus_int_int() {
    _assertValue3(5, "2 + 3");
  }

  void test_plus_string_string() {
    _assertValue4("ab", "'a' + 'b'");
  }

  void test_remainder_double_double() {
    _assertValue2(3.2 % 2.3, "3.2 % 2.3");
  }

  void test_remainder_int_int() {
    _assertValue3(2, "8 % 3");
  }

  void test_rightShift() {
    _assertValue3(16, "64 >> 2");
  }

  void test_stringLength_complex() {
    _assertValue3(6, "('qwe' + 'rty').length");
  }

  void test_stringLength_simple() {
    _assertValue3(6, "'Dvorak'.length");
  }

  void test_times_double_double() {
    _assertValue2(2.3 * 3.2, "2.3 * 3.2");
  }

  void test_times_int_int() {
    _assertValue3(6, "2 * 3");
  }

  void test_truncatingDivide_double_double() {
    _assertValue3(1, "3.2 ~/ 2.3");
  }

  void test_truncatingDivide_int_int() {
    _assertValue3(3, "10 ~/ 3");
  }

  void _assertValue(bool expectedValue, String contents) {
    EvaluationResult result = _getExpressionValue(contents);
    DartObject value = result.value;
    expect(value.type.name, "bool");
    expect(value.toBoolValue(), expectedValue);
  }

  void _assertValue2(double expectedValue, String contents) {
    EvaluationResult result = _getExpressionValue(contents);
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value.type.name, "double");
    expect(value.toDoubleValue(), expectedValue);
  }

  void _assertValue3(int expectedValue, String contents) {
    EvaluationResult result = _getExpressionValue(contents);
    expect(result.isValid, isTrue);
    DartObject value = result.value;
    expect(value.type.name, "int");
    expect(value.toIntValue(), expectedValue);
  }

  void _assertValue4(String expectedValue, String contents) {
    EvaluationResult result = _getExpressionValue(contents);
    DartObject value = result.value;
    expect(value, isNotNull);
    ParameterizedType type = value.type;
    expect(type, isNotNull);
    expect(type.name, "String");
    expect(value.toStringValue(), expectedValue);
  }

  EvaluationResult _getExpressionValue(String contents) {
    Source source = addSource("var x = $contents;");
    LibraryElement library = resolve2(source);
    CompilationUnit unit =
        analysisContext.resolveCompilationUnit(source, library);
    expect(unit, isNotNull);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(1));
    CompilationUnitMember declaration = declarations[0];
    EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableDeclaration,
        TopLevelVariableDeclaration, declaration);
    NodeList<VariableDeclaration> variables =
        (declaration as TopLevelVariableDeclaration).variables.variables;
    expect(variables, hasLength(1));
    ConstantEvaluator evaluator = new ConstantEvaluator(
        source, analysisContext.typeProvider,
        typeSystem: analysisContext.typeSystem);
    return evaluator.evaluate(variables[0].initializer);
  }
}
