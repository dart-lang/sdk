// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnwrapIfBodyTest);
  });
}

@reflectiveTest
class UnwrapIfBodyTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.UNWRAP_IF_BODY;

  Future<void> test_atCondition() async {
    await resolveTestCode('''
void f(bool b) {
  if (b) { // ref
    0;
  }
}
''');
    await assertHasAssistAt('b) { // ref', '''
void f(bool b) {
  0;
}
''');
  }

  Future<void> test_atLeftCurlyBrace() async {
    await resolveTestCode('''
void f(bool b) {
  if (b) { // ref
    0;
  }
}
''');
    await assertNoAssistAt('{ // ref');
  }

  Future<void> test_atLeftParenthesis() async {
    await resolveTestCode('''
void f(bool b) {
  if (b) {
    0;
  }
}
''');
    await assertHasAssistAt('(b)', '''
void f(bool b) {
  0;
}
''');
  }

  Future<void> test_atNestedThenStatement() async {
    await resolveTestCode('''
void f(bool b) {
  if (b) {
    0;
  }
}
''');
    await assertNoAssistAt('0;');
  }

  Future<void> test_atRightParenthesis() async {
    await resolveTestCode('''
void f(bool b) {
  if (b) { // ref
    0;
  }
}
''');
    await assertHasAssistAt(' { // ref', '''
void f(bool b) {
  0;
}
''');
  }

  Future<void> test_block() async {
    await resolveTestCode('''
void f(bool b) {
  0;
  if (b) {
    1;
    2;
  }
  3;
}
''');
    await assertHasAssistAt('if (b)', '''
void f(bool b) {
  0;
  1;
  2;
  3;
}
''');
  }

  Future<void> test_singleStatement() async {
    await resolveTestCode('''
void f(bool b) {
  0;
  if (b) 1;
  2;
}
''');
    await assertHasAssistAt('if (b)', '''
void f(bool b) {
  0;
  1;
  2;
}
''');
  }

  Future<void> test_withElse() async {
    await resolveTestCode('''
void f(bool b) {
  0;
  if (b) {
    1;
  } else {
    2;
  }
  3;
}
''');
    await assertNoAssistAt('if (b)');
  }

  Future<void> test_withElse_atElse() async {
    await resolveTestCode('''
void f(bool b) {
  if (b) {
    0;
  } else {
    1;
  }
}
''');
    await assertNoAssistAt('else');
  }
}
