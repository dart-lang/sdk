// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnOfInvalidTypeForThenTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ReturnOfInvalidTypeForThenTest extends PubPackageResolutionTest {
  test_blockFunctionBody_async_emptyReturn_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future) {
  future.then<dynamic>((_) => 0, onError: (e, st) async {
    return;
  });
}
''');
  }

  test_blockFunctionBody_async_emptyReturn_nonVoid() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future) {
  future.then<int>((_) => 0, onError: (e, st) async {
    return;
//  ^^^^^^
// [diag.returnWithoutValue] The return value is missing after 'return'.
  });
}
''');
  }

  test_blockFunctionBody_async_emptyReturn_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future) {
  future.then<int?>((_) => 0, onError: (e, st) async {
    return;
//  ^^^^^^
// [diag.returnWithoutValue] The return value is missing after 'return'.
  });
}
''');
  }

  test_blockFunctionBody_async_emptyReturn_void() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.then<void>((_) => 0, onError: (e, st) async {
    return;
  });
}
''');
  }

  test_blockFunctionBody_invalidReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future) {
  future.then((_) => 0, onError: (e, st) {
    if (1 == 2) {
      return 7;
    } else {
      return 0.5;
//           ^^^
// [diag.returnOfInvalidTypeFromThen] A value of type 'double' can't be returned by the 'onError' handler because it must be assignable to 'FutureOr<int>', as required by 'Future.then'.
    }
  });
}
''');
  }

  test_blockFunctionBody_void_objectQuestionReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future) {
  future.then<void>((_) {}, onError: (e, st) {
    return Future<Object?>.error(0.5);
  });
}
''');
  }

  test_expressionFunctionBody_invalidReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future) {
  future.then((_) => 0, onError: (e, st) => 'c');
//                                          ^^^
// [diag.returnOfInvalidTypeFromThen] A value of type 'String' can't be returned by the 'onError' handler because it must be assignable to 'FutureOr<int>', as required by 'Future.then'.
}
''');
  }

  test_expressionFunctionBody_Null_okReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future) {
  future.then<Null>((_) => null, onError: (e, st) => null);
}
''');
  }

  test_expressionFunctionBody_Null_voidReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, void Function(dynamic, StackTrace) callback) {
  future.then<Null>((_) => null, onError: callback);
}
''');
  }

  test_expressionFunctionBody_okReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future) {
  future.then((_) => 0, onError: (e, st) => 0);
}
''');
  }

  test_expressionFunctionBody_void_okReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future) {
  future.then<void>((_) => 0, onError: (e, st) => 0);
}
''');
  }

  test_referencedFunction_FutureOfNull_voidReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, void Function(dynamic, StackTrace) callback) {
  future.then<Null>((_) => null, onError: callback);
}
''');
  }

  test_referencedFunction_FutureOfNull_voidReturnType2() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, void Function() callback) {
  future.then<Null>((_) => null, onError: (_, _) => callback());
}
''');
  }

  test_referencedFunction_invalidReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, double Function(dynamic, StackTrace) callback) {
  future.then((_) => 0, onError: callback);
//                               ^^^^^^^^
// [diag.returnTypeInvalidForThen] The return type 'double' isn't assignable to 'FutureOr<int>', as required by 'Future.then'.
}
''');
  }

  test_referencedFunction_void_voidReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, Future<Object?> Function(dynamic, StackTrace) callback) {
  future.then<void>((_) {}, onError: callback);
}
''');
  }
}
