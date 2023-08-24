// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SortConstructorsFirstTest);
  });
}

@reflectiveTest
class SortConstructorsFirstTest extends LintRuleTest {
  @override
  String get lintRule => 'sort_constructors_first';

  test_constructorBeforeMethod() async {
    await assertNoDiagnostics(r'''
abstract class A {
  const A();
  void f();
}
''');
  }

  test_fieldBeforeConstructor() async {
    await assertDiagnostics(r'''
abstract class A {
  final a = 0;
  A();
}
''', [
      lint(36, 1),
    ]);
  }

  test_methodBeforeConstructor() async {
    await assertDiagnostics(r'''
abstract class A {
  void f();
  const A();
}
''', [
      lint(39, 1),
    ]);
  }

  test_methodBeforeConstructor_extensionType() async {
    // Since the check logic is shared w/ classes and enums, one test should
    // provide sufficient coverage for extension types.
    await assertDiagnostics(r'''
extension type E(Object o) {
  void f() {}
  E.e(this.o);
}
''', [
      lint(45, 1),
    ]);
  }

  test_methodBeforeConstructors() async {
    await assertDiagnostics(r'''
abstract class A {
  void f();
  A();
  A.named();
}
''', [
      lint(33, 1),
      lint(40, 1),
    ]);
  }

  test_ok() async {
    await assertNoDiagnostics(r'''
enum A {
  a,b,c;
  const A();
  int f() => 0;
}
''');
  }

  test_staticFieldBeforeConstructor() async {
    await assertDiagnostics(r'''
abstract class A {
  static final a = 0;
  A();
}
''', [
      lint(43, 1),
    ]);
  }

  test_unsorted() async {
    await assertDiagnostics(r'''
enum A {
  a,b,c;
  int f() => 0;
  const A();
}
''', [
      lint(42, 1),
    ]);
  }
}
