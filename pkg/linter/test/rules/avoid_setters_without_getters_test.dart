// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidSettersWithoutGettersTest);
  });
}

@reflectiveTest
class AvoidSettersWithoutGettersTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.avoid_setters_without_getters;

  test_class_getter_noSetter() async {
    await assertNoDiagnostics(r'''
class A {
  int get x => 0;
}
''');
  }

  test_class_inheritedSetter_noGetter() async {
    await assertNoDiagnostics(r'''
class A {
  // ignore: avoid_setters_without_getters
  set x(int value) {}
}
class B extends A {
  @override
  set x(int value) {}
}
''');
  }

  test_class_setter_andGetter() async {
    await assertNoDiagnostics(r'''
class A {
  int get x => 0;

  set x(int value) {}
}
''');
  }

  test_class_setter_inheritedGetter() async {
    await assertNoDiagnostics(r'''
class A {
  int get x => 0;
}
class B extends A {
  set x(int value) {}
}
''');
  }

  test_class_setter_noGetter() async {
    await assertDiagnostics(r'''
class A {
  set x(int value) {}
}
''', [
      lint(16, 1),
    ]);
  }

  test_class_static_getter_setter() async {
    await assertNoDiagnostics(r'''
class A {
  static int get x => 0;
  static set x(int value) {}
}
''');
  }

  test_enum() async {
    await assertDiagnostics(r'''
enum A {
  a,b,c;
  set x(int x) {}
}
''', [
      lint(24, 1),
    ]);
  }

  test_extensionType() async {
    await assertDiagnostics(r'''
extension type B(int a) {
  set i(int i) {}
}
''', [
      lint(32, 1),
    ]);
  }
}
