// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.g.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessarySetLiteralTest);
  });
}

@reflectiveTest
class UnnecessarySetLiteralTest extends PubPackageResolutionTest {
  test_blockFunctionBody() async {
    await assertNoErrorsInCode(r'''
void g(void Function() fun) {}

void f() {
  g(() {1;});
}
''');
  }

  test_expressionFunctionBody_dynamic() async {
    await assertNoErrorsInCode(r'''
void g(Function() fun) {}

void f() {
  g(() => {1});
}
''');
  }

  test_expressionFunctionBody_future() async {
    await assertNoErrorsInCode(r'''
void g(Future Function() fun) {}

void f() {
  g(() async => {1});
}
''');
  }

  test_expressionFunctionBody_future_object() async {
    await assertNoErrorsInCode(r'''
void g(Future<Object> Function() fun) {}

void f() {
  g(() async => {1});
}
''');
  }

  test_expressionFunctionBody_future_void() async {
    await assertErrorsInCode(r'''
void g(Future<void> Function() fun) {}

void f() {
  g(() async => {1});
}
''', [
      error(WarningCode.UNNECESSARY_SET_LITERAL, 67, 3),
    ]);
  }

  test_expressionFunctionBody_futureOr() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';

void g(FutureOr Function() fun) {}

void f() {
  g(() async => {1});
}
''');
  }

  test_expressionFunctionBody_futureOr_object() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';

void g(FutureOr<Object> Function() fun) {}

void f() {
  g(() async => {1});
}
''');
  }

  test_expressionFunctionBody_futureOr_void() async {
    await assertErrorsInCode(r'''
import 'dart:async';

void g(FutureOr<void> Function() fun) {}

void f() {
  g(() async => {1});
}
''', [
      error(WarningCode.UNNECESSARY_SET_LITERAL, 91, 3),
    ]);
  }

  test_expressionFunctionBody_map() async {
    await assertNoErrorsInCode(r'''
void g(void Function() fun) {}

void f() {
  g(() => {1: 2});
}
''');
  }

  test_expressionFunctionBody_multipleElements() async {
    await assertErrorsInCode(r'''
void g(void Function() fun) {}

void f() {
  g(() => {1, 2});
}
''', [
      error(WarningCode.UNNECESSARY_SET_LITERAL, 53, 6),
    ]);
  }

  test_expressionFunctionBody_multipleElements_statements() async {
    await assertErrorsInCode(r'''
void g(void Function() fun) {}

void f(bool b) {
  g(() => {1, if (b) 2 else 3, 4, for (;;) 5},);
}
''', [
      error(WarningCode.UNNECESSARY_SET_LITERAL, 59, 35),
    ]);
  }

  test_expressionFunctionBody_object() async {
    await assertNoErrorsInCode(r'''
void g(Object Function() fun) {}

void f() {
  g(() => {1});
}
''');
  }

  test_expressionFunctionBody_statement() async {
    await assertErrorsInCode(r'''
void g(void Function(bool) fun) {}

void f() {
  g((value) => {if (value) print('')});
}
''', [
      error(WarningCode.UNNECESSARY_SET_LITERAL, 62, 22),
    ]);
  }

  test_expressionFunctionBody_void() async {
    await assertErrorsInCode(r'''
void g(void Function() fun) {}

void f() {
  g(() => {1});
}
''', [
      error(WarningCode.UNNECESSARY_SET_LITERAL, 53, 3),
    ]);
  }

  test_expressionFunctionBody_void_empty() async {
    await assertNoErrorsInCode(r'''
void g(void Function() fun) {}

void f() {
  g(() => {});
}
''');
  }

  test_functionDeclaration_dynamic() async {
    await assertNoErrorsInCode(r'''
f() => {1};
''');
  }

  test_functionDeclaration_future() async {
    await assertNoErrorsInCode(r'''
Future f() async => {1};
''');
  }

  test_functionDeclaration_future_object() async {
    await assertNoErrorsInCode(r'''
Future<Object> f() async => {1};
''');
  }

  test_functionDeclaration_future_void() async {
    await assertErrorsInCode(r'''
Future<void> f() async => {1};
''', [
      error(WarningCode.UNNECESSARY_SET_LITERAL, 26, 3),
    ]);
  }

  test_functionDeclaration_futureOr() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';

FutureOr f() async => {1};
''');
  }

  test_functionDeclaration_futureOr_object() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';

FutureOr<Object> f() async => {1};
''');
  }

  test_functionDeclaration_futureOr_void() async {
    await assertErrorsInCode(r'''
import 'dart:async';

FutureOr<void> f() async => {1};
''', [
      error(WarningCode.UNNECESSARY_SET_LITERAL, 50, 3),
    ]);
  }

  test_functionDeclaration_map() async {
    await assertNoErrorsInCode(r'''
void f() => {1: 2};
''');
  }

  test_functionDeclaration_multipleElements() async {
    await assertErrorsInCode(r'''
void f() => {1, 2};
''', [
      error(WarningCode.UNNECESSARY_SET_LITERAL, 12, 6),
    ]);
  }

  test_functionDeclaration_multipleElements_statements() async {
    await assertErrorsInCode(r'''
void f(bool b) => {1, if (b) 2 else 3, 4, for (;;) 5};
''', [
      error(WarningCode.UNNECESSARY_SET_LITERAL, 18, 35),
    ]);
  }

  test_functionDeclaration_object() async {
    await assertNoErrorsInCode(r'''
Object f() => {1};
''');
  }

  test_functionDeclaration_statement() async {
    await assertErrorsInCode(r'''
void f(bool value) => {if (value) print('')};
''', [
      error(WarningCode.UNNECESSARY_SET_LITERAL, 22, 22),
    ]);
  }

  test_functionDeclaration_void() async {
    await assertErrorsInCode(r'''
void f() => {1};
''', [
      error(WarningCode.UNNECESSARY_SET_LITERAL, 12, 3),
    ]);
  }
}
