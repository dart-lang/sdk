// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(JoinVariableDeclarationTest);
  });
}

@reflectiveTest
class JoinVariableDeclarationTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.joinVariableDeclaration;

  Future<void> test_onAssignment() async {
    await resolveTestCode('''
void f() {
  var v;
  ^v = 1;
}
''');
    await assertHasAssist('''
void f() {
  var v = 1;
}
''');
  }

  Future<void> test_onAssignment_hasInitializer() async {
    await resolveTestCode('''
void f() {
  var v = 1;
  ^v = 2;
}
''');
    await assertNoAssist();
  }

  Future<void> test_onAssignment_notAdjacent() async {
    await resolveTestCode('''
void f() {
  var v;
  var bar;
  ^v = 1;
}
''');
    await assertNoAssist();
  }

  Future<void> test_onAssignment_notAssignment() async {
    await resolveTestCode('''
void f() {
  var v;
  ^v += 1;
}
''');
    await assertNoAssist();
  }

  Future<void> test_onAssignment_notDeclaration() async {
    await resolveTestCode('''
void f(var v) {
  ^v = 1;
}
''');
    await assertNoAssist();
  }

  Future<void> test_onAssignment_notLeftArgument() async {
    await resolveTestCode('''
void f() {
  var v;
  1 + ^v;
}
''');
    await assertNoAssist();
  }

  Future<void> test_onAssignment_notOneVariable() async {
    await resolveTestCode('''
void f() {
  var v, v2;
  ^v = 1;
}
''');
    await assertNoAssist();
  }

  Future<void> test_onAssignment_notResolved() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f() {
  var v;
  ^x = 1;
}
''');
    await assertNoAssist();
  }

  Future<void> test_onAssignment_notSameBlock() async {
    await resolveTestCode('''
void f() {
  var v;
  {
    ^v = 1;
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_onDeclaration_hasInitializer() async {
    await resolveTestCode('''
void f() {
  var ^v = 1;
  v = 2;
}
''');
    await assertNoAssist();
  }

  Future<void> test_onDeclaration_lastStatement() async {
    await resolveTestCode('''
void f() {
  if (true)
    var ^v;
}
''');
    await assertNoAssist();
  }

  Future<void> test_onDeclaration_nextNotAssignmentExpression() async {
    await resolveTestCode('''
void f() {
  var ^v;
  42;
}
''');
    await assertNoAssist();
  }

  Future<void> test_onDeclaration_nextNotExpressionStatement() async {
    await resolveTestCode('''
void f() {
  var ^v;
  if (true) return;
}
''');
    await assertNoAssist();
  }

  Future<void> test_onDeclaration_nextNotPureAssignment() async {
    await resolveTestCode('''
void f() {
  var ^v;
  v += 1;
}
''');
    await assertNoAssist();
  }

  Future<void> test_onDeclaration_notOneVariable() async {
    await resolveTestCode('''
void f() {
  var ^v, v2;
  v = 1;
}
''');
    await assertNoAssist();
  }

  Future<void> test_onDeclaration_onName() async {
    await resolveTestCode('''
void f() {
  var ^v;
  v = 1;
}
''');
    await assertHasAssist('''
void f() {
  var v = 1;
}
''');
  }

  Future<void> test_onDeclaration_onType() async {
    await resolveTestCode('''
void f() {
  ^int v;
  v = 1;
}
''');
    await assertHasAssist('''
void f() {
  int v = 1;
}
''');
  }

  Future<void> test_onDeclaration_onVar() async {
    await resolveTestCode('''
void f() {
  ^var v;
  v = 1;
}
''');
    await assertHasAssist('''
void f() {
  var v = 1;
}
''');
  }
}
