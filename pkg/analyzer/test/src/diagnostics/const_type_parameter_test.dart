// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstTypeParameterTest);
  });
}

@reflectiveTest
class ConstTypeParameterTest extends PubPackageResolutionTest {
  test_constantPattern_typeParameter() async {
    await assertErrorsInCode(r'''
void f<T>(x) {
  if (x case T) {}
}
''', [
      error(CompileTimeErrorCode.CONST_TYPE_PARAMETER, 28, 1),
    ]);
  }

  test_constantPattern_typeParameter_nested() async {
    await assertErrorsInCode(r'''
void f<T>(Object? x) {
  if (x case const (T)) {}
}
''', [
      error(CompileTimeErrorCode.CONST_TYPE_PARAMETER, 43, 1),
    ]);
  }

  test_constantPattern_typeParameter_nested2() async {
    await assertErrorsInCode(r'''
void f<T>(Object? x) {
  if (x case const (List<T>)) {}
}
''', [
      error(CompileTimeErrorCode.CONST_TYPE_PARAMETER, 43, 7),
    ]);
  }
}
