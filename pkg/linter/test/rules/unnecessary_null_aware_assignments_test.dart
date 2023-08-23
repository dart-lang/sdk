// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNullAwareAssignmentsTest);
  });
}

@reflectiveTest
class UnnecessaryNullAwareAssignmentsTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_null_aware_assignments';

  test_explicitSetter() async {
    await assertNoDiagnostics(r'''
int? get x => null;
set x(int? x) {}

void f() {
  x ??= null;
}
''');
  }

  test_localVariable_nullAssignment() async {
    await assertDiagnostics(r'''
  void f() {
    var x;
    x ??= null;
  }
''', [
      lint(28, 10),
    ]);
  }

  test_localVariable_otherAssignment() async {
    await assertNoDiagnostics(r'''
  void f() {
    var x;
    x ??= 1;
  }
''');
  }
}
