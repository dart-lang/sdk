// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixedReturnTypesTest);
  });
}

@reflectiveTest
class MixedReturnTypesTest extends DriverResolutionTest {
  test_method() async {
    await assertErrorsInCode('''
class C {
  m(int x) {
    if (x < 0) {
      return;
    }
    return 0;
  }
}
''', [
      error(StaticWarningCode.MIXED_RETURN_TYPES, 46, 6),
      error(StaticWarningCode.MIXED_RETURN_TYPES, 64, 6),
    ]);
  }

  test_topLevelFunction() async {
    await assertErrorsInCode('''
f(int x) {
  if (x < 0) {
    return;
  }
  return 0;
}
''', [
      error(StaticWarningCode.MIXED_RETURN_TYPES, 30, 6),
      error(StaticWarningCode.MIXED_RETURN_TYPES, 44, 6),
    ]);
  }
}
