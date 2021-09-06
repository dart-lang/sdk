// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_error_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../transform_set_parser_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnexpectedTokenTest);
  });
}

@reflectiveTest
class UnexpectedTokenTest extends AbstractTransformSetParserTest {
  void test_integer() {
    assertErrors('''
version: 1
transforms:
  - title: 'Remove nullOk'
    date: 2020-11-04
    element:
      uris: [ 'test.dart' ]
      method: 'm'
      inClass: 'C'
    oneOf:
      - if: "'x' == 'y' 'z'"
        changes: []
''', [
      error(TransformSetErrorCode.unexpectedToken, 184, 3),
    ]);
  }
}
