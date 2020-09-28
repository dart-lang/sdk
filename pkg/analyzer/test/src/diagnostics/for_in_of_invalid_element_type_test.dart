// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForInOfInvalidElementTypeTest);
  });
}

@reflectiveTest
class ForInOfInvalidElementTypeTest extends PubPackageResolutionTest {
  test_await_declaredVariableWrongType() async {
    await assertErrorsInCode('''
f() async {
  Stream<String> stream;
  await for (int i in stream) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 54, 1),
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 59, 6),
    ]);
  }

  test_await_existingVariableWrongType() async {
    await assertErrorsInCode('''
f() async {
  Stream<String> stream;
  int i;
  await for (i in stream) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 43, 1),
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 64, 6),
    ]);
  }

  test_bad_type_bound() async {
    await assertErrorsInCode('''
class Foo<T extends Iterable<int>> {
  void method(T iterable) {
    for (String i in iterable) {}
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 81, 1),
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 86, 8),
    ]);
  }

  test_declaredVariableWrongType() async {
    await assertErrorsInCode('''
f() {
  for (int i in <String>[]) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 22, 10),
    ]);
  }

  test_existingVariableWrongType() async {
    await assertErrorsInCode('''
f() {
  int i;
  for (i in <String>[]) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 12, 1),
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 27, 10),
    ]);
  }
}
