// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinSuperClassConstraintDisallowedClassTest);
  });
}

@reflectiveTest
class MixinSuperClassConstraintDisallowedClassTest
    extends PubPackageResolutionTest {
  test_dartCoreEnum() async {
    await assertNoErrorsInCode(r'''
mixin M on Enum {}
''');
  }

  test_dartCoreEnum_language216() async {
    await assertErrorsInCode(
      r'''
// @dart = 2.16
mixin M on Enum {}
''',
      [
        error(
          CompileTimeErrorCode.mixinSuperClassConstraintDisallowedClass,
          27,
          4,
        ),
      ],
    );

    var node = findNode.singleMixinOnClause;
    assertResolvedNodeText(node, r'''
MixinOnClause
  onKeyword: on
  superclassConstraints
    NamedType
      name: Enum
      element2: dart:core::@class::Enum
      type: Enum
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_in_inAugmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
mixin A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
augment mixin A on int {}
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, [
      error(
        CompileTimeErrorCode.mixinSuperClassConstraintDisallowedClass,
        37,
        3,
      ),
    ]);
  }

  test_int() async {
    await assertErrorsInCode(
      r'''
mixin M on int {}
''',
      [
        error(
          CompileTimeErrorCode.mixinSuperClassConstraintDisallowedClass,
          11,
          3,
        ),
      ],
    );

    var node = findNode.singleMixinOnClause;
    assertResolvedNodeText(node, r'''
MixinOnClause
  onKeyword: on
  superclassConstraints
    NamedType
      name: int
      element2: dart:core::@class::int
      type: int
''');
  }
}
