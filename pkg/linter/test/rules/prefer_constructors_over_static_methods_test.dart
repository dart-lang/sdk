// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferConstructorsOverStaticMethodsTest);
  });
}

@reflectiveTest
class PreferConstructorsOverStaticMethodsTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_constructors_over_static_methods';

  test_extensionMethod() async {
    await assertNoDiagnostics(r'''
class A {
  A.named();
}
extension E on A {
  static A foo() => A.named();
}
''');
  }

  test_factoryConstructor() async {
    await assertNoDiagnostics(r'''
class A {
  A.named();
  factory A.f() {
    return A.named();
  }
}
''');
  }

  test_staticGetter() async {
    await assertDiagnostics(r'''
class A {
  A.named();
  static A get getter => A.named();
}
''', [
      lint(38, 6),
    ]);
  }

  test_staticMethod_expressionBody() async {
    await assertDiagnostics(r'''
class A {
  A.named();
  static A staticM() => A.named();
}
''', [
      lint(34, 7),
    ]);
  }

  test_staticMethod_expressionBody_extensionType() async {
    // Since the check logic is shared one test should be sufficient to verify
    // extension types are supported.
    await assertDiagnostics(r'''
extension type E(int i) {
  static E make(int i) => E(i);
}
''', [
      lint(37, 4),
    ]);
  }

  test_staticMethod_generic() async {
    await assertNoDiagnostics(r'''
class A {
  A.named();
  static A generic<T>() => A.named();
}
''');
  }

  test_staticMethod_referenceToConstructedInstanceOfClass() async {
    await assertDiagnostics(r'''
class A {
  A.named();
  static A instanceM() {
    final a = A.named();
    return a;
  }
}
''', [
      lint(34, 9),
    ]);
  }

  test_staticMethod_referenceToExistingInstanceOfClass() async {
    await assertNoDiagnostics(r'''
class A {
  static final array = <A>[];
  static A staticM(int i) {
    return array[i];
  }
}
''');
  }

  test_staticMethod_returnsInstantiatedInstance() async {
    await assertNoDiagnostics(r'''
class A<T> {
  A.named();
  static A<int> staticM() => A.named();
}
''');
  }

  test_staticMethod_returnsNullable() async {
    await assertNoDiagnostics(r'''
class A {
  A.named();
  static A? staticM() => 1 == 1 ? null : A.named();
}
''');
  }

  test_staticMethod_returnsUnrelatedType() async {
    await assertNoDiagnostics(r'''
class A {
  A.named();
  static Object staticM() => Object();

  /*static A? ok2() => 1==1 ? null : A.internal(); // OK*/
}
''');
  }
}
