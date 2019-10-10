// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldInStructWithInitializerTest);
  });
}

@reflectiveTest
class FieldInStructWithInitializerTest extends DriverResolutionTest {
  test_withInitializer() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C extends Struct<C> {
  Pointer p = null;
}
''', [
      error(HintCode.FIELD_IN_STRUCT_WITH_INITIALIZER, 57, 1),
    ]);
  }

  test_withoutInitializer() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
class C extends Struct<C> {
  Pointer p;
}
''');
  }
}
