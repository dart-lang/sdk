// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryTypeCheckFalseTest);
  });
}

@reflectiveTest
class UnnecessaryTypeCheckFalseTest extends DriverResolutionTest {
  test_null_not_Null() async {
    await assertErrorsInCode(r'''
bool b = null is! Null;
''', [HintCode.UNNECESSARY_TYPE_CHECK_FALSE]);
  }

  test_type_not_dynamic() async {
    await assertErrorsInCode(r'''
m(i) {
  bool b = i is! dynamic;
}
''', [HintCode.UNNECESSARY_TYPE_CHECK_FALSE]);
  }

  test_type_not_object() async {
    await assertErrorsInCode(r'''
m(i) {
  bool b = i is! Object;
}
''', [HintCode.UNNECESSARY_TYPE_CHECK_FALSE]);
  }
}
