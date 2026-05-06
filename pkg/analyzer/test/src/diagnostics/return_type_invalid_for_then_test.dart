// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnTypeInvalidForThenTest);
  });
}

@reflectiveTest
class ReturnTypeInvalidForThenTest extends PubPackageResolutionTest {
  test_dynamic_returnTypeIsUnrelatedFuture() async {
    await assertNoErrorsInCode('''
void f(
    Future<int> future, Future<String> Function(dynamic, StackTrace) cb) {
  future.then<dynamic>((_) => 1, onError: cb);
}
''');
  }

  test_dynamic_unrelatedReturnType() async {
    await assertNoErrorsInCode('''
void f(Future<int> future, String Function(dynamic, StackTrace) cb) {
  future.then<dynamic>((_) => 1, onError: cb);
}
''');
  }

  test_invalidReturnType() async {
    await assertErrorsInCode(
      '''
void f(Future<int> future, String Function(dynamic, StackTrace) cb) {
  future.then<int>((_) => 1, onError: cb);
}
''',
      [error(diag.returnTypeInvalidForThen, 108, 2)],
    );
  }

  test_nullableReturnType() async {
    await assertErrorsInCode(
      '''
void f(Future<int> future, int? Function(dynamic, StackTrace) cb) {
  future.then((_) => 1, onError: cb);
}
''',
      [error(diag.returnTypeInvalidForThen, 101, 2)],
    );
  }

  test_returnTypeIsFuture() async {
    await assertNoErrorsInCode('''
void f(Future<int> future, Future<int> Function(dynamic, StackTrace) cb) {
  future.then<int>((_) => 1, onError: cb);
}
''');
  }

  test_returnTypeIsFutureOr() async {
    await assertNoErrorsInCode('''
import 'dart:async';
void f(Future<int> future, FutureOr<int> Function(dynamic, StackTrace) cb) {
  future.then<int>((_) => 1, onError: cb);
}
''');
  }

  test_returnTypeIsVoid_int() async {
    await assertErrorsInCode(
      '''
void f(Future<int> future, void Function(dynamic, StackTrace) cb) {
  future.then<int>((_) => 1, onError: cb);
}
''',
      [error(diag.returnTypeInvalidForThen, 106, 2)],
    );
  }

  test_returnTypeIsVoid_nullableInt() async {
    await assertNoErrorsInCode('''
void f(Future<int> future, void Function(dynamic, StackTrace) cb) {
  future.then<int?>((_) => 1, onError: cb);
}
''');
  }

  test_sameReturnType() async {
    await assertNoErrorsInCode('''
void f(Future<int> future, int Function(dynamic, StackTrace) cb) {
  future.then<int>((_) => 1, onError: cb);
}
''');
  }

  test_void_returnTypeIsUnrelatedFuture() async {
    await assertNoErrorsInCode('''
void f(Future<void> future, Future<String> Function(dynamic, StackTrace) cb) {
  future.then<void>((_) => 1, onError: cb);
}
''');
  }

  test_void_unrelatedReturnType() async {
    await assertNoErrorsInCode('''
void f(Future<void> future, String Function(dynamic, StackTrace) cb) {
  future.then<void>((_) => 1, onError: cb);
}
''');
  }
}
