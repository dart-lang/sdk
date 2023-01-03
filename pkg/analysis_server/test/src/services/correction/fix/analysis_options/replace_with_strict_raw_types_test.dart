// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithStrictRawTypesTest);
  });
}

@reflectiveTest
class ReplaceWithStrictRawTypesTest extends AnalysisOptionsFixTest {
  Future<void> test_hasLanguage() async {
    await assertHasFix('''
analyzer:
  language:
    strict-inference: true
  strong-mode:
    implicit-dynamic: false
''', '''
analyzer:
  language:
    strict-inference: true
    strict-raw-types: true
''');
  }

  Future<void> test_hasLanguage_isAfter() async {
    await assertHasFix('''
analyzer:
  strong-mode:
    implicit-dynamic: false
  language:
    strict-inference: true
''', '''
analyzer:
  language:
    strict-inference: true
    strict-raw-types: true
''');
  }

  Future<void> test_hasStrictRawTypesFalse() async {
    await assertHasFix('''
analyzer:
  language:
    strict-raw-types: false
  strong-mode:
    implicit-dynamic: false
''', '''
analyzer:
  language:
    strict-raw-types: true
''');
  }

  Future<void> test_hasStrictRawTypesTrue() async {
    await assertHasFix('''
analyzer:
  language:
    strict-raw-types: true
  strong-mode:
    implicit-dynamic: false
''', '''
analyzer:
  language:
    strict-raw-types: true
''');
  }

  Future<void> test_noLanguage() async {
    await assertHasFix('''
analyzer:
  strong-mode:
    implicit-dynamic: false
''', '''
analyzer:
  language:
    strict-raw-types: true
''');
  }

  Future<void> test_noLanguage_analyzerHasOtherEntries() async {
    await assertHasFix('''
analyzer:
  errors:
    unused_import: ignore
  strong-mode:
    implicit-dynamic: false
''', '''
analyzer:
  errors:
    unused_import: ignore
  language:
    strict-raw-types: true
''');
  }

  Future<void> test_noLanguage_analyzerHasOtherEntriesAfter() async {
    await assertHasFix('''
analyzer:
  strong-mode:
    implicit-dynamic: false
  errors:
    unused_import: ignore
''', '''
analyzer:
  errors:
    unused_import: ignore
  language:
    strict-raw-types: true
''');
  }

  Future<void> test_noLanguage_hasOtherStrongModeEntry() async {
    await assertHasFix('''
analyzer:
  strong-mode:
    implicit-casts: false
    implicit-dynamic: false
''', '''
analyzer:
  language:
    strict-raw-types: true
  strong-mode:
    implicit-casts: false
''', errorFilter: (error) => error.message.contains('implicit-dynamic'));
  }

  Future<void> test_noLanguage_implicitDynamicHasComment() async {
    await assertHasFix('''
analyzer:
  strong-mode:
    # No implicit dynamic
    implicit-dynamic: false
''', '''
analyzer:
  language:
    strict-raw-types: true
''');
  }

  Future<void> test_noLanguage_strongModeHasComment() async {
    // TODO(srawlins): This is unfortunate; it would be better to remove the
    // comment. But we leave this assertion as is to show at least the file is
    // not corrupted.
    await assertHasFix('''
analyzer:
  # Strong mode
  strong-mode:
    implicit-dynamic: false
''', '''
analyzer:
  # Strong mode
  language:
    strict-raw-types: true
''');
  }
}
