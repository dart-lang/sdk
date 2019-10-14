// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantTypeArgumentTest);
  });
}

@reflectiveTest
class NonConstantTypeArgumentTest extends DriverResolutionTest {
  test_asFunction_R() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
typedef T = int Function(int);
class C<R extends int Function(int)> {
  void f(Pointer<NativeFunction<T>> p) {
    p.asFunction<R>();
  }
}
''', [
      error(FfiCode.NON_CONSTANT_TYPE_ARGUMENT, 147, 1),
    ]);
  }

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
      error(FfiCode.NON_CONSTANT_TYPE_ARGUMENT, 110, 1),
    ]);
  }

  test_lookupFunction_F() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
typedef T = int Function(int);
class C<F extends int Function(int)> {
  void f(DynamicLibrary lib, NativeFunction x) {
    lib.lookupFunction<T, F>('g');
  }
}
''', [
      error(FfiCode.NON_CONSTANT_TYPE_ARGUMENT, 164, 1),
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
      error(FfiCode.NON_CONSTANT_TYPE_ARGUMENT, 152, 1),
    ]);
  }
}
