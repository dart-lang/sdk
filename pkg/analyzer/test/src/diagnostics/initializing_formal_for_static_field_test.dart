// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InitializingFormalForStaticFieldTest);
  });
}

@reflectiveTest
class InitializingFormalForStaticFieldTest extends PubPackageResolutionTest {
  test_static() async {
    await assertErrorsInCode(r'''
class A {
  static int x;
  A([this.x]) {}
}
''', [
      error(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_STATIC_FIELD, 31, 6),
    ]);
  }
}
