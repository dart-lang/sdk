// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ObjectCannotExtendAnotherClassTest);
  });
}

@reflectiveTest
class ObjectCannotExtendAnotherClassTest extends PubPackageResolutionTest {
  @failingTest
  test_object_extends_class() async {
    // TODO(brianwilkerson): Implement this check.
    await assertErrorsInCode(r'''
class Object extends List {}
''', [
      error(CompileTimeErrorCode.OBJECT_CANNOT_EXTEND_ANOTHER_CLASS, 0, 0),
    ]);
  }
}
