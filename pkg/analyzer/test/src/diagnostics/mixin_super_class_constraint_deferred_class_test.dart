// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinSuperClassConstraintDeferredClassTest);
  });
}

@reflectiveTest
class MixinSuperClassConstraintDeferredClassTest
    extends PubPackageResolutionTest {
  test_error_onClause_deferredClass() async {
    await assertErrorsInCode(
      r'''
import 'dart:math' deferred as math;
mixin M on math.Random {}
''',
      [
        error(
          CompileTimeErrorCode.mixinSuperClassConstraintDeferredClass,
          48,
          11,
        ),
      ],
    );

    var node = findNode.singleMixinOnClause;
    assertResolvedNodeText(node, r'''
MixinOnClause
  onKeyword: on
  superclassConstraints
    NamedType
      importPrefix: ImportPrefixReference
        name: math
        period: .
        element2: <testLibraryFragment>::@prefix2::math
      name: Random
      element2: dart:math::@class::Random
      type: Random
''');
  }
}
