// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_error_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../transform_set_parser_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingTemplateEndTest);
  });
}

@reflectiveTest
class MissingTemplateEndTest extends AbstractTransformSetParserTest {
  void test_missing() {
    assertErrors('''
version: 1
transforms:
- date: 2020-09-19
  element:
    uris: ['test.dart']
    function: 'f'
  title: ''
  changes:
    - kind: 'addParameter'
      index: 0
      name: 'a'
      style: optional_positional
      argumentValue:
        expression: 'a{% x b'
''', [
      error(TransformSetErrorCode.missingTemplateEnd, 252, 2),
    ]);
  }
}
