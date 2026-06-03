// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  test_NativeCallable_isolateLocal_argumentMustBeAConstant() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
int f(int i) => i * 2;
void g() {
  int e = 123;
  NativeCallable<Int32 Function(Int32)>.isolateLocal(f, exceptionalReturn: e);
//                                                                         ^
// [diag.argumentMustBeAConstant] Argument 'exceptionalReturn' must be a constant.
}
''');
  }

  test_NativeCallable_isolateLocal_exceptionMustBeASubtype() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
int f(int i) => i * 2;
void g() {
  NativeCallable<Int32 Function(Int32)>.isolateLocal(f, exceptionalReturn: '?');
//                                                                         ^^^
// [diag.mustBeASubtype] The type 'String' must be a subtype of 'Int32' for 'isolateLocal'.
}
''');
  }

  test_NativeCallable_isolateLocal_inferred() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
int f(int i) => i * 2;
void g() {
  NativeCallable<Int32 Function(Int32)>? callback;
  callback = NativeCallable.isolateLocal(f, exceptionalReturn: 4);
  callback.close();
}
''');
  }

  test_NativeCallable_isolateLocal_invalidExceptionValue() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
void f(int i) => i * 2;
void g() {
  NativeCallable<Void Function(Int32)>.isolateLocal(f, exceptionalReturn: 4);
//                                                     ^^^^^^^^^^^^^^^^^^^^
// [diag.invalidExceptionValue] The method isolateLocal can't have an exceptional return value (the second argument) when the return type of the function is either 'void', 'Handle' or 'Pointer'.
}
''');
  }

  test_NativeCallable_isolateLocal_missingExceptionValue() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
int f(int i) => i * 2;
void g() {
  NativeCallable<Int32 Function(Int32)>.isolateLocal(f);
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.missingExceptionValue] The method isolateLocal must have an exceptional return value (the second argument) when the return type of the function is neither 'void', 'Handle', nor 'Pointer'.
}
''');
  }

  test_NativeCallable_isolateLocal_mustBeANativeFunctionType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
int f(int i) => i * 2;
void g() {
  NativeCallable<int Function(int)>.isolateLocal(f, exceptionalReturn: 4);
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.mustBeANativeFunctionType] The type 'int Function(int)' given to 'NativeCallable' must be a valid 'dart:ffi' native function type.
}
''');
  }

  test_NativeCallable_isolateLocal_mustBeASubtype() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
int f(int i) => i * 2;
void g() {
  NativeCallable<Int32 Function(Double)>.isolateLocal(f, exceptionalReturn: 4);
//                                                    ^
// [diag.mustBeASubtype] The type 'int Function(int)' must be a subtype of 'Int32 Function(Double)' for 'NativeCallable'.
}
''');
  }

  test_NativeCallable_isolateLocal_mustHaveTypeArgs() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
int f(int i) => i * 2;
void g() {
  NativeCallable.isolateLocal(f, exceptionalReturn: 4);
//^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.mustBeANativeFunctionType] The type 'Function' given to 'NativeCallable' must be a valid 'dart:ffi' native function type.
}
''');
  }

  test_NativeCallable_isolateLocal_ok() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
int f(int i) => i * 2;
void g() {
  NativeCallable<Int32 Function(Int32)>.isolateLocal(f, exceptionalReturn: 4);
}
''');
  }

  test_NativeCallable_isolateLocal_okVoid() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
void f(int i) => i * 2;
void g() {
  NativeCallable<Void Function(Int32)>.isolateLocal(f);
}
''');
  }

  test_NativeCallable_isolateLocal_voidReturnPermissive() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
int f(int i) => i * 2;
void g() {
  NativeCallable<Void Function(Int32)>.isolateLocal(f);
}
''');
  }

  test_NativeCallable_listener_inferred() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
void f(int i) => i * 2;
void g() {
  NativeCallable<Void Function(Int32)>? callback;
  callback = NativeCallable.listener(f);
  callback.close();
}
''');
  }

  test_NativeCallable_listener_mustBeANativeFunctionType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
void f(int i) => i * 2;
void g() {
  NativeCallable<void Function(int)>.listener(f);
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.mustBeANativeFunctionType] The type 'void Function(int)' given to 'NativeCallable' must be a valid 'dart:ffi' native function type.
}
''');
  }

  test_NativeCallable_listener_mustBeASubtype() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
void f(int i) => i * 2;
void g() {
  NativeCallable<Void Function(Double)>.listener(f);
//                                               ^
// [diag.mustBeASubtype] The type 'void Function(int)' must be a subtype of 'Void Function(Double)' for 'NativeCallable'.
}
''');
  }

  test_NativeCallable_listener_mustHaveTypeArgs() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
int f(int i) => i * 2;
void g() {
  NativeCallable.listener(f);
//^^^^^^^^^^^^^^^^^^^^^^^
// [diag.mustBeANativeFunctionType] The type 'Function' given to 'NativeCallable' must be a valid 'dart:ffi' native function type.
}
''');
  }

  test_NativeCallable_listener_mustReturnVoid() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
int f(int i) => i * 2;
void g() {
  NativeCallable<Int32 Function(Int32)>.listener(f);
//                                               ^
// [diag.mustReturnVoid] The return type of the function passed to 'NativeCallable.listener' must be 'void' rather than 'Int32'.
}
''');
  }

  test_NativeCallable_listener_ok() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
void f(int i) => i * 2;
void g() {
  NativeCallable<Void Function(Int32)>.listener(f);
}
''');
  }

  test_NativeCallable_listener_voidReturnPermissive() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
int f(int i) => i * 2;
void g() {
  NativeCallable<Void Function(Int32)>.listener(f);
}
''');
  }
}
