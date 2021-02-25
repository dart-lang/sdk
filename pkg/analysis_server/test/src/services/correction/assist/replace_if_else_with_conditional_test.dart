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
  AssistKind get kind => DartAssistKind.REPLACE_IF_ELSE_WITH_CONDITIONAL;

  Future<void> test_assignment() async {
    await resolveTestCode('''
main() {
  int vvv;
  if (true) {
    vvv = 111;
  } else {
    vvv = 222;
  }
}
''');
    await assertHasAssistAt('if (true)', '''
main() {
  int vvv;
  vvv = true ? 111 : 222;
}
''');
  }

  Future<void> test_expressionVsReturn() async {
    await resolveTestCode('''
main() {
  if (true) {
    print(42);
  } else {
    return;
  }
}
''');
    await assertNoAssistAt('else');
  }

  Future<void> test_notIfStatement() async {
    await resolveTestCode('''
main() {
  print(0);
}
''');
    await assertNoAssistAt('print');
  }

  Future<void> test_notSingleStatement() async {
    await resolveTestCode('''
main() {
  int vvv;
  if (true) {
    print(0);
    vvv = 111;
  } else {
    print(0);
    vvv = 222;
  }
}
''');
    await assertNoAssistAt('if (true)');
  }

  Future<void> test_return() async {
    await resolveTestCode('''
main() {
  if (true) {
    return 111;
  } else {
    return 222;
  }
}
''');
    await assertHasAssistAt('if (true)', '''
main() {
  return true ? 111 : 222;
}
''');
  }
}
