// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidTypeArgumentForStructTest);
  });
}

@reflectiveTest
class InvalidTypeArgumentForStructTest extends DriverResolutionTest {
  test_invalid() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class A extends Struct<A> {}
class B extends Struct<A> {}
''', [
      error(FfiCode.INVALID_TYPE_ARGUMENT_FOR_STRUCT, 71, 1),
    ]);
  }
}
