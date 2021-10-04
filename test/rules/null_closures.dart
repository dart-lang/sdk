// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullClosuresTest);
  });
}

@reflectiveTest
class NullClosuresTest extends LintRuleTest {
  @override
  String get lintRule => 'null_closures';

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
