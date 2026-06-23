// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AlwaysPutControlBodyOnNewLineTest);
  });
}

@reflectiveTest
class AlwaysPutControlBodyOnNewLineTest extends LintRuleTest {
  @override
  List<DiagnosticCode> get ignoredDiagnosticCodes => [
    diag.deadCode,
    diag.unusedLocalVariable,
  ];

  @override
  String get lintRule => LintNames.always_put_control_body_on_new_line;

  test_doWhile_bodyAdjacent() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  do [!print!]('');
  while (true);
}
''');
  }

  test_doWhile_bodyOnNewline() async {
    await assertNoDiagnostics(r'''
void f() {
  do
    print('');
  while (true);
}
''');
  }

  test_forEachLoop_blockBody_empty() async {
    await assertNoDiagnostics(r'''
void f() {
  for (var i in []) {}
}
''');
  }

  test_forEachLoop_bodyAdjacent() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  for (var i in []) [!return!];
}
''');
  }

  test_forEachLoop_bodyOnNewline() async {
    await assertNoDiagnostics(r'''
void f() {
  for (var i in [])
    return;
}
''');
  }

  test_forLoop_blockBody_empty() async {
    await assertNoDiagnostics(r'''
void f() {
  for (;;) {}
}
''');
  }

  test_forLoop_bodyAdjacent() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  for (;;) [!return!];
}
''');
  }

  test_forLoop_bodyOnNewline() async {
    await assertNoDiagnostics(r'''
void f() {
  for (;;)
    return;
}
''');
  }

  test_ifStatement_blockElse_empty() async {
    await assertNoDiagnostics(r'''
void f() {
  if (false) {
    return;
  }
  else {}
}
''');
  }

  test_ifStatement_blockElseIfThen_empty() async {
    await assertNoDiagnostics(r'''
void f() {
  if (false)
    return;
  else if (false) {}
  else
    return;
}
''');
  }

  test_ifStatement_blockThen_empty() async {
    await assertNoDiagnostics(r'''
void f() {
  if (false) {}
}
''');
  }

  test_ifStatement_elseAdjacent() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  if (false)
    return;
  else [!return!];
}
''');
  }

  test_ifStatement_elseOnNewline() async {
    await assertNoDiagnostics(r'''
void f() {
  if (false) {
    return;
  }
  else
    return;
}
''');
  }

  test_ifStatement_thenAdjacent() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  if (false) [!return!];
}
''');
  }

  test_ifStatement_thenAdjacent_multiline() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  if (false) [!print!](
    'text'
    'text');
}
''');
  }

  test_ifStatement_thenIsBlock_adjacentStatement() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  if (false) [!{!] print('');
  }
}
''');
  }

  test_ifStatement_thenIsEmpty() async {
    await assertNoDiagnostics(r'''
void f() {
  if (false) {}
}
''');
  }

  test_ifStatement_thenOnNewline() async {
    await assertNoDiagnostics(r'''
void f() {
  if (false)
    return;
}
''');
  }

  test_whileLoop_blockBody_empty() async {
    await assertNoDiagnostics(r'''
void f() {
  while (true) {}
}
''');
  }

  test_whileLoop_bodyAdjacent() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  while (true) [!return!];
}
''');
  }

  test_whileLoop_bodyOnNewline() async {
    await assertNoDiagnostics(r'''
void f() {
  while (true)
    return;
}
''');
  }
}
