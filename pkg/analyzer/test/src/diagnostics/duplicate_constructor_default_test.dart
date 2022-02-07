// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateConstructorDefaultTest);
  });
}

@reflectiveTest
class DuplicateConstructorDefaultTest extends PubPackageResolutionTest {
  test_class_empty_empty() async {
    await assertErrorsInCode(r'''
class C {
  C();
  C();
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, 19, 1),
    ]);
  }

  test_class_empty_new() async {
    await assertErrorsInCode(r'''
class C {
  C();
  C.new();
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, 19, 5),
    ]);
  }

  test_class_new_new() async {
    await assertErrorsInCode(r'''
class C {
  C.new();
  C.new();
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT, 23, 5),
    ]);
  }
}
