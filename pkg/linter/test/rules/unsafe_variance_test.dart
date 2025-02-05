// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnsafeVarianceTest);
  });
}

@reflectiveTest
class UnsafeVarianceTest extends LintRuleTest {
  @override
  String get lintRule => 'unsafe_variance';

  test_class_getter() async {
    await assertDiagnostics(r'''
class A<X> {
  void Function([X])? get func2 => null;
}
''', [
      lint(30, 1),
    ]);
  }

  test_class_method_bound() async {
    await assertDiagnostics(r'''
class A<X> {
  int Function<Y extends X>() m2() => <Y extends X>() => 2;
}
''', [
      lint(38, 1),
    ]);
  }

  test_class_method_parameter() async {
    await assertNoDiagnostics(r'''
class A<X> {
  void m3(void Function(void Function(X)) _) {}
  void m4(X _) {}
}
''');
  }

  test_class_method_return() async {
    await assertDiagnostics(r'''
class A<X> {
  X Function(X) m1() => (X x) => x;
}
''', [
      lint(26, 1),
    ]);
  }

  test_class_method_return_typedef() async {
    await assertDiagnostics(r'''
class A<X> {
  Func<X> m1() => (X x) => x;
}
typedef Func<X> = X Function(X);
''', [
      lint(20, 1),
    ]);
  }

  test_class_variable() async {
    await assertDiagnostics(r'''
class A<X> {
  void Function(X) func;
  A(this.func);
}
''', [
      lint(29, 1),
    ]);
  }

  test_enum_getter() async {
    await assertDiagnostics(r'''
enum E<X> {
  e;
  void Function([X])? get func2 => null;
}
''', [
      lint(34, 1),
    ]);
  }

  test_extension_getter() async {
    await assertNoDiagnostics(r'''
extension E<X> on List<X> {
  void Function([X])? get func2 => null;
}
''');
  }

  test_extension_type_getter() async {
    await assertNoDiagnostics(r'''
extension type A<X>(X x) {
  void Function([X])? get func2 => null;
}
''');
  }

  test_mixin_getter() async {
    await assertDiagnostics(r'''
mixin A<X> {
  void Function([X])? get func2;
}
''', [
      lint(30, 1),
    ]);
  }

  test_static_class_member() async {
    await assertNoDiagnostics(r'''
class A<X> {
  static void Function<X>(X)? get func => null;
  static void Function(X)? m<X>() => null;
}
''');
  }

  test_static_enum_member() async {
    await assertNoDiagnostics(r'''
enum E<X> {
  e;
  static void Function<X>(X)? get func => null;
  static void Function(X)? m<X>() => null;
}
''');
  }

  test_static_extension_member() async {
    await assertNoDiagnostics(r'''
extension E<X> on int {
  static void Function<X>(X)? get func => null;
  static void Function(X)? m<X>() => null;
}
''');
  }

  test_static_extension_type_member() async {
    await assertNoDiagnostics(r'''
extension type E<X>(X x) {
  static void Function<X>(X)? get func => null;
  static void Function(X)? m<X>() => null;
}
''');
  }

  test_static_mixin_member() async {
    await assertNoDiagnostics(r'''
mixin A<X> {
  static void Function<X>(X)? get func => null;
  static void Function(X)? m<X>() => null;
}
''');
  }
}
