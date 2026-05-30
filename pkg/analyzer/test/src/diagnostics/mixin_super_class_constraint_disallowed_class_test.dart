// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinSuperClassConstraintDisallowedClassTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MixinSuperClassConstraintDisallowedClassTest
    extends PubPackageResolutionTest {
  test_dartCoreEnum() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M on Enum {}
''');
  }

  test_dartCoreEnum_language216() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.16
mixin M on Enum {}
//         ^^^^
// [diag.mixinSuperClassConstraintDisallowedClass] 'Enum' can't be used as a superclass constraint.
''');

    var node = result.findNode.singleMixinOnClause;
    assertResolvedNodeText(node, r'''
MixinOnClause
  onKeyword: on
  superclassConstraints
    NamedType
      name: Enum
      element: dart:core::@class::Enum
      type: Enum
''');
  }

  test_in_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {}
augment mixin A on int {}
//                 ^^^
// [diag.mixinSuperClassConstraintDisallowedClass] 'int' can't be used as a superclass constraint.
''');
  }

  test_int() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin M on int {}
//         ^^^
// [diag.mixinSuperClassConstraintDisallowedClass] 'int' can't be used as a superclass constraint.
''');

    var node = result.findNode.singleMixinOnClause;
    assertResolvedNodeText(node, r'''
MixinOnClause
  onKeyword: on
  superclassConstraints
    NamedType
      name: int
      element: dart:core::@class::int
      type: int
''');
  }
}
