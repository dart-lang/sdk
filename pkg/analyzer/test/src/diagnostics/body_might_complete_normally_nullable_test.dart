// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BodyMightCompleteNormallyNullableTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class BodyMightCompleteNormallyNullableTest extends PubPackageResolutionTest {
  test_function_async_block_futureOrIntQuestion() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
FutureOr<int?> f(Future f) async {}
//             ^
// [diag.bodyMightCompleteNormallyNullable] This function has a nullable return type of 'FutureOr<int?>', but ends without returning a value.
''');
  }

  test_function_async_block_futureOrVoid() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
FutureOr<void> f(Future f) async {}
''');
  }

  test_function_async_block_void() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
void f(Future f) async {}
''');
  }

  test_function_switchStatement_exhaustive_extensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E { a, b }

extension type EE(E it) {}

int f(EE e) {
  switch (e) {
    case E.a:
      return 0;
    case E.b:
      return 1;
  }
}
''');
  }

  test_function_sync_block_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
dynamic f() {}
''');
  }

  test_function_sync_block_intQuestion() async {
    await resolveTestCodeWithDiagnostics(r'''
int? f() {}
//   ^
// [diag.bodyMightCompleteNormallyNullable] This function has a nullable return type of 'int?', but ends without returning a value.
''');
  }

  test_function_sync_block_intQuestion_definiteReturn() async {
    await resolveTestCodeWithDiagnostics(r'''
int? f() {
  return null;
}
''');
  }

  test_function_sync_block_Null() async {
    await resolveTestCodeWithDiagnostics(r'''
Null f() {}
''');
  }

  test_function_sync_block_void() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {}
''');
  }
}
