// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldInitializerFactoryConstructorTest);
  });
}

@reflectiveTest
class FieldInitializerFactoryConstructorTest extends DriverResolutionTest {
  test_fieldFormalParameter() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  factory A(this.x) => throw 0;
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_FACTORY_CONSTRUCTOR, 31, 6),
    ]);
  }

  test_functionTypedParameter() async {
    await assertErrorsInCode(r'''
class A {
  int Function() x;
  factory A(int this.x());
}
''', [
      // TODO(srawlins): Only report one error. Theoretically change Fasta to
      // report "Field initiailizer in factory constructor" as a parse error.
      error(CompileTimeErrorCode.FIELD_INITIALIZER_FACTORY_CONSTRUCTOR, 42, 12),
      error(ParserErrorCode.MISSING_FUNCTION_BODY, 55, 1),
    ]);
  }
}
