// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ArgumentTypeNotAssignableCatchErrorOnErrorTest);
    defineReflectiveTests(
        ArgumentTypeNotAssignableCatchErrorOnErrorWithNullSafetyTest);
  });
}

@reflectiveTest
class ArgumentTypeNotAssignableCatchErrorOnErrorTest
    extends PubPackageResolutionTest {
  void test_firstParameterIsDynamic() async {
    await assertNoErrorsInCode('''
void f(Future<int> future, Future<int> Function(dynamic a) callback) {
  future.catchError(callback);
}
''');
  }

  void test_firstParameterIsNamed() async {
    await assertErrorsInCode('''
void f(Future<int> future, Future<int> Function({Object a}) callback) {
  future.catchError(callback);
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_CATCH_ERROR_ON_ERROR, 92, 8),
    ]);
  }

  void test_firstParameterIsOptional() async {
    await assertErrorsInCode('''
void f(Future<int> future, Future<int> Function([Object a]) callback) {
  future.catchError(callback);
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_CATCH_ERROR_ON_ERROR, 92, 8),
    ]);
  }

  void test_functionExpression_firstParameterIsDynamic() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.catchError((dynamic a) {});
}
''');
  }

  void test_functionExpression_firstParameterIsImplicit() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.catchError((a) {});
}
''');
  }

  void test_functionExpression_firstParameterIsNamed() async {
    await assertErrorsInCode('''
void f(Future<void> future) {
  future.catchError(({Object a = 1}) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_CATCH_ERROR_ON_ERROR, 50, 19),
    ]);
  }

  void test_functionExpression_firstParameterIsOptional() async {
    await assertErrorsInCode('''
void f(Future<void> future) {
  future.catchError(([Object a = 1]) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_CATCH_ERROR_ON_ERROR, 50, 19),
    ]);
  }

  void test_functionExpression_firstParameterIsVar() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.catchError((var a) {});
}
''');
  }

  void test_functionExpression_noParameters() async {
    await assertErrorsInCode('''
void f(Future<void> future) {
  future.catchError(() {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_CATCH_ERROR_ON_ERROR, 50, 5),
    ]);
  }

  void test_functionExpression_secondParameterIsDynamic() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.catchError((Object a, dynamic b) {});
}
''');
  }

  void test_functionExpression_secondParameterIsImplicit() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.catchError((Object a, b) {});
}
''');
  }

  void test_functionExpression_secondParameterIsNamed() async {
    await assertErrorsInCode('''
void f(Future<void> future) {
  future.catchError((Object a, {StackTrace b}) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_CATCH_ERROR_ON_ERROR, 50, 29),
    ]);
  }

  void test_functionExpression_secondParameterIsVar() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.catchError((Object a, var b) {});
}
''');
  }

  void test_functionExpression_tooManyParameters() async {
    await assertErrorsInCode('''
void f(Future<void> future) {
  future.catchError((a, b, c) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_CATCH_ERROR_ON_ERROR, 50, 12),
    ]);
  }

  void test_functionExpression_wrongFirstParameterType() async {
    await assertErrorsInCode('''
void f(Future<void> future) {
  future.catchError((String a) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_CATCH_ERROR_ON_ERROR, 50, 13),
    ]);
  }

  void test_functionExpression_wrongSecondParameterType() async {
    await assertErrorsInCode('''
void f(Future<void> future) {
  future.catchError((Object a, String b) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_CATCH_ERROR_ON_ERROR, 50, 23),
    ]);
  }

  void test_noParameters() async {
    await assertErrorsInCode('''
void f(Future<int> future, Future<int> Function() callback) {
  future.catchError(callback);
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_CATCH_ERROR_ON_ERROR, 82, 8),
    ]);
  }

  void test_okType() async {
    await assertNoErrorsInCode('''
void f(Future<int> future, Future<int> Function(Object, StackTrace) callback) {
  future.catchError(callback);
}
''');
  }

  void test_secondParameterIsDynamic() async {
    await assertNoErrorsInCode('''
void f(Future<int> future, Future<int> Function(Object a, dynamic b) callback) {
  future.catchError(callback);
}
''');
  }

  void test_secondParameterIsNamed() async {
    await assertErrorsInCode('''
void f(Future<int> future, Future<int> Function(Object a, {StackTrace b}) callback) {
  future.catchError(callback);
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_CATCH_ERROR_ON_ERROR, 106, 8),
    ]);
  }

  void test_tooManyParameters() async {
    await assertErrorsInCode('''
void f(Future<int> future, Future<int> Function(int, int, int) callback) {
  future.catchError(callback);
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_CATCH_ERROR_ON_ERROR, 95, 8),
    ]);
  }

  void test_wrongSecondParameterType() async {
    await assertErrorsInCode('''
void f(Future<int> future, Future<int> Function(Object, String) callback) {
  future.catchError(callback);
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_CATCH_ERROR_ON_ERROR, 96, 8),
    ]);
  }

  voidtest_wrongFirstParameterType() async {
    await assertErrorsInCode('''
void f(Future<int> future, Future<int> Function(String) callback) {
  future.catchError(callback);
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_CATCH_ERROR_ON_ERROR, 88, 8),
    ]);
  }
}

@reflectiveTest
class ArgumentTypeNotAssignableCatchErrorOnErrorWithNullSafetyTest
    extends ArgumentTypeNotAssignableCatchErrorOnErrorTest
    with WithNullSafetyMixin {
  void test_functionExpression_firstParameterIsNullableObject() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.catchError((Object? a) {});
}
''');
  }

  @override
  void test_functionExpression_secondParameterIsNamed() async {
    await assertErrorsInCode('''
void f(Future<void> future) {
  future.catchError((Object a, {required StackTrace b}) {});
}
''', [
      error(HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_CATCH_ERROR_ON_ERROR, 50, 38),
    ]);
  }

  void test_functionExpression_secondParameterIsNullableStackTrace() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.catchError((Object a, StackTrace? b) {});
}
''');
  }
}
