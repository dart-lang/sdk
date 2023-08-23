// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferTypingUninitializedVariablesTest);
  });
}

@reflectiveTest
class PreferTypingUninitializedVariablesTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_typing_uninitialized_variables';

  test_field_final_noInitializer() async {
    await assertDiagnostics(r'''
class C {
  final x;
  C(this.x);
}
''', [
      lint(18, 1),
    ]);
  }

  test_field_typed() async {
    await assertNoDiagnostics(r'''
class C {
  String? x;
}
''');
  }

  test_field_var_noInitializer() async {
    await assertDiagnostics(r'''
class C {
  var x;
}
''', [
      lint(16, 1),
    ]);
  }

  test_field_var_noInitializer_notFirst() async {
    await assertDiagnostics(r'''
class C {
  var a = 5,
      b;
}
''', [
      lint(29, 1),
    ]);
  }

  test_field_var_noInitializer_static() async {
    await assertDiagnostics(r'''
class C {
  static var x;
}
''', [
      lint(23, 1),
    ]);
  }

  test_forEachLoopVariable_final() async {
    await assertNoDiagnostics(r'''
void f() {
  for (final e in <String>[]) {}
}
''');
  }

  test_forLoopVariable_var_noInitializer() async {
    await assertDiagnostics(r'''
void f() {
  for (var i, j = 0; j < 5; i = j, j++) {}
}
''', [
      lint(22, 1),
    ]);
  }

  test_localVariable_var_initializer() async {
    await assertNoDiagnostics(r'''
void f() {
  // ignore: unused_local_variable
  var x = 1;
}
''');
  }

  test_localVariable_var_noInitializer() async {
    await assertDiagnostics(r'''
void f() {
  // ignore: unused_local_variable
  var x;
}
''', [
      lint(52, 1),
    ]);
  }

  test_topLevelVariable_var_initializer() async {
    await assertNoDiagnostics(r'''
var x = 4;
''');
  }

  test_topLevelVariable_var_noInitializer() async {
    await assertDiagnostics(r'''
var x;
''', [
      lint(4, 1),
    ]);
  }
}
