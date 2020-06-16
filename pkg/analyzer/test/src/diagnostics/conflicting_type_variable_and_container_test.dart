// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConflictingTypeVariableAndClassTest);
    defineReflectiveTests(ConflictingTypeVariableAndExtensionTest);
  });
}

@reflectiveTest
class ConflictingTypeVariableAndClassTest extends DriverResolutionTest {
  test_conflict_on_class() async {
    await assertErrorsInCode(r'''
class T<T> {}
''', [
      error(CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_CLASS, 8, 1),
    ]);
  }

  test_conflict_on_mixin() async {
    await assertErrorsInCode(r'''
mixin T<T> {}
''', [
      error(CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_CLASS, 8, 1),
    ]);
  }
}

@reflectiveTest
class ConflictingTypeVariableAndExtensionTest extends DriverResolutionTest {
  test_conflict() async {
    await assertErrorsInCode(r'''
extension T<T> on String {}
''', [
      error(
          CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_EXTENSION, 12, 1),
    ]);
  }
}
