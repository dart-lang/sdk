// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MismatchedGetterAndSetterTypesTest);
  });
}

@reflectiveTest
class MismatchedGetterAndSetterTypesTest extends DriverResolutionTest {
  test_topLevel() async {
    await assertErrorsInCode('''
int get g { return 0; }
set g(String v) {}''', [
      error(StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES, 0, 23),
    ]);
  }
}
