// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
extension on Object {
  int operator +(Object other) => 0;
}

const Object v1 = 0;
const v2 = v1 + v1;
//         ^^^^^^^
// [diag.constEvalExtensionMethod] Extension methods can't be used in constant expressions.
''');
  }

  test_prefixExpression() async {
    await resolveTestCodeWithDiagnostics(r'''
extension on Object {
  int operator -() => 0;
}

const Object v1 = 1;
const v2 = -v1;
//         ^^^
// [diag.constEvalExtensionMethod] Extension methods can't be used in constant expressions.
''');
  }
}
