// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/refactoring/remove_import_prefix.dart';
import 'package:language_server_protocol/protocol_generated.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'refactoring_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveImportPrefixTest);
  });
}

/// Tests the RemoveImportPrefix refactor (code action).
///
/// More complete tests for the refactor implementation (such as updating
/// references to imported symbols) are in
/// `test\services\refactoring\legacy\rename_import_test.dart`.
@reflectiveTest
class RemoveImportPrefixTest extends RefactoringTest {
  @override
  String get refactoringCommandId => RemoveImportPrefix.commandName;

  String get refactoringTitle => RemoveImportPrefix.constTitle;

  Future<void> test_bad_deferred() async {
    var originalSource = '''
^import 'package:path/path.dart' deferred as path;
''';
    await _assertNoRefactoring(originalSource: originalSource);
  }

  Future<void> test_bad_noPrefix() async {
    var originalSource = '''
^import 'package:path/path.dart';
''';
    await _assertNoRefactoring(originalSource: originalSource);
  }

  Future<void> test_good() async {
    var originalSource = '''
^import 'package:path/path.dart' as path;
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
import 'package:path/path.dart';
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> _assertNoRefactoring({required String originalSource}) async {
    await assertNoRefactoring(
      originalSource: originalSource,
      refactoringTitle: refactoringTitle,
    );
  }

  Future<void> _assertRefactoring({
    required String originalSource,
    required String expected,
    String? otherFilePath,
    String? otherFileContent,
    ProgressToken? commandWorkDoneToken,
  }) async {
    await assertRefactoring(
      originalSource: originalSource,
      expected: expected,
      refactoringTitle: refactoringTitle,
      otherFilePath: otherFilePath,
      otherFileContent: otherFileContent,
      commandWorkDoneToken: commandWorkDoneToken,
    );
  }
}
