// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_error_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../transform_set_parser_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingOneOfMultipleKeysTest);
  });
}

@reflectiveTest
class MissingOneOfMultipleKeysTest extends AbstractTransformSetParserTest {
  void test_element() {
    assertErrors('''
version: 1
transforms:
- title: ''
  date: 2020-09-14
  element:
    uris: ['test.dart']
  changes: []
''', [
      error(TransformSetErrorCode.missingOneOfMultipleKeys, 69, 22),
    ]);
  }

  void test_element_container() {
    assertErrors('''
version: 1
transforms:
- title: ''
  date: 2020-09-14
  element:
    uris: ['test.dart']
    method: 'm'
  changes: []
''', [
      error(TransformSetErrorCode.missingOneOfMultipleKeys, 69, 38),
    ]);
  }

  void test_removeParameterChange() {
    assertErrors('''
version: 1
transforms:
- title: ''
  date: 2020-09-14
  element:
    uris: ['test.dart']
    function: 'f'
  changes:
    - kind: removeParameter
''', [
      error(TransformSetErrorCode.missingOneOfMultipleKeys, 124, 22),
    ]);
  }

  void test_transform() {
    assertErrors('''
version: 1
transforms:
- title: ''
  date: 2020-09-14
  element:
    uris: ['test.dart']
    function: 'f'
''', [
      error(TransformSetErrorCode.missingOneOfMultipleKeys, 0, 107),
    ]);
  }
}
