// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtraPositionalArgumentsCouldBeNamedTest);
    defineReflectiveTests(ExtraPositionalArgumentsTest);
  });
}

@reflectiveTest
class ExtraPositionalArgumentsCouldBeNamedTest extends DriverResolutionTest {
  test_functionExpressionInvocation() async {
    await assertErrorsInCode('''
main() {
  (int x, {int y}) {} (0, 1);
}
''', [
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED, 31,
          6),
    ]);
  }

  test_methodInvocation_topLevelFunction() async {
    await assertErrorsInCode('''
f({x, y}) {}
main() {
  f(0, 1, '2');
}
''', [
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED, 25,
          11),
    ]);
  }
}

@reflectiveTest
class ExtraPositionalArgumentsTest extends DriverResolutionTest {
  test_functionExpressionInvocation() async {
    await assertErrorsInCode('''
main() {
  (int x) {} (0, 1);
}
''', [
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 22, 6),
    ]);
  }

  test_methodInvocation_topLevelFunction() async {
    await assertErrorsInCode('''
f() {}
main() {
  f(0, 1, '2');
}
''', [
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 19, 11),
    ]);
  }
}
