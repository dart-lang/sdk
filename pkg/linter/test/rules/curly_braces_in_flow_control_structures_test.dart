// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
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
    await assertDiagnosticsFromMarkup(r'''
void f() {
  do [!print('');!]
  while (true);
}
''');
  }

  test_doWhile_singleStatement_lineAfterDo() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  do
    [!print('');!]
  while (true);
}
''');
  }

  test_doWhile_singleStatement_sameLineAsDoAndWhile() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  do [!print('');!] while (true);
}
''');
  }

  test_forEachLoop_block_sameLine() async {
    await assertNoDiagnostics(r'''
void f(List<int> l) {
  for (var i in l) {}
}
''');
  }

  test_forEachLoop_singleStatement_lineAfter() async {
    await assertDiagnosticsFromMarkup(r'''
void f(List<int> l) {
  for (var i in l)
    [!return;!]
}
''');
  }

  test_forEachLoop_singleStatement_sameLine() async {
    await assertDiagnosticsFromMarkup(r'''
void f(List<int> l) {
  for (var i in l) [!return;!]
}
''');
  }

  test_forLoop_emptyBlock_sameLine() async {
    await assertNoDiagnostics(r'''
void f() {
  for (;;) {}
}
''');
  }

  test_forLoop_singleStatement_lineAfter() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  for (;;)
    [!return;!]
}
''');
  }

  test_forLoop_singleStatement_sameLine() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  for (;;) [!return;!]
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
void f() {
  if (1 == 2)
    [!return;!]
}
''');
  }

  test_ifStatement_singleStatement_multiLine() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  if (1 == 2) [!print(
    'First argument'
    'Second argument');!]
}
''');
  }

  test_ifStatement_singleStatement_sameLine() async {
    await assertNoDiagnostics(r'''
void f() {
  if (1 == 2) return;
}
''');
  }

  test_ifStatement_singleStatement_sameLine_multiLineCondition() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  if (1 ==
      2) [!return;!]
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
void f() {
  if (1 == 2) {}
  else
    [!return;!]
}
''');
  }

  test_ifStatementElse_singleStatement_sameLine() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  if (1 == 2) {}
  else [!return;!]
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
void f() {
  if (1 == 2) {}
  else if (1 == 2)
    [!return;!]
}
''');
  }

  test_ifStatementElseIf_singleStatement_sameLine_lineAfterIfCondition() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  if (1 == 2) {
  } else if (1 == 3) [!return;!]
}
''');
  }

  test_whileLoop_block_sameLine() async {
    await assertNoDiagnostics(r'''
void f() {
  while (true) {}
}
''');
  }

  test_whileLoop_singleStatement_nextLine() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  while (true)
    [!return;!]
}
''');
  }

  test_whileLoop_singleStatement_sameLine() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  while (true) [!return;!]
}
''');
  }
}
