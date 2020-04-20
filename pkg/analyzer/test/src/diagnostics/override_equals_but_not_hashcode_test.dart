// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OverrideEqualsButNotHashCodeTest);
  });
}

@reflectiveTest
class OverrideEqualsButNotHashCodeTest extends DriverResolutionTest {
  test_overrideBoth() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator ==(x) { return x; }
  get hashCode => 0;
}''');
  }

  @failingTest
  test_overrideEquals_andNotHashCode() async {
    await assertErrorsInCode(r'''
class A {
  bool operator ==(x) {}
}''', [
      error(HintCode.OVERRIDE_EQUALS_BUT_NOT_HASH_CODE, 6, 1),
    ]);
  }
}
