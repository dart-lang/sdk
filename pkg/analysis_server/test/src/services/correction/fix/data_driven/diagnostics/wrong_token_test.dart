// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_error_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../code_fragment_parser_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WrongTokenTest);
  });
}

@reflectiveTest
class WrongTokenTest extends AbstractCodeFragmentParserTest {
  void test_closeBracket() {
    assertErrors('arguments[2 3', [
      error(TransformSetErrorCode.wrongToken, 12, 1),
    ]);
  }

  void test_identifier_afterPeriod() {
    assertErrors('arguments[2].1', [
      error(TransformSetErrorCode.wrongToken, 13, 1),
    ]);
  }

  void test_identifier_initial() {
    assertErrors('1', [
      error(TransformSetErrorCode.wrongToken, 0, 1),
    ]);
  }

  void test_index() {
    assertErrors('arguments[.', [
      error(TransformSetErrorCode.wrongToken, 10, 1),
    ]);
  }

  void test_openBracket() {
    assertErrors('arguments.', [
      error(TransformSetErrorCode.wrongToken, 9, 1),
    ]);
  }

  void test_period() {
    assertErrors('arguments[2] typeArguments', [
      error(TransformSetErrorCode.wrongToken, 13, 13),
    ]);
  }
}
