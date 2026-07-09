// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessarySetLiteralTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnnecessarySetLiteralTest extends PubPackageResolutionTest {
  test_blockFunctionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
void g(void Function() fun) {}

void f() {
  g(() {1;});
}
''');
  }

  test_expressionFunctionBody_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
void g(Function() fun) {}

void f() {
  g(() => {1});
}
''');
  }

  test_expressionFunctionBody_future() async {
    await resolveTestCodeWithDiagnostics(r'''
void g(Future Function() fun) {}

void f() {
  g(() async => {1});
}
''');
  }

  test_expressionFunctionBody_future_object() async {
    await resolveTestCodeWithDiagnostics(r'''
void g(Future<Object> Function() fun) {}

void f() {
  g(() async => {1});
}
''');
  }

  test_expressionFunctionBody_future_void() async {
    await resolveTestCodeWithDiagnostics(r'''
void g(Future<void> Function() fun) {}

void f() {
  g(() async => {1});
//              ^^^
// [diag.unnecessarySetLiteral] Braces unnecessarily wrap this expression in a set literal.
}
''');
  }

  test_expressionFunctionBody_futureOr() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

void g(FutureOr Function() fun) {}

void f() {
  g(() async => {1});
}
''');
  }

  test_expressionFunctionBody_futureOr_object() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

void g(FutureOr<Object> Function() fun) {}

void f() {
  g(() async => {1});
}
''');
  }

  test_expressionFunctionBody_futureOr_void() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

void g(FutureOr<void> Function() fun) {}

void f() {
  g(() async => {1});
//              ^^^
// [diag.unnecessarySetLiteral] Braces unnecessarily wrap this expression in a set literal.
}
''');
  }

  test_expressionFunctionBody_map() async {
    await resolveTestCodeWithDiagnostics(r'''
void g(void Function() fun) {}

void f() {
  g(() => {1: 2});
}
''');
  }

  test_expressionFunctionBody_multipleElements() async {
    await resolveTestCodeWithDiagnostics(r'''
void g(void Function() fun) {}

void f() {
  g(() => {1, 2});
//        ^^^^^^
// [diag.unnecessarySetLiteral] Braces unnecessarily wrap this expression in a set literal.
}
''');
  }

  test_expressionFunctionBody_multipleElements_statements() async {
    await resolveTestCodeWithDiagnostics(r'''
void g(void Function() fun) {}

void f(bool b) {
  g(() => {1, if (b) 2 else 3, 4, for (;;) 5},);
//        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.unnecessarySetLiteral] Braces unnecessarily wrap this expression in a set literal.
}
''');
  }

  test_expressionFunctionBody_object() async {
    await resolveTestCodeWithDiagnostics(r'''
void g(Object Function() fun) {}

void f() {
  g(() => {1});
}
''');
  }

  test_expressionFunctionBody_statement() async {
    await resolveTestCodeWithDiagnostics(r'''
void g(void Function(bool) fun) {}

void f() {
  g((value) => {if (value) print('')});
//             ^^^^^^^^^^^^^^^^^^^^^^
// [diag.unnecessarySetLiteral] Braces unnecessarily wrap this expression in a set literal.
}
''');
  }

  test_expressionFunctionBody_void() async {
    await resolveTestCodeWithDiagnostics(r'''
void g(void Function() fun) {}

void f() {
  g(() => {1});
//        ^^^
// [diag.unnecessarySetLiteral] Braces unnecessarily wrap this expression in a set literal.
}
''');
  }

  test_expressionFunctionBody_void_empty() async {
    await resolveTestCodeWithDiagnostics(r'''
void g(void Function() fun) {}

void f() {
  g(() => {});
}
''');
  }

  test_functionDeclaration_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
f() => {1};
''');
  }

  test_functionDeclaration_future() async {
    await resolveTestCodeWithDiagnostics(r'''
Future f() async => {1};
''');
  }

  test_functionDeclaration_future_object() async {
    await resolveTestCodeWithDiagnostics(r'''
Future<Object> f() async => {1};
''');
  }

  test_functionDeclaration_future_void() async {
    await resolveTestCodeWithDiagnostics(r'''
Future<void> f() async => {1};
//                        ^^^
// [diag.unnecessarySetLiteral] Braces unnecessarily wrap this expression in a set literal.
''');
  }

  test_functionDeclaration_futureOr() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

FutureOr f() async => {1};
''');
  }

  test_functionDeclaration_futureOr_object() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

FutureOr<Object> f() async => {1};
''');
  }

  test_functionDeclaration_futureOr_void() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';

FutureOr<void> f() async => {1};
//                          ^^^
// [diag.unnecessarySetLiteral] Braces unnecessarily wrap this expression in a set literal.
''');
  }

  test_functionDeclaration_map() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() => {1: 2};
''');
  }

  test_functionDeclaration_multipleElements() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() => {1, 2};
//          ^^^^^^
// [diag.unnecessarySetLiteral] Braces unnecessarily wrap this expression in a set literal.
''');
  }

  test_functionDeclaration_multipleElements_statements() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool b) => {1, if (b) 2 else 3, 4, for (;;) 5};
//                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.unnecessarySetLiteral] Braces unnecessarily wrap this expression in a set literal.
''');
  }

  test_functionDeclaration_object() async {
    await resolveTestCodeWithDiagnostics(r'''
Object f() => {1};
''');
  }

  test_functionDeclaration_statement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool value) => {if (value) print('')};
//                    ^^^^^^^^^^^^^^^^^^^^^^
// [diag.unnecessarySetLiteral] Braces unnecessarily wrap this expression in a set literal.
''');
  }

  test_functionDeclaration_void() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() => {1};
//          ^^^
// [diag.unnecessarySetLiteral] Braces unnecessarily wrap this expression in a set literal.
''');
  }
}
