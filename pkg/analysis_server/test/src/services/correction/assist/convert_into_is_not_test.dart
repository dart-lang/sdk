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
  AssistKind get kind => DartAssistKind.CONVERT_INTO_IS_NOT;

  Future<void> test_childOfIs_left() async {
    await resolveTestCode('''
main(p) {
  !(p is String);
}
''');
    await assertHasAssistAt('p is', '''
main(p) {
  p is! String;
}
''');
  }

  Future<void> test_childOfIs_right() async {
    await resolveTestCode('''
main(p) {
  !(p is String);
}
''');
    await assertHasAssistAt('String)', '''
main(p) {
  p is! String;
}
''');
  }

  Future<void> test_is() async {
    await resolveTestCode('''
main(p) {
  !(p is String);
}
''');
    await assertHasAssistAt('is String', '''
main(p) {
  p is! String;
}
''');
  }

  Future<void> test_is_alreadyIsNot() async {
    await resolveTestCode('''
main(p) {
  p is! String;
}
''');
    await assertNoAssistAt('is!');
  }

  Future<void> test_is_higherPrecedencePrefix() async {
    await resolveTestCode('''
main(p) {
  !!(p is String);
}
''');
    await assertHasAssistAt('is String', '''
main(p) {
  !(p is! String);
}
''');
  }

  Future<void> test_is_noEnclosingParenthesis() async {
    await resolveTestCode('''
main(p) {
  p is String;
}
''');
    await assertNoAssistAt('is String');
  }

  Future<void> test_is_noPrefix() async {
    await resolveTestCode('''
main(p) {
  (p is String);
}
''');
    await assertNoAssistAt('is String');
  }

  Future<void> test_is_not_higherPrecedencePrefix() async {
    await resolveTestCode('''
main(p) {
  !!(p is String);
}
''');
    await assertHasAssistAt('!(p', '''
main(p) {
  !(p is! String);
}
''');
  }

  Future<void> test_is_notIsExpression() async {
    await resolveTestCode('''
main(p) {
  123 + 456;
}
''');
    await assertNoAssistAt('123 +');
  }

  Future<void> test_is_notTheNotOperator() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
main(p) {
  ++(p is String);
}
''');
    await assertNoAssistAt('is String');
  }

  Future<void> test_not() async {
    await resolveTestCode('''
main(p) {
  !(p is String);
}
''');
    await assertHasAssistAt('!(p', '''
main(p) {
  p is! String;
}
''');
  }

  Future<void> test_not_alreadyIsNot() async {
    await resolveTestCode('''
main(p) {
  !(p is! String);
}
''');
    await assertNoAssistAt('!(p');
  }

  Future<void> test_not_noEnclosingParenthesis() async {
    await resolveTestCode('''
main(p) {
  !p;
}
''');
    await assertNoAssistAt('!p');
  }

  Future<void> test_not_notIsExpression() async {
    await resolveTestCode('''
main(p) {
  !(p == null);
}
''');
    await assertNoAssistAt('!(p');
  }

  Future<void> test_not_notTheNotOperator() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
main(p) {
  ++(p is String);
}
''');
    await assertNoAssistAt('++(');
  }

  Future<void> test_parentheses() async {
    await resolveTestCode('''
main(p) {
  !(p is String);
}
''');
    await assertHasAssistAt('(p is', '''
main(p) {
  p is! String;
}
''');
  }
}
