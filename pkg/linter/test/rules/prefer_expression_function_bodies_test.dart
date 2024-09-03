// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferExpressionFunctionBodiesTest);
  });
}

@reflectiveTest
class PreferExpressionFunctionBodiesTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_expression_function_bodies';

  test_function_multipleStatements() async {
    await assertNoDiagnostics(r'''
int f() {
  int a = 2 + 3;
  return a;
}
''');
  }

  test_function_returnStatement() async {
    await assertDiagnostics(r'''
int f() {
  return 1;
}
''', [
      lint(8, 15),
    ]);
  }

  test_getter_expressionFunctionBody() async {
    await assertNoDiagnostics(r'''
class A {
  int get f => 0;
}
''');
  }

  test_getter_returnStatement() async {
    await assertDiagnostics(r'''
class A {
  get f {
    return 7 - 6;
  }
}
''', [
      lint(18, 23),
    ]);
  }

  test_method_multipleStatements() async {
    await assertNoDiagnostics(r'''
class A {
  int m() {
    if (1 == 2) {
      return 1;
    }
    return 0;
  }
}
''');
  }

  test_method_returnStatement() async {
    await assertDiagnostics(r'''
class A {
  int m() {
    return 1;
  }
}
''', [
      lint(20, 19),
    ]);
  }

  test_setter_expressionFunctionBody() async {
    await assertNoDiagnostics(r'''
class A {
  int x = 0;
  set f(int p) => x = p;
}
''');
  }

  test_setter_noReturn() async {
    await assertNoDiagnostics(r'''
class A {
  int x = 0;
  set f(int p) {
    x = p;
  }
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/4221
  test_voidReturn() async {
    await assertNoDiagnostics(r'''
class C {
  void f() {
    return;
  }
}
''');
  }
}
