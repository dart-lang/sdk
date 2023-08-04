// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AwaitOfExtensionTypeNotFutureTest);
  });
}

@reflectiveTest
class AwaitOfExtensionTypeNotFutureTest extends PubPackageResolutionTest {
  test_hasError() async {
    await assertErrorsInCode(r'''
extension type A(int it) {}

void f(A a) async {
  await a;
}
''', [
      error(CompileTimeErrorCode.AWAIT_OF_EXTENSION_TYPE_NOT_FUTURE, 51, 5),
    ]);
  }

  test_noError() async {
    await assertNoErrorsInCode(r'''
extension type A(Future<int> it) implements Future<int> {}

void f(A a) async {
  await a;
}
''');
  }
}
