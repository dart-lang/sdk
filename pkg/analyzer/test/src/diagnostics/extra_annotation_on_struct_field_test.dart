// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtraAnnotationOnStructFieldTest);
  });
}

@reflectiveTest
class ExtraAnnotationOnStructFieldTest extends DriverResolutionTest {
  test_one() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
class C extends Struct {
  @Int32() int x;
}
''');
  }

  test_two() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C extends Struct {
  @Int32() @Int16() int x;
}
''', [
      error(FfiCode.EXTRA_ANNOTATION_ON_STRUCT_FIELD, 55, 8),
    ]);
  }
}
