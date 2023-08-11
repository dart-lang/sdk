// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidReturnTypesOnSettersTest);
  });
}

@reflectiveTest
class AvoidReturnTypesOnSettersTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_return_types_on_setters';

  test_implicitReturnType() async {
    await assertNoDiagnostics(r'''
set f(int p) {}
''');
  }

  test_instanceSetter_implicitReturnType() async {
    await assertNoDiagnostics(r'''
class C {
  set f(int p) {}
}
''');
  }

  test_instanceSetter_voidReturnType() async {
    await assertDiagnostics(r'''
class C {
  void set f(int p) {}
}
''', [
      lint(12, 4),
    ]);
  }

  test_staticSetter_implicitReturnType() async {
    await assertNoDiagnostics(r'''
class C {
  static set f(String p) {}
}
''');
  }

  test_staticSetter_voidReturnType() async {
    await assertDiagnostics(r'''
class C {
  static void set f(String p) {}
}
''', [
      lint(19, 4),
    ]);
  }

  test_voidReturnType() async {
    await assertDiagnostics(r'''
void set f(int p) {}
''', [
      lint(0, 4),
    ]);
  }
}
