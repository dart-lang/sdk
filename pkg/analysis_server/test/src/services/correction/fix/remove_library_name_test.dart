// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveLibraryNameTest);
  });
}

@reflectiveTest
class RemoveLibraryNameTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_LIBRARY_NAME;

  @override
  String get lintCode => LintNames.unnecessary_library_name;

  Future<void> test_namedLibrary_libraryIdentifier() async {
    await resolveTestCode('''
/// A library.
library l.m.n;
''');
    await assertHasFix('''
/// A library.
library;
''');
  }

  Future<void> test_namedLibrary_simpleId() async {
    await resolveTestCode('''
/// A library.
library l;
''');
    await assertHasFix('''
/// A library.
library;
''');
  }
}
