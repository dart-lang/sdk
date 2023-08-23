// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

// ignore_for_file: file_names

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferIterableWhereTypeTest);
  });
}

@reflectiveTest
class PreferIterableWhereTypeTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_iterable_whereType';

  test_closureWithIs() async {
    await assertDiagnostics(r'''
var x = [42].where((e) => e is String);
''', [
      lint(13, 5),
    ]);
  }

  test_closureWithIs_blockBodySingleStatement() async {
    await assertDiagnostics(r'''
var x = [42].where(
  (e) {
    return e is String;
});
''', [
      lint(13, 5),
    ]);
  }

  test_closureWithIs_multipleStatements() async {
    await assertNoDiagnostics(r'''
var x = [42].where((e) {
  print('');
  return e is String;
});
''');
  }

  test_closureWithIs_parenthesized() async {
    await assertDiagnostics(r'''
var x = [42].where((e) => (e is String));
''', [
      lint(13, 5),
    ]);
  }

  test_closureWithIs_wrongSimpleTarget() async {
    await assertNoDiagnostics(r'''
var l = [42];
var x = l.where((e) => l is String);
''');
  }

  test_closureWithIs_wrongTarget() async {
    await assertNoDiagnostics(r'''
var x = [42].where((e) => e.isEven is String);
''');
  }

  test_closureWithIsNot() async {
    await assertNoDiagnostics(r'''
var x = [42, 42.5].where((e) => e is! int);
''');
  }

  test_functionReference() async {
    await assertNoDiagnostics(r'''
bool p(Object e) => false;
var x = [42].where(p);
''');
  }

  test_nonIterable_whereMethod_closure_explicitTarget() async {
    await assertNoDiagnostics(r'''
class A {
  void where(bool Function(Object) g) {}
}

void f(A a) {
  a.where((e) => e is String);
}
''');
  }

  test_nonIterable_whereMethod_closure_implicitTarget() async {
    await assertNoDiagnostics(r'''
class A {
  void where(bool Function(Object) f) {}

  void m(A a) {
    a.where((e) => e is String);
  }
}

''');
  }

  test_nonIterable_whereMethod_explicitTarget() async {
    await assertNoDiagnostics(r'''
class A {
  bool where() => true;
}

void f(A a) {
  a.where();
}
''');
  }

  test_nonIterable_whereMethod_implicitTarget() async {
    await assertNoDiagnostics(r'''
class A {
  bool where() => true;

  void m() {
    where();
  }
}
''');
  }

  test_whereType() async {
    await assertNoDiagnostics(r'''
var x = [42].whereType<String>();
''');
  }
}
