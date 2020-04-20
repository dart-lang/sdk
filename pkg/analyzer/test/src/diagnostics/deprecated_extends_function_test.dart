// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedExtendsFunctionTest);
  });
}

@reflectiveTest
class DeprecatedExtendsFunctionTest extends DriverResolutionTest {
  test_core() async {
    await assertErrorsInCode('''
class A extends Function {}
''', [
      error(HintCode.DEPRECATED_EXTENDS_FUNCTION, 16, 8),
    ]);
  }

  test_local() async {
    await assertErrorsInCode('''
class Function {}
class A extends Function {}
''', [
      error(HintCode.DEPRECATED_FUNCTION_CLASS_DECLARATION, 6, 8),
      error(HintCode.DEPRECATED_EXTENDS_FUNCTION, 34, 8),
    ]);
  }
}
