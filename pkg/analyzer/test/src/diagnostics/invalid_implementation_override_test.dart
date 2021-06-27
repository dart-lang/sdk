// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidImplementationOverrideTest);
    defineReflectiveTests(InvalidImplementationOverrideWithNullSafetyTest);
  });
}

@reflectiveTest
class InvalidImplementationOverrideTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin {
  test_getter_abstractOverridesConcrete() async {
    await assertErrorsInCode('''
class A {
  num get g => 7;
}
class B	extends A {
  int get g;
}
''', [
      error(CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE, 36, 1),
    ]);
  }

  test_method_abstractOverridesConcrete() async {
    await assertErrorsInCode('''
class A	{
  int add(int a, int b) => a + b;
}
class B	extends A {
  int add();
}
''', [
      error(CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE, 52, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 72, 3),
    ]);
  }

  test_method_abstractOverridesConcrete_expandedParameterType() async {
    await assertErrorsInCode('''
class A {
  int add(int a) => a;
}
class B	extends A {
  int add(num a);
}
''', [
      error(CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE, 41, 1),
    ]);
  }

  test_method_abstractOverridesConcrete_expandedParameterType_covariant() async {
    await assertNoErrorsInCode('''
class A {
  int add(covariant int a) => a;
}
class B	extends A {
  int add(num a);
}
''');
  }

  test_method_abstractOverridesConcrete_withOptional() async {
    await assertErrorsInCode('''
class A {
  int add() => 7;
}
class B	extends A {
  int add([int a = 0, int b = 0]);
}
''', [
      error(CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE, 36, 1),
    ]);
  }

  test_method_abstractOverridesConcreteInMixin() async {
    await assertErrorsInCode('''
mixin M {
  int add(int a, int b) => a + b;
}
class A with M {
  int add();
}
''', [
      error(CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE, 52, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 69, 3),
    ]);
  }

  test_method_abstractOverridesConcreteViaMixin() async {
    await assertErrorsInCode('''
class A {
  int add(int a, int b) => a + b;
}
mixin M {
  int add();
}
class B	extends A with M {}
''', [
      error(CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE, 77, 1),
      error(CompileTimeErrorCode.INVALID_OVERRIDE, 94, 1),
    ]);
  }
}

@reflectiveTest
class InvalidImplementationOverrideWithNullSafetyTest
    extends PubPackageResolutionTest with WithNullSafetyMixin {}
