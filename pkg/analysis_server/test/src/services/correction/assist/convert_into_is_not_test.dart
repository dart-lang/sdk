// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertIntoIsNotTest);
  });
}

@reflectiveTest
class ConvertIntoIsNotTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertIntoIsNot;

  Future<void> test_childOfIs_left() async {
    await resolveTestCode('''
void f(p) {
  !(^p is String);
}
''');
    await assertHasAssist('''
void f(p) {
  p is! String;
}
''');
  }

  Future<void> test_childOfIs_right() async {
    await resolveTestCode('''
void f(p) {
  !(p is ^String);
}
''');
    await assertHasAssist('''
void f(p) {
  p is! String;
}
''');
  }

  Future<void> test_is() async {
    await resolveTestCode('''
void f(p) {
  !(p ^is String);
}
''');
    await assertHasAssist('''
void f(p) {
  p is! String;
}
''');
  }

  Future<void> test_is_alreadyIsNot() async {
    await resolveTestCode('''
void f(p) {
  p ^is! String;
}
''');
    await assertNoAssist();
  }

  Future<void> test_is_higherPrecedencePrefix() async {
    await resolveTestCode('''
void f(p) {
  !!(p ^is String);
}
''');
    await assertHasAssist('''
void f(p) {
  !(p is! String);
}
''');
  }

  Future<void> test_is_noEnclosingParenthesis() async {
    await resolveTestCode('''
void f(p) {
  p ^is String;
}
''');
    await assertNoAssist();
  }

  Future<void> test_is_noPrefix() async {
    await resolveTestCode('''
void f(p) {
  (p ^is String);
}
''');
    await assertNoAssist();
  }

  Future<void> test_is_not_higherPrecedencePrefix() async {
    await resolveTestCode('''
void f(p) {
  !^!(p is String);
}
''');
    await assertHasAssist('''
void f(p) {
  !(p is! String);
}
''');
  }

  Future<void> test_is_notIsExpression() async {
    await resolveTestCode('''
void f(p) {
  ^123 + 456;
}
''');
    await assertNoAssist();
  }

  Future<void> test_is_notTheNotOperator() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f(p) {
  ++(p ^is String);
}
''');
    await assertNoAssist();
  }

  Future<void> test_not() async {
    await resolveTestCode('''
void f(p) {
  ^!(p is String);
}
''');
    await assertHasAssist('''
void f(p) {
  p is! String;
}
''');
  }

  Future<void> test_not_alreadyIsNot() async {
    await resolveTestCode('''
void f(p) {
  ^!(p is! String);
}
''');
    await assertNoAssist();
  }

  Future<void> test_not_noEnclosingParenthesis() async {
    await resolveTestCode('''
void f(p) {
  ^!p;
}
''');
    await assertNoAssist();
  }

  Future<void> test_not_notIsExpression() async {
    await resolveTestCode('''
void f(p) {
  ^!(p == null);
}
''');
    await assertNoAssist();
  }

  Future<void> test_not_notTheNotOperator() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f(p) {
  ^++(p is String);
}
''');
    await assertNoAssist();
  }

  Future<void> test_parentheses() async {
    await resolveTestCode('''
void f(p) {
  !^(p is String);
}
''');
    await assertHasAssist('''
void f(p) {
  p is! String;
}
''');
  }
}
