// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseToAndAsIfApplicableTest);
  });
}

@reflectiveTest
class UseToAndAsIfApplicableTest extends LintRuleTest {
  @override
  String get lintRule => 'use_to_and_as_if_applicable';

  test_asOther_argumentIsThis() async {
    await assertNoDiagnostics(r'''
class B {
  A asOther() {
    return A.from(this);
  }
}

class A {
  A.from(B _);
}
''');
  }

  test_asX_argumentIsThis() async {
    await assertNoDiagnostics(r'''
class B {
  A asA() {
    return A.from(this);
  }
}

class A {
  A.from(B _);
}
''');
  }

  test_asx_argumentIsThis() async {
    await assertDiagnostics(r'''
class B {
  A asa() {
    return A.from(this);
  }
}

class A {
  A.from(B _);
}
''', [
      lint(14, 3),
    ]);
  }

  test_asX_private_argumentIsThis() async {
    await assertNoDiagnostics(r'''
class B {
  // ignore: unused_element
  A _asA() {
    return A.from(this);
  }
}

class A {
  A.from(B _);
}
''');
  }

  test_asx_private_argumentIsThis() async {
    await assertDiagnostics(r'''
class B {
  // ignore: unused_element
  A _asa() {
    return A.from(this);
  }
}

class A {
  A.from(B _);
}
''', [
      lint(42, 4),
    ]);
  }

  test_getX_argumentIsOther_extends() async {
    await assertNoDiagnostics(r'''
abstract class C {
  A getA();
}
class D extends C {
  A getA() => A.from(B());
}

class A {
  A.from(B _);
}
class B {}
''');
  }

  test_getX_argumentIsOther_implements() async {
    await assertNoDiagnostics(r'''
abstract class C {
  A getA();
}
class D implements C {
  A getA() => A.from(B());
}

class A {
  A.from(B _);
}
class B {}
''');
  }

  test_getX_argumentIsOther_superConstraint() async {
    await assertNoDiagnostics(r'''
abstract class C {
  A getA();
}
mixin D on C {
  A getA() => A.from(B());
}

class A {
  A.from(B _);
}
class B {}
''');
  }

  test_namedOtherwise_argumentIsThis() async {
    await assertDiagnostics(r'''
class B {
  A foo() {
    return A.from(this);
  }
}

class A {
  A.from(B _);
}
''', [
      lint(14, 3),
    ]);
  }

  test_namedOtherwise_private_argumentIsThis() async {
    await assertDiagnostics(r'''
class B {
  // ignore: unused_element
  A _foo() {
    return A.from(this);
  }
}

class A {
  A.from(B _);
}
''', [
      lint(42, 4),
    ]);
  }

  test_namedOtherwise_private_hasParameters_argumentIsThis() async {
    await assertNoDiagnostics(r'''
class B {
  // ignore: unused_element
  A _foo(int a) {
    return A.from(this);
  }
}

class A {
  A.from(B _);
}
''');
  }

  test_toOther_argumentIsThis() async {
    await assertNoDiagnostics(r'''
class B {
  A toList() {
    return A.from(this);
  }
}

class A {
  A.from(B _);
}
''');
  }

  test_toX_argumentIsThis() async {
    await assertNoDiagnostics(r'''
class B {
  A toA() {
    return A.from(this);
  }
}

class A {
  A.from(B _);
}
''');
  }

  test_tox_argumentIsThis() async {
    await assertDiagnostics(r'''
class B {
  A toa() {
    return A.from(this);
  }
}

class A {
  A.from(B _);
}
''', [
      lint(14, 3),
    ]);
  }

  test_toX_private_argumentIsThis() async {
    await assertNoDiagnostics(r'''
class B {
  // ignore: unused_element
  A _toA() {
    return A.from(this);
  }
}

class A {
  A.from(B _);
}
''');
  }

  test_tox_private_argumentIsThis() async {
    await assertDiagnostics(r'''
class B {
  // ignore: unused_element
  A _toa() {
    return A.from(this);
  }
}

class A {
  A.from(B _);
}
''', [
      lint(42, 4),
    ]);
  }
}
