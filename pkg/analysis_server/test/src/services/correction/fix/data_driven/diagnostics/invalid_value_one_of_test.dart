// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_error_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../transform_set_parser_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidValueOneOfTest);
  });
}

@reflectiveTest
class InvalidValueOneOfTest extends AbstractTransformSetParserTest {
  void test_changeKind() {
    assertErrors('''
version: 1
transforms:
- title: 'Rename A'
  date: 2020-09-08
  element:
    uris: ['test.dart']
    class: 'A'
  changes:
    - kind: 'invalid'
''', [
      error(TransformSetErrorCode.invalidValueOneOf, 135, 9),
    ]);
  }

  void test_valueKind() {
    assertErrors('''
version: 1
transforms:
- title: 'Rename A'
  date: 2020-09-08
  element:
    uris: ['test.dart']
    class: 'A'
  changes:
    - kind: 'addTypeParameter'
      index: 0
      name: 'T'
      argumentValue: 
        expression: ''
        variables:
          x:
            kind: 'invalid'
''', [
      error(TransformSetErrorCode.invalidValueOneOf, 280, 9),
    ]);
  }
}
