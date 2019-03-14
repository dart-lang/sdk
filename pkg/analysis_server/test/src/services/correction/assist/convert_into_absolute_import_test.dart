// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertIntoAbsoluteImportTest);
  });
}

@reflectiveTest
class ConvertIntoAbsoluteImportTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_INTO_ABSOLUTE_IMPORT;

  test_fileName_onUri() async {
    addSource('/home/test/lib/foo.dart', '');

    await resolveTestUnit('''
import 'foo.dart';
''');
    await assertHasAssistAt('foo.dart', '''
import 'package:test/foo.dart';
''');
  }

  test_fileName_onImport() async {
    addSource('/home/test/lib/foo.dart', '');

    await resolveTestUnit('''
import 'foo.dart';
''');
    // Validate assist is on import keyword too.
    await assertHasAssistAt('import', '''
import 'package:test/foo.dart';
''');
  }

  test_nonPackage_Uri() async {
    addSource('/home/test/lib/foo.dart', '');

    await resolveTestUnit('''
import 'dart:core';
''');

    await assertNoAssistAt('dart:core');
    await assertNoAssistAt('import');
  }

  test_path() async {
    addSource('/home/test/lib/foo/bar.dart', '');

    testFile = convertPath('/home/test/lib/src/test.dart');

    await resolveTestUnit('''
import '../foo/bar.dart';
''');
    await assertHasAssistAt('bar.dart', '''
import 'package:test/foo/bar.dart';
''');
  }
}
