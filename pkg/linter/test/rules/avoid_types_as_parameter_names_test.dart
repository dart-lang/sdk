// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidTypesAsParameterNamesTest);
  });
}

@reflectiveTest
class AvoidTypesAsParameterNamesTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_types_as_parameter_names';

  test_extensionType() async {
    await assertDiagnostics(r'''
extension type E(int i) { }

void f(E) { }
''', [
      lint(36, 1),
    ]);
  }

  test_super() async {
    await assertDiagnostics(r'''
class A {
  String a;
  A(this.a);
}
class B extends A {
  B(super.String);
}
''', [
      lint(67, 6),
    ]);
  }
}
