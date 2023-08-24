// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidSettersWithoutGettersTest);
  });
}

@reflectiveTest
class AvoidSettersWithoutGettersTest extends LintRuleTest {
  @override
  List<String> get experiments => ['inline-class'];

  @override
  String get lintRule => 'avoid_setters_without_getters';

  test_enum() async {
    await assertDiagnostics(r'''
enum A {
  a,b,c;
  set x(int x) {}
}
''', [
      lint(24, 1),
    ]);
  }

  test_extensionType() async {
    await assertDiagnostics(r'''
extension type B(int a) {
  set i(int i) {}
}
''', [
      lint(32, 1),
    ]);
  }
}
