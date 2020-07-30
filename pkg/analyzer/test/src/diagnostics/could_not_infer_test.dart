// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CouldNotInferTest);
  });
}

@reflectiveTest
class CouldNotInferTest extends DriverResolutionTest {
  test_function() async {
    await assertErrorsInCode(r'''
T f<T>(T t) => null;
main() { f(<S>(S s) => s); }
''', [
      error(CompileTimeErrorCode.COULD_NOT_INFER, 30, 1),
    ]);
  }

  test_functionType() async {
    await assertErrorsInCode(r'''
T Function<T>(T) f;
main() { f(<S>(S s) => s); }
''', [
      error(CompileTimeErrorCode.COULD_NOT_INFER, 29, 1),
    ]);
  }

  test_method() async {
    await assertErrorsInCode(r'''
class C {
  T f<T>(T t) => null;
}
main() { new C().f(<S>(S s) => s); }
''', [
      error(CompileTimeErrorCode.COULD_NOT_INFER, 52, 1),
    ]);
  }
}
