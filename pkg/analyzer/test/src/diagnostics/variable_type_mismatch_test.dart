// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VariableTypeMismatchTest);
  });
}

/// TODO(paulberry): move other tests from [CheckedModeCompileTimeErrorCodeTest]
/// to this class.
@reflectiveTest
class VariableTypeMismatchTest extends DriverResolutionTest {
  @FailingTest(reason: 'Workaround for #35993 is too broad')
  test_int_to_double_variable_reference_is_not_promoted() async {
    // Note: in the following code, the declaration of `y` should produce an
    // error because we should only promote literal ints to doubles; we
    // shouldn't promote the reference to the variable `x`.
    addTestFile('''
const Object x = 0;
const double y = x;
    ''');
    await resolveTestFile();
    assertTestErrors([CheckedModeCompileTimeErrorCode.VARIABLE_TYPE_MISMATCH]);
  }
}
