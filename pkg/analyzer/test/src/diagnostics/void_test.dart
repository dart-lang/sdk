// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VoidTest);
  });
}

@reflectiveTest
class VoidTest extends DriverResolutionTest {
  test_void_with_type_parameters() async {
    await assertErrorsInCode('''
void<int> f() {}
''', [
      error(ParserErrorCode.VOID_WITH_TYPE_PARAMETERS, 4, 1),
    ]);
  }

  test_void_with_no_type_parameters() async {
    await assertErrorsInCode('''
void f() {}
''', []);
  }
}
