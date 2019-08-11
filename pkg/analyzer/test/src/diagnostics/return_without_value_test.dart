// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnWithoutValueTest);
  });
}

@reflectiveTest
class ReturnWithoutValueTest extends DriverResolutionTest {
  test_async() async {
    await assertErrorsInCode('''
import 'dart:async';
Future<int> f() async {
  return;
}
''', [
      error(StaticWarningCode.RETURN_WITHOUT_VALUE, 47, 7),
    ]);
  }

  test_async_future_object_with_return() async {
    await assertErrorsInCode('''
import 'dart:async';
Future<Object> f() async {
  return;
}
''', [
      error(StaticWarningCode.RETURN_WITHOUT_VALUE, 50, 7),
    ]);
  }

  test_factoryConstructor() async {
    await assertErrorsInCode('''
class A { factory A() { return; } }
''', [
      error(StaticWarningCode.RETURN_WITHOUT_VALUE, 24, 7),
    ]);
  }

  test_function() async {
    await assertErrorsInCode('''
int f() { return; }
''', [
      error(StaticWarningCode.RETURN_WITHOUT_VALUE, 10, 7),
    ]);
  }

  test_localFunction() async {
    await assertErrorsInCode('''
class C {
  m(int x) {
    return (int y) {
      if (y < 0) {
        return;
      }
      return 0;
    };
  }
}
''', [
      error(StaticWarningCode.RETURN_WITHOUT_VALUE, 71, 7),
    ]);
  }

  test_method() async {
    await assertErrorsInCode('''
class A { int m() { return; } }
''', [
      error(StaticWarningCode.RETURN_WITHOUT_VALUE, 20, 7),
    ]);
  }

  test_multipleInconsistentReturns() async {
    // Tests that only the RETURN_WITHOUT_VALUE warning is created, and no
    // MIXED_RETURN_TYPES are created.
    await assertErrorsInCode('''
int f(int x) {
  if (x < 0) {
    return 1;
  }
  return;
}
''', [
      error(StaticWarningCode.RETURN_WITHOUT_VALUE, 50, 7),
    ]);
  }

  test_Null() async {
    // Test that block bodied functions with return type Null and an empty
    // return cause a static warning.
    await assertNoErrorsInCode('''
Null f() {
  return;
}
''');
  }
}
