// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstEvalExtensionMethodTest);
  });
}

@reflectiveTest
class ConstEvalExtensionMethodTest extends PubPackageResolutionTest {
  test_binaryExpression() async {
    await assertErrorsInCode(
      '''
extension on Object {
  int operator +(Object other) => 0;
}

const Object v1 = 0;
const v2 = v1 + v1;
''',
      [error(CompileTimeErrorCode.constEvalExtensionMethod, 94, 7)],
    );
  }

  test_prefixExpression() async {
    await assertErrorsInCode(
      '''
extension on Object {
  int operator -() => 0;
}

const Object v1 = 1;
const v2 = -v1;
''',
      [error(CompileTimeErrorCode.constEvalExtensionMethod, 82, 3)],
    );
  }
}
