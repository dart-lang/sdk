// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonGenerativeConstructorTest);
  });
}

@reflectiveTest
class NonGenerativeConstructorTest extends DriverResolutionTest {
  test_explicit() async {
    await assertErrorsInCode(r'''
class A {
  factory A.named() => null;
}
class B extends A {
  B() : super.named();
}
''', [
      error(CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR, 69, 13),
    ]);
  }

  test_implicit() async {
    await assertErrorsInCode(r'''
class A {
  factory A() => null;
}
class B extends A {
  B();
}
''', [
      error(CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR, 57, 1),
    ]);
  }

  test_implicit2() async {
    await assertErrorsInCode(r'''
class A {
  factory A() => null;
}
class B extends A {
}
''', [
      error(CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR, 41, 1),
    ]);
  }
}
