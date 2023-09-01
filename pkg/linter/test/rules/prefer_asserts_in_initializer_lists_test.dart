// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferAssertsInInitializerListsTest);
    defineReflectiveTests(PreferAssertsInInitializerListsSuperTest);
  });
}

@reflectiveTest
class PreferAssertsInInitializerListsSuperTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_asserts_in_initializer_lists';

  test_super() async {
    await assertDiagnostics(r'''
class A {
  final int a;
  A(this.a);
}

class B extends A {
  B(super.a) {
    assert(a != 0);
  }
}
''', [
      lint(80, 6),
    ]);
  }
}

@reflectiveTest
class PreferAssertsInInitializerListsTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_asserts_in_initializer_lists';

  test_afterFirstStatement() async {
    await assertNoDiagnostics(r'''
class A {
  A.named(a) {
    print('');
    assert(a != null);
  }
}

''');
  }

  test_firstStatement() async {
    await assertDiagnostics(r'''
class A {
  A.named(a) {
    assert(a != null);
  }
}

''', [
      lint(29, 6),
    ]);
  }

  test_initializer() async {
    await assertNoDiagnostics(r'''
class A {
  A.named(a) : assert(a != null);
}

''');
  }

  test_nonBoolExpression() async {
    await assertDiagnostics(r'''
class A {
  bool? f;
  A() {
    assert(()
    {
      f = true;
      return false;
    });
  }
}
''', [
      // No lint
      error(CompileTimeErrorCode.NON_BOOL_EXPRESSION, 40, 50),
    ]);
  }
}
