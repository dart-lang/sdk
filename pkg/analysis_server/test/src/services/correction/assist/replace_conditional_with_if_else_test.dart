// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceConditionalWithIfElseTest);
  });
}

@reflectiveTest
class ReplaceConditionalWithIfElseTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.REPLACE_CONDITIONAL_WITH_IF_ELSE;

  Future<void> test_assignment() async {
    await resolveTestCode('''
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

  Future<void> test_noEnclosingStatement() async {
    await resolveTestCode('''
var v = true ? 111 : 222;
''');
    await assertNoAssistAt('? 111');
  }

  Future<void> test_notConditional() async {
    await resolveTestCode('''
main() {
  var v = 42;
}
''');
    await assertNoAssistAt('v = 42');
  }

  Future<void> test_return() async {
    await resolveTestCode('''
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

  Future<void> test_variableDeclaration() async {
    await resolveTestCode('''
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
