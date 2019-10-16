// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantTypeArgumentToPointerTest);
  });
}

@reflectiveTest
class NonConstantTypeArgumentToPointerTest extends DriverResolutionTest {
  test_asFunction_F() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
typedef R = int Function(int);
class C<T extends Function> {
  void f(Pointer<NativeFunction<T>> p) {
    p.asFunction<R>();
  }
}
''', [
      error(FfiCode.NON_NATIVE_FUNCTION_TYPE_ARGUMENT_TO_POINTER, 138, 1),
    ]);
  }
}
