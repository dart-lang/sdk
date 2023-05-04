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

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/49759')
  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f(int i) {
  switch(i) {
    case 0:
      i++;
    case 1:
      i++;
    case 2:
      i++;
  }
}
''');
    await assertHasFixAllFix(
        CompileTimeErrorCode.SWITCH_CASE_COMPLETES_NORMALLY, '''
void f(int i) {
  switch(i) {
    case 0:
      i++;
      break;
    case 1:
      i++;
      break;
    case 2:
      i++;
  }
}
''');
  }

  Future<void> test_singleFile_language219() async {
    await resolveTestCode('''
// @dart=2.19
void f(int i) {
  switch(i) {
    case 0:
      i++;
    case 1:
      i++;
    case 2:
      i++;
  }
}
''');
    await assertHasFixAllFix(
        CompileTimeErrorCode.SWITCH_CASE_COMPLETES_NORMALLY, '''
// @dart=2.19
void f(int i) {
  switch(i) {
    case 0:
      i++;
      break;
    case 1:
      i++;
      break;
    case 2:
      i++;
  }
}
''');
  }
}

@reflectiveTest
class AddSwitchCaseBreakTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_SWITCH_CASE_BREAK;

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/49759')
  Future<void> test_indentation() async {
    await resolveTestCode('''
void f(int i) {
    switch(i) {
        case 0:
            i++;
        case 1:
            i++;
  }
}
''');
    await assertHasFix('''
void f(int i) {
    switch(i) {
        case 0:
            i++;
            break;
        case 1:
            i++;
  }
}
''');
  }

  Future<void> test_indentation_language219() async {
    await resolveTestCode('''
// @dart=2.19
void f(int i) {
    switch(i) {
        case 0:
            i++;
        case 1:
            i++;
  }
}
''');
    await assertHasFix('''
// @dart=2.19
void f(int i) {
    switch(i) {
        case 0:
            i++;
            break;
        case 1:
            i++;
  }
}
''');
  }
}
