// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveSettingTest);
  });
}

@reflectiveTest
class RemoveSettingTest extends AnalysisOptionsFixTest {
  Future<void> test_enableSuperMixins() async {
    await assertHasFix('''
analyzer:
  enable-experiment:
    - non-nullable
  language:
    enableSuperMixins: true
''', '''
analyzer:
  enable-experiment:
    - non-nullable
''');
  }

  Future<void> test_invalidExperiment_first() async {
    await assertHasFix('''
analyzer:
  enable-experiment:
    - not-an-experiment
    - non-nullable
''', '''
analyzer:
  enable-experiment:
    - non-nullable
''');
  }

  Future<void> test_invalidExperiment_last() async {
    await assertHasFix('''
analyzer:
  enable-experiment:
    - non-nullable
    - not-an-experiment
''', '''
analyzer:
  enable-experiment:
    - non-nullable
''');
  }

  Future<void> test_invalidExperiment_only() async {
    await assertHasFix('''
analyzer:
  enable-experiment:
    - not-an-experiment
''', '''
''');
  }
}
