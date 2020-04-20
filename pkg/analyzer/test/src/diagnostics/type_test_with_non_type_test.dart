// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeTestWithNonTypeTest);
  });
}

@reflectiveTest
class TypeTestWithNonTypeTest extends DriverResolutionTest {
  test_parameter() async {
    await assertErrorsInCode('''
var A = 0;
f(var p) {
  if (p is A) {
  }
}''', [
      error(StaticWarningCode.TYPE_TEST_WITH_NON_TYPE, 33, 1),
    ]);
  }
}
