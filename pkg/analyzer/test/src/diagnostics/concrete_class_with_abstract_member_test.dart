// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConcreteClassWithAbstractMemberTest);
  });
}

@reflectiveTest
class ConcreteClassWithAbstractMemberTest extends DriverResolutionTest {
  test_direct() async {
    await assertErrorsInCode('''
class A {
  m();
}''', [
      error(StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER, 12, 4),
    ]);
  }

  test_noSuchMethod_interface() async {
    await assertErrorsInCode('''
class I {
  noSuchMethod(v) => '';
}
class A implements I {
  m();
}''', [
      error(StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER, 62, 4),
    ]);
  }
}
