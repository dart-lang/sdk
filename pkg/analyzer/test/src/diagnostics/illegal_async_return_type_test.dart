// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IllegalAsyncReturnTypeTest);
  });
}

@reflectiveTest
class IllegalAsyncReturnTypeTest extends DriverResolutionTest {
  test_function_nonFuture() async {
    await assertErrorsInCode('''
int f() async {}
''', [
      error(StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE, 0, 3),
    ]);
  }

  test_function_nonFuture_void() async {
    await assertNoErrorsInCode('''
void f() async {}
''');
  }

  test_function_nonFuture_withReturn() async {
    await assertErrorsInCode('''
int f() async {
  return 2;
}
''', [
      error(StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE, 0, 3),
    ]);
  }

  test_function_subtypeOfFuture() async {
    await assertErrorsInCode('''
import 'dart:async';
abstract class SubFuture<T> implements Future<T> {}
SubFuture<int> f() async {
  return 0;
}
''', [
      error(StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE, 73, 14),
    ]);
  }

  test_method_nonFuture() async {
    await assertErrorsInCode('''
class C {
  int m() async {}
}
''', [
      error(StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE, 12, 3),
    ]);
  }

  test_method_nonFuture_void() async {
    await assertNoErrorsInCode('''
class C {
  void m() async {}
}
''');
  }

  test_method_subtypeOfFuture() async {
    await assertErrorsInCode('''
import 'dart:async';
abstract class SubFuture<T> implements Future<T> {}
class C {
  SubFuture<int> m() async {
    return 0;
  }
}
''', [
      error(StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE, 85, 14),
    ]);
  }
}
