// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FfiNativeCallableListenersMustReturnVoid);
  });
}

@reflectiveTest
class FfiNativeCallableListenersMustReturnVoid
    extends PubPackageResolutionTest {
  test_NativeCallable_listener_inferred() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
void f(int i) => i * 2;
void g() {
  NativeCallable<Void Function(Int32)>? callback;
  callback = NativeCallable.listener(f);
  callback.close();
}
''', []);
  }

  test_NativeCallable_listener_mustBeANativeFunctionType() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
void f(int i) => i * 2;
void g() {
  NativeCallable<void Function(int)>.listener(f);
}
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 56, 43),
    ]);
  }

  test_NativeCallable_listener_mustBeASubtype() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
void f(int i) => i * 2;
void g() {
  NativeCallable<Void Function(Double)>.listener(f);
}
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 103, 1),
    ]);
  }

  test_NativeCallable_listener_mustHaveTypeArgs() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
int f(int i) => i * 2;
void g() {
  NativeCallable.listener(f);
}
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 55, 23),
    ]);
  }

  test_NativeCallable_listener_mustReturnVoid() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
int f(int i) => i * 2;
void g() {
  NativeCallable<Int32 Function(Int32)>.listener(f);
}
''', [
      error(FfiCode.MUST_RETURN_VOID, 102, 1),
    ]);
  }

  test_NativeCallable_listener_ok() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
void f(int i) => i * 2;
void g() {
  NativeCallable<Void Function(Int32)>.listener(f);
}
''', []);
  }
}
