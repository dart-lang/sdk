// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperGoesLastTest);
  });
}

@reflectiveTest
class SuperGoesLastTest extends LintRuleTest {
  @override
  String get lintRule => 'super_goes_last';

  test_invalidSuperInvocation() async {
    await assertDiagnostics(r'''
class A {
  int a;
  A(this.a);
}

class C extends A {
  int _c;
  C(int a)
      : super(a), _c = a + 1;
}

''', [
      error(HintCode.UNUSED_FIELD, 61, 2),
      error(CompileTimeErrorCode.SUPER_INVOCATION_NOT_LAST, 84, 5),
      lint('super_goes_last', 84, 8),
    ]);
  }
}
