// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IntegerLiteralImplTest);
  });
}

@reflectiveTest
class IntegerLiteralImplTest {
  test_isValidLiteral_dec_negative_equalMax() async {
    expect(
        IntegerLiteralImpl.isValidLiteral('9223372036854775808', true), true);
  }

  test_isValidLiteral_dec_negative_fewDigits() async {
    expect(IntegerLiteralImpl.isValidLiteral('24', true), true);
  }

  test_isValidLiteral_dec_negative_leadingZeros_overMax() async {
    expect(IntegerLiteralImpl.isValidLiteral('009923372036854775807', true),
        false);
  }

  test_isValidLiteral_dec_negative_leadingZeros_underMax() async {
    expect(
        IntegerLiteralImpl.isValidLiteral('004223372036854775807', true), true);
  }

  test_isValidLiteral_dec_negative_oneOverMax() async {
    expect(
        IntegerLiteralImpl.isValidLiteral('9223372036854775809', true), false);
  }

  test_isValidLiteral_dec_negative_tooManyDigits() async {
    expect(
        IntegerLiteralImpl.isValidLiteral('10223372036854775808', true), false);
  }

  test_isValidLiteral_dec_positive_equalMax() async {
    expect(
        IntegerLiteralImpl.isValidLiteral('9223372036854775807', false), true);
  }

  test_isValidLiteral_dec_positive_fewDigits() async {
    expect(IntegerLiteralImpl.isValidLiteral('42', false), true);
  }

  test_isValidLiteral_dec_positive_leadingZeros_overMax() async {
    expect(IntegerLiteralImpl.isValidLiteral('009923372036854775807', false),
        false);
  }

  test_isValidLiteral_dec_positive_leadingZeros_underMax() async {
    expect(IntegerLiteralImpl.isValidLiteral('004223372036854775807', false),
        true);
  }

  test_isValidLiteral_dec_positive_oneOverMax() async {
    expect(
        IntegerLiteralImpl.isValidLiteral('9223372036854775808', false), false);
  }

  test_isValidLiteral_dec_positive_tooManyDigits() async {
    expect(IntegerLiteralImpl.isValidLiteral('10223372036854775808', false),
        false);
  }

  test_isValidLiteral_hex_negative_equalMax() async {
    expect(IntegerLiteralImpl.isValidLiteral('0x7FFFFFFFFFFFFFFF', true), true);
  }

  test_isValidLiteral_heX_negative_equalMax() async {
    expect(IntegerLiteralImpl.isValidLiteral('0X7FFFFFFFFFFFFFFF', true), true);
  }

  test_isValidLiteral_hex_negative_fewDigits() async {
    expect(IntegerLiteralImpl.isValidLiteral('0xFF', true), true);
  }

  test_isValidLiteral_heX_negative_fewDigits() async {
    expect(IntegerLiteralImpl.isValidLiteral('0XFF', true), true);
  }

  test_isValidLiteral_hex_negative_leadingZeros_overMax() async {
    expect(IntegerLiteralImpl.isValidLiteral('0x00FFFFFFFFFFFFFFFFF', true),
        false);
  }

  test_isValidLiteral_heX_negative_leadingZeros_overMax() async {
    expect(IntegerLiteralImpl.isValidLiteral('0X00FFFFFFFFFFFFFFFFF', true),
        false);
  }

  test_isValidLiteral_hex_negative_leadingZeros_underMax() async {
    expect(
        IntegerLiteralImpl.isValidLiteral('0x007FFFFFFFFFFFFFFF', true), true);
  }

  test_isValidLiteral_heX_negative_leadingZeros_underMax() async {
    expect(
        IntegerLiteralImpl.isValidLiteral('0X007FFFFFFFFFFFFFFF', true), true);
  }

  test_isValidLiteral_hex_negative_oneOverMax() async {
    expect(
        IntegerLiteralImpl.isValidLiteral('0x8000000000000000', true), false);
  }

  test_isValidLiteral_heX_negative_oneOverMax() async {
    expect(
        IntegerLiteralImpl.isValidLiteral('0X8000000000000000', true), false);
  }

  test_isValidLiteral_hex_negative_tooManyDigits() async {
    expect(
        IntegerLiteralImpl.isValidLiteral('0x10000000000000000', true), false);
  }

  test_isValidLiteral_heX_negative_tooManyDigits() async {
    expect(
        IntegerLiteralImpl.isValidLiteral('0X10000000000000000', true), false);
  }

  test_isValidLiteral_hex_positive_equalMax() async {
    expect(
        IntegerLiteralImpl.isValidLiteral('0x7FFFFFFFFFFFFFFF', false), true);
  }

  test_isValidLiteral_heX_positive_equalMax() async {
    expect(
        IntegerLiteralImpl.isValidLiteral('0X7FFFFFFFFFFFFFFF', false), true);
  }

  test_isValidLiteral_hex_positive_fewDigits() async {
    expect(IntegerLiteralImpl.isValidLiteral('0xFF', false), true);
  }

  test_isValidLiteral_heX_positive_fewDigits() async {
    expect(IntegerLiteralImpl.isValidLiteral('0XFF', false), true);
  }

  test_isValidLiteral_hex_positive_leadingZeros_overMax() async {
    expect(IntegerLiteralImpl.isValidLiteral('0x00FFFFFFFFFFFFFFFFF', false),
        false);
  }

  test_isValidLiteral_heX_positive_leadingZeros_overMax() async {
    expect(IntegerLiteralImpl.isValidLiteral('0X00FFFFFFFFFFFFFFFFF', false),
        false);
  }

  test_isValidLiteral_hex_positive_leadingZeros_underMax() async {
    expect(
        IntegerLiteralImpl.isValidLiteral('0x007FFFFFFFFFFFFFFF', false), true);
  }

  test_isValidLiteral_heX_positive_leadingZeros_underMax() async {
    expect(
        IntegerLiteralImpl.isValidLiteral('0X007FFFFFFFFFFFFFFF', false), true);
  }

  test_isValidLiteral_hex_positive_oneOverMax() async {
    expect(
        IntegerLiteralImpl.isValidLiteral('0x10000000000000000', false), false);
  }

  test_isValidLiteral_heX_positive_oneOverMax() async {
    expect(
        IntegerLiteralImpl.isValidLiteral('0X10000000000000000', false), false);
  }

  test_isValidLiteral_hex_positive_tooManyDigits() async {
    expect(IntegerLiteralImpl.isValidLiteral('0xFF0000000000000000', false),
        false);
  }

  test_isValidLiteral_heX_positive_tooManyDigits() async {
    expect(IntegerLiteralImpl.isValidLiteral('0XFF0000000000000000', false),
        false);
  }
}
