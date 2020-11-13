// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToSetLiteralTest);
  });
}

@reflectiveTest
class ConvertToSetLiteralTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_TO_SET_LITERAL;

  Future<void> test_default_declaredType() async {
    await resolveTestCode('''
Set s = S/*caret*/et();
''');
    await assertHasAssist('''
Set s = {};
''');
  }

  Future<void> test_default_minimal() async {
    await resolveTestCode('''
var s = S/*caret*/et();
''');
    await assertHasAssist('''
var s = <dynamic>{};
''');
  }

  Future<void> test_default_newKeyword() async {
    await resolveTestCode('''
var s = new S/*caret*/et();
''');
    await assertHasAssist('''
var s = <dynamic>{};
''');
  }

  Future<void> test_default_typeArg() async {
    await resolveTestCode('''
var s = S/*caret*/et<int>();
''');
    await assertHasAssist('''
var s = <int>{};
''');
  }

  Future<void> test_from_empty() async {
    await resolveTestCode('''
var s = S/*caret*/et.from([]);
''');
    await assertHasAssist('''
var s = <dynamic>{};
''');
  }

  Future<void> test_from_newKeyword() async {
    await resolveTestCode('''
var s = new S/*caret*/et.from([2, 3]);
''');
    await assertHasAssist('''
var s = {2, 3};
''');
  }

  Future<void> test_from_noKeyword_declaredType() async {
    await resolveTestCode('''
Set s = S/*caret*/et.from([2, 3]);
''');
    await assertHasAssist('''
Set s = {2, 3};
''');
  }

  Future<void> test_from_noKeyword_typeArg_onConstructor() async {
    await resolveTestCode('''
var s = S/*caret*/et<int>.from([2, 3]);
''');
    await assertHasAssist('''
var s = <int>{2, 3};
''');
  }

  Future<void> test_from_noKeyword_typeArg_onConstructorAndLiteral() async {
    await resolveTestCode('''
var s = S/*caret*/et<int>.from(<num>[2, 3]);
''');
    await assertHasAssist('''
var s = <int>{2, 3};
''');
  }

  Future<void> test_from_noKeyword_typeArg_onLiteral() async {
    await resolveTestCode('''
var s = S/*caret*/et.from(<int>[2, 3]);
''');
    await assertHasAssist('''
var s = <int>{2, 3};
''');
  }

  Future<void> test_from_nonEmpty() async {
    await resolveTestCode('''
var s = S/*caret*/et.from([2, 3]);
''');
    await assertHasAssist('''
var s = {2, 3};
''');
  }

  Future<void> test_from_notALiteral() async {
    await resolveTestCode('''
var l = [1];
Set s = new S/*caret*/et.from(l);
''');
    await assertNoAssist();
  }

  Future<void> test_from_trailingComma() async {
    await resolveTestCode('''
var s = S/*caret*/et.from([2, 3,]);
''');
    await assertHasAssist('''
var s = {2, 3,};
''');
  }

  Future<void> test_toSet_empty() async {
    await resolveTestCode('''
var s = [].to/*caret*/Set();
''');
    await assertHasAssist('''
var s = <dynamic>{};
''');
  }

  Future<void> test_toSet_empty_typeArg() async {
    await resolveTestCode('''
var s = <int>[].to/*caret*/Set();
''');
    await assertHasAssist('''
var s = <int>{};
''');
  }

  Future<void> test_toSet_nonEmpty() async {
    await resolveTestCode('''
var s = [2, 3].to/*caret*/Set();
''');
    await assertHasAssist('''
var s = {2, 3};
''');
  }

  Future<void> test_toSet_nonEmpty_typeArg() async {
    await resolveTestCode('''
var s = <int>[2, 3].to/*caret*/Set();
''');
    await assertHasAssist('''
var s = <int>{2, 3};
''');
  }

  Future<void> test_toSet_notALiteral() async {
    await resolveTestCode('''
var l = [];
var s = l.to/*caret*/Set();
''');
    await assertNoAssist();
  }
}
