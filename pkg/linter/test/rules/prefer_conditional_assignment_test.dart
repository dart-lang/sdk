// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferConditionalAssignmentTest);
  });
}

@reflectiveTest
class PreferConditionalAssignmentTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.prefer_conditional_assignment;

  test_field_ifEqNull() async {
    await assertDiagnostics(r'''
class C {
  String? x;

  void f(String s) {
    if (x == null) {
      x = s;
    }
  }
}
''', [
      lint(49, 35),
    ]);
  }

  test_field_ifEqNull_conditionWrappedInParens() async {
    await assertDiagnostics(r'''
class C {
  String? x;
  void f(String s) {
    if ((x == null)) {
      x = s;
    }
  }
}
''', [
      lint(48, 37),
    ]);
  }

  test_field_ifEqNull_eachWrappedInParens() async {
    await assertDiagnostics(r'''
class C {
  String? x;
  void f(String s) {
    if ((x) == (null)) {
      x = s;
    }
  }
}
''', [
      lint(48, 39),
    ]);
  }

  test_field_ifEqNull_statementBody() async {
    await assertDiagnostics(r'''
class C {
  String? x;
  String? f(String s) {
    if (x == null)
      x = s;
    return x;
  }
}
''', [
      lint(51, 27),
    ]);
  }

  test_field_ifHasElse() async {
    await assertNoDiagnostics(r'''
class C {
  String? x;

  void f() {
    if (x == null) {
      x = foo(this);
    } else {}
  }
}

String foo(C c) => '';
''');
  }

  test_field_onOtherTarget() async {
    await assertNoDiagnostics(r'''
class C {
  String? x;
  void f(C a, C b) {
    if (a.x == null) {
      b.x = '';
    }
  }
}
''');
  }

  test_field_onSameTarget() async {
    await assertDiagnostics(r'''
class C {
  String? x;
  void f(C a) {
    if (a.x == null) {
      a.x = '';
    }
  }
}
''', [
      lint(43, 40),
    ]);
  }

  test_field_unrelatedAssignment() async {
    await assertNoDiagnostics(r'''
class C {
  String? x;
  var y = 1;
  void f() {
    if (x == null) {
      y = 0;
    }
  }
}
''');
  }

  test_field_unrelatedAssignment_thenAssignment() async {
    await assertNoDiagnostics(r'''
class C {
  String? x;
  var y = 1;
  void f() {
    if (x == null) {
      y = 0;
      x = '';
    }
  }
}
''');
  }
}
