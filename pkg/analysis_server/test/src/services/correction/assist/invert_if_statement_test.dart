// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvertIfStatementTest);
  });
}

@reflectiveTest
class InvertIfStatementTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.invertIfStatement;

  Future<void> test_ifCase() async {
    await resolveTestCode('''
void f(Object? x) {
  ^if (x case int()) {
    0;
  } else {
    1;
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_thenBlock_elseBlock() async {
    await resolveTestCode('''
void f() {
  ^if (true) {
    0;
  } else {
    1;
  }
}
''');
    await assertHasAssist('''
void f() {
  if (false) {
    1;
  } else {
    0;
  }
}
''');
  }

  Future<void> test_thenBlock_elseIf() async {
    await resolveTestCode('''
void f(bool c1, bool c2) {
  ^if (c1) {
    0;
  } else if (c2) {
    1;
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_thenBlock_elseStatement() async {
    await resolveTestCode('''
void f() {
  i^f (true) {
    0;
  } else
    1;
}
''');
    await assertNoAssist();
  }

  Future<void> test_thenStatement_elseBlock() async {
    await resolveTestCode('''
void f() {
  i^f (true)
    0;
  else {
    1;
  }
}
''');
    await assertNoAssist();
  }
}
