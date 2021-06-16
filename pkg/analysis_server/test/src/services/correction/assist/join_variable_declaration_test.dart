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
  AssistKind get kind => DartAssistKind.JOIN_VARIABLE_DECLARATION;

  Future<void> test_onAssignment() async {
    await resolveTestCode('''
main() {
  var v;
  v = 1;
}
''');
    await assertHasAssistAt('v =', '''
main() {
  var v = 1;
}
''');
  }

  Future<void> test_onAssignment_hasInitializer() async {
    await resolveTestCode('''
main() {
  var v = 1;
  v = 2;
}
''');
    await assertNoAssistAt('v = 2');
  }

  Future<void> test_onAssignment_notAdjacent() async {
    await resolveTestCode('''
main() {
  var v;
  var bar;
  v = 1;
}
''');
    await assertNoAssistAt('v = 1');
  }

  Future<void> test_onAssignment_notAssignment() async {
    await resolveTestCode('''
main() {
  var v;
  v += 1;
}
''');
    await assertNoAssistAt('v += 1');
  }

  Future<void> test_onAssignment_notDeclaration() async {
    await resolveTestCode('''
main(var v) {
  v = 1;
}
''');
    await assertNoAssistAt('v = 1');
  }

  Future<void> test_onAssignment_notLeftArgument() async {
    await resolveTestCode('''
main() {
  var v;
  1 + v; // marker
}
''');
    await assertNoAssistAt('v; // marker');
  }

  Future<void> test_onAssignment_notOneVariable() async {
    await resolveTestCode('''
main() {
  var v, v2;
  v = 1;
}
''');
    await assertNoAssistAt('v = 1');
  }

  Future<void> test_onAssignment_notResolved() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
main() {
  var v;
  x = 1;
}
''');
    await assertNoAssistAt('x = 1');
  }

  Future<void> test_onAssignment_notSameBlock() async {
    await resolveTestCode('''
main() {
  var v;
  {
    v = 1;
  }
}
''');
    await assertNoAssistAt('v = 1');
  }

  Future<void> test_onDeclaration_hasInitializer() async {
    await resolveTestCode('''
main() {
  var v = 1;
  v = 2;
}
''');
    await assertNoAssistAt('v = 1');
  }

  Future<void> test_onDeclaration_lastStatement() async {
    await resolveTestCode('''
main() {
  if (true)
    var v;
}
''');
    await assertNoAssistAt('v;');
  }

  Future<void> test_onDeclaration_nextNotAssignmentExpression() async {
    await resolveTestCode('''
main() {
  var v;
  42;
}
''');
    await assertNoAssistAt('v;');
  }

  Future<void> test_onDeclaration_nextNotExpressionStatement() async {
    await resolveTestCode('''
main() {
  var v;
  if (true) return;
}
''');
    await assertNoAssistAt('v;');
  }

  Future<void> test_onDeclaration_nextNotPureAssignment() async {
    await resolveTestCode('''
main() {
  var v;
  v += 1;
}
''');
    await assertNoAssistAt('v;');
  }

  Future<void> test_onDeclaration_notOneVariable() async {
    await resolveTestCode('''
main() {
  var v, v2;
  v = 1;
}
''');
    await assertNoAssistAt('v, ');
  }

  Future<void> test_onDeclaration_onName() async {
    await resolveTestCode('''
main() {
  var v;
  v = 1;
}
''');
    await assertHasAssistAt('v;', '''
main() {
  var v = 1;
}
''');
  }

  Future<void> test_onDeclaration_onType() async {
    await resolveTestCode('''
main() {
  int v;
  v = 1;
}
''');
    await assertHasAssistAt('int v', '''
main() {
  int v = 1;
}
''');
  }

  Future<void> test_onDeclaration_onVar() async {
    await resolveTestCode('''
main() {
  var v;
  v = 1;
}
''');
    await assertHasAssistAt('var v', '''
main() {
  var v = 1;
}
''');
  }
}
