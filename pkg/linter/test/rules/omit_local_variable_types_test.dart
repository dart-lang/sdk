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

  test_field() async {
    await assertNoDiagnostics(r'''
class C {
  int a = 3;
}
''');
  }

  test_forEach() async {
    await assertDiagnostics(r'''
f() {
  for (int i in [1, 2, 3]) { }
}
''', [
      lint(13, 3),
    ]);
  }

  test_forEach_ok() async {
    await assertNoDiagnostics(r'''
f() {
  for (var i in [1, 2, 3]) { }
}
''');
  }

  test_forIn_iterableSubclass() async {
    await assertDiagnostics(r'''
abstract class StringIterator<E> implements Iterable<E> {}

void f(StringIterator<String> items) {
  for (String item in items) {}
}
''', [
      lint(106, 6),
    ]);
  }

  test_forIn_rightSideIsIterableOfDynamic_typedWithString() async {
    await assertNoDiagnostics(r'''
void f(Iterable<dynamic> items) {
  for (String item in items) {}
}
''');
  }

  test_forIn_rightSideIsIterableOfString_typedWithDynamic() async {
    await assertNoDiagnostics(r'''
abstract class StringIterator<E> implements Iterable<E> {}
void f(StringIterator<String> items) {
  for (dynamic item in items) {}
}
''');
  }

  test_forLoop_declarationHasRedundantType() async {
    await assertDiagnostics(r'''
class C {
  late C next;
}
void f(C head) {
  for (C node = head; ; node = node.next) {}
}
''', [
      lint(51, 1),
    ]);
  }

  /// Types are considered an important part of the pattern so we
  /// intentionally do not lint on declared variable patterns.
  test_listPattern_destructured() async {
    await assertNoDiagnostics(r'''
f() {
  var [int a] = <int>[1];
}
''');
  }

  test_local_multiple() async {
    await assertDiagnostics(r'''
f() {
  String a = 'a', b = 'b';
}
''', [
      lint(8, 6),
    ]);
  }

  test_local_multiple_ok() async {
    await assertNoDiagnostics(r'''
f() {
  var a = 'a', b = 'b';
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

  test_multipleLocalVariables_rightSideIsIterable_typedWithRawIterable() async {
    await assertDiagnostics(r'''
void f() {
  Iterable a = new Iterable.empty(), b = new Iterable.empty();
}
''', [
      lint(13, 8),
    ]);
  }

  test_multipleLocalVariables_rightSideIsList_typedWithRawIterable() async {
    await assertNoDiagnostics(r'''
void f() {
  Iterable a = [], b = new Iterable.empty();
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

  test_rightSideIsInt_typedWithDouble() async {
    await assertNoDiagnostics(r'''
void f() {
  double x = 0;
}
''');
  }

  test_rightSideIsInt_typedWithDynamic() async {
    await assertNoDiagnostics(r'''
void f() {
  dynamic x = 0;
}
''');
  }

  test_rightSideIsNull_typedWithNull() async {
    await assertNoDiagnostics(r'''
void f() {
  const Null a = null;
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
      lint(42, 6),
    ]);
  }
}
