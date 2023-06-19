// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FfiRawVoidCallbacksMustReturnVoid);
  });
}

@reflectiveTest
class FfiRawVoidCallbacksMustReturnVoid extends PubPackageResolutionTest {
  test_RawVoidCallback_inferred() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
void f(int i) => i * 2;
void g() {
  RawVoidCallback<Void Function(Int32)>? callback;
  callback = RawVoidCallback(f);
  callback.close();
}
''', []);
  }

  test_RawVoidCallback_mustBeANativeFunctionType() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
void f(int i) => i * 2;
void g() {
  RawVoidCallback<void Function(int)>(f);
}
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 56, 35),
    ]);
  }

  test_RawVoidCallback_mustBeASubtype() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
void f(int i) => i * 2;
void g() {
  RawVoidCallback<Void Function(Double)>(f);
}
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 95, 1),
    ]);
  }

  test_RawVoidCallback_mustHaveTypeArgs() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
int f(int i) => i * 2;
void g() {
  RawVoidCallback(f);
}
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 55, 15),
    ]);
  }

  test_RawVoidCallback_mustReturnVoid() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
int f(int i) => i * 2;
void g() {
  RawVoidCallback<Int32 Function(Int32)>(f);
}
''', [
      error(FfiCode.MUST_RETURN_VOID, 94, 1),
    ]);
  }

  test_RawVoidCallback_ok() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
void f(int i) => i * 2;
void g() {
  RawVoidCallback<Void Function(Int32)>(f);
}
''', []);
  }
}
