// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForInOfInvalidTypeTest);
  });
}

@reflectiveTest
class ForInOfInvalidTypeTest extends DriverResolutionTest {
  test_await_notStream() async {
    await assertErrorsInCode('''
f() async {
  await for (var i in true) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 29, 1),
      error(StaticTypeWarningCode.FOR_IN_OF_INVALID_TYPE, 34, 4),
    ]);
  }

  test_notIterable() async {
    await assertErrorsInCode('''
f() {
  for (var i in true) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
      error(StaticTypeWarningCode.FOR_IN_OF_INVALID_TYPE, 22, 4),
    ]);
  }
}
