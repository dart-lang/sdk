// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
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
  AssistKind get kind => DartAssistKind.USE_CURLY_BRACES;

  Future<void> test_do_block() async {
    await resolveTestCode('''
main() {
  /*caret*/do {
    print(0);
  } while (true);
}
''');
    await assertNoAssist();
  }

  Future<void> test_do_body_middle() async {
    await resolveTestCode('''
main() {
  do print/*caret*/(0); while (true);
}
''');
    await assertHasAssist('''
main() {
  do {
    print(0);
  } while (true);
}
''');
  }

  Future<void> test_do_body_start() async {
    await resolveTestCode('''
main() {
  do /*caret*/print(0); while (true);
}
''');
    await assertHasAssist('''
main() {
  do {
    print(0);
  } while (true);
}
''');
  }

  Future<void> test_do_condition() async {
    await resolveTestCode('''
main() {
  do print(0); while (/*caret*/true);
}
''');
    await assertHasAssist('''
main() {
  do {
    print(0);
  } while (true);
}
''');
  }

  Future<void> test_do_end() async {
    await resolveTestCode('''
main() {
  do print(0); while (true);/*caret*/
}
''');
    await assertHasAssist('''
main() {
  do {
    print(0);
  } while (true);
}
''');
  }

  Future<void> test_do_keyword_do() async {
    await resolveTestCode('''
main() {
  /*caret*/do print(0); while (true);
}
''');
    await assertHasAssist('''
main() {
  do {
    print(0);
  } while (true);
}
''');
  }

  Future<void> test_do_keyword_while() async {
    await resolveTestCode('''
main() {
  do print(0); /*caret*/while (true);
}
''');
    await assertHasAssist('''
main() {
  do {
    print(0);
  } while (true);
}
''');
  }

  Future<void> test_for_body_end() async {
    await resolveTestCode('''
main() {
  for (;;) print(0);/*caret*/
}
''');
    await assertHasAssist('''
main() {
  for (;;) {
    print(0);
  }
}
''');
  }

  Future<void> test_for_body_middle() async {
    await resolveTestCode('''
main() {
  for (;;) print/*caret*/(0);
}
''');
    await assertHasAssist('''
main() {
  for (;;) {
    print(0);
  }
}
''');
  }

  Future<void> test_for_body_start() async {
    await resolveTestCode('''
main() {
  for (;;) /*caret*/print(0);
}
''');
    await assertHasAssist('''
main() {
  for (;;) {
    print(0);
  }
}
''');
  }

  Future<void> test_for_condition() async {
    await resolveTestCode('''
main() {
  for (/*caret*/;;) print(0);
}
''');
    await assertHasAssist('''
main() {
  for (;;) {
    print(0);
  }
}
''');
  }

  Future<void> test_for_keyword() async {
    await resolveTestCode('''
main() {
  /*caret*/for (;;) print(0);
}
''');
    await assertHasAssist('''
main() {
  for (;;) {
    print(0);
  }
}
''');
  }

  Future<void> test_for_keyword_block() async {
    await resolveTestCode('''
main() {
  /*caret*/for (;;) {
    print(0);
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_if_else_keyword() async {
    await resolveTestCode('''
main(int a) {
  if (a == 0)
    print(0);
  /*caret*/else print(1);
}
''');
    await assertHasAssist('''
main(int a) {
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
main(int a) {
  if (a == 0)
    print(0);
  else /*caret*/print(1);
}
''');
    await assertHasAssist('''
main(int a) {
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
main(int a) {
  /*caret*/if (a == 0) {
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
main(int a) {
  /*caret*/if (a == 0) print(0);
  else {
    print(1);
  }
}
''');
    await assertHasAssist('''
main(int a) {
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
main(int a) {
  /*caret*/if (a == 0) {
    print(0);
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_if_keyword_withElse() async {
    await resolveTestCode('''
main(int a) {
  /*caret*/if (a == 0)
    print(0);
  else print(1);
}
''');
    await assertHasAssist('''
main(int a) {
  if (a == 0) {
    print(0);
  } else {
    print(1);
  }
}
''');
  }

  Future<void> test_if_keyword_withoutElse() async {
    await resolveTestCode('''
main(int a) {
  /*caret*/if (a == 0)
    print(0);
}
''');
    await assertHasAssist('''
main(int a) {
  if (a == 0) {
    print(0);
  }
}
''');
  }

  Future<void> test_if_then_withElse() async {
    await resolveTestCode('''
main(int a) {
  if (a == 0)
    /*caret*/print(0);
  else print(1);
}
''');
    await assertHasAssist('''
main(int a) {
  if (a == 0) {
    print(0);
  } else print(1);
}
''');
  }

  Future<void> test_if_then_withoutElse() async {
    await resolveTestCode('''
main(int a) {
  if (a == 0) /*caret*/print(0);
}
''');
    await assertHasAssist('''
main(int a) {
  if (a == 0) {
    print(0);
  }
}
''');
  }

  Future<void> test_noAssistWithLint() async {
    createAnalysisOptionsFile(
        lints: [LintNames.curly_braces_in_flow_control_structures]);
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
main() {
  do print/*caret*/(0); while (true);
}
''');
    await assertNoAssist();
  }

  Future<void> test_while_body_end() async {
    await resolveTestCode('''
main() {
  while (true) print(0);/*caret*/
}
''');
    await assertHasAssist('''
main() {
  while (true) {
    print(0);
  }
}
''');
  }

  Future<void> test_while_body_middle() async {
    await resolveTestCode('''
main() {
  while (true) print/*caret*/(0);
}
''');
    await assertHasAssist('''
main() {
  while (true) {
    print(0);
  }
}
''');
  }

  Future<void> test_while_body_start() async {
    await resolveTestCode('''
main() {
  while (true) /*caret*/print(0);
}
''');
    await assertHasAssist('''
main() {
  while (true) {
    print(0);
  }
}
''');
  }

  Future<void> test_while_condition() async {
    await resolveTestCode('''
main() {
  while (/*caret*/true) print(0);
}
''');
    await assertHasAssist('''
main() {
  while (true) {
    print(0);
  }
}
''');
  }

  Future<void> test_while_keyword() async {
    await resolveTestCode('''
main() {
  /*caret*/while (true) print(0);
}
''');
    await assertHasAssist('''
main() {
  while (true) {
    print(0);
  }
}
''');
  }

  Future<void> test_while_keyword_block() async {
    await resolveTestCode('''
main() {
  /*caret*/while (true) {
    print(0);
  }
}
''');
    await assertNoAssist();
  }
}
