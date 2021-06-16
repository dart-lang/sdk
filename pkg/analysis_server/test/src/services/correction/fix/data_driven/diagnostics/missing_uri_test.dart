// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_error_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../transform_set_parser_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingUriTest);
  });
}

@reflectiveTest
class MissingUriTest extends AbstractTransformSetParserTest {
  void test_element_empty() {
    assertErrors('''
version: 1
transforms:
- title: ''
  date: 2020-09-14
  element:
    uris: []
    method: 'm'
    inClass: 'C'
  changes: []
''', [
      error(TransformSetErrorCode.missingUri, 75, 2),
    ]);
  }

  void test_element_nonEmpty() {
    assertErrors('''
version: 1
transforms:
- title: ''
  date: 2020-09-14
  element:
    uris: [3]
    method: 'm'
    inClass: 'C'
  changes: []
''', [
      error(TransformSetErrorCode.invalidValue, 76, 1),
    ]);
  }

  void test_import_empty() {
    assertErrors('''
version: 1
transforms:
- title: ''
  date: 2020-09-14
  element:
    uris: ['']
    method: 'm'
    inClass: 'C'
  changes:
    - kind: 'addTypeParameter'
      index: 0
      name: 'T'
      argumentValue:
        expression: ''
        variables:
          t:
            kind: 'import'
            uris: []
            name: 'String'
''', [
      error(TransformSetErrorCode.missingUri, 307, 2),
    ]);
  }

  void test_import_nonEmpty() {
    assertErrors('''
version: 1
transforms:
- title: ''
  date: 2020-09-14
  element:
    uris: ['']
    method: 'm'
    inClass: 'C'
  changes:
    - kind: 'addTypeParameter'
      index: 0
      name: 'T'
      argumentValue:
        expression: ''
        variables:
          t:
            kind: 'import'
            uris: [3]
            name: 'String'
''', [
      error(TransformSetErrorCode.invalidValue, 308, 1),
    ]);
  }
}
