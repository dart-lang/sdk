// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BodyMayCompleteNormallyCatchErrorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class BodyMayCompleteNormallyCatchErrorTest extends PubPackageResolutionTest {
  test_alwaysReturn() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future) {
  future.catchError((e, st) {
    return 7;
  });
}
''');
  }

  test_noReturn_futureOrVoidReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
void f(Future<FutureOr<void>> future) {
  future.catchError((e, st) {});
}
''');
  }

  test_noReturn_namedBeforePositional() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future) {
  future.catchError(test: (_) => false, (e, st) {});
//                                              ^
// [diag.bodyMightCompleteNormallyCatchError] This 'onError' handler must return a value assignable to 'int', but ends without returning a value.
}
''');
  }

  test_noReturn_nonNullableReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future) {
  future.catchError((e, st) {});
//                          ^
// [diag.bodyMightCompleteNormallyCatchError] This 'onError' handler must return a value assignable to 'int', but ends without returning a value.
}
''');
  }

  test_noReturn_nullableReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int?> future) {
  future.catchError((e, st) {});
//                          ^
// [diag.bodyMightCompleteNormallyCatchError] This 'onError' handler must return a value assignable to 'int?', but ends without returning a value.
}
''');
  }

  test_noReturn_nullReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<Null> future) {
  future.catchError((e, st) {});
}
''');
  }

  test_noReturn_voidReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.catchError((e, st) {});
}
''');
  }
}
