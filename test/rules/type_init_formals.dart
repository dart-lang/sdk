// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeInitFormalsTest);
  });
}

@reflectiveTest
class TypeInitFormalsTest extends LintRuleTest {
  @override
  String get lintRule => 'type_init_formals';

  test_extraPositionalArgument() async {
    await assertDiagnostics(r'''
class A {
  String? p1;
  String p2 = '';
  A.y({required String? this.p2});
}
''', [
      // No lint
      error(CompileTimeErrorCode.FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE, 49,
          24),
    ]);
  }
}
