// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnOfInvalidTypeForThenTest);
  });
}

@reflectiveTest
class ReturnOfInvalidTypeForThenTest extends PubPackageResolutionTest {
  test_blockFunctionBody_async_emptyReturn_dynamic() async {
    await assertNoErrorsInCode('''
void f(Future<int> future) {
  future.then<dynamic>((_) => 0, onError: (e, st) async {
    return;
  });
}
''');
  }

  test_blockFunctionBody_async_emptyReturn_nonVoid() async {
    await assertErrorsInCode(
      '''
void f(Future<int> future) {
  future.then<int>((_) => 0, onError: (e, st) async {
    return;
  });
}
''',
      [error(diag.returnWithoutValue, 87, 6)],
    );
  }

  test_blockFunctionBody_async_emptyReturn_nullable() async {
    await assertErrorsInCode(
      '''
void f(Future<int> future) {
  future.then<int?>((_) => 0, onError: (e, st) async {
    return;
  });
}
''',
      [error(diag.returnWithoutValue, 88, 6)],
    );
  }

  test_blockFunctionBody_async_emptyReturn_void() async {
    await assertNoErrorsInCode('''
void f(Future<void> future) {
  future.then<void>((_) => 0, onError: (e, st) async {
    return;
  });
}
''');
  }

  test_blockFunctionBody_invalidReturnType() async {
    await assertErrorsInCode(
      '''
void f(Future<int> future) {
  future.then((_) => 0, onError: (e, st) {
    if (1 == 2) {
      return 7;
    } else {
      return 0.5;
    }
  });
}
''',
      [error(diag.returnOfInvalidTypeFromThen, 132, 3)],
    );
  }

  test_blockFunctionBody_void_objectQuestionReturnType() async {
    await assertNoErrorsInCode('''
void f(Future<int> future) {
  future.then<void>((_) {}, onError: (e, st) {
    return Future<Object?>.error(0.5);
  });
}
''');
  }

  test_expressionFunctionBody_invalidReturnType() async {
    await assertErrorsInCode(
      '''
void f(Future<int> future) {
  future.then((_) => 0, onError: (e, st) => 'c');
}
''',
      [error(diag.returnOfInvalidTypeFromThen, 73, 3)],
    );
  }

  test_expressionFunctionBody_Null_okReturnType() async {
    await assertNoErrorsInCode('''
void f(Future<int> future) {
  future.then<Null>((_) => null, onError: (e, st) => null);
}
''');
  }

  test_expressionFunctionBody_Null_voidReturnType() async {
    await assertNoErrorsInCode('''
void f(Future<int> future, void Function(dynamic, StackTrace) callback) {
  future.then<Null>((_) => null, onError: callback);
}
''');
  }

  test_expressionFunctionBody_okReturnType() async {
    await assertNoErrorsInCode('''
void f(Future<int> future) {
  future.then((_) => 0, onError: (e, st) => 0);
}
''');
  }

  test_expressionFunctionBody_void_okReturnType() async {
    await assertNoErrorsInCode('''
void f(Future<int> future) {
  future.then<void>((_) => 0, onError: (e, st) => 0);
}
''');
  }

  test_referencedFunction_FutureOfNull_voidReturnType() async {
    await assertNoErrorsInCode('''
void f(Future<int> future, void Function(dynamic, StackTrace) callback) {
  future.then<Null>((_) => null, onError: callback);
}
''');
  }

  test_referencedFunction_FutureOfNull_voidReturnType2() async {
    await assertNoErrorsInCode('''
void f(Future<int> future, void Function() callback) {
  future.then<Null>((_) => null, onError: (_, _) => callback());
}
''');
  }

  test_referencedFunction_invalidReturnType() async {
    await assertErrorsInCode(
      '''
void f(Future<int> future, double Function(dynamic, StackTrace) callback) {
  future.then((_) => 0, onError: callback);
}
''',
      [error(diag.returnTypeInvalidForThen, 109, 8)],
    );
  }

  test_referencedFunction_void_voidReturnType() async {
    await assertNoErrorsInCode('''
void f(Future<int> future, Future<Object?> Function(dynamic, StackTrace) callback) {
  future.then<void>((_) {}, onError: callback);
}
''');
  }
}
