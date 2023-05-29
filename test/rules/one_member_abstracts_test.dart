// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OneMemberAbstractsTest);
  });
}

@reflectiveTest
class OneMemberAbstractsTest extends LintRuleTest {
  @override
  String get lintRule => 'one_member_abstracts';

  test_sealed_concreteMethod_noDiagnostic() async {
    await assertNoDiagnostics(r'''
sealed class C {
  void f() { }
}
''');
  }

  test_sealed_noDiagnostic() async {
    await assertNoDiagnostics(r'''
sealed class C {
  void f();
}
''');
  }
}
