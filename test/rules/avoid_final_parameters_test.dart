// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidFinalParametersTest);
  });
}

@reflectiveTest
class AvoidFinalParametersTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_final_parameters';

  @override
  List<String> get experiments => [
        EnableString.super_parameters,
      ];

  test_super() async {
    await assertDiagnostics(r'''
class A {
  String? a;
  String? b;
  A(this.a, this.b);
}
class B extends A {
  B(final super.a, final super.b);
}
''', [
      lint('avoid_final_parameters', 83, 13),
      lint('avoid_final_parameters', 98, 13),
    ]);
  }
}
