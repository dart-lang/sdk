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

  test_macroClass() async {
    await assertDiagnostics(r'''
abstract macro class M {
  void m();
}
''', [
      // TODO(pq): add abstract macro compilation error when implemented
    ]);
  }

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

  test_oneMember_augmentedAbstractClass_augmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
part 'test.dart';

abstract class A { }
''');

    await assertNoDiagnostics(r'''
part of 'a.dart';

augment abstract class A {
  void m();
}
''');
  }

  test_oneMember_augmentedAbstractClass_declaration() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment abstract class A {
  void m();
}
''');

    await assertDiagnostics(r'''
part 'a.dart';

abstract class A { }
''', [
      lint(31, 1),
    ]);
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

  test_twoMembers_augmentedAbstractClass_declaration() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment abstract class A {
  void m();
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
part of 'test.dart';

augment abstract class A {
  void n();
}
''');

    await assertNoDiagnostics(r'''
part 'a.dart';
part 'b.dart';

abstract class A { }
''');
  }

  test_twoMembers_oneField() async {
    await assertNoDiagnostics(r'''
abstract class C {
  int x = 0;
  int f();
}
''');
  }

  test_twoMembers_oneGetter() async {
    await assertNoDiagnostics(r'''
abstract class C {
  int get x => 0;
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
