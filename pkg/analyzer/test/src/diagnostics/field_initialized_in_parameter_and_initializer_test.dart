// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FinalInitializedInParameterAndInitializerTest);
  });
}

@reflectiveTest
class FinalInitializedInParameterAndInitializerTest
    extends PubPackageResolutionTest {
  test_class_augmentation() async {
    newFile(testFile.path, r'''
part 'a.dart';

class A {
  final int f;
  A(this.f);
}
''');

    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {
  augment A(this.f) : f = 0;
}
''');

    await resolveFile2(testFile);
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertErrorsInResult([
      error(CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER,
          62, 1),
    ]);
  }

  test_class_fieldFormalParameter_initializer() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A(this.x) : x = 1 {}
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER,
          33, 1),
    ]);
  }

  test_enum_fieldFormalParameter_initializer() async {
    await assertErrorsInCode(r'''
enum E {
  v(0);
  final int x;
  const E(this.x) : x = 1;
}
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 11, 4),
      error(CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER,
          52, 1),
    ]);
  }

  test_extensionType_fieldFormalParameter_initializer() async {
    await assertErrorsInCode(r'''
extension type A(int it) {
  A.named(this.it) : it = 0;
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER,
          48, 2),
    ]);
  }
}
