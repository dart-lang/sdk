// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ControlFlowInFinallyTest);
    // TODO(srawlins): Add tests with labels.
  });
}

@reflectiveTest
class ControlFlowInFinallyTest extends LintRuleTest {
  @override
  String get lintRule => 'control_flow_in_finally';

  test_break() async {
    await assertDiagnostics(r'''
void f() {
  for (var o in [1, 2]) {
    try {
    } catch (e) {
    } finally {
      if (1 > 0) {
        break;
      }
    }
  }
}
''', [
      lint(108, 6),
    ]);
  }

  test_break_loopDeclaredWithinFinally() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
  } catch (e) {
  } finally {
    for (var o in [1, 2]) {
      if (1 > 0) {
        break;
      }
    }
  }
}
''');
  }

  test_continue() async {
    await assertDiagnostics(r'''
void f() {
  for (var o in [1, 2]) {
    try {
    } catch (e) {
    } finally {
      continue;
    }
  }
}
''', [
      lint(87, 9),
    ]);
  }

  test_continue_deep() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
  } catch (e) {
  } finally {
    for (var o in [1, 2]) {
      if (1 > 0) {
        continue;
      }
    }
  }
}
''');
  }

  test_nonControlFlow() async {
    await assertNoDiagnostics(r'''
void f(int i) {
  try {
  } catch (e) {
  } finally {
    i = i * i;
  }
}
''');
  }

  test_return() async {
    await assertDiagnostics(r'''
void f() {
  try {
  } catch (e) {
  } finally {
    return;
  }
}
''', [
      lint(53, 7),
    ]);
  }

  test_returnInClosure() async {
    await assertNoDiagnostics(r'''
void f() {
  try {
  } catch (e) {
  } finally {
    () {
      return 1.0;
    };
  }
}
''');
  }
}
