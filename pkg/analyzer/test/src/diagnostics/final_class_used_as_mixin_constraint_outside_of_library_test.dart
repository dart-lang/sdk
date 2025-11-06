// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FinalClassUsedAsMixinConstraintOutsideOfLibraryTest);
  });
}

@reflectiveTest
class FinalClassUsedAsMixinConstraintOutsideOfLibraryTest
    extends PubPackageResolutionTest {
  test_inside() async {
    await assertNoErrorsInCode(r'''
final class A {}
base mixin B on A {}
''');
  }

  test_outside() async {
    newFile('$testPackageLibPath/a.dart', r'''
final class A {}
''');

    await assertErrorsInCode(
      r'''
import 'a.dart';
base mixin B on A {}
''',
      [
        error(
          CompileTimeErrorCode.finalClassUsedAsMixinConstraintOutsideOfLibrary,
          33,
          1,
        ),
      ],
    );
  }

  test_outside_multiple() async {
    newFile('$testPackageLibPath/a.dart', r'''
final class A {}
final class B {}
''');

    await assertErrorsInCode(
      r'''
import 'a.dart';
base mixin C on A, B {}
''',
      [
        error(
          CompileTimeErrorCode.finalClassUsedAsMixinConstraintOutsideOfLibrary,
          33,
          1,
        ),
        error(
          CompileTimeErrorCode.finalClassUsedAsMixinConstraintOutsideOfLibrary,
          36,
          1,
        ),
      ],
    );
  }

  test_outside_noBase() async {
    // Test that we won't get a [SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED]
    // error.
    newFile('$testPackageLibPath/a.dart', r'''
final class A {}
''');

    await assertErrorsInCode(
      r'''
import 'a.dart';
mixin B on A {}
''',
      [
        error(
          CompileTimeErrorCode.finalClassUsedAsMixinConstraintOutsideOfLibrary,
          28,
          1,
        ),
      ],
    );
  }

  test_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/a.dart', r'''
final class A {}
typedef ATypedef = A;
''');

    await assertErrorsInCode(
      r'''
import 'a.dart';
base mixin B on ATypedef {}
''',
      [
        error(
          CompileTimeErrorCode.finalClassUsedAsMixinConstraintOutsideOfLibrary,
          33,
          8,
        ),
      ],
    );
  }

  test_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/a.dart', r'''
final class A {}
''');

    await assertErrorsInCode(
      r'''
import 'a.dart';
typedef ATypedef = A;
base mixin B on ATypedef {}
''',
      [
        error(
          CompileTimeErrorCode.finalClassUsedAsMixinConstraintOutsideOfLibrary,
          55,
          8,
        ),
      ],
    );
  }
}
