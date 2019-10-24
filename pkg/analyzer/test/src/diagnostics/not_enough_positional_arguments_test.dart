// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotEnoughPositionalArgumentsTest);
  });
}

@reflectiveTest
class NotEnoughPositionalArgumentsTest extends DriverResolutionTest {
  test_functionExpression() async {
    await assertErrorsInCode('''
main() {
  (int x) {} ();
}''', [
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS, 22, 2),
    ]);
  }

  test_functionInvocation() async {
    await assertErrorsInCode('''
f(int a, String b) {}
main() {
  f();
}''', [
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS, 34, 2),
    ]);
  }

  test_getterReturningFunction() async {
    await assertErrorsInCode('''
typedef Getter(self);
Getter getter = (x) => x;
main() {
  getter();
}''', [
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS, 65, 2),
    ]);
  }
}
