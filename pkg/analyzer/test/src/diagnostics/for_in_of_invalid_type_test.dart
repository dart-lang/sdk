// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForInOfInvalidTypeTest);
    defineReflectiveTests(ForInOfInvalidTypeWithNullSafetyTest);
  });
}

@reflectiveTest
class ForInOfInvalidTypeTest extends PubPackageResolutionTest {
  test_awaitForIn_dynamic() async {
    await assertNoErrorsInCode('''
f(dynamic e) async {
  await for (var id in e) {
    id;
  }
}
''');
  }

  test_awaitForIn_interfaceType_notStream() async {
    await assertErrorsInCode('''
f(bool e) async {
  await for (var id in e) {
    id;
  }
}
''', [
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE, 41, 1),
    ]);
  }

  test_forIn_dynamic() async {
    await assertNoErrorsInCode('''
f(dynamic e) {
  for (var id in e) {
    id;
  }
}
''');
  }

  test_forIn_interfaceType_notIterable() async {
    await assertErrorsInCode('''
f(bool e) {
  for (var id in e) {
    id;
  }
}
''', [
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE, 29, 1),
    ]);
  }
}

@reflectiveTest
class ForInOfInvalidTypeWithNullSafetyTest extends ForInOfInvalidTypeTest
    with WithNullSafetyMixin {
  test_awaitForIn_never() async {
    await assertErrorsInCode('''
f(Never e) async {
  await for (var id in e) {
    id;
  }
}
''', [
      error(HintCode.DEAD_CODE, 32, 26),
    ]);
    // TODO(scheglov) extract for-in resolution and implement
//    assertType(findNode.simple('id;'), 'Never');
  }

  test_forIn_never() async {
    await assertErrorsInCode('''
f(Never e) {
  for (var id in e) {
    id;
  }
}
''', [
      error(HintCode.DEAD_CODE, 20, 26),
    ]);
    // TODO(scheglov) extract for-in resolution and implement
//    assertType(findNode.simple('id;'), 'Never');
  }
}
