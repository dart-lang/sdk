// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstFormalParameterTest);
  });
}

@reflectiveTest
class ConstFormalParameterTest extends DriverResolutionTest {
  test_fieldFormalParameter() async {
    await assertErrorsInCode(r'''
class A {
  var x;
  A(const this.x) {}
}
''', [
      error(CompileTimeErrorCode.CONST_FORMAL_PARAMETER, 23, 12),
      error(ParserErrorCode.EXTRANEOUS_MODIFIER, 23, 5),
    ]);
  }

  test_simpleFormalParameter() async {
    await assertErrorsInCode('''
f(const x) {}
''', [
      error(CompileTimeErrorCode.CONST_FORMAL_PARAMETER, 2, 7),
      error(ParserErrorCode.EXTRANEOUS_MODIFIER, 2, 5),
    ]);
  }
}
