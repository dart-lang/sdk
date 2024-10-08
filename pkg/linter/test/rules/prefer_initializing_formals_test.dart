// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/analyzer_error_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferInitializingFormalsTest);
  });
}

@reflectiveTest
class PreferInitializingFormalsTest extends LintRuleTest {
  @override
  List<AnalyzerErrorCode> get ignoredErrorCodes => [
        WarningCode.UNUSED_LOCAL_VARIABLE,
        WarningCode.UNUSED_FIELD,
      ];

  @override
  String get lintRule => LintNames.prefer_initializing_formals;

  test_assignedInBody() async {
    await assertDiagnostics(r'''
class C {
  num x = 0;
  C(num x) {
    this.x = x;
  }
}
''', [
      lint(40, 10),
    ]);
  }

  test_assignedInBody_andHasSuperInitializer() async {
    await assertDiagnostics(r'''
class A {
  int a, b;
  A(this.a, this.b);
}
class C extends A {
  int? c, d;
  C(int c, int d) : super(c, d) {
    this.c = c;
    this.d = d;
  }
}
''', [
      lint(116, 10),
      lint(132, 10),
    ]);
  }

  test_assignedInBody_justSetters() async {
    await assertNoDiagnostics(r'''
class C {
  C(num x, num y) {
    this.x = x;
    this.y = y;
  }
  set x(num value) {}
  set y(num value) {}
}
''');
  }

  test_assignedInBody_namedParameters() async {
    await assertDiagnostics(r'''
class C {
  num? x, y;
  C({num? x, num y = 1}) {
    this.x = x;
    this.y = y;
  }
}
''', [
      lint(54, 10),
      lint(70, 10),
    ]);
  }

  test_assignedInBody_namedParameters_renamed() async {
    await assertNoDiagnostics(r'''
class C {
  num? x, y;
  C({num? a, num b = 1}) {
    this.x = a;
    this.y = b;
  }
}
''');
  }

  test_assignedInBody_subsequent() async {
    await assertDiagnostics(r'''
class C {
  num x = 0, y = 0;
  C(num x, num y) {
    this.x = x;
    this.y = y;
  }
}
''', [
      lint(54, 10),
      lint(70, 10),
    ]);
  }

  test_assignedInInitializer_andHasSuperInitializer() async {
    await assertDiagnostics(r'''
class A {
  int a, b;
  A(this.a, this.b);
}
class C extends A {
  int c, d;
  C(int c, int d)
      : this.c = c,
        this.d = d,
        super(c, d);
}
''', [
      lint(103, 10),
      lint(123, 10),
    ]);
  }

  test_assignedInInitializer_assignmentWithCalculation() async {
    // https://github.com/dart-lang/linter/issues/2605
    await assertNoDiagnostics(r'''
class C {
  final int f;
  C(bool p) : f = p ? 1 : 0;
}
''');
  }

  test_assignedInInitializer_namedParameters() async {
    await assertDiagnostics(r'''
class C {
  num? x, y;
  C({num? x, num y = 1})
      : this.x = x,
        this.y = y;
}
''', [
      lint(56, 10),
      lint(76, 10),
    ]);
  }

  test_assignedInInitializer_renamedParameter() async {
    await assertNoDiagnostics(r'''
class C {
  final int a, b;

  C(this.b) : a = b;
}
''');
  }

  test_assignedInInitializer_renamedToBePrivate() async {
    await assertNoDiagnostics(r'''
class C {
  final num _x, _y;
  C(num x, num y)
      : _x = x,
        _y = y;
}
''');
  }

  test_assignedInInitializer_renamedToBePrivate_explicitThis() async {
    await assertNoDiagnostics(r'''
class C {
  final num _x, _y;
  C(num x, num y)
      : this._x = x,
        this._y = y;
}
''');
  }

  test_factoryConstructor() async {
    // https://github.com/dart-lang/linter/issues/2441
    await assertNoDiagnostics(r'''
class C {
  String? x;
  factory C.withX(String? x) {
    var c = C._();
    c.x = x;
    return c;
  }
  C._();
}
''');
  }

  test_fieldFormal() async {
    await assertNoDiagnostics(r'''
class C {
  int x;
  C(this.x);
}
''');
  }

  test_fieldFormal_multiple() async {
    await assertNoDiagnostics(r'''
class C {
  num x, y;
  C(this.x, this.y);
}
''');
  }

  test_inheritedFromSuperClass() async {
    await assertNoDiagnostics(r'''
class A {
  int x;
  A(this.x);
}
class B extends A {
  B(int y) : super(y) {
    x = y;
  }
}
''');
  }

  test_paramter() async {
    await assertNoDiagnostics(r'''
void f(int p) {}
''');
  }

  test_renamedParameter() async {
    // https://github.com/dart-lang/linter/issues/2664
    await assertNoDiagnostics(r'''
class C {
  int? x;
  C(int initialX) : x = initialX;
}
''');
  }
}
