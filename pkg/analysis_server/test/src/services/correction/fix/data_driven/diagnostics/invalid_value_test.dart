// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../transform_set_parser_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidValueTest);
  });
}

@reflectiveTest
class InvalidValueTest extends AbstractTransformSetParserTest {
  void test_change() {
    assertErrors(
      '''
version: 1
transforms:
- title: 'Rename A'
  date: 2020-09-08
  element:
    uris: ['test.dart']
    class: 'A'
  changes:
    - 'rename'
''',
      [error(diag.invalidValue, 129, 8)],
    );
  }

  void test_element() {
    assertErrors(
      '''
version: 1
transforms:
- title: 'Rename A'
  date: 2020-09-08
  element: 5
  changes:
    - kind: 'rename'
      newName: 'B'
''',
      [error(diag.invalidValue, 73, 1)],
    );
  }

  void test_int_list() {
    assertErrors(
      '''
version: []
transforms:
- title: 'Rename A'
  element:
    uris: ['test.dart']
    class: 'A'
  changes:
    - kind: 'rename'
      newName: 'B'
''',
      [error(diag.invalidValue, 9, 2)],
    );
  }

  void test_int_string() {
    assertErrors(
      '''
version: 'first'
transforms:
- title: 'Rename A'
  element:
    uris: ['test.dart']
    class: 'A'
  changes:
    - kind: 'rename'
      newName: 'B'
''',
      [error(diag.invalidValue, 9, 7)],
    );
  }

  void test_list() {
    assertErrors(
      '''
version: 1
transforms: 3
''',
      [error(diag.invalidValue, 23, 1)],
    );
  }

  void test_string_int() {
    assertErrors(
      '''
version: 1
transforms:
- title: 0
  date: 2020-09-08
  element:
    uris: ['test.dart']
    class: 'A'
  changes:
    - kind: 'rename'
      newName: 'B'
''',
      [error(diag.invalidValue, 32, 1)],
    );
  }

  void test_string_list() {
    assertErrors(
      '''
version: 1
transforms:
- title: []
  date: 2020-09-08
  element:
    uris: ['test.dart']
    class: 'A'
  changes:
    - kind: 'rename'
      newName: 'B'
''',
      [error(diag.invalidValue, 32, 2)],
    );
  }

  void test_transform() {
    assertErrors(
      '''
version: 1
transforms:
- 'rename'
''',
      [error(diag.invalidValue, 25, 8)],
    );
  }

  void test_transformSet() {
    assertErrors(
      '''
- 'rename'
''',
      [error(diag.invalidValue, 0, 11)],
    );
  }

  void test_valueExtractor() {
    assertErrors(
      '''
version: 1
transforms:
- title: 'Rename A'
  date: 2020-09-08
  element:
    uris: ['test.dart']
    class: 'A'
  changes:
    - kind: 'addTypeParameter'
      index: 1
      name: 'T'
      argumentValue: 'int'
''',
      [error(diag.invalidValue, 206, 5)],
    );
  }
}
