// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/yaml/pubspec_generator.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'yaml_generator_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PubspecGeneratorTest);
  });
}

@reflectiveTest
class PubspecGeneratorTest extends YamlGeneratorTest {
  @override
  String get fileName => 'pubspec.yaml';

  @override
  PubspecGenerator get generator => PubspecGenerator(resourceProvider);

  void test_empty() {
    getCompletions('^');
    assertSuggestion('name: ');
  }

  void test_environment() {
    getCompletions('''
environment:
  ^
''');
    assertSuggestion('flutter: ');
    assertSuggestion('sdk: ');
  }
}
