// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstWithTypeParametersTest);
  });
}

@reflectiveTest
class ConstWithTypeParametersTest extends PubPackageResolutionTest {
  test_direct() async {
    await assertErrorsInCode('''
class A<T> {
  const A();
  void m() {
    const A<T>();
  }
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS, 51, 1),
    ]);
  }

  test_indirect() async {
    await assertErrorsInCode('''
class A<T> {
  const A();
  void m() {
    const A<List<T>>();
  }
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS, 56, 1),
    ]);
  }

  test_indirect_functionType_returnType() async {
    await assertErrorsInCode('''
class A<T> {
  const A();
  void m() {
    const A<T Function()>();
  }
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS, 51, 1),
    ]);
  }

  test_indirect_functionType_simpleParameter() async {
    await assertErrorsInCode('''
class A<T> {
  const A();
  void m() {
    const A<void Function(T)>();
  }
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS, 65, 1),
    ]);
  }

  test_indirect_functionType_typeParameter() async {
    await assertNoErrorsInCode('''
class A<T> {
  const A();
  void m() {
    const A<void Function<U>()>();
  }
}
''');
  }

  test_indirect_functionType_typeParameter_typeParameterBound() async {
    await assertErrorsInCode('''
class A<T> {
  const A();
  void m() {
    const A<void Function<U extends T>()>();
  }
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS, 75, 1),
    ]);
  }
}
