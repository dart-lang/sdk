// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidImplementationOverrideTest);
  });
}

@reflectiveTest
class InvalidImplementationOverrideTest extends PubPackageResolutionTest {
  test_class_generic_method_generic_hasCovariantParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  void foo<U>(covariant Object a, U b) {}
}
class B extends A<int> {}
''');
  }

  test_class_getter_abstractOverridesConcrete() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  num get g => 7;
}
class B	extends A {
//    ^
// [diag.invalidImplementationOverride] 'A.g' ('num Function()') isn't a valid concrete implementation of 'B.g' ('int Function()').
  int get g;
}
''');
  }

  test_class_method_abstractOverridesConcrete() async {
    await resolveTestCodeWithDiagnostics(r'''
class A	{
  int add(int a, int b) => a + b;
//    ^^^
// [context 1] The member being overridden.
}
class B	extends A {
//    ^
// [diag.invalidImplementationOverride] 'A.add' ('int Function(int, int)') isn't a valid concrete implementation of 'B.add' ('int Function()').
  int add();
//    ^^^
// [diag.invalidOverride][context 1] 'B.add' ('int Function()') isn't a valid override of 'A.add' ('int Function(int, int)').
}
''');
  }

  test_class_method_abstractOverridesConcrete_expandedParameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int add(int a) => a;
}
class B	extends A {
//    ^
// [diag.invalidImplementationOverride] 'A.add' ('int Function(int)') isn't a valid concrete implementation of 'B.add' ('int Function(num)').
  int add(num a);
}
''');
  }

  test_class_method_abstractOverridesConcrete_expandedParameterType_covariant() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int add(covariant int a) => a;
}
class B	extends A {
  int add(num a);
}
''');
  }

  test_class_method_abstractOverridesConcrete_withOptional() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int add() => 7;
}
class B	extends A {
//    ^
// [diag.invalidImplementationOverride] 'A.add' ('int Function()') isn't a valid concrete implementation of 'B.add' ('int Function([int, int])').
  int add([int a = 0, int b = 0]);
}
''');
  }

  test_class_method_abstractOverridesConcreteInMixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int add(int a, int b) => a + b;
//    ^^^
// [context 1] The member being overridden.
}
class A with M {
//    ^
// [diag.invalidImplementationOverride] 'M.add' ('int Function(int, int)') isn't a valid concrete implementation of 'A.add' ('int Function()').
  int add();
//    ^^^
// [diag.invalidOverride][context 1] 'A.add' ('int Function()') isn't a valid override of 'M.add' ('int Function(int, int)').
}
''');
  }

  test_class_method_abstractOverridesConcreteViaMixin() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int add(int a, int b) => a + b;
//    ^^^
// [context 1] The member being overridden.
}
mixin M {
  int add();
}
class B	extends A with M {}
//    ^
// [diag.invalidImplementationOverride] 'A.add' ('int Function(int, int)') isn't a valid concrete implementation of 'M.add' ('int Function()').
//                     ^
// [diag.invalidOverride][context 1] 'M.add' ('int Function()') isn't a valid override of 'A.add' ('int Function(int, int)').
''');
  }

  test_class_method_covariant_inheritance_merge() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {}

class C {
  /// Not covariant-by-declaration here.
  void foo(B b) {}
}

abstract class I {
  /// Is covariant-by-declaration here.
  void foo(covariant A a);
}

/// Is covariant-by-declaration here.
class D extends C implements I {}
''');
  }

  test_class_setter_abstractOverridesConcrete() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set c(int i) {}
}

class B extends A {
//    ^
// [diag.invalidImplementationOverrideSetter] The setter 'A.c' ('void Function(int)') isn't a valid concrete implementation of 'B.c' ('void Function(num)').
  set c(num i);
}
''');
  }

  test_enum_getter_abstractOverridesConcrete() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  num get foo => 0;
}
enum E with M {
//   ^
// [diag.invalidImplementationOverride] 'M.foo' ('num Function()') isn't a valid concrete implementation of 'E.foo' ('int Function()').
  v;
  int get foo;
}
''');
  }

  test_enum_method_abstractOverridesConcrete() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  num foo() => 0;
}
enum E with M {
//   ^
// [diag.invalidImplementationOverride] 'M.foo' ('num Function()') isn't a valid concrete implementation of 'E.foo' ('int Function()').
  v;
  int foo();
}
''');
  }

  test_enum_method_mixin_toString() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class I {
  String toString([int? value]);
}

enum E1 implements I {
//   ^^
// [diag.invalidImplementationOverride] 'Object.toString' ('String Function()') isn't a valid concrete implementation of 'I.toString' ('String Function([int?])').
    v
}

enum E2 implements I {
  v;
  String toString([int? value]) => '';
}
''');
  }
}
