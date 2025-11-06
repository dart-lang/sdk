// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FinalInitializedInDeclarationAndConstructorTest);
  });
}

@reflectiveTest
class FinalInitializedInDeclarationAndConstructorTest
    extends PubPackageResolutionTest {
  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_augmentation() async {
    newFile(testFile.path, r'''
part 'a.dart';

class A {
  final int f = 0;
  A(this.f);
}
''');

    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {
  augment A(this.f);
}
''');

    await resolveFile2(testFile);
    assertErrorsInResult([
      error(
        CompileTimeErrorCode.finalInitializedInDeclarationAndConstructor,
        54,
        1,
      ),
    ]);

    await resolveFile2(a);
    assertNoErrorsInResult();
  }

  test_class_fieldFormalParameter() async {
    await assertErrorsInCode(
      '''
class A {
  final x = 0;
  A(this.x) {}
}
''',
      [
        error(
          CompileTimeErrorCode.finalInitializedInDeclarationAndConstructor,
          34,
          1,
        ),
      ],
    );
  }

  test_enum_fieldFormalParameter() async {
    await assertErrorsInCode(
      '''
enum E {
  v(0);
  final x = 0;
  const E(this.x);
}
''',
      [
        error(CompileTimeErrorCode.constEvalThrowsException, 11, 4),
        error(
          CompileTimeErrorCode.finalInitializedInDeclarationAndConstructor,
          47,
          1,
        ),
      ],
    );
  }
}
