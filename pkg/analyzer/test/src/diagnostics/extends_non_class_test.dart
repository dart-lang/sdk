// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtendsNonClassTest);
    defineReflectiveTests(ExtendsNonClassWithNullSafetyTest);
  });
}

@reflectiveTest
class ExtendsNonClassTest extends PubPackageResolutionTest {}

@reflectiveTest
class ExtendsNonClassWithNullSafetyTest extends ExtendsNonClassTest
    with WithNullSafetyMixin {
  test_Never() async {
    await assertErrorsInCode('''
class A extends Never {}
''', [
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 16, 5),
    ]);
  }
}
