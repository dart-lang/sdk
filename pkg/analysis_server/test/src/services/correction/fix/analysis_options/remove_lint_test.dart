// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveLintTest);
  });
}

@reflectiveTest
class RemoveLintTest extends AnalysisOptionsFixTest {
  void setUp() {
    registerLintRules();
  }

  Future<void> test_deprecated() async {
    await assertHasFix('''
linter:
  rules:
    - camel_case_types
    - super_goes_last
''', '''
linter:
  rules:
    - camel_case_types
''');
  }

  Future<void> test_deprecated_only() async {
    await assertHasFix('''
linter:
  rules:
    - super_goes_last
''', '''
''');
  }

  Future<void> test_deprecated_withSectionAfter() async {
    await assertHasFix('''
linter:
  rules:
    - camel_case_types
    - super_goes_last
section:
  - foo
''', '''
linter:
  rules:
    - camel_case_types
section:
  - foo
''');
  }

  Future<void> test_deprecated_withSectionBefore() async {
    await assertHasFix('''
analyzer:
  exclude:
    - test/data/**

linter:
  rules:
    - camel_case_types
    - super_goes_last
''', '''
analyzer:
  exclude:
    - test/data/**

linter:
  rules:
    - camel_case_types
''');
  }
}
