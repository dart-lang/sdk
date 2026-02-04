// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddSwitchCaseBreakMultiTest);
    defineReflectiveTests(AddSwitchCaseBreakTest);
  });
}

@reflectiveTest
class AddSwitchCaseBreakMultiTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.addSwitchCaseBreakMulti;

  @override
  String get testPackageLanguageVersion => '2.19';

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f(Object? x) {
  switch (x) {
    case 0:
      0;
    case 1:
      1;
    case 2:
      2;
  }
}
''');
    await assertHasFixAllFix(diag.switchCaseCompletesNormally, '''
void f(Object? x) {
  switch (x) {
    case 0:
      0;
      break;
    case 1:
      1;
      break;
    case 2:
      2;
  }
}
''');
  }
}

@reflectiveTest
class AddSwitchCaseBreakTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.addSwitchCaseBreak;

  @override
  String get testPackageLanguageVersion => '2.19';

  Future<void> test_sharedCaseBody() async {
    await resolveTestCode('''
void f(Object? x) {
  switch (x) {
    case 0:
    case 1:
      0;
    case 2:
      2;
  }
}
''');
    await assertHasFix('''
void f(Object? x) {
  switch (x) {
    case 0:
    case 1:
      0;
      break;
    case 2:
      2;
  }
}
''');
  }
}
