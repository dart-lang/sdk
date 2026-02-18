// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TightenTypeOfInitializingFormalsTest);
  });
}

@reflectiveTest
class TightenTypeOfInitializingFormalsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.tighten_type_of_initializing_formals;

  test_superInit() async {
    await assertDiagnostics(
      r'''
class A {
  String? a;
  A(this.a);
}

class B extends A {
  B(String super.a);
}

class C extends A {
  C(super.a) : assert(a != null);
}
''',
      [lint(107, 7)],
    );
  }

  test_thisInit_asserts() async {
    await assertDiagnostics(
      r'''
class A {
  String? p;
  A(this.p) : assert(p != null);
  A.a(this.p) : assert(null != p);
}
''',
      [lint(27, 6), lint(62, 6)],
    );
  }

  test_thisInit_asserts_newSyntax() async {
    await assertDiagnostics(
      r'''
class A {
  String? p;
  new(this.p) : assert(p != null);
}
''',
      [lint(29, 6)],
    );
  }

  test_thisInit_asserts_positionalParams() async {
    await assertDiagnostics(
      r'''
class A {
  A(
    this.p1,
    String? p2,
    this.p3, {
    this.p4,
    this.p5,
  }) : assert(p1 != null),
       assert(p2 != null),
       assert(p4 != null);

  String? p;
  String? p1;
  String? p2;
  String? p3;
  String? p4;
  String? p5;
}
''',
      [lint(19, 7), lint(63, 7)],
    );
  }

  test_thisInit_asserts_primaryConstructor() async {
    await assertDiagnostics(
      r'''
class A(this.p) {
  String? p;
  this : assert(p != null);
}
''',
      [lint(8, 6)],
    );
  }

  test_thisInit_asserts_primaryConstructor_declaring() async {
    await assertNoDiagnostics(r'''
class A(final String? p) {
  this : assert(p != null);
}
''');
  }

  test_thisInit_noAssert() async {
    await assertNoDiagnostics(r'''
class A {
  String? p;
  A(this.p);
}
''');
  }

  test_thisInit_noAssert_primaryConstructor() async {
    await assertNoDiagnostics(r'''
class A(this.p) {
  String? p;
}
''');
  }

  test_thisInit_noAssert_primaryConstructor_declaring() async {
    await assertNoDiagnostics(r'''
class A(final String? p);
''');
  }

  test_thisInit_tightens() async {
    await assertDiagnostics(
      r'''
class A {
  String? p;
  A(String this.p) : assert(p != null);
  A.a(String this.p) : assert(null != p);
}
''',
      [
        // No lint
        error(diag.unnecessaryNullComparisonNeverNullTrue, 53, 7),
        error(diag.unnecessaryNullComparisonNeverNullTrue, 93, 7),
      ],
    );
  }
}
