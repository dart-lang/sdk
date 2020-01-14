// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperInRedirectingConstructorTest);
  });
}

@reflectiveTest
class SuperInRedirectingConstructorTest extends DriverResolutionTest {
  test_redirectionSuper() async {
    await assertErrorsInCode(r'''
class A {}
class B {
  B() : this.name(), super();
  B.name() {}
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR, 42, 7),
    ]);
  }

  test_superRedirection() async {
    await assertErrorsInCode(r'''
class A {}
class B {
  B() : super(), this.name();
  B.name() {}
}
''', [
      error(StrongModeCode.INVALID_SUPER_INVOCATION, 29, 7),
      error(CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR, 29, 7),
    ]);
  }
}
