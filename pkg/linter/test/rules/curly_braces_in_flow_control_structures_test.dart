// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CurlyBracesInFlowControlStructuresTest);
  });
}

@reflectiveTest
class CurlyBracesInFlowControlStructuresTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.curly_braces_in_flow_control_structures;

  test_doWhile_block_sameLineAsDo() async {
    await assertNoDiagnostics(r'''
void f() {
  do { print(''); }
  while (true);
}
''');
  }

  test_doWhile_singeStatement_sameLineAsDo() async {
    await assertDiagnostics(r'''
void f() {
  do print('');
  while (true);
}
''', [
      lint(16, 10),
    ]);
  }

  test_doWhile_singleStatement_lineAfterDo() async {
    await assertDiagnostics(r'''
void f() {
  do
    print('');
  while (true);
}
''', [
      lint(20, 10),
    ]);
  }

  test_doWhile_singleStatement_sameLineAsDoAndWhile() async {
    await assertDiagnostics(r'''
void f() {
  do print(''); while (true);
}
''', [
      lint(16, 10),
    ]);
  }

  test_forEachLoop_block_sameLine() async {
    await assertNoDiagnostics(r'''
void f(List<int> l) {
  for (var i in l) {}
}
''');
  }

  test_forEachLoop_singleStatement_lineAfter() async {
    await assertDiagnostics(r'''
void f(List<int> l) {
  for (var i in l)
    return;
}
''', [
      lint(45, 7),
    ]);
  }

  test_forEachLoop_singleStatement_sameLine() async {
    await assertDiagnostics(r'''
void f(List<int> l) {
  for (var i in l) return;
}
''', [
      lint(41, 7),
    ]);
  }

  test_forLoop_emptyBlock_sameLine() async {
    await assertNoDiagnostics(r'''
void f() {
  for (;;) {}
}
''');
  }

  test_forLoop_singleStatement_lineAfter() async {
    await assertDiagnostics(r'''
void f() {
  for (;;)
    return;
}
''', [
      lint(26, 7),
    ]);
  }

  test_forLoop_singleStatement_sameLine() async {
    await assertDiagnostics(r'''
void f() {
  for (;;) return;
}
''', [
      lint(22, 7),
    ]);
  }

  test_ifStatement_block_sameLine() async {
    await assertNoDiagnostics(r'''
void f() {
  if (1 == 2) {}
}
''');
  }

  test_ifStatement_block_sameLine_multiLine() async {
    await assertNoDiagnostics(r'''
void f() {
  if (1 == 2) {
  }
}
''');
  }

  test_ifStatement_singleStatement_lineAfter() async {
    await assertDiagnostics(r'''
void f() {
  if (1 == 2)
    return;
}
''', [
      lint(29, 7),
    ]);
  }

  test_ifStatement_singleStatement_multiLine() async {
    await assertDiagnostics(r'''
void f() {
  if (1 == 2) print(
    'First argument'
    'Second argument');
}
''', [
      lint(25, 51),
    ]);
  }

  test_ifStatement_singleStatement_sameLine() async {
    await assertNoDiagnostics(r'''
void f() {
  if (1 == 2) return;
}
''');
  }

  test_ifStatement_singleStatement_sameLine_multiLineCondition() async {
    await assertDiagnostics(r'''
void f() {
  if (1 ==
      2) return;
}
''', [
      lint(31, 7),
    ]);
  }

  test_ifStatementElse_block_sameLine() async {
    await assertNoDiagnostics(r'''
void f() {
  if (1 == 2) {}
  else {}
}
''');
  }

  test_ifStatementElse_singleStatement_lineAfter() async {
    await assertDiagnostics(r'''
void f() {
  if (1 == 2) {}
  else
    return;
}
''', [
      lint(39, 7),
    ]);
  }

  test_ifStatementElse_singleStatement_sameLine() async {
    await assertDiagnostics(r'''
void f() {
  if (1 == 2) {}
  else return;
}
''', [
      lint(35, 7),
    ]);
  }

  test_ifStatementElseIf_block_sameLine_multiLine() async {
    await assertNoDiagnostics(r'''
void f() {
  if (1 == 2) {} else if (2 == 3) {
  }
}
''');
  }

  test_ifStatementElseIf_singleStatement_lineAfter() async {
    await assertDiagnostics(r'''
void f() {
  if (1 == 2) {}
  else if (1 == 2)
    return;
}
''', [
      lint(51, 7),
    ]);
  }

  test_ifStatementElseIf_singleStatement_sameLine_lineAfterIfCondition() async {
    await assertDiagnostics(r'''
void f() {
  if (1 == 2) {
  } else if (1 == 3) return;
}
''', [
      lint(48, 7),
    ]);
  }

  test_whileLoop_block_sameLine() async {
    await assertNoDiagnostics(r'''
void f() {
  while (true) {}
}
''');
  }

  test_whileLoop_singleStatement_nextLine() async {
    await assertDiagnostics(r'''
void f() {
  while (true)
    return;
}
''', [
      lint(30, 7),
    ]);
  }

  test_whileLoop_singleStatement_sameLine() async {
    await assertDiagnostics(r'''
void f() {
  while (true) return;
}
''', [
      lint(26, 7),
    ]);
  }
}
