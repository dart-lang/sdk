// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_error_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../transform_set_parser_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidRequiredIfTest);
  });
}

@reflectiveTest
class InvalidRequiredIfTest extends AbstractTransformSetParserTest {
  void test_requiredNamed() {
    assertErrors('''
version: 1
transforms:
- title: ''
  date: 2020-09-14
  element:
    uris: ['test.dart']
    method: 'm'
    inClass: 'C'
  changes:
    - kind: addParameter
      style: required_named
      index: 0
      name: 'p'
      argumentValue:
        expression: ''
        requiredIf: "p != ''"
        variables:
          p:
            kind: 'fragment'
            value: 'arguments[1]'
''', [
      error(TransformSetErrorCode.invalidRequiredIf, 269, 10),
    ]);
  }
}
