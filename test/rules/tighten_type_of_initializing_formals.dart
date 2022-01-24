// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TightenTypeOfInitializingFormalsTest);
  });
}

@reflectiveTest
class TightenTypeOfInitializingFormalsTest extends LintRuleTest {
  @override
  List<String> get experiments => [
        EnableString.super_parameters,
      ];

  @override
  String get lintRule => 'tighten_type_of_initializing_formals';

  test_superInit() async {
    await assertDiagnostics(r'''
class A {
  String? a;
  A(this.a);
}

class B extends A {
  B(String super.a);
}

class C extends A {
  C(super.a) : assert(a != null);
}
''', [
      lint('tighten_type_of_initializing_formals', 107, 7),
    ]);
  }
}
