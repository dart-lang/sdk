// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonTypeInCatchClauseTest);
  });
}

@reflectiveTest
class NonTypeInCatchClauseTest extends PubPackageResolutionTest {
  test_isClass() async {
    await assertErrorsInCode(r'''
f() {
  try {
  } on String catch (e) {
  }
}
''', [
      error(HintCode.UNUSED_CATCH_CLAUSE, 35, 1),
    ]);
  }

  test_isFunctionTypeAlias() async {
    await assertErrorsInCode(r'''
typedef F();
f() {
  try {
  } on F catch (e) {
  }
}
''', [
      error(HintCode.UNUSED_CATCH_CLAUSE, 43, 1),
    ]);
  }

  test_isTypeParameter() async {
    await assertErrorsInCode(r'''
class A<T> {
  f() {
    try {
    } on T catch (e) {
    }
  }
}
''', [
      error(HintCode.UNUSED_CATCH_CLAUSE, 49, 1),
    ]);
  }

  test_notDefined() async {
    await assertErrorsInCode('''
f() {
  try {
  } on T catch (e) {
  }
}
''', [
      error(CompileTimeErrorCode.NON_TYPE_IN_CATCH_CLAUSE, 21, 1),
      error(HintCode.UNUSED_CATCH_CLAUSE, 30, 1),
    ]);
  }

  test_notType() async {
    await assertErrorsInCode('''
var T = 0;
f() {
  try {
  } on T catch (e) {
  }
}
''', [
      error(CompileTimeErrorCode.NON_TYPE_IN_CATCH_CLAUSE, 32, 1),
      error(HintCode.UNUSED_CATCH_CLAUSE, 41, 1),
    ]);
  }

  test_noType() async {
    await assertNoErrorsInCode(r'''
f() {
  try {
  } catch (e) {
  }
}
''');
  }
}
