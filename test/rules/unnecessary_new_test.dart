// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNewTest);
  });
}

@reflectiveTest
class UnnecessaryNewTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_new';

  test_named_new() async {
    await assertDiagnostics(r'''
class A {
  A.named();
}

void f() {
  new A.named();
}
''', [
      lint(39, 13),
    ]);
  }

  test_named_noNew() async {
    await assertNoDiagnostics(r'''
class A {
  A.named();
}

void f() {
  A.named();
}
''');
  }

  test_unnamed_const() async {
    await assertNoDiagnostics(r'''
class A {
  const A();
}

void f() {
  const A();
}
''');
  }

  test_unnamed_new() async {
    await assertDiagnostics(r'''
class A {
  const A();
}

void f() {
  new A();
}
''', [
      lint(39, 7),
    ]);
  }

  test_unnamed_newName_const() async {
    await assertNoDiagnostics(r'''
class A {
  const A();
}

void f() {
  const A.new();
}
''');
  }

  test_unnamed_newName_new() async {
    await assertDiagnostics(r'''
class A {
  const A();
}

void f() {
  new A.new();
}
''', [
      lint(39, 11),
    ]);
  }

  test_unnamed_noNew() async {
    await assertNoDiagnostics(r'''
class A {
  const A();
}

void f() {
  A();
}
''');
  }
}
