// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NewWithInvalidTypeParametersTest);
  });
}

@reflectiveTest
class NewWithInvalidTypeParametersTest extends DriverResolutionTest {
  test_nonGeneric() async {
    await assertErrorsInCode('''
class A {}
f() { return new A<A>(); }
''', [
      error(StaticWarningCode.NEW_WITH_INVALID_TYPE_PARAMETERS, 28, 4),
    ]);
  }

  test_tooFew() async {
    await assertErrorsInCode('''
class A {}
class C<K, V> {}
f(p) {
  return new C<A>();
}
''', [
      error(StaticWarningCode.NEW_WITH_INVALID_TYPE_PARAMETERS, 48, 4),
    ]);
  }

  test_tooMany() async {
    await assertErrorsInCode('''
class A {}
class C<E> {}
f(p) {
  return new C<A, A>();
}
''', [
      error(StaticWarningCode.NEW_WITH_INVALID_TYPE_PARAMETERS, 45, 7),
    ]);
  }
}
