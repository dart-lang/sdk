// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseCurlyBracesTest);
  });
}

@reflectiveTest
class UseCurlyBracesTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.useCurlyBraces;

  Future<void> test_comment() async {
    await resolveTestCode('''
void f() {
  ^while (true)
    print(0); // something
}
''');
    await assertHasAssist('''
void f() {
  while (true) {
    print(0); // something
  }
}
''');
  }

  Future<void> test_comment_body1() async {
    await resolveTestCode('''
void f() {
  ^while (true)
    // something
    print(0);
}
''');
    await assertHasAssist('''
void f() {
  while (true) {
    // something
    print(0);
  }
}
''');
  }

  Future<void> test_comment_body2() async {
    await resolveTestCode('''
void f() {
  ^while (true) // something
    print(0);
}
''');
    await assertHasAssist('''
void f() {
  while (true) {
    // something
    print(0);
  }
}
''');
  }

  Future<void> test_comment_outside() async {
    await resolveTestCode('''
void f() {
  ^while (true)
    print(0);
  // something
}
''');
    await assertHasAssist('''
void f() {
  while (true) {
    print(0);
  }
  // something
}
''');
  }

  Future<void> test_do_block() async {
    await resolveTestCode('''
void f() {
  ^do {
    print(0);
  } while (true);
}
''');
    await assertNoAssist();
  }

  Future<void> test_do_body_middle() async {
    await resolveTestCode('''
void f() {
  do print^(0); while (true);
}
''');
    await assertHasAssist('''
void f() {
  do {
    print(0);
  } while (true);
}
''');
  }

  Future<void> test_do_body_start() async {
    await resolveTestCode('''
void f() {
  do ^print(0); while (true);
}
''');
    await assertHasAssist('''
void f() {
  do {
    print(0);
  } while (true);
}
''');
  }

  Future<void> test_do_comment() async {
    await resolveTestCode('''
void f() {
  ^do print(0); // something
    while (true);
}
''');
    await assertHasAssist('''
void f() {
  do {
    print(0); // something
  } while (true);
}
''');
  }

  Future<void> test_do_condition() async {
    await resolveTestCode('''
void f() {
  do print(0); while (^true);
}
''');
    await assertHasAssist('''
void f() {
  do {
    print(0);
  } while (true);
}
''');
  }

  Future<void> test_do_end() async {
    await resolveTestCode('''
void f() {
  do print(0); while (true);^
}
''');
    await assertHasAssist('''
void f() {
  do {
    print(0);
  } while (true);
}
''');
  }

  Future<void> test_do_keyword_do() async {
    await resolveTestCode('''
void f() {
  ^do print(0); while (true);
}
''');
    await assertHasAssist('''
void f() {
  do {
    print(0);
  } while (true);
}
''');
  }

  Future<void> test_do_keyword_while() async {
    await resolveTestCode('''
void f() {
  do print(0); ^while (true);
}
''');
    await assertHasAssist('''
void f() {
  do {
    print(0);
  } while (true);
}
''');
  }

  Future<void> test_for_body_end() async {
    await resolveTestCode('''
void f() {
  for (;;) print(0);^
}
''');
    await assertHasAssist('''
void f() {
  for (;;) {
    print(0);
  }
}
''');
  }

  Future<void> test_for_body_middle() async {
    await resolveTestCode('''
void f() {
  for (;;) print^(0);
}
''');
    await assertHasAssist('''
void f() {
  for (;;) {
    print(0);
  }
}
''');
  }

  Future<void> test_for_body_start() async {
    await resolveTestCode('''
void f() {
  for (;;) ^print(0);
}
''');
    await assertHasAssist('''
void f() {
  for (;;) {
    print(0);
  }
}
''');
  }

  Future<void> test_for_condition() async {
    await resolveTestCode('''
void f() {
  for (^;;) print(0);
}
''');
    await assertHasAssist('''
void f() {
  for (;;) {
    print(0);
  }
}
''');
  }

  Future<void> test_for_keyword() async {
    await resolveTestCode('''
void f() {
  ^for (;;) print(0);
}
''');
    await assertHasAssist('''
void f() {
  for (;;) {
    print(0);
  }
}
''');
  }

  Future<void> test_for_keyword_block() async {
    await resolveTestCode('''
void f() {
  ^for (;;) {
    print(0);
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_if_else_if() async {
    await resolveTestCode('''
void f(int a) {
  if (a == 0) {
    print(0);
  } ^else if (a == 1) {
    print(1);
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_if_else_ifKeyword() async {
    await resolveTestCode('''
void f(int a) {
  if (a == 0) {
    print(0);
  } else ^if (a == 1) {
    print(1);
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_if_else_keyword() async {
    await resolveTestCode('''
void f(int a) {
  if (a == 0)
    print(0);
  ^else print(1);
}
''');
    await assertHasAssist('''
void f(int a) {
  if (a == 0)
    print(0);
  else {
    print(1);
  }
}
''');
  }

  Future<void> test_if_else_statement() async {
    await resolveTestCode('''
void f(int a) {
  if (a == 0)
    print(0);
  else ^print(1);
}
''');
    await assertHasAssist('''
void f(int a) {
  if (a == 0)
    print(0);
  else {
    print(1);
  }
}
''');
  }

  Future<void> test_if_keyword_blockBoth() async {
    await resolveTestCode('''
void f(int a) {
  ^if (a == 0) {
    print(0);
  } else {
    print(1);
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_if_keyword_blockElse() async {
    await resolveTestCode('''
void f(int a) {
  ^if (a == 0) print(0);
  else {
    print(1);
  }
}
''');
    await assertHasAssist('''
void f(int a) {
  if (a == 0) {
    print(0);
  } else {
    print(1);
  }
}
''');
  }

  Future<void> test_if_keyword_blockThen() async {
    await resolveTestCode('''
void f(int a) {
  ^if (a == 0) {
    print(0);
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_if_keyword_withElse() async {
    await resolveTestCode('''
void f(int a) {
  ^if (a == 0)
    print(0);
  else print(1);
}
''');
    await assertHasAssist('''
void f(int a) {
  if (a == 0) {
    print(0);
  } else {
    print(1);
  }
}
''');
  }

  Future<void> test_if_keyword_withElse_comment() async {
    await resolveTestCode('''
void f(int a) {
  ^if (a == 0)
    print(0); // something
  else print(1);
}
''');
    await assertHasAssist('''
void f(int a) {
  if (a == 0) {
    print(0); // something
  } else {
    print(1);
  }
}
''');
  }

  Future<void> test_if_keyword_withElseIf() async {
    await resolveTestCode('''
void f(int a) {
  ^if (a == 0) {
    print(0);
  } else if (a == 1) {
    print(1);
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_if_keyword_withoutElse() async {
    await resolveTestCode('''
void f(int a) {
  ^if (a == 0)
    print(0);
}
''');
    await assertHasAssist('''
void f(int a) {
  if (a == 0) {
    print(0);
  }
}
''');
  }

  Future<void> test_if_then_withElse() async {
    await resolveTestCode('''
void f(int a) {
  if (a == 0)
    ^print(0);
  else print(1);
}
''');
    await assertHasAssist('''
void f(int a) {
  if (a == 0) {
    print(0);
  } else print(1);
}
''');
  }

  Future<void> test_if_then_withoutElse() async {
    await resolveTestCode('''
void f(int a) {
  if (a == 0) ^print(0);
}
''');
    await assertHasAssist('''
void f(int a) {
  if (a == 0) {
    print(0);
  }
}
''');
  }

  Future<void> test_noAssistWithLint() async {
    createAnalysisOptionsFile(
      lints: [LintNames.curly_braces_in_flow_control_structures],
    );
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f() {
  do print^(0); while (true);
}
''');
    await assertNoAssist();
  }

  Future<void> test_while_body_end() async {
    await resolveTestCode('''
void f() {
  while (true) print(0);^
}
''');
    await assertHasAssist('''
void f() {
  while (true) {
    print(0);
  }
}
''');
  }

  Future<void> test_while_body_middle() async {
    await resolveTestCode('''
void f() {
  while (true) print^(0);
}
''');
    await assertHasAssist('''
void f() {
  while (true) {
    print(0);
  }
}
''');
  }

  Future<void> test_while_body_start() async {
    await resolveTestCode('''
void f() {
  while (true) ^print(0);
}
''');
    await assertHasAssist('''
void f() {
  while (true) {
    print(0);
  }
}
''');
  }

  Future<void> test_while_condition() async {
    await resolveTestCode('''
void f() {
  while (^true) print(0);
}
''');
    await assertHasAssist('''
void f() {
  while (true) {
    print(0);
  }
}
''');
  }

  Future<void> test_while_keyword() async {
    await resolveTestCode('''
void f() {
  ^while (true) print(0);
}
''');
    await assertHasAssist('''
void f() {
  while (true) {
    print(0);
  }
}
''');
  }

  Future<void> test_while_keyword_block() async {
    await resolveTestCode('''
void f() {
  ^while (true) {
    print(0);
  }
}
''');
    await assertNoAssist();
  }
}
