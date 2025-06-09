// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceIfElseWithConditionalTest);
  });
}

@reflectiveTest
class ReplaceIfElseWithConditionalTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.replaceIfElseWithConditional;

  Future<void> test_assignment() async {
    await resolveTestCode('''
void f() {
  int vvv;
  i^f (true) {
    vvv = 111;
  } else {
    vvv = 222;
  }
}
''');
    await assertHasAssist('''
void f() {
  int vvv;
  vvv = true ? 111 : 222;
}
''');
  }

  Future<void> test_expressionVsReturn() async {
    await resolveTestCode('''
void f() {
  if (true) {
    print(42);
  } el^se {
    return;
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_ifCasePattern() async {
    await resolveTestCode('''
f() {
  var json = [1, 2, 3];
  int vvv;
  i^f (json case [3, 4]) {
    vvv = 111;
  } else {
    vvv = 222;
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_notIfStatement() async {
    await resolveTestCode('''
void f() {
  p^rint(0);
}
''');
    await assertNoAssist();
  }

  Future<void> test_notSingleStatement() async {
    await resolveTestCode('''
void f() {
  int vvv;
  i^f (true) {
    print(0);
    vvv = 111;
  } else {
    print(0);
    vvv = 222;
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_return_expression_expression() async {
    await resolveTestCode('''
int f() {
  i^f (true) {
    return 111;
  } else {
    return 222;
  }
}
''');
    await assertHasAssist('''
int f() {
  return true ? 111 : 222;
}
''');
  }

  Future<void> test_return_expression_nothing() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f(bool c) {
  i^f (c) {
    return 111;
  } else {
    return;
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_return_nothing_expression() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f(bool c) {
  ^if (c) {
    return;
  } else {
    return 222;
  }
}
''');
    await assertNoAssist();
  }
}
