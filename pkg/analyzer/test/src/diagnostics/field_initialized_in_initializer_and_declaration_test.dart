// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldInitializedInInitializerAndDeclarationTest);
  });
}

@reflectiveTest
class FieldInitializedInInitializerAndDeclarationTest
    extends PubPackageResolutionTest {
  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_augmentation() async {
    newFile(testFile.path, r'''
part 'a.dart';

class A {
  final int f = 0;
  A();
}
''');

    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {
  augment A() : f = 1;
}
''');

    await resolveFile2(testFile);
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertErrorsInResult([
      error(
        CompileTimeErrorCode.fieldInitializedInInitializerAndDeclaration,
        56,
        1,
      ),
    ]);
  }

  test_class_both() async {
    await assertErrorsInCode(
      '''
class A {
  final int x = 0;
  A() : x = 1;
}
''',
      [
        error(
          CompileTimeErrorCode.fieldInitializedInInitializerAndDeclaration,
          37,
          1,
        ),
      ],
    );
  }

  test_enum_both() async {
    await assertErrorsInCode(
      '''
enum E {
  v;
  final int x = 0;
  const E() : x = 1;
}
''',
      [
        error(CompileTimeErrorCode.constEvalThrowsException, 11, 1),
        error(
          CompileTimeErrorCode.fieldInitializedInInitializerAndDeclaration,
          47,
          1,
        ),
      ],
    );
  }
}
