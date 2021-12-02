// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_error_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../transform_set_parser_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IncompatibleElementKindTest);
  });
}

@reflectiveTest
class IncompatibleElementKindTest extends AbstractTransformSetParserTest {
  void test_integer() {
    assertErrors('''
version: 1
transforms:
- title: 'Replace'
  date: 2021-11-30
  element:
    uris: ['test.dart']
    method: 'm'
    inClass: 'C'
  changes:
    - kind: 'replacedBy'
      newElement:
        uris: ['test.dart']
        variable: 'v'
''', [
      error(TransformSetErrorCode.incompatibleElementKind, 191, 42),
    ]);
  }
}
