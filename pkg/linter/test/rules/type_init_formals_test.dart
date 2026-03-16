// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeInitFormalsTest);
  });
}

@reflectiveTest
class TypeInitFormalsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.type_init_formals;

  test_extraPositionalArgument() async {
    await assertDiagnostics(
      r'''
class A {
  String? p1;
  String p2 = '';
  A.y({required String? this.p2});
}
''',
      [
        // No lint
        error(diag.fieldInitializingFormalNotAssignable, 49, 24),
      ],
    );
  }

  test_initializingFormalForNonExistentField() async {
    await assertDiagnostics(
      r'''
class Invalid {
  Invalid(int this.x); // OK
}
''',
      [
        // No lint
        error(diag.initializingFormalForNonExistentField, 26, 10),
      ],
    );
  }

  test_requiredParam_declaring() async {
    await assertNoDiagnostics(r'''
class A({required var String s});
''');
  }

  test_requiredParam_inPrimaryConstructor_tightening() async {
    await assertNoDiagnostics(r'''
class A({required String this.s}) {
  String? s;
}
''');
  }

  test_requiredParam_inPrimaryConstructor_unnecessaryType() async {
    await assertDiagnostics(
      r'''
class A({required String this.s}) {
  String s;
}
''',
      [lint(18, 6)],
    );
  }

  test_requiredParam_tightening() async {
    await assertNoDiagnostics(r'''
class A {
  String? s;
  A({required String this.s});
}
''');
  }

  test_requiredParam_unnecessaryNullableType() async {
    await assertDiagnostics(
      r'''
class A {
  String? s;
  A({required String? this.s});
}
''',
      [lint(37, 7)],
    );
  }

  test_requiredParam_unnecessaryType() async {
    await assertDiagnostics(
      r'''
class A {
  String s = '';
  A({required String this.s});
}
''',
      [lint(41, 6)],
    );
  }

  test_super() async {
    await assertDiagnostics(
      r'''
class A {
  String? a;
  A({this.a});
}

class B extends A {
  B({String? super.a});
}
''',
      [lint(66, 7)],
    );
  }

  test_typed_fieldIsDynamic() async {
    await assertNoDiagnostics(r'''
class C {
  var x;
  C(int this.x);
}
''');
  }

  test_typed_sameAsField() async {
    await assertDiagnostics(
      r'''
class C {
  int x;
  C(int this.x);
}
''',
      [lint(23, 3)],
    );
  }

  test_typed_subtypeOfField() async {
    await assertNoDiagnostics(r'''
class C {
  num x;
  C.i(int this.x);
  C.d(double this.x);
}
''');
  }

  test_untyped() async {
    await assertNoDiagnostics(r'''
class C {
  int x;
  C(this.x);
}
''');
  }
}
