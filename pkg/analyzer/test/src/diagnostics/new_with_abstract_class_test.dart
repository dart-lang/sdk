// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NewWithAbstractClassTest);
  });
}

@reflectiveTest
class NewWithAbstractClassTest extends DriverResolutionTest {
  test_generic() async {
    await assertErrorsInCode('''
abstract class A<E> {}
void f() {
  new A<int>();
}
''', [
      error(StaticWarningCode.NEW_WITH_ABSTRACT_CLASS, 40, 6),
    ]);

    assertType(findNode.instanceCreation('new A<int>'), 'A<int>');
  }

  test_nonGeneric() async {
    await assertErrorsInCode('''
abstract class A {}
void f() {
  new A();
}
''', [
      error(StaticWarningCode.NEW_WITH_ABSTRACT_CLASS, 37, 1),
    ]);
  }
}
