// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnTypeInvalidForCatchErrorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ReturnTypeInvalidForCatchErrorTest extends PubPackageResolutionTest {
  test_dynamic_returnTypeIsUnrelatedFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(
    Future<dynamic> future, Future<String> Function(dynamic, StackTrace) cb) {
  future.catchError(cb);
}
''');
  }

  test_dynamic_unrelatedReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<dynamic> future, String Function(dynamic, StackTrace) cb) {
  future.catchError(cb);
}
''');
  }

  test_invalidReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, String Function(dynamic, StackTrace) cb) {
  future.catchError(cb);
//                  ^^
// [diag.returnTypeInvalidForCatchError] The return type 'String' isn't assignable to 'FutureOr<int>', as required by 'Future.catchError'.
}
''');
  }

  test_Null_returnTypeIsVoid() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<Null> future, void Function(dynamic, StackTrace) cb) {
  future.catchError(cb);
}
''');
  }

  test_nullableReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, String? Function(dynamic, StackTrace) cb) {
  future.catchError(cb);
//                  ^^
// [diag.returnTypeInvalidForCatchError] The return type 'String?' isn't assignable to 'FutureOr<int>', as required by 'Future.catchError'.
}
''');
  }

  test_returnTypeIsFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, Future<int> Function(dynamic, StackTrace) cb) {
  future.catchError(cb);
}
''');
  }

  test_returnTypeIsFutureOr() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
void f(Future<int> future, FutureOr<int> Function(dynamic, StackTrace) cb) {
  future.catchError(cb);
}
''');
  }

  test_sameReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, int Function(dynamic, StackTrace) cb) {
  future.catchError(cb);
}
''');
  }

  test_void_returnTypeIsUnrelatedFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future, Future<String> Function(dynamic, StackTrace) cb) {
  future.catchError(cb);
}
''');
  }

  test_void_unrelatedReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future, String Function(dynamic, StackTrace) cb) {
  future.catchError(cb);
}
''');
  }
}
