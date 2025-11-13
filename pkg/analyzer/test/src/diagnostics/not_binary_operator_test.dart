// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonBinaryOperatorTest);
  });
}

@reflectiveTest
class NonBinaryOperatorTest extends PubPackageResolutionTest {
  test_unaryTilde() async {
    await assertErrorsInCode('var a = 5 ~ 3;', [
      error(diag.notBinaryOperator, 10, 1),
    ]);
  }
}
