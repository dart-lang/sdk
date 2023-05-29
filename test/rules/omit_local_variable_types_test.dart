// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OmitLocalVariableTypesTest);
  });
}

@reflectiveTest
class OmitLocalVariableTypesTest extends LintRuleTest {
  @override
  String get lintRule => 'omit_local_variable_types';

  /// Types are considered an important part of the pattern so we
  /// intentionally do not lint on declared variable patterns.
  test_listPattern_destructured() async {
    await assertNoDiagnostics(r'''
f() {
  var [int a] = <int>[1];
}
''');
  }

  test_mapPattern_destructured() async {
    await assertNoDiagnostics(r'''
f() {
  var {'a': int a} = <String, int>{'a': 1};
}
''');
  }

  test_objectPattern_destructured() async {
    await assertNoDiagnostics(r'''
class A {
  int a;
  A(this.a);
}
f() {
  final A(a: int _b) = A(1);
}
''');
  }

  test_objectPattern_switch() async {
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

  /// https://github.com/dart-lang/linter/issues/3016
  @failingTest
  test_paramIsType() async {
    await assertDiagnostics(r'''
T bar<T>(T d) => d;

String f() {
  String h = bar('');
  return h;
}
''', [
      lint(42, 26),
    ]);
  }

  test_record_destructured() async {
    await assertNoDiagnostics(r'''
f(Object o) {
  switch (o) {
    case (int x, String s):
  }
}
''');
  }

  test_recordPattern_switch() async {
    await assertNoDiagnostics(r'''
f() {
  switch ((1, 2)) {
    case (int a, final int b):
  }
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/3016
  test_typeNeededForInference() async {
    await assertNoDiagnostics(r'''
T bar<T>(dynamic d) => d;

String f() {
  String h = bar('');
  return h;
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/3016
  test_typeParamProvided() async {
    await assertDiagnostics(r'''
T bar<T>(dynamic d) => d;

String f() {
  String h = bar<String>('');
  return h;
}
''', [
      lint(42, 26),
    ]);
  }
}
