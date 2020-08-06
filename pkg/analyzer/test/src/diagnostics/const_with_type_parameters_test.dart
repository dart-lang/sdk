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
    await assertErrorsInCode(r'''
class A<T> {
  static const V = const A<T>();
  const A();
}
''', [
      error(CompileTimeErrorCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 40, 1),
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS, 40, 1),
    ]);
  }

  test_indirect() async {
    await assertErrorsInCode(r'''
class A<T> {
  static const V = const A<List<T>>();
  const A();
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS, 45, 1),
      error(CompileTimeErrorCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 45, 1),
    ]);
  }
}
