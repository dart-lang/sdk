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

  test_oneMember_abstract() async {
    await assertDiagnostics(r'''
abstract class C {
  void m();
}
''', [
      lint(15, 1),
    ]);
  }

  test_oneMember_abstractGetter() async {
    await assertNoDiagnostics(r'''
abstract class C {
  String get s;
}
''');
  }

  test_oneMember_appliedMixin() async {
    await assertNoDiagnostics(r'''
abstract class C with M {
  void m2();
}

mixin M {
  void m1();
}
''');
  }

  test_oneMember_extendedType() async {
    await assertNoDiagnostics(r'''
abstract class D extends C {
  int m2();
}

abstract class C {
  int m2() => 42;
}
''');
  }

  test_oneMember_implementedInterface() async {
    await assertNoDiagnostics(r'''
abstract class D implements C {
  void m3();
}

abstract class C {
  void m1();
  void m2();
}
''');
  }

  test_oneMember_nonAbstract() async {
    await assertNoDiagnostics(r'''
abstract class C {
  int f() => 42;
}
''');
  }

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

  test_twoMembers() async {
    await assertNoDiagnostics(r'''
abstract class C {
  int x = 0;
  int f();
}
''');
  }

  test_zeroMember_extendedTypeHasOneMember() async {
    await assertDiagnostics(r'''
abstract class D extends C {}

abstract class C {
  void m();
}
''', [
      lint(46, 1),
    ]);
  }
}
