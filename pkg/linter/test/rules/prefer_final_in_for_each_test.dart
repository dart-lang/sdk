// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferFinalInForEachTestLanguage300);
  });
}

@reflectiveTest
class PreferFinalInForEachTestLanguage300 extends LintRuleTest {
  @override
  String get lintRule => 'prefer_final_in_for_each';

  test_int() async {
    await assertDiagnostics(r'''
f() {
  for (var i in [1, 2, 3]) { }
}
''', [
      lint(17, 1),
    ]);
  }

  test_int_final_ok() async {
    await assertNoDiagnostics(r'''
f() {
  for (final i in [1, 2, 3]) { }
}
''');
  }

  test_int_mutated_ok() async {
    await assertNoDiagnostics(r'''
f() {
  for (var i in [1, 2, 3]) {
    i += 1;
  }
}
''');
  }

  test_list() async {
    await assertDiagnostics(r'''
f() {
  for (var [i, j] in [[1, 2]]) { }
}
''', [
      lint(17, 6),
    ]);
  }

  test_list_final() async {
    await assertNoDiagnostics(r'''
f() {
  for (final [i, j] in [[1, 2]]) { }
}
''');
  }

  test_list_mutated() async {
    await assertNoDiagnostics(r'''
f() {
  for (var [i, j] in [[1, 2]]) {
    i += 2;
  }
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/4353
  test_listLiteral_forEach() async {
    await assertDiagnostics(r'''
List<int> f() => [
      for (var i in [1, 2]) i + 3
    ];
''', [
      lint(34, 1),
    ]);
  }

  test_listLiteral_forEach_mutated() async {
    await assertNoDiagnostics(r'''
List<int> f() => [
      for (var i in [1, 2]) i += 3
    ];
''');
  }

  test_map() async {
    await assertDiagnostics(r'''
f() {
  for (var {'i' : j} in [{'i' : 1}]) { }
}
''', [
      lint(17, 9),
    ]);
  }

  test_map_final() async {
    await assertNoDiagnostics(r'''
f() {
  for (final {'i' : j} in [{'i' : 1}]) { }
}
''');
  }

  test_map_mutated() async {
    await assertNoDiagnostics(r'''
f() {
  for (var {'i' : j} in [{'i' : 1}]) {
    j += 2;
  }
}
''');
  }

  test_object() async {
    await assertDiagnostics(r'''
class A {
  int a;
  A(this.a);
}

f() {
  for (var A(:a) in [A(1)]) { }
}
''', [
      lint(52, 5),
    ]);
  }

  test_object_final() async {
    await assertNoDiagnostics(r'''
class A {
  int a;
  A(this.a);
}

f() {
  for (final A(:a) in [A(1)]) { }
}
''');
  }

  test_object_mutated() async {
    await assertNoDiagnostics(r'''
class A {
  int a;
  A(this.a);
}

f() {
  for (var A(:a) in [A(1)]) {
    a += 2;
  }
}
''');
  }

  test_outOfLoopDeclaration_ok() async {
    await assertNoDiagnostics(r'''
f() {
  int j;
  for (j in [1, 2, 3]) { }
}
''');
  }

  test_record() async {
    await assertDiagnostics(r'''
f() {
  for (var (i, j) in [(1, 2)]) { }
}
''', [
      lint(17, 6),
    ]);
  }

  test_record_final() async {
    await assertNoDiagnostics(r'''
f() {
  for (final (i, j) in [(1, 2)]) { }
}
''');
  }

  test_record_mutated() async {
    await assertNoDiagnostics(r'''
f() {
  for (var (int i, j) in [(1, 2)]) {
    i++;
  }
}
''');
  }
}
