// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToPackageImportTest);
  });
}

@reflectiveTest
class ConvertToPackageImportTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_TO_PACKAGE_IMPORT;

  Future<void> test_fileName_onImport() async {
    addSource('/home/test/lib/foo.dart', '');

    await resolveTestCode('''
import 'foo.dart';
''');
    // Validate assist is on import keyword too.
    await assertHasAssistAt('import', '''
import 'package:test/foo.dart';
''');
  }

  Future<void> test_fileName_onUri() async {
    addSource('/home/test/lib/foo.dart', '');

    await resolveTestCode('''
import 'foo.dart';
''');
    await assertHasAssistAt('foo.dart', '''
import 'package:test/foo.dart';
''');
  }

  Future<void> test_invalidUri() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
import ':[invalidUri]';
''');
    await assertNoAssistAt('invalid');
  }

  Future<void> test_nonPackage_Uri() async {
    addSource('/home/test/lib/foo.dart', '');
    testFile = convertPath('/home/test/lib/src/test.dart');
    await resolveTestCode('''
import 'dart:core';
''');

    await assertNoAssistAt('dart:core');
    await assertNoAssistAt('import');
  }

  Future<void> test_packageUri() async {
    addSource('/home/test/lib/foo.dart', '');

    await resolveTestCode('''
import 'package:test/foo.dart';
''');
    await assertNoAssistAt('foo.dart');
    await assertNoAssistAt('import');
  }

  Future<void> test_path() async {
    addSource('/home/test/lib/foo/bar.dart', '');

    testFile = convertPath('/home/test/lib/src/test.dart');

    await resolveTestCode('''
import '../foo/bar.dart';
''');
    await assertHasAssistAt('bar.dart', '''
import 'package:test/foo/bar.dart';
''');
  }

  Future<void> test_relativeImport_noAssistWithLint() async {
    createAnalysisOptionsFile(lints: [LintNames.avoid_relative_lib_imports]);
    verifyNoTestUnitErrors = false;
    addSource('/home/test/lib/foo.dart', '');

    await resolveTestCode('''
import '../lib/foo.dart';
''');
    await assertNoAssist();
  }
}
