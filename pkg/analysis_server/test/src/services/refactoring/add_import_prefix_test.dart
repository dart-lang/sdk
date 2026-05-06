// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/services/refactoring/add_import_prefix.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'refactoring_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddImportPrefixTest);
  });
}

/// Tests the AddImportPrefix refactor (code action) and that it generates a
/// sensible default prefix/name.
///
/// More complete tests for the refactor implementation (such as updating
/// references to imported symbols) are in
/// `test\services\refactoring\legacy\rename_import_test.dart`.
@reflectiveTest
class AddImportPrefixTest extends RefactoringTest {
  @override
  String get refactoringCommandId => AddImportPrefix.commandName;

  String get refactoringTitle => AddImportPrefix.constTitle;

  Future<void> test_bad_existingPrefix() async {
    var originalSource = '''
^import 'package:path/path.dart' as path;
''';
    await _assertNoRefactoring(originalSource: originalSource);
  }

  Future<void> test_bad_exportDirective() async {
    var originalSource = '''
^export 'package:path/path.dart';
''';
    await _assertNoRefactoring(originalSource: originalSource);
  }

  /// For convenience, allow the position to be the end of the line.
  Future<void> test_good_location_afterSemicolon() async {
    var originalSource = '''
import 'package:test/main.dart';^
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
import 'package:test/main.dart' as main;
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_good_location_beforeSemicolon() async {
    var originalSource = '''
import 'package:test/main.dart'^;
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
import 'package:test/main.dart' as main;
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_good_location_importKeyword() async {
    var originalSource = '''
im^port 'package:test/main.dart';
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
import 'package:test/main.dart' as main;
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_good_location_uri() async {
    var originalSource = '''
import 'package:test/ma^in.dart';
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
import 'package:test/main.dart' as main;
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_good_name_createsUniquePrefix() async {
    var originalSource = '''
import 'package:x0/main.dart' as main;
import 'package:x1/main.dart' as main1;
import 'package:x2/main.dart' as main2;
^import 'package:test/main.dart';
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
import 'package:x0/main.dart' as main;
import 'package:x1/main.dart' as main1;
import 'package:x2/main.dart' as main2;
import 'package:test/main.dart' as main3;
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_good_name_filenameIsInvalidDartIdentifier() async {
    var originalSource = r'''
^import '1. - !foo"bar.dart';
''';
    var expected = r'''
>>>>>>>>>> lib/main.dart
import '1. - !foo"bar.dart' as foo_bar;
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_good_name_filenameIsKeyword() async {
    var originalSource = '''
^import 'class.dart';
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
import 'class.dart' as prefix;
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_good_name_packageUri_existing() async {
    var originalSource = '''
^import 'package:test/main.dart';
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
import 'package:test/main.dart' as main;
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_good_name_packageUri_notExisting() async {
    var originalSource = '''
^import 'package:invalid/missing_file.dart';
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
import 'package:invalid/missing_file.dart' as missing_file;
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_good_name_relativeUri_existing() async {
    var originalSource = '''
^import 'main.dart';
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
import 'main.dart' as main;
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_good_name_relativeUri_notExisting() async {
    var originalSource = '''
^import 'missing_file.dart';
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
import 'missing_file.dart' as missing_file;
''';
    await _assertRefactoring(
      originalSource: originalSource,
      expected: expected,
    );
  }

  Future<void> test_good_name_underscoresCollapsed() async {
    var originalSource = '''
^import 'foo - bar.dart';
''';
    var expected = '''
>>>>>>>>>> lib/main.dart
import 'foo - bar.dart' as foo_bar;
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
