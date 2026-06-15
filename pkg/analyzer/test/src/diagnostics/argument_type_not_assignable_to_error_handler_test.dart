// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
      ArgumentTypeNotAssignableToErrorHandler_FutureCatchErrorTest,
    );
    defineReflectiveTests(
      ArgumentTypeNotAssignableToErrorHandler_FutureThenTest,
    );
    defineReflectiveTests(
      ArgumentTypeNotAssignableToErrorHandler_StreamHandleErrorTest,
    );
    defineReflectiveTests(
      ArgumentTypeNotAssignableToErrorHandler_StreamListenTest,
    );
    defineReflectiveTests(
      ArgumentTypeNotAssignableToErrorHandler_StreamSubscriptionOnErrorTest,
    );
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ArgumentTypeNotAssignableToErrorHandler_FutureCatchErrorTest
    extends PubPackageResolutionTest {
  void test_firstParameterIsDynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, Future<int> Function(dynamic a) callback) {
  future.catchError(callback);
}
''');
  }

  void test_firstParameterIsNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, Future<int> Function({Object a}) callback) {
  future.catchError(callback);
//                  ^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Future<int> Function({Object a})' can't be assigned to the parameter type 'FutureOr<int> Function(Object)' or 'FutureOr<int> Function(Object, StackTrace)'.
}
''');
  }

  void test_firstParameterIsOptional() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, Future<int> Function([Object a]) callback) {
  future.catchError(callback);
}
''');
  }

  void test_functionExpression_firstParameterIsDynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.catchError((dynamic a) {});
}
''');
  }

  void test_functionExpression_firstParameterIsImplicit() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.catchError((a) {});
}
''');
  }

  void test_functionExpression_firstParameterIsNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.catchError(({Object a = 1}) {});
//                  ^^^^^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Null Function({Object a})' can't be assigned to the parameter type 'FutureOr<void> Function(Object)' or 'FutureOr<void> Function(Object, StackTrace)'.
}
''');
  }

  void test_functionExpression_firstParameterIsNullableObject() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.catchError((Object? a) {});
}
''');
  }

  void test_functionExpression_firstParameterIsOptional() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.catchError(([Object a = 1]) {});
}
''');
  }

  void test_functionExpression_firstParameterIsUntyped() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.catchError((a) {});
}
''');
  }

  void test_functionExpression_noParameters() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.catchError(() {});
//                  ^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Null Function()' can't be assigned to the parameter type 'FutureOr<void> Function(Object)' or 'FutureOr<void> Function(Object, StackTrace)'.
}
''');
  }

  void test_functionExpression_secondParameterIsDynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.catchError((Object a, dynamic b) {});
}
''');
  }

  void test_functionExpression_secondParameterIsImplicit() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.catchError((Object a, b) {});
}
''');
  }

  void test_functionExpression_secondParameterIsNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.catchError((Object a, {required StackTrace b}) {});
//                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Null Function(Object, {required StackTrace b})' can't be assigned to the parameter type 'FutureOr<void> Function(Object)' or 'FutureOr<void> Function(Object, StackTrace)'.
}
''');
  }

  void test_functionExpression_secondParameterIsNullableStackTrace() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.catchError((Object a, StackTrace? b) {});
}
''');
  }

  void test_functionExpression_secondParameterIsUntyped() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.catchError((Object a, b) {});
}
''');
  }

  void test_functionExpression_tooManyParameters() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.catchError((a, b, c) {});
//                  ^^^^^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Null Function(dynamic, dynamic, dynamic)' can't be assigned to the parameter type 'FutureOr<void> Function(Object)' or 'FutureOr<void> Function(Object, StackTrace)'.
}
''');
  }

  void test_functionExpression_wrongFirstParameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.catchError((String a) {});
//                  ^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Null Function(String)' can't be assigned to the parameter type 'FutureOr<void> Function(Object)' or 'FutureOr<void> Function(Object, StackTrace)'.
}
''');
  }

  void test_functionExpression_wrongSecondParameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.catchError((Object a, String b) {});
//                  ^^^^^^^^^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Null Function(Object, String)' can't be assigned to the parameter type 'FutureOr<void> Function(Object)' or 'FutureOr<void> Function(Object, StackTrace)'.
}
''');
  }

  void test_noParameters() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, Future<int> Function() callback) {
  future.catchError(callback);
//                  ^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Future<int> Function()' can't be assigned to the parameter type 'FutureOr<int> Function(Object)' or 'FutureOr<int> Function(Object, StackTrace)'.
}
''');
  }

  void test_okType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, Future<int> Function(Object, StackTrace) callback) {
  future.catchError(callback);
}
''');
  }

  void test_secondParameterIsDynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, Future<int> Function(Object a, dynamic b) callback) {
  future.catchError(callback);
}
''');
  }

  void test_secondParameterIsNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, Future<int> Function(Object a, {StackTrace b}) callback) {
  future.catchError(callback);
//                  ^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Future<int> Function(Object, {StackTrace b})' can't be assigned to the parameter type 'FutureOr<int> Function(Object)' or 'FutureOr<int> Function(Object, StackTrace)'.
}
''');
  }

  void test_tooManyParameters() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, Future<int> Function(int, int, int) callback) {
  future.catchError(callback);
//                  ^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Future<int> Function(int, int, int)' can't be assigned to the parameter type 'FutureOr<int> Function(Object)' or 'FutureOr<int> Function(Object, StackTrace)'.
}
''');
  }

  void test_wrongFirstParameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, Future<int> Function(String) callback) {
  future.catchError(callback);
//                  ^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Future<int> Function(String)' can't be assigned to the parameter type 'FutureOr<int> Function(Object)' or 'FutureOr<int> Function(Object, StackTrace)'.
}
''');
  }

  void test_wrongSecondParameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, Future<int> Function(Object, String) callback) {
  future.catchError(callback);
//                  ^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Future<int> Function(Object, String)' can't be assigned to the parameter type 'FutureOr<int> Function(Object)' or 'FutureOr<int> Function(Object, StackTrace)'.
}
''');
  }
}

@reflectiveTest
class ArgumentTypeNotAssignableToErrorHandler_FutureThenTest
    extends PubPackageResolutionTest {
  void test_firstParameterIsDynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future, void Function(dynamic a) callback) {
  future.then((_) {}, onError: callback);
}
''');
  }

  void test_firstParameterIsNamed() async {
    // `void` must be specified explicitly on `then()`; the inferred type from
    // `() {}` would otherwise be `Null`, and `void` (or `Future<void>`, or
    // `Future<int>`) would be an illegal return type for the `onError` handler.
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future, Future<void> Function({Object a}) callback) {
  future.then<void>((_) {}, onError: callback);
//                                   ^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Future<void> Function({Object a})' can't be assigned to the parameter type 'FutureOr<void> Function(Object)' or 'FutureOr<void> Function(Object, StackTrace)'.
}
''');
  }

  void test_functionExpression_firstParameterIsNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.then((_) {}, onError: ({Object a = 1}) {});
//                             ^^^^^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Null Function({Object a})' can't be assigned to the parameter type 'FutureOr<Null> Function(Object)' or 'FutureOr<Null> Function(Object, StackTrace)'.
}
''');
  }

  void test_functionExpression_firstParameterIsNullableObject() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.then((_) {}, onError: (Object? a) {});
}
''');
  }

  void test_functionExpression_noParameters() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.then((_) {}, onError: () {});
//                             ^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Null Function()' can't be assigned to the parameter type 'FutureOr<Null> Function(Object)' or 'FutureOr<Null> Function(Object, StackTrace)'.
}
''');
  }

  void test_functionExpression_secondParameterIsNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.then((_) {}, onError: (Object a, {StackTrace? b}) {});
//                             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Null Function(Object, {StackTrace? b})' can't be assigned to the parameter type 'FutureOr<Null> Function(Object)' or 'FutureOr<Null> Function(Object, StackTrace)'.
}
''');
  }

  void test_functionExpression_secondParameterIsNullableStackTrace() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.then((_) {}, onError: (Object a, StackTrace? b) {});
}
''');
  }

  void test_functionExpression_wrongFirstParameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.then((_) {}, onError: (String a) {});
//                             ^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Null Function(String)' can't be assigned to the parameter type 'FutureOr<Null> Function(Object)' or 'FutureOr<Null> Function(Object, StackTrace)'.
}
''');
  }

  void test_functionType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future, Function callback) {
  future.then((_) {}, onError: callback);
}
''');
  }
}

@reflectiveTest
class ArgumentTypeNotAssignableToErrorHandler_StreamHandleErrorTest
    extends PubPackageResolutionTest {
  void test_firstParameterIsDynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Stream<void> stream, void Function(dynamic a) callback) {
  stream.handleError(callback);
}
''');
  }

  void test_firstParameterIsNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Stream<void> stream, Future<int> Function({Object a}) callback) {
  stream.handleError(callback);
//                   ^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Future<int> Function({Object a})' can't be assigned to the parameter type 'void Function(Object)' or 'void Function(Object, StackTrace)'.
}
''');
  }

  void test_functionExpression_firstParameterIsNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Stream<void> stream) {
  stream.handleError(({Object a = 1}) {});
//                   ^^^^^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Null Function({Object a})' can't be assigned to the parameter type 'void Function(Object)' or 'void Function(Object, StackTrace)'.
}
''');
  }

  void test_functionExpression_firstParameterIsNullableObject() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Stream<void> stream) {
  stream.handleError((Object? a) {});
}
''');
  }

  void test_functionExpression_noParameters() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Stream<void> stream) {
  stream.handleError(() {});
//                   ^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Null Function()' can't be assigned to the parameter type 'void Function(Object)' or 'void Function(Object, StackTrace)'.
}
''');
  }

  void test_functionExpression_secondParameterIsNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Stream<void> stream) {
  stream.handleError((Object a, {StackTrace? b}) {});
//                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Null Function(Object, {StackTrace? b})' can't be assigned to the parameter type 'void Function(Object)' or 'void Function(Object, StackTrace)'.
}
''');
  }

  void test_functionExpression_secondParameterIsNullableStackTrace() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Stream<void> stream) {
  stream.handleError((Object a, StackTrace? b) {});
}
''');
  }

  void test_functionExpression_wrongFirstParameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Stream<void> stream) {
  stream.handleError((String a) {});
//                   ^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Null Function(String)' can't be assigned to the parameter type 'void Function(Object)' or 'void Function(Object, StackTrace)'.
}
''');
  }
}

@reflectiveTest
class ArgumentTypeNotAssignableToErrorHandler_StreamListenTest
    extends PubPackageResolutionTest {
  void test_firstParameterIsDynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Stream<void> stream, void Function(dynamic a) callback) {
  stream.listen((_) {}, onError: callback);
}
''');
  }

  void test_firstParameterIsNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Stream<void> stream, Future<int> Function({Object a}) callback) {
  stream.listen((_) {}, onError: callback);
//                      ^^^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Future<int> Function({Object a})' can't be assigned to the parameter type 'void Function(Object)' or 'void Function(Object, StackTrace)'.
}
''');
  }

  void test_functionExpression_firstParameterIsNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Stream<void> stream) {
  stream.listen((_) {}, onError: ({Object a = 1}) {});
//                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Null Function({Object a})' can't be assigned to the parameter type 'void Function(Object)' or 'void Function(Object, StackTrace)'.
}
''');
  }

  void test_functionExpression_firstParameterIsNullableObject() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Stream<void> stream) {
  stream.listen((_) {}, onError: (Object? a) {});
}
''');
  }

  void test_functionExpression_noParameters() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Stream<void> stream) {
  stream.listen((_) {}, onError: () {});
//                      ^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Null Function()' can't be assigned to the parameter type 'void Function(Object)' or 'void Function(Object, StackTrace)'.
}
''');
  }

  void test_functionExpression_secondParameterIsNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Stream<void> stream) {
  stream.listen((_) {}, onError: (Object a, {StackTrace? b}) {});
//                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Null Function(Object, {StackTrace? b})' can't be assigned to the parameter type 'void Function(Object)' or 'void Function(Object, StackTrace)'.
}
''');
  }

  void test_functionExpression_secondParameterIsNullableStackTrace() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Stream<void> stream) {
  stream.listen((_) {}, onError: (Object a, StackTrace? b) {});
}
''');
  }

  void test_functionExpression_wrongFirstParameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Stream<void> stream) {
  stream.listen((_) {}, onError: (String a) {});
//                      ^^^^^^^^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Null Function(String)' can't be assigned to the parameter type 'void Function(Object)' or 'void Function(Object, StackTrace)'.
}
''');
  }
}

@reflectiveTest
class ArgumentTypeNotAssignableToErrorHandler_StreamSubscriptionOnErrorTest
    extends PubPackageResolutionTest {
  void test_firstParameterIsDynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
void f(
    StreamSubscription<void> subscription, void Function(dynamic a) callback) {
  subscription.onError(callback);
}
''');
  }

  void test_firstParameterIsNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
void f(
    StreamSubscription<void> subscription,
    Future<int> Function({Object a}) callback) {
  subscription.onError(callback);
//                     ^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Future<int> Function({Object a})' can't be assigned to the parameter type 'void Function(Object)' or 'void Function(Object, StackTrace)'.
}
''');
  }

  void test_functionExpression_firstParameterIsNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
void f(StreamSubscription<void> subscription) {
  subscription.onError(({Object a = 1}) {});
//                     ^^^^^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Null Function({Object a})' can't be assigned to the parameter type 'void Function(Object)' or 'void Function(Object, StackTrace)'.
}
''');
  }

  void test_functionExpression_firstParameterIsNullableObject() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
void f(StreamSubscription<void> subscription) {
  subscription.onError((Object? a) {});
}
''');
  }

  void test_functionExpression_noParameters() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
void f(StreamSubscription<void> subscription) {
  subscription.onError(() {});
//                     ^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Null Function()' can't be assigned to the parameter type 'void Function(Object)' or 'void Function(Object, StackTrace)'.
}
''');
  }

  void test_functionExpression_secondParameterIsNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
void f(StreamSubscription<void> subscription) {
  subscription.onError((Object a, {StackTrace? b}) {});
//                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Null Function(Object, {StackTrace? b})' can't be assigned to the parameter type 'void Function(Object)' or 'void Function(Object, StackTrace)'.
}
''');
  }

  void test_functionExpression_secondParameterIsNullableStackTrace() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
void f(StreamSubscription<void> subscription) {
  subscription.onError((Object a, StackTrace? b) {});
}
''');
  }

  void test_functionExpression_wrongFirstParameterType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
void f(StreamSubscription<void> subscription) {
  subscription.onError((String a) {});
//                     ^^^^^^^^^^^^^
// [diag.argumentTypeNotAssignableToErrorHandler] The argument type 'Null Function(String)' can't be assigned to the parameter type 'void Function(Object)' or 'void Function(Object, StackTrace)'.
}
''');
  }
}
