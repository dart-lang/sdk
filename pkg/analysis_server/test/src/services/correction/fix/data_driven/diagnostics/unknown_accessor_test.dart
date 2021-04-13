// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_error_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../code_fragment_parser_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnknownAccessorTest);
  });
}

@reflectiveTest
class UnknownAccessorTest extends AbstractCodeFragmentParserTest {
  void test_afterPeriod() {
    assertErrors('arguments[0].argument[1]', [
      error(TransformSetErrorCode.unknownAccessor, 13, 8),
    ]);
  }

  void test_initial() {
    assertErrors('argument[0]', [
      error(TransformSetErrorCode.unknownAccessor, 0, 8),
    ]);
  }
}
