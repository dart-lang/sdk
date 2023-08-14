// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
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
  FixKind get kind => DartFixKind.ADD_SWITCH_CASE_BREAK_MULTI;

  @override
  String? get testPackageLanguageVersion => '2.19';

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
    await assertHasFixAllFix(
        CompileTimeErrorCode.SWITCH_CASE_COMPLETES_NORMALLY, '''
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
  FixKind get kind => DartFixKind.ADD_SWITCH_CASE_BREAK;

  @override
  String? get testPackageLanguageVersion => '2.19';

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
