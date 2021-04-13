// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_error_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../transform_set_parser_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingKeyTest);
  });
}

@reflectiveTest
class MissingKeyTest extends AbstractTransformSetParserTest {
  void test_addParameterChange_argumentValue() {
    assertErrors('''
version: 1
transforms:
- title: ''
  date: 2020-09-14
  element:
    uris: ['test.dart']
    function: 'f'
  changes:
    - kind: 'addParameter'
      index: 0
      name: 'a'
      style: required_positional
''', [
      error(TransformSetErrorCode.missingKey, 124, 85),
    ]);
  }

  void test_addParameterChange_index() {
    assertErrors('''
version: 1
transforms:
- title: ''
  date: 2020-09-14
  element:
    uris: ['test.dart']
    function: 'f'
  changes:
    - kind: 'addParameter'
      name: 'a'
      style: required_positional
      argumentValue:
        kind: 'argument'
        index: 0
''', [
      error(TransformSetErrorCode.missingKey, 124, 133),
    ]);
  }

  void test_addParameterChange_name() {
    assertErrors('''
version: 1
transforms:
- title: ''
  date: 2020-09-14
  element:
    uris: ['test.dart']
    function: 'f'
  changes:
    - kind: 'addParameter'
      index: 0
      style: required_positional
      argumentValue:
        kind: 'argument'
        index: 0
''', [
      error(TransformSetErrorCode.missingKey, 124, 132),
    ]);
  }

  void test_addParameterChange_style() {
    assertErrors('''
version: 1
transforms:
- title: ''
  date: 2020-09-14
  element:
    uris: ['test.dart']
    function: 'f'
  changes:
    - kind: 'addParameter'
      index: 0
      name: 'a'
      argumentValue:
        kind: 'argument'
        index: 0
''', [
      error(TransformSetErrorCode.missingKey, 124, 115),
    ]);
  }

  void test_addTypeParameterChange_argumentValue() {
    assertErrors('''
version: 1
transforms:
- title: ''
  date: 2020-09-14
  element:
    uris: ['test.dart']
    function: 'f'
  changes:
    - kind: 'addTypeParameter'
      index: 0
      name: 'a'
''', [
      error(TransformSetErrorCode.missingKey, 124, 56),
    ]);
  }

  void test_addTypeParameterChange_index() {
    assertErrors('''
version: 1
transforms:
- title: ''
  date: 2020-09-14
  element:
    uris: ['test.dart']
    function: 'f'
  changes:
    - kind: 'addTypeParameter'
      name: 'a'
      argumentValue:
        expression: ''
''', [
      error(TransformSetErrorCode.missingKey, 124, 85),
    ]);
  }

  void test_addTypeParameterChange_name() {
    assertErrors('''
version: 1
transforms:
- title: ''
  date: 2020-09-14
  element:
    uris: ['test.dart']
    function: 'f'
  changes:
    - kind: 'addTypeParameter'
      index: 0
      argumentValue:
        expression: ''
''', [
      error(TransformSetErrorCode.missingKey, 124, 84),
    ]);
  }

  void test_change_kind() {
    assertErrors('''
version: 1
transforms:
- title: ''
  date: 2020-09-14
  element:
    uris: ['test.dart']
    function: 'f'
  changes:
    - index: 0
''', [
      error(TransformSetErrorCode.missingKey, 124, 9),
    ]);
  }

  void test_element_uris() {
    assertErrors('''
version: 1
transforms:
- title: ''
  date: 2020-09-14
  element:
    function: 'f'
  changes: []
''', [
      error(TransformSetErrorCode.missingKey, 69, 16),
    ]);
  }

  void test_renameChange_newName() {
    assertErrors('''
version: 1
transforms:
- title: ''
  date: 2020-09-14
  element:
    uris: ['test.dart']
    function: 'f'
  changes:
    - kind: 'rename'
''', [
      error(TransformSetErrorCode.missingKey, 124, 15),
    ]);
  }

  void test_transform_date() {
    assertErrors('''
version: 1
transforms:
- title: ''
  element:
    uris: ['test.dart']
    function: 'f'
  changes: []
''', [
      error(TransformSetErrorCode.missingKey, 25, 77),
    ]);
  }

  void test_transform_element() {
    assertErrors('''
version: 1
transforms:
- title: ''
  date: 2020-09-14
  changes: []
''', [
      error(TransformSetErrorCode.missingKey, 25, 43),
    ]);
  }

  void test_transform_title() {
    assertErrors('''
version: 1
transforms:
- date: 2020-09-14
  element:
    uris: ['test.dart']
    function: 'f'
  changes: []
''', [
      error(TransformSetErrorCode.missingKey, 25, 84),
    ]);
  }

  void test_transformSet_transforms() {
    assertErrors('''
version: 1
''', [
      error(TransformSetErrorCode.missingKey, 0, 11),
    ]);
  }

  void test_transformSet_version() {
    assertErrors('''
transforms: []
''', [
      error(TransformSetErrorCode.missingKey, 0, 15),
    ]);
  }
}
