// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidFieldInitializersInConstClassesTest);
  });
}

@reflectiveTest
class AvoidFieldInitializersInConstClassesTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_field_initializers_in_const_classes';

  test_constClass_constructorInitializer() async {
    await assertDiagnostics(r'''
class C {
  final a;
  const C() : a = const [];
}
''', [
      lint(35, 12),
    ]);
  }

  test_constClass_constructorInitializer_explicitThis() async {
    await assertDiagnostics(r'''
class C {
  final a;
  const C(int a) : this.a = 0;
}
''', [
      lint(40, 10),
    ]);
  }

  test_constClass_constructorInitializer_usingParameter() async {
    await assertNoDiagnostics(r'''
class C {
  final a;
  const C(b) : a = b;
}
''');
  }

  test_constClass_fieldFormalParameter() async {
    await assertNoDiagnostics(r'''
class C {
  final a;
  const C(this.a);
}
''');
  }

  test_constClass_fieldInitiailizer() async {
    await assertDiagnostics(r'''
class C {
  final a = const [];
  const C();
}
''', [
      lint(18, 12),
    ]);
  }

  test_constClass_multipleConstructors() async {
    await assertNoDiagnostics(r'''
class C {
  final a;
  const C.c1() : a = const [];
  const C.c2() : a = const {};
}
''');
  }

  test_mixin() async {
    await assertNoDiagnostics(r'''
mixin M {
  final a = const [];
}
''');
  }
}
