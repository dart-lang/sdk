// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstEvalMethodInvocationTest);
  });
}

@reflectiveTest
class ConstEvalMethodInvocationTest extends PubPackageResolutionTest {
  test_function() async {
    await assertErrorsInCode('''
int f() {
  return 3;
}
const a = f();
''', [
      error(CompileTimeErrorCode.CONST_EVAL_METHOD_INVOCATION, 34, 3),
    ]);
  }

  test_identical() async {
    await assertNoErrorsInCode('''
const a = identical(1, 1);
''');
  }
}
