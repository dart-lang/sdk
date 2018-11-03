// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceIfElseWithConditionalTest);
  });
}

@reflectiveTest
class ReplaceIfElseWithConditionalTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.REPLACE_IF_ELSE_WITH_CONDITIONAL;

  test_assignment() async {
    await resolveTestUnit('''
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

  test_expressionVsReturn() async {
    await resolveTestUnit('''
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

  test_notIfStatement() async {
    await resolveTestUnit('''
main() {
  print(0);
}
''');
    await assertNoAssistAt('print');
  }

  test_notSingleStatement() async {
    await resolveTestUnit('''
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

  test_return() async {
    await resolveTestUnit('''
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
