// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/utilities/legacy.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullClosuresPreNNBDTest);
    defineReflectiveTests(NullClosuresTest);
  });
}

@reflectiveTest
class NullClosuresPreNNBDTest extends LintRuleTest {
  @override
  String get lintRule => 'null_closures';

  @override
  void setUp() {
    super.setUp();
    noSoundNullSafety = false;
  }

  void tearDown() {
    noSoundNullSafety = true;
  }

  test_list_firstWhere() async {
    await assertNoDiagnostics(r'''
// @dart=2.9

f() => <int>[2, 4, 6].firstWhere((e) => e.isEven, orElse: () => null);
''');
  }

  test_list_generate() async {
    await assertDiagnostics(r'''
// @dart=2.9

f() => List.generate(3, null);
''', [
      lint(38, 4),
    ]);
  }

  test_list_where() async {
    await assertDiagnostics(r'''
// @dart=2.9

f() => <int>[2, 4, 6].where(null);
''', [
      lint(42, 4),
    ]);
  }

  test_map_putIfAbsent() async {
    await assertDiagnostics(r'''
// @dart=2.9

f() {
  var map = <int, int>{};
  map.putIfAbsent(7, null);
  return map;
}
''', [
      lint(67, 4),
    ]);
  }
}

@reflectiveTest
class NullClosuresTest extends LintRuleTest {
  @override
  String get lintRule => 'null_closures';

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
