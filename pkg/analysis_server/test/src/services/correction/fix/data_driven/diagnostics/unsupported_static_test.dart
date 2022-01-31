// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_error_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../transform_set_parser_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnsupportedStaticTest);
  });
}

@reflectiveTest
class UnsupportedStaticTest extends AbstractTransformSetParserTest {
  void test_class() {
    assertErrors('''
version: 1
transforms:
- title: ''
  date: 2021-11-22
  element:
    uris: ['test.dart']
    class: 'C'
    static: true
  changes: []
''', [
      error(TransformSetErrorCode.unsupportedStatic, 108, 6),
    ]);
  }

  void test_getter_inClass() {
    assertNoErrors('''
version: 1
transforms:
- title: ''
  date: 2021-11-22
  element:
    uris: ['test.dart']
    getter: 'm'
    inClass: 'C'
    static: true
  changes: []
''');
  }

  void test_getter_topLevel() {
    assertErrors('''
version: 1
transforms:
- title: ''
  date: 2021-11-22
  element:
    uris: ['test.dart']
    getter: 'g'
    static: true
  changes: []
''', [
      error(TransformSetErrorCode.unsupportedStatic, 109, 6),
    ]);
  }
}
