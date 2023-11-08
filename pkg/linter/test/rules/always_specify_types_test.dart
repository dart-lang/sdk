// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AlwaysSpecifyTypesTest);
  });
}

@reflectiveTest
class AlwaysSpecifyTypesTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => 'always_specify_types';

  test_extensionType_optionalTypeArgs() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';

@optionalTypeArgs
extension type E<T>(int i) { }

void f() {
  E e = E(1);
}
''');
  }

  test_extensionType_typeArgs() async {
    await assertDiagnostics(r'''
extension type E<T>(int i) { }

void f() {
  E e = E(1);
}
''', [
      lint(45, 1),
      lint(51, 1),
    ]);
  }

  test_listPattern_destructured() async {
    await assertDiagnostics(r'''
f() {
  var [a] = <int>[1];
}
''', [
      lint(13, 1),
    ]);
  }

  test_listPattern_destructured_listLiteral() async {
    await assertDiagnostics(r'''
f() {
  var [int a] = [1];
}
''', [
      lint(22, 1),
    ]);
  }

  test_listPattern_destructured_ok() async {
    await assertNoDiagnostics(r'''
f() {
  var [int a] = <int>[1];
}
''');
  }

  test_mapPattern_destructured() async {
    await assertDiagnostics(r'''
f() {
  var {'a': a} = <String, int>{'a': 1};
}
''', [
      lint(18, 1),
    ]);
  }

  test_mapPattern_destructured_ok() async {
    await assertNoDiagnostics(r'''
f() {
  var {'a': int a} = <String, int>{'a': 1};
}
''');
  }

  test_objectPattern_switch_final() async {
    await assertDiagnostics(r'''
class A {
  int a;
  A(this.a);
}

f() {
  switch (A(1)) {
    case A(a: >0 && final b):
  }
}
''', [
      lint(79, 5),
    ]);
  }

  test_objectPattern_switch_ok() async {
    await assertNoDiagnostics(r'''
class A {
  int a;
  A(this.a);
}

f() {
  switch (A(1)) {
    case A(a: >0 && int b):
  }
}
''');
  }

  test_objectPattern_switch_var() async {
    await assertDiagnostics(r'''
class A {
  int a;
  A(this.a);
}

f() {
  switch (A(1)) {
    case A(a: >0 && var b):
  }
}
''', [
      lint(79, 3),
    ]);
  }

  test_recordPattern_switch() async {
    await assertDiagnostics(r'''
f() {
  switch ((1, 2)) {
    case (final a, var b):
  }
}
''', [
      lint(36, 5),
      lint(45, 3),
    ]);
  }

  test_recordPattern_switch_ok() async {
    await assertNoDiagnostics(r'''
f() {
  switch ((1, 2)) {
    case (int a, int b):
  }
}
''');
  }
}
