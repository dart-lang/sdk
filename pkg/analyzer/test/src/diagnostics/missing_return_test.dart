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
    await assertErrorsInCode(r'''
import 'dart:async';
Future<int> f() async {}
''', [
      error(HintCode.MISSING_RETURN, 33, 1),
    ]);
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
    await assertErrorsInCode(r'''
class A {
  factory A() {}
}
''', [
      error(HintCode.MISSING_RETURN, 12, 14),
    ]);
  }

  test_function() async {
    await assertErrorsInCode(r'''
int f() {}
''', [
      error(HintCode.MISSING_RETURN, 4, 1),
    ]);
  }

  test_functionExpression_declared() async {
    await assertErrorsInCode(r'''
main() {
  f() {} // no hint
}
''', [
      error(HintCode.UNUSED_ELEMENT, 11, 1),
    ]);
  }

  test_functionExpression_expression() async {
    await assertErrorsInCode(r'''
main() {
  int Function() f = () => null; // no hint
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 26, 1),
    ]);
  }

  test_functionExpression_futureOrDynamic() async {
    await assertErrorsInCode(r'''
import 'dart:async';
main() {
  FutureOr<dynamic> Function() f = () { print(42); };
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 61, 1),
    ]);
  }

  test_functionExpression_futureOrInt() async {
    await assertErrorsInCode(r'''
import 'dart:async';
main() {
  FutureOr<int> Function() f = () { print(42); };
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 57, 1),
      error(HintCode.MISSING_RETURN, 61, 17),
    ]);
  }

  test_functionExpression_inferred() async {
    await assertErrorsInCode(r'''
main() {
  int Function() f = () { print(42); };
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 26, 1),
      error(HintCode.MISSING_RETURN, 30, 17),
    ]);
  }

  test_functionExpression_inferred_dynamic() async {
    await assertErrorsInCode(r'''
main() {
  Function() f = () { print(42); }; // no hint
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 22, 1),
    ]);
  }

  test_functionExpressionAsync_inferred() async {
    await assertErrorsInCode(r'''
main() {
  Future<int> Function() f = () async { print(42); }; 
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 34, 1),
      error(HintCode.MISSING_RETURN, 38, 23),
    ]);
  }

  test_functionExpressionAsync_inferred_dynamic() async {
    await assertErrorsInCode(r'''
main() {
  Future Function() f = () async { print(42); }; // no hint
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 29, 1),
    ]);
  }

  test_method() async {
    await assertErrorsInCode(r'''
class A {
  int m() {}
}
''', [
      error(HintCode.MISSING_RETURN, 16, 1),
    ]);
  }

  test_method_annotation() async {
    await assertErrorsInCode(r'''
abstract class A {
  int m();
}
@override
class B extends A {
  m() {}
}
''', [
      error(HintCode.MISSING_RETURN, 64, 1),
    ]);
  }

  test_method_futureOrDynamic() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';
class A {
  FutureOr<dynamic> m() {}
}
''');
  }

  test_method_futureOrInt() async {
    await assertErrorsInCode(r'''
import 'dart:async';
class A {
  FutureOr<int> m() {}
}
''', [
      error(HintCode.MISSING_RETURN, 47, 1),
    ]);
  }

  test_method_inferred() async {
    await assertErrorsInCode(r'''
abstract class A {
  int m();
}
class B extends A {
  m() {}
}
''', [
      error(HintCode.MISSING_RETURN, 54, 1),
    ]);
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
