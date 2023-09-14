// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: file_names

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferForElementsToMapFromIterableTest);
  });
}

@reflectiveTest
class PreferForElementsToMapFromIterableTest extends LintRuleTest {
  // TODO(srawlins): Add tests with block-bodied closures.

  @override
  String get lintRule => 'prefer_for_elements_to_map_fromIterable';

  test_hasKeyAndValue_closuresAreSimple() async {
    await assertDiagnostics(r'''
void f(Iterable<int> i) {
  Map.fromIterable(i, key: (k) => k * 2, value: (v) => 0);
}
''', [
      lint(28, 55),
    ]);
  }

  test_hasKeyAndValue_closuresReferenceE() async {
    await assertDiagnostics(r'''
void f(Iterable<int> i, int e) {
  Map.fromIterable(i, key: (k) => k * e, value: (v) => v + e);
}
''', [
      lint(35, 59),
    ]);
  }

  test_hasKeyAndValue_closuresShadowVariable() async {
    await assertDiagnostics(r'''
void f(Iterable<int> i, int k) {
  Map.fromIterable(i, key: (k) => k * 2, value: (v) => k);
}
''', [
      lint(35, 55),
    ]);
  }

  test_missingKey() async {
    await assertNoDiagnostics(r'''
void f(Iterable<int> i) {
  Map.fromIterable(i, value: (e) => e + 3);
}
''');
  }

  test_nonMap_fromIterable() async {
    await assertNoDiagnostics(r'''
void f(Iterable<int> i) {
  A.fromIterable(i, key: (e) => e * 2, value: (e) => e + 3);
}

class A<K, V> {
  A.fromIterable(
      Iterable<int> i, {K Function(int)? key, V Function(int)? value});
}
''');
  }
}
