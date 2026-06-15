// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnOfInvalidTypeForCatchErrorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ReturnOfInvalidTypeForCatchErrorTest extends PubPackageResolutionTest {
  test_async_okReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future) {
  future.catchError((e, st) async => 0);
}
''');
  }

  test_blockFunctionBody_async_emptyReturn_nonVoid() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future) {
  future.catchError((e, st) async {
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
  future.catchError((e, st) async {
    return;
  });
}
''');
  }

  test_blockFunctionBody_emptyReturn_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<dynamic> future) {
  future.catchError((e, st) {
    return;
  });
}
''');
  }

  test_blockFunctionBody_emptyReturn_nonVoid() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future) {
  future.catchError((e, st) {
    return;
//  ^^^^^^
// [diag.returnWithoutValue] The return value is missing after 'return'.
  });
}
''');
  }

  test_blockFunctionBody_emptyReturn_Null() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<Null> future) {
  future.catchError((e, st) {
    return;
  });
}
''');
  }

  test_blockFunctionBody_emptyReturn_void() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.catchError((e, st) {
    return;
  });
}
''');
  }

  test_blockFunctionBody_invalidReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future) {
  future.catchError((e, st) {
    if (1 == 2) {
      return 7;
    } else {
      return 0.5;
//           ^^^
// [diag.returnOfInvalidTypeFromCatchError] A value of type 'double' can't be returned by the 'onError' handler because it must be assignable to 'FutureOr<int>'.
    }
  });
}
''');
  }

  test_blockFunctionBody_withLocalFunction_expression_okReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future) {
  future.catchError((e, st) {
    double g() => 0.5;
    if (g() == 0.5) return 0;
    return 1;
  });
}
''');
  }

  test_blockFunctionBody_withLocalFunction_okReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future) {
  future.catchError((e, st) {
    double g() {
      return 0.5;
    }
    if (g() == 0.5) return 0;
    return 1;
  });
}
''');
  }

  test_expressionFunctionBody_invalidReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future) {
  future.catchError((e, st) => 'c');
//                             ^^^
// [diag.returnOfInvalidTypeFromCatchError] A value of type 'String' can't be returned by the 'onError' handler because it must be assignable to 'FutureOr<int>'.
}
''');
  }

  test_Null_okReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<Null> future) {
  future.catchError((e, st) => null);
}
''');
  }

  test_Null_voidReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<Null> future, void Function() g) {
  future.catchError((e, st) => g());
}
''');
  }

  test_nullableType_emptyReturn() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int?> future) {
  future.catchError((e, st) {
    return;
//  ^^^^^^
// [diag.returnWithoutValue] The return value is missing after 'return'.
  });
}
''');
  }

  test_nullableType_invalidReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int?> future) {
  future.catchError((e, st) => '');
//                             ^^
// [diag.returnOfInvalidTypeFromCatchError] A value of type 'String' can't be returned by the 'onError' handler because it must be assignable to 'FutureOr<int?>'.
}
''');
  }

  test_okReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future) {
  future.catchError((e, st) => 0);
}
''');
  }

  test_void_okReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<void> future) {
  future.catchError((e, st) => 0);
}
''');
  }

  test_voidReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Future<int> future, void Function() g) {
  future.catchError((e, st) => g());
//                             ^^^
// [diag.returnOfInvalidTypeFromCatchError] A value of type 'void' can't be returned by the 'onError' handler because it must be assignable to 'FutureOr<int>'.
}
''');
  }
}
