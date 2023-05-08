// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToIfCaseStatementChainTest);
  });
}

@reflectiveTest
class ConvertToIfCaseStatementChainTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_TO_IF_CASE_STATEMENT_CHAIN;

  Future<void> test_noDefault() async {
    await resolveTestCode('''
void f(Object? x) {
  switch (x) {
    case int():
      0;
    case double():
      1;
  }
}
''');
    await assertHasAssistAt('switch', '''
void f(Object? x) {
  if (x case int()) {
    0;
  } else if (x case double()) {
    1;
  }
}
''');
  }

  Future<void> test_noDefault_hasWhen() async {
    await resolveTestCode('''
void f(Object? x) {
  switch (x) {
    case int() when x > 0:
      0;
    case double():
      1;
  }
}
''');
    await assertHasAssistAt('switch', '''
void f(Object? x) {
  if (x case int() when x > 0) {
    0;
  } else if (x case double()) {
    1;
  }
}
''');
  }

  Future<void> test_noStatements() async {
    await resolveTestCode('''
void f(Object? x) {
  switch (x) {
    case int():
      0;
    case double():
  }
}
''');
    await assertHasAssistAt('switch', '''
void f(Object? x) {
  if (x case int()) {
    0;
  } else if (x case double()) {
  }
}
''');
  }

  Future<void> test_sharedBody() async {
    await resolveTestCode('''
void f(Object? x) {
  switch (x) {
    case int():
    case double():
      0;
  }
}
''');
    await assertHasAssistAt('switch', '''
void f(Object? x) {
  if (x case int() || double()) {
    0;
  }
}
''');
  }

  Future<void> test_sharedBody_hasWhen() async {
    await resolveTestCode('''
void f(Object? x) {
  switch (x) {
    case int() when x > 0:
    case double():
      0;
  }
}
''');
    await assertNoAssistAt('switch');
  }

  Future<void> test_withDefault() async {
    await resolveTestCode('''
void f(Object? x) {
  switch (x) {
    case int():
      0;
    case double():
      1;
    default:
      2;
  }
}
''');
    await assertHasAssistAt('switch', '''
void f(Object? x) {
  if (x case int()) {
    0;
  } else if (x case double()) {
    1;
  } else {
    2;
  }
}
''');
  }

  Future<void> test_withDefault_shared() async {
    await resolveTestCode('''
void f(Object? x) {
  switch (x) {
    case int():
      0;
    case double():
    default:
      1;
  }
}
''');
    await assertNoAssistAt('switch');
  }
}
