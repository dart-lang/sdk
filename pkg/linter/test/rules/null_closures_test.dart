// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullClosuresTest);
  });
}

@reflectiveTest
class NullClosuresTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.null_closures;

  test_futureWait_cleanUp_closure() async {
    await assertNoDiagnostics(r'''
void f() {
  Future.wait([], cleanUp: (_) => print('clean'));
}
''');
  }

  test_futureWait_cleanUp_null() async {
    await assertDiagnostics(r'''
void f() {
  Future.wait([], cleanUp: null);
}
''', [
      lint(29, 13),
    ]);
  }

  test_iterableFirstWhere_orElse_null() async {
    await assertDiagnostics(r'''
void f(List<int> list) {
  list.firstWhere((e) => e.isEven, orElse: null);
}
''', [
      lint(60, 12),
    ]);
  }

  test_iterableSingleWhere_orElse_closure() async {
    await assertNoDiagnostics(r'''
void f(List<int?> list) {
  list.singleWhere((e) => e?.isEven ?? false, orElse: () => null);
}
''');
  }

  test_iterableSingleWhere_orElse_null() async {
    await assertDiagnostics(r'''
void f(Set<int> set) {
  set.singleWhere((e) => e.isEven, orElse: null);
}
''', [
      lint(58, 12),
    ]);
  }

  test_iterableWhere_noOrElse() async {
    await assertNoDiagnostics(r'''
void f(List<int> list) {
  list.where((e) => e.isEven);
}
''');
  }

  test_listGenerate_closure() async {
    await assertNoDiagnostics(r'''
void f() {
  new List.generate(3, (_) => null);
}
''');
  }

  test_mapKeys() async {
    await assertNoDiagnostics(r'''
void f(Map<int, int> map) {
  map.keys;
}
''');
  }

  test_mapOtherMethod() async {
    await assertNoDiagnostics(r'''
void f(Map<int, int> map) {
  map.addAll({});
}
''');
  }

  test_mapPutIfAbsent_closure() async {
    await assertNoDiagnostics(r'''
void f(Map<int, int?> map) {
  map.putIfAbsent(7, () => null);
}
''');
  }

  ///https://github.com/dart-lang/linter/issues/1414
  test_recursiveInterfaceInheritance() async {
    await assertDiagnostics(r'''
class A extends B {
  A(int x);
}

class B extends A {}

void test_cycle() {
  A(null);
}
''', [
      // No lint
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 41, 1),
      error(CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT, 41, 1),
      error(CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 81, 4),
    ]);
  }
}
