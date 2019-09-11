// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedClassTest);
  });
}

@reflectiveTest
class UndefinedClassTest extends DriverResolutionTest {
  test_instanceCreation() async {
    await assertErrorsInCode('''
f() { new C(); }
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 10, 1),
    ]);
  }

  test_variableDeclaration() async {
    await assertErrorsInCode('''
f() { C c; }
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 6, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 8, 1),
    ]);
  }
}
