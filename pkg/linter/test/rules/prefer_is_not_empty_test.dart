// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferIsNotEmptyTest);
  });
}

@reflectiveTest
class PreferIsNotEmptyTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_is_not_empty';

  test_iterable_isEmpty() async {
    await assertNoDiagnostics(r'''
void f(Iterable<int> p) {
  p.isEmpty;
}
''');
  }

  test_iterable_isEmpty_not() async {
    await assertDiagnostics(r'''
void f(Iterable<int> p) {
  !p.isEmpty;
}
''', [
      lint(28, 10),
    ]);
  }

  test_list_isEmpty() async {
    await assertNoDiagnostics(r'''
var x = [].isEmpty;
''');
  }

  test_list_isEmpty_doubleParens_not() async {
    await assertDiagnostics(r'''
var x = !(([4].isEmpty));
''', [
      lint(8, 16),
    ]);
  }

  test_list_isEmpty_not() async {
    await assertDiagnostics(r'''
var x = ![1].isEmpty;
''', [
      lint(8, 12),
    ]);
  }

  test_list_isEmpty_parens_not() async {
    await assertDiagnostics(r'''
var x = !([3].isEmpty);
''', [
      lint(8, 14),
    ]);
  }

  test_map_isEmpty() async {
    await assertNoDiagnostics(r'''
var x = {}.isEmpty;
''');
  }

  test_map_isEmpty_not() async {
    await assertDiagnostics(r'''
var x = !{2: 'a'}.isEmpty;
''', [
      lint(8, 17),
    ]);
  }
}
