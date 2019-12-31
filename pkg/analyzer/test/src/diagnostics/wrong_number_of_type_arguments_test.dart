// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WrongNumberOfTypeArgumentsTest);
  });
}

@reflectiveTest
class WrongNumberOfTypeArgumentsTest extends DriverResolutionTest {
  test_const_nonGeneric() async {
    await assertErrorsInCode('''
class C {
  const C();
}

f() {
  return const C<int>();
}
''', [
      error(StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 47, 6),
    ]);
  }

  test_const_tooFew() async {
    await assertErrorsInCode('''
class C<K, V> {
  const C();
}

f() {
  return const C<int>();
}
''', [
      error(StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 53, 6),
    ]);
  }

  test_const_tooMany() async {
    await assertErrorsInCode('''
class C<E> {
  const C();
}

f() {
  return const C<int, int>();
}
''', [
      error(StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 50, 11),
    ]);
  }

  test_new_nonGeneric() async {
    await assertErrorsInCode('''
class C {}

f() {
  return new C<int>();
}
''', [
      error(StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 31, 6),
    ]);
  }

  test_new_tooFew() async {
    await assertErrorsInCode('''
class C<K, V> {}

f() {
  return new C<int>();
}
''', [
      error(StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 37, 6),
    ]);
  }

  test_new_tooMany() async {
    await assertErrorsInCode('''
class C<E> {}

f() {
  return new C<int, int>();
}
''', [
      error(StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 34, 11),
    ]);
  }
}
