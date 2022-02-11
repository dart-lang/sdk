// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseIsEvenRatherThanModuloTest);
  });
}

@reflectiveTest
class UseIsEvenRatherThanModuloTest extends LintRuleTest {
  @override
  String get lintRule => 'use_is_even_rather_than_modulo';

  test_undefinedClass() async {
    await assertDiagnostics(r'''
Class tmp;
bool a = tmp % 2 == 0;
''', [
      // No lint
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 0, 5),
    ]);
  }
}
