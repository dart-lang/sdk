// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix/data_driven/rename.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_set_error_code.dart';
import 'package:matcher/matcher.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'transform_set_parser_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TransformSetParserTest);
  });
}

@reflectiveTest
class TransformSetParserTest extends AbstractTransformSetParserTest {
  void test_element_getter_inMixin() {
    parse('''
version: 1
transforms:
- title: 'Rename g'
  element:
    uris: ['test.dart']
    getter: 'g'
    inMixin: 'A'
  changes: []
''');
    var transforms = result.transformsFor('g', ['test.dart']);
    expect(transforms, hasLength(1));
    var transform = transforms[0];
    expect(transform.title, 'Rename g');
    expect(transform.changes, isEmpty);
  }

  void test_element_getter_topLevel() {
    parse('''
version: 1
transforms:
- title: 'Rename g'
  element:
    uris: ['test.dart']
    getter: 'g'
  changes: []
''');
    var transforms = result.transformsFor('g', ['test.dart']);
    expect(transforms, hasLength(1));
    var transform = transforms[0];
    expect(transform.title, 'Rename g');
    expect(transform.changes, isEmpty);
  }

  void test_element_method_inClass() {
    parse('''
version: 1
transforms:
- title: 'Rename m'
  element:
    uris: ['test.dart']
    method: 'm'
    inClass: 'A'
  changes: []
''');
    var transforms = result.transformsFor('m', ['test.dart']);
    expect(transforms, hasLength(1));
    var transform = transforms[0];
    expect(transform.title, 'Rename m');
    expect(transform.changes, isEmpty);
  }

  void test_incomplete() {
    parse('''
version: 1
transforms:
''');
    expect(result, null);
    // TODO(brianwilkerson) Report a diagnostic.
    errorListener.assertErrors([]);
  }

  void test_invalidYaml() {
    parse('''
[
''');
    expect(result, null);
    errorListener.assertErrors([
      error(TransformSetErrorCode.yamlSyntaxError, 2, 0),
    ]);
  }

  void test_rename() {
    parse('''
version: 1
transforms:
- title: 'Rename A'
  element:
    uris:
      - 'test.dart'
    class: 'A'
  changes:
    - kind: 'rename'
      newName: 'B'
''');
    var transforms = result.transformsFor('A', ['test.dart']);
    expect(transforms, hasLength(1));
    var transform = transforms[0];
    expect(transform.title, 'Rename A');
    expect(transform.changes, hasLength(1));
    var rename = transform.changes[0] as Rename;
    expect(rename.newName, 'B');
  }
}
