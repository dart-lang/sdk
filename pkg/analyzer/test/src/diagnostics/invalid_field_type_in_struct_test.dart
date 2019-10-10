// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidFieldTypeInStructTest);
  });
}

@reflectiveTest
class InvalidFieldTypeInStructTest extends DriverResolutionTest {
  test_invalid() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C extends Struct<C> {
  String str;
}
''', [
      error(HintCode.INVALID_FIELD_TYPE_IN_STRUCT, 49, 6),
    ]);
  }

  test_valid() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
class C extends Struct<C> {
  Pointer p;
}
''');
  }
}
