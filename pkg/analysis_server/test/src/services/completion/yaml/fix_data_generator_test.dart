// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/yaml/fix_data_generator.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'yaml_generator_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FixDataGeneratorTest);
  });
}

@reflectiveTest
class FixDataGeneratorTest extends YamlGeneratorTest {
  @override
  String get fileName => 'fix_data.yaml';

  @override
  FixDataGenerator get generator => FixDataGenerator(resourceProvider);

  void test_empty() {
    getCompletions('^');
    assertSuggestion('version: ');
    assertSuggestion('transforms:');
  }

  void test_transforms_changes_listItem_last() {
    getCompletions('''
transforms:
  - changes:
    - kind: rename
      ^
''');
    assertSuggestion('newName: ');
    assertNoSuggestion('kind: ');
  }

  void test_transforms_changes_listItem_only() {
    getCompletions('''
transforms:
  - changes:
    - ^
''');
    assertSuggestion('kind: ');
  }

  void test_transforms_element() {
    getCompletions('''
transforms:
  - element:
      ^
''');
    assertSuggestion('uris: ');
  }

  void test_transforms_listItem_last() {
    getCompletions('''
transforms:
  - title: ''
    ^
''');
    assertSuggestion('date: ');
    assertNoSuggestion('title: ');
  }

  void test_transforms_listItem_only() {
    getCompletions('''
transforms:
  - ^
''');
    assertSuggestion('title: ');
  }
}
