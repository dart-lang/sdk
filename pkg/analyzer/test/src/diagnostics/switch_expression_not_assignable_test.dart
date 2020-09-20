// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SwitchExpressionNotAssignableTest);
  });
}

@reflectiveTest
class SwitchExpressionNotAssignableTest extends PubPackageResolutionTest {
  test_simple() async {
    await assertErrorsInCode('''
f(int p) {
  switch (p) {
    case 'a': break;
  }
}''', [
      error(CompileTimeErrorCode.SWITCH_EXPRESSION_NOT_ASSIGNABLE, 21, 1),
    ]);
  }
}
