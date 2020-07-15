// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceMemberAccessFromFactoryTest);
  });
}

@reflectiveTest
class InstanceMemberAccessFromFactoryTest extends DriverResolutionTest {
  test_named() async {
    await assertErrorsInCode(r'''
class A {
  m() {}
  A();
  factory A.make() {
    m();
    return new A();
  }
}
''', [
      error(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY, 51, 1),
    ]);
  }

  test_unnamed() async {
    await assertErrorsInCode(r'''
class A {
  m() {}
  A._();
  factory A() {
    m();
    return new A._();
  }
}
''', [
      error(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY, 48, 1),
    ]);
  }
}
