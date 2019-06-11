// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryTypeCheckTrueTest);
  });
}

@reflectiveTest
class UnnecessaryTypeCheckTrueTest extends DriverResolutionTest {
  test_null_is_Null() async {
    await assertErrorsInCode(r'''
bool b = null is Null;
''', [
      error(HintCode.UNNECESSARY_TYPE_CHECK_TRUE, 9, 12),
    ]);
  }

  test_type_is_dynamic() async {
    await assertErrorsInCode(r'''
m(i) {
  bool b = i is dynamic;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 14, 1),
      error(HintCode.UNNECESSARY_TYPE_CHECK_TRUE, 18, 12),
    ]);
  }

  test_type_is_object() async {
    await assertErrorsInCode(r'''
m(i) {
  bool b = i is Object;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 14, 1),
      error(HintCode.UNNECESSARY_TYPE_CHECK_TRUE, 18, 11),
    ]);
  }
}
