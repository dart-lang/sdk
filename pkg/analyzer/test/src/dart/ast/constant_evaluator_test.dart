// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/constant_evaluator.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'parse_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantEvaluatorTest);
  });
}

@reflectiveTest
class ConstantEvaluatorTest extends ParseBase {
  void test_binary_bitAnd() {
    int value = _getConstantValue("74 & 42");
    expect(value, 74 & 42);
  }

  void test_binary_bitOr() {
    int value = _getConstantValue("74 | 42");
    expect(value, 74 | 42);
  }

  void test_binary_bitXor() {
    int value = _getConstantValue("74 ^ 42");
    expect(value, 74 ^ 42);
  }

  void test_binary_divide_double() {
    Object value = _getConstantValue("3.2 / 2.3");
    expect(value, 3.2 / 2.3);
  }

  void test_binary_divide_integer() {
    Object value = _getConstantValue("3 / 2");
    expect(value, 1.5);
  }

  void test_binary_equal_boolean() {
    Object value = _getConstantValue("true == false");
    expect(value, false);
  }

  void test_binary_equal_integer() {
    Object value = _getConstantValue("2 == 3");
    expect(value, false);
  }

  void test_binary_equal_invalidLeft() {
    Object value = _getConstantValue("a == 3");
    expect(value, ConstantEvaluator.NOT_A_CONSTANT);
  }

  void test_binary_equal_invalidRight() {
    Object value = _getConstantValue("2 == a");
    expect(value, ConstantEvaluator.NOT_A_CONSTANT);
  }

  void test_binary_equal_string() {
    Object value = _getConstantValue("'a' == 'b'");
    expect(value, false);
  }

  void test_binary_greaterThan() {
    Object value = _getConstantValue("2 > 3");
    expect(value, false);
  }

  void test_binary_greaterThanOrEqual() {
    Object value = _getConstantValue("2 >= 3");
    expect(value, false);
  }

  void test_binary_leftShift() {
    int value = _getConstantValue("16 << 2");
    expect(value, 64);
  }

  void test_binary_lessThan() {
    Object value = _getConstantValue("2 < 3");
    expect(value, true);
  }

  void test_binary_lessThanOrEqual() {
    Object value = _getConstantValue("2 <= 3");
    expect(value, true);
  }

  void test_binary_logicalAnd() {
    Object value = _getConstantValue("true && false");
    expect(value, false);
  }

  void test_binary_logicalOr() {
    Object value = _getConstantValue("true || false");
    expect(value, true);
  }

  void test_binary_minus_double() {
    Object value = _getConstantValue("3.2 - 2.3");
    expect(value, 3.2 - 2.3);
  }

  void test_binary_minus_integer() {
    Object value = _getConstantValue("3 - 2");
    expect(value, 1);
  }

  void test_binary_notEqual_boolean() {
    Object value = _getConstantValue("true != false");
    expect(value, true);
  }

  void test_binary_notEqual_integer() {
    Object value = _getConstantValue("2 != 3");
    expect(value, true);
  }

  void test_binary_notEqual_invalidLeft() {
    Object value = _getConstantValue("a != 3");
    expect(value, ConstantEvaluator.NOT_A_CONSTANT);
  }

  void test_binary_notEqual_invalidRight() {
    Object value = _getConstantValue("2 != a");
    expect(value, ConstantEvaluator.NOT_A_CONSTANT);
  }

  void test_binary_notEqual_string() {
    Object value = _getConstantValue("'a' != 'b'");
    expect(value, true);
  }

  void test_binary_plus_double() {
    Object value = _getConstantValue("2.3 + 3.2");
    expect(value, 2.3 + 3.2);
  }

  void test_binary_plus_double_string() {
    Object value = _getConstantValue("'world' + 5.5");
    expect(value, ConstantEvaluator.NOT_A_CONSTANT);
  }

  void test_binary_plus_int_string() {
    Object value = _getConstantValue("'world' + 5");
    expect(value, ConstantEvaluator.NOT_A_CONSTANT);
  }

  void test_binary_plus_integer() {
    Object value = _getConstantValue("2 + 3");
    expect(value, 5);
  }

  void test_binary_plus_string() {
    Object value = _getConstantValue("'hello ' + 'world'");
    expect(value, 'hello world');
  }

  void test_binary_plus_string_double() {
    Object value = _getConstantValue("5.5 + 'world'");
    expect(value, ConstantEvaluator.NOT_A_CONSTANT);
  }

  void test_binary_plus_string_int() {
    Object value = _getConstantValue("5 + 'world'");
    expect(value, ConstantEvaluator.NOT_A_CONSTANT);
  }

  void test_binary_remainder_double() {
    Object value = _getConstantValue("3.2 % 2.3");
    expect(value, 3.2 % 2.3);
  }

  void test_binary_remainder_integer() {
    Object value = _getConstantValue("8 % 3");
    expect(value, 2);
  }

  void test_binary_rightShift() {
    int value = _getConstantValue("64 >> 2");
    expect(value, 16);
  }

  void test_binary_times_double() {
    Object value = _getConstantValue("2.3 * 3.2");
    expect(value, 2.3 * 3.2);
  }

  void test_binary_times_integer() {
    Object value = _getConstantValue("2 * 3");
    expect(value, 6);
  }

  void test_binary_truncatingDivide_double() {
    int value = _getConstantValue("3.2 ~/ 2.3");
    expect(value, 1);
  }

  void test_binary_truncatingDivide_integer() {
    int value = _getConstantValue("10 ~/ 3");
    expect(value, 3);
  }

  @failingTest
  void test_constructor() {
    Object value = _getConstantValue("?");
    expect(value, null);
  }

  @failingTest
  void test_identifier_class() {
    Object value = _getConstantValue("?");
    expect(value, null);
  }

  @failingTest
  void test_identifier_function() {
    Object value = _getConstantValue("?");
    expect(value, null);
  }

  @failingTest
  void test_identifier_static() {
    Object value = _getConstantValue("?");
    expect(value, null);
  }

  @failingTest
  void test_identifier_staticMethod() {
    Object value = _getConstantValue("?");
    expect(value, null);
  }

  @failingTest
  void test_identifier_topLevel() {
    Object value = _getConstantValue("?");
    expect(value, null);
  }

  @failingTest
  void test_identifier_typeParameter() {
    Object value = _getConstantValue("?");
    expect(value, null);
  }

  void test_literal_boolean_false() {
    Object value = _getConstantValue("false");
    expect(value, false);
  }

  void test_literal_boolean_true() {
    Object value = _getConstantValue("true");
    expect(value, true);
  }

  void test_literal_list() {
    List value = _getConstantValue("['a', 'b', 'c']");
    expect(value.length, 3);
    expect(value[0], "a");
    expect(value[1], "b");
    expect(value[2], "c");
  }

  void test_literal_map() {
    Map value = _getConstantValue("{'a' : 'm', 'b' : 'n', 'c' : 'o'}");
    expect(value.length, 3);
    expect(value["a"], "m");
    expect(value["b"], "n");
    expect(value["c"], "o");
  }

  void test_literal_null() {
    Object value = _getConstantValue("null");
    expect(value, null);
  }

  void test_literal_number_double() {
    Object value = _getConstantValue("3.45");
    expect(value, 3.45);
  }

  void test_literal_number_integer() {
    Object value = _getConstantValue("42");
    expect(value, 42);
  }

  void test_literal_string_adjacent() {
    Object value = _getConstantValue("'abc' 'def'");
    expect(value, "abcdef");
  }

  void test_literal_string_interpolation_invalid() {
    Object value = _getConstantValue("'a\${f()}c'");
    expect(value, ConstantEvaluator.NOT_A_CONSTANT);
  }

  void test_literal_string_interpolation_valid() {
    Object value = _getConstantValue("'a\${3}c'");
    expect(value, "a3c");
  }

  void test_literal_string_simple() {
    Object value = _getConstantValue("'abc'");
    expect(value, "abc");
  }

  void test_parenthesizedExpression() {
    Object value = _getConstantValue("('a')");
    expect(value, "a");
  }

  void test_unary_bitNot() {
    int value = _getConstantValue("~42");
    expect(value, ~42);
  }

  void test_unary_logicalNot() {
    Object value = _getConstantValue("!true");
    expect(value, false);
  }

  void test_unary_negated_double() {
    Object value = _getConstantValue("-42.3");
    expect(value, -42.3);
  }

  void test_unary_negated_integer() {
    Object value = _getConstantValue("-42");
    expect(value, -42);
  }

  Object _getConstantValue(String expressionCode) {
    var path = convertPath('/test/lib/test.dart');

    newFile(path, content: '''
void f() {
  ($expressionCode); // ref
}
''');

    var parseResult = parseUnit(path);
    expect(parseResult.errors, isEmpty);

    var findNode = FindNode(parseResult.content, parseResult.unit);
    var expression = findNode.parenthesized('); // ref').expression;

    return expression.accept(ConstantEvaluator());
  }
}
