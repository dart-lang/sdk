// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnTypeInvalidForThenTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ReturnTypeInvalidForThenTest extends PubPackageResolutionTest {
  test_dynamic_returnTypeIsUnrelatedFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(
    Future<int> future, Future<String> Function(dynamic, StackTrace) cb) {
  future.then<dynamic>((_) => 1, onError: cb);
}
''');
  }

  test_dynamic_unrelatedReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, String Function(dynamic, StackTrace) cb) {
  future.then<dynamic>((_) => 1, onError: cb);
}
''');
  }

  test_invalidReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, String Function(dynamic, StackTrace) cb) {
  future.then<int>((_) => 1, onError: cb);
//                                    ^^
// [diag.returnTypeInvalidForThen] The return type 'String' isn't assignable to 'FutureOr<int>', as required by 'Future.then'.
}
''');
  }

  test_nullableReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, int? Function(dynamic, StackTrace) cb) {
  future.then((_) => 1, onError: cb);
//                               ^^
// [diag.returnTypeInvalidForThen] The return type 'int?' isn't assignable to 'FutureOr<int>', as required by 'Future.then'.
}
''');
  }

  test_returnTypeIsFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, Future<int> Function(dynamic, StackTrace) cb) {
  future.then<int>((_) => 1, onError: cb);
}
''');
  }

  test_returnTypeIsFutureOr() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
void f(Future<int> future, FutureOr<int> Function(dynamic, StackTrace) cb) {
  future.then<int>((_) => 1, onError: cb);
}
''');
  }

  test_returnTypeIsVoid_int() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, void Function(dynamic, StackTrace) cb) {
  future.then<int>((_) => 1, onError: cb);
//                                    ^^
// [diag.returnTypeInvalidForThen] The return type 'void' isn't assignable to 'FutureOr<int>', as required by 'Future.then'.
}
''');
  }

  test_returnTypeIsVoid_nullableInt() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, void Function(dynamic, StackTrace) cb) {
  future.then<int?>((_) => 1, onError: cb);
}
''');
  }

  test_sameReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, int Function(dynamic, StackTrace) cb) {
  future.then<int>((_) => 1, onError: cb);
}
''');
  }

  test_void_returnTypeIsUnrelatedFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future, Future<String> Function(dynamic, StackTrace) cb) {
  future.then<void>((_) => 1, onError: cb);
}
''');
  }

  test_void_unrelatedReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future, String Function(dynamic, StackTrace) cb) {
  future.then<void>((_) => 1, onError: cb);
}
''');
  }
}
