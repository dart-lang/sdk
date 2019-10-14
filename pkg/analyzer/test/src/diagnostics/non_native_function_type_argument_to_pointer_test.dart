// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonNativeFunctionTypeArgumentToPointerTest);
  });
}

@reflectiveTest
class NonNativeFunctionTypeArgumentToPointerTest extends DriverResolutionTest {
  test_asFunction() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
typedef R = int Function(int);
class C {
  void f(Pointer<Double> p) {
    p.asFunction<R>();
  }
}
''', [
      error(FfiCode.NON_NATIVE_FUNCTION_TYPE_ARGUMENT_TO_POINTER, 94, 1),
    ]);
  }
}
