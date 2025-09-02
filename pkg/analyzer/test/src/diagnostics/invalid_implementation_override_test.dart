// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
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
    await assertNoErrorsInCode('''
class A<T> {
  void foo<U>(covariant Object a, U b) {}
}
class B extends A<int> {}
''');
  }

  test_class_getter_abstractOverridesConcrete() async {
    await assertErrorsInCode(
      '''
class A {
  num get g => 7;
}
class B	extends A {
  int get g;
}
''',
      [error(CompileTimeErrorCode.invalidImplementationOverride, 36, 1)],
    );
  }

  test_class_method_abstractOverridesConcrete() async {
    await assertErrorsInCode(
      '''
class A	{
  int add(int a, int b) => a + b;
}
class B	extends A {
  int add();
}
''',
      [
        error(CompileTimeErrorCode.invalidImplementationOverride, 52, 1),
        error(
          CompileTimeErrorCode.invalidOverride,
          72,
          3,
          contextMessages: [message(testFile, 16, 3)],
        ),
      ],
    );
  }

  test_class_method_abstractOverridesConcrete_expandedParameterType() async {
    await assertErrorsInCode(
      '''
class A {
  int add(int a) => a;
}
class B	extends A {
  int add(num a);
}
''',
      [error(CompileTimeErrorCode.invalidImplementationOverride, 41, 1)],
    );
  }

  test_class_method_abstractOverridesConcrete_expandedParameterType_covariant() async {
    await assertNoErrorsInCode('''
class A {
  int add(covariant int a) => a;
}
class B	extends A {
  int add(num a);
}
''');
  }

  test_class_method_abstractOverridesConcrete_withOptional() async {
    await assertErrorsInCode(
      '''
class A {
  int add() => 7;
}
class B	extends A {
  int add([int a = 0, int b = 0]);
}
''',
      [error(CompileTimeErrorCode.invalidImplementationOverride, 36, 1)],
    );
  }

  test_class_method_abstractOverridesConcreteInMixin() async {
    await assertErrorsInCode(
      '''
mixin M {
  int add(int a, int b) => a + b;
}
class A with M {
  int add();
}
''',
      [
        error(CompileTimeErrorCode.invalidImplementationOverride, 52, 1),
        error(
          CompileTimeErrorCode.invalidOverride,
          69,
          3,
          contextMessages: [message(testFile, 16, 3)],
        ),
      ],
    );
  }

  test_class_method_abstractOverridesConcreteViaMixin() async {
    await assertErrorsInCode(
      '''
class A {
  int add(int a, int b) => a + b;
}
mixin M {
  int add();
}
class B	extends A with M {}
''',
      [
        error(CompileTimeErrorCode.invalidImplementationOverride, 77, 1),
        error(
          CompileTimeErrorCode.invalidOverride,
          94,
          1,
          contextMessages: [message(testFile, 16, 3)],
        ),
      ],
    );
  }

  test_class_method_covariant_inheritance_merge() async {
    await assertNoErrorsInCode(r'''
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
    await assertErrorsInCode(
      '''
class A {
  set c(int i) {}
}

class B extends A {
  set c(num i);
}
''',
      [
        error(
          CompileTimeErrorCode.invalidImplementationOverrideSetter,
          37,
          1,
          messageContains: ["'A.c'", "'B.c'"],
        ),
      ],
    );
  }

  test_enum_getter_abstractOverridesConcrete() async {
    await assertErrorsInCode(
      '''
mixin M {
  num get foo => 0;
}
enum E with M {
  v;
  int get foo;
}
''',
      [error(CompileTimeErrorCode.invalidImplementationOverride, 37, 1)],
    );
  }

  test_enum_method_abstractOverridesConcrete() async {
    await assertErrorsInCode(
      '''
mixin M {
  num foo() => 0;
}
enum E with M {
  v;
  int foo();
}
''',
      [error(CompileTimeErrorCode.invalidImplementationOverride, 35, 1)],
    );
  }

  test_enum_method_mixin_toString() async {
    await assertErrorsInCode(
      '''
abstract class I {
  String toString([int? value]);
}

enum E1 implements I {
  v
}

enum E2 implements I {
  v;
  String toString([int? value]) => '';
}
''',
      [error(CompileTimeErrorCode.invalidImplementationOverride, 60, 2)],
    );
  }
}
