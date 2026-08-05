// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InconsistentInheritanceTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class InconsistentInheritanceTest extends PubPackageResolutionTest {
  test_class_augmentWithInterface_augmentWithMixin() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
part 'c.dart';

mixin A {
  void foo(int _);
}

abstract class B {
  void foo(String _);
}

abstract class C extends Object {}
//             ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'foo': A.foo (void Function(int)), B.foo (void Function(String)).
''',
      b: r'''
part of 'a.dart';

augment abstract class C implements B {}
''',
      c: r'''
part of 'a.dart';

augment abstract class C with A {}
''',
    });
  }

  test_class_augmentWithMixin_augmentWithInterface() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var b = getFile('$testPackageLibPath/b.dart');
    var c = getFile('$testPackageLibPath/c.dart');

    await resolveFilesWithDiagnostics({
      a: r'''
part 'b.dart';
part 'c.dart';

mixin A {
  void foo(int _);
}

abstract class B {
  void foo(String _);
}

abstract class C extends Object {}
//             ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'foo': A.foo (void Function(int)), B.foo (void Function(String)).
''',
      b: r'''
part of 'a.dart';

augment abstract class C with A {}
''',
      c: r'''
part of 'a.dart';

augment abstract class C implements B {}
''',
    });
  }

  test_class_augmentWithMixin_sameFile() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class I {
  String foo();
}

mixin M {
  int foo() => 0;
}

class A implements I {}
//    ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'foo': M.foo (int Function()), I.foo (String Function()).

augment class A with M {}
''');
  }

  /// https://github.com/dart-lang/sdk/issues/47026
  test_class_covariantInSuper_withTwoUnrelated() async {
    await resolveTestCodeWithDiagnostics(r'''
class D1 {}
class D2 {}
class D implements D1, D2 {}

class A { void m(covariant D d) {} }
abstract class B1 { void m(D1 d1); }
abstract class B2 { void m(D2 d2); }
class C extends A implements B1, B2 {}
//    ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'm': A.m (void Function(D)), B1.m (void Function(D1)), B2.m (void Function(D2)).
''');
  }

  test_class_parameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void m(int i);
}
abstract class B {
  void m(String s);
}
abstract class C implements A, B {}
//             ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'm': A.m (void Function(int)), B.m (void Function(String)).
''');
  }

  test_class_parameterType_inheritedFromBase() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void m(int i);
}
abstract class B {
  void m(String s);
}
abstract class C extends B implements A {}
//             ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'm': B.m (void Function(String)), A.m (void Function(int)).
''');
  }

  test_class_parameterType_inheritedInInterface() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void m(int i);
}
abstract class B {
  void m(String s);
}
abstract class B2 extends B {}
abstract class C implements A, B2 {}
//             ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'm': A.m (void Function(int)), B.m (void Function(String)).
''');
  }

  test_class_parameterType_inheritedInInterface_andMixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  void m(int i);
}
abstract class B {
  void m(String s);
}
abstract class B2 extends B {}
abstract class C extends Object with A implements B2 {}
//             ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'm': A.m (void Function(int)), B.m (void Function(String)).
''');
  }

  test_class_parameterType_inheritedInInterface_andMixinApplication() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  void m(int i);
}
abstract class B {
  void m(String s);
}
abstract class B2 extends B {}
abstract class C = Object with A implements B2;
//             ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'm': A.m (void Function(int)), B.m (void Function(String)).
''');
  }

  test_class_parameterType_mixedIntoInterface() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void m(int i);
}
mixin B {
  void m(String s);
}
abstract class B2 extends Object with B {}
abstract class C implements A, B2 {}
//             ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'm': A.m (void Function(int)), B.m (void Function(String)).
''');
  }

  test_class_parameterType_mixedIntoInterface_andMixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  void m(int i);
}
mixin B {
  void m(String s);
}
abstract class B2 extends Object with B {}
abstract class C extends Object with A implements B2 {}
//             ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'm': A.m (void Function(int)), B.m (void Function(String)).
''');
  }

  test_class_parameterType_twoConflictingInterfaces() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void m(int i);
}
abstract class B {
  void m(String s);
}
abstract class C {
  void n(String s);
}
abstract class D implements A, B, C {}
//             ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'm': A.m (void Function(int)), B.m (void Function(String)).
''');
  }

  test_class_requiredParameters() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void m();
}
abstract class B {
  void m(int y);
}
abstract class C implements A, B {}
//             ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'm': A.m (void Function()), B.m (void Function(int)).
''');
  }

  test_class_returnType() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int m();
}
abstract class B {
  String m();
}
abstract class C implements A, B {}
//             ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'm': A.m (int Function()), B.m (String Function()).
''');
  }

  test_enum_returnType() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int foo();
}

abstract class B {
  String foo();
}

enum E implements A, B {v}
//   ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'foo': A.foo (int Function()), B.foo (String Function()).
''');
  }

  test_enum_returnType_augmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int foo();
}

abstract class B {
  String foo();
}

enum E implements A {v}
//   ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'foo': A.foo (int Function()), B.foo (String Function()).

augment enum E implements B {}
''');
  }

  test_mixin_implements_parameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void m(int i);
}
abstract class B {
  void m(String s);
}
mixin M implements A, B {}
//    ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'm': A.m (void Function(int)), B.m (void Function(String)).
''');
  }

  test_mixin_implements_requiredParameters() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void m();
}
abstract class B {
  void m(int y);
}
mixin M implements A, B {}
//    ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'm': A.m (void Function()), B.m (void Function(int)).
''');
  }

  test_mixin_implements_returnType() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int m();
}
abstract class B {
  String m();
}
mixin M implements A, B {}
//    ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'm': A.m (int Function()), B.m (String Function()).
''');
  }

  test_mixin_on_parameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void m(int i);
}
abstract class B {
  void m(String s);
}
mixin M on A, B {}
//    ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'm': A.m (void Function(int)), B.m (void Function(String)).
''');
  }

  test_mixin_on_requiredParameters() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void m();
}
abstract class B {
  void m(int y);
}
mixin M on A, B {}
//    ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'm': A.m (void Function()), B.m (void Function(int)).
''');
  }

  test_mixin_on_returnType() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int m();
}
abstract class B {
  String m();
}
mixin M on A, B {}
//    ^
// [diag.inconsistentInheritance] Superinterfaces don't have a valid override for 'm': A.m (int Function()), B.m (String Function()).
''');
  }

  test_overrideWithDynamicParameterType_inheritsAndInterface() async {
    await resolveTestCodeWithDiagnostics(r'''
class B {
  void m(int i) {}
}

class I {
  void m(String s) {}
}

class C extends B implements I {
  void m(dynamic d) {}
}
''');
  }

  test_overrideWithDynamicParameterType_mixinAndInterface() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin B {
  void m(int i) {}
}

class I {
  void m(String s) {}
}

class C extends Object with B implements I {
  void m(dynamic d) {}
}
''');
  }
}
