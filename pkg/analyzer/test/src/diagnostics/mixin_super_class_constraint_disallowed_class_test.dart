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
    await assertErrorsInCode(r'''
// @dart = 2.16
mixin M on Enum {}
''', [
      error(CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS,
          27, 4),
    ]);

    final node = findNode.singleOnClause;
    assertResolvedNodeText(node, r'''
OnClause
  onKeyword: on
  superclassConstraints
    NamedType
      name: Enum
      element: dart:core::@class::Enum
      type: Enum
''');
  }

  test_int() async {
    await assertErrorsInCode(r'''
mixin M on int {}
''', [
      error(CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS,
          11, 3),
    ]);

    final node = findNode.singleOnClause;
    assertResolvedNodeText(node, r'''
OnClause
  onKeyword: on
  superclassConstraints
    NamedType
      name: int
      element: dart:core::@class::int
      type: int
''');
  }
}
