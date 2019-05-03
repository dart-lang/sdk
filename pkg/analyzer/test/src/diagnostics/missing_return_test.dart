// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/package_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingReturnTest);
  });
}

@reflectiveTest
class MissingReturnTest extends DriverResolutionTest with PackageMixin {
  test_alwaysThrows() async {
    addMetaPackage();
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@alwaysThrows
void a() {
  throw 'msg';
}

int f() {
  a();
}''');
  }

  test_async() async {
    await assertErrorCodesInCode(r'''
import 'dart:async';
Future<int> f() async {}
''', [HintCode.MISSING_RETURN]);
  }

  test_async_futureOrVoid() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';
FutureOr<void> f(Future f) async {}
''');
  }

  test_async_futureVoid() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';
Future<void> f() async {}
''');
  }

  test_emptyFunctionBody() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  int m();
}''');
  }

  test_expressionFunctionBody() async {
    await assertNoErrorsInCode(r'''
int f() => 0;
''');
  }

  test_factory() async {
    await assertErrorCodesInCode(r'''
class A {
  factory A() {}
}
''', [HintCode.MISSING_RETURN]);
  }

  test_function() async {
    await assertErrorCodesInCode(r'''
int f() {}
''', [HintCode.MISSING_RETURN]);
  }

  test_method() async {
    await assertErrorCodesInCode(r'''
class A {
  int m() {}
}''', [HintCode.MISSING_RETURN]);
  }

  test_method_inferred() async {
    await assertErrorCodesInCode(r'''
abstract class A {
  int m();
}
class B extends A {
  m() {}
}
''', [HintCode.MISSING_RETURN]);
  }

  test_noReturnType() async {
    await assertNoErrorsInCode(r'''
f() {}
''');
  }

  test_voidReturnType() async {
    await assertNoErrorsInCode(r'''
void f() {}
''');
  }
}
