// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MustBeANativeFunctionTypeTest);
  });
}

@reflectiveTest
class MustBeANativeFunctionTypeTest extends PubPackageResolutionTest {
  test_fromFunction() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
int f(int i) => i * 2;
class C<T extends Function> {
  void g() {
    Pointer.fromFunction<T>(f);
  }
}
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 89, 26),
    ]);
  }

  test_lookupFunction() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
typedef S = int Function(int);
typedef F = String Function(String);
void f(DynamicLibrary lib) {
  lib.lookupFunction<S, F>('g');
}
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 137, 1),
    ]);
  }

  test_lookupFunction_T() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
typedef F = int Function(int);
class C<T extends Function> {
  void f(DynamicLibrary lib, NativeFunction x) {
    lib.lookupFunction<T, F>('g');
  }
}
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 152, 1),
    ]);
  }
}
