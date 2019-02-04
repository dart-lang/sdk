// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceConditionalWithIfElseTest);
  });
}

@reflectiveTest
class ReplaceConditionalWithIfElseTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.REPLACE_CONDITIONAL_WITH_IF_ELSE;

  test_assignment() async {
    await resolveTestUnit('''
main() {
  var v;
  v = true ? 111 : 222;
}
''');
    // on conditional
    await assertHasAssistAt('11 :', '''
main() {
  var v;
  if (true) {
    v = 111;
  } else {
    v = 222;
  }
}
''');
    // on variable
    await assertHasAssistAt('v =', '''
main() {
  var v;
  if (true) {
    v = 111;
  } else {
    v = 222;
  }
}
''');
  }

  test_noEnclosingStatement() async {
    await resolveTestUnit('''
var v = true ? 111 : 222;
''');
    await assertNoAssistAt('? 111');
  }

  test_notConditional() async {
    await resolveTestUnit('''
main() {
  var v = 42;
}
''');
    await assertNoAssistAt('v = 42');
  }

  test_return() async {
    await resolveTestUnit('''
main() {
  return true ? 111 : 222;
}
''');
    await assertHasAssistAt('return ', '''
main() {
  if (true) {
    return 111;
  } else {
    return 222;
  }
}
''');
  }

  test_variableDeclaration() async {
    await resolveTestUnit('''
main() {
  int a = 1, vvv = true ? 111 : 222, b = 2;
}
''');
    await assertHasAssistAt('11 :', '''
main() {
  int a = 1, vvv, b = 2;
  if (true) {
    vvv = 111;
  } else {
    vvv = 222;
  }
}
''');
  }
}
