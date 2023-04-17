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
    await assertErrorsInCode(r'''
import 'dart:math' deferred as math;
mixin M on math.Random {}
''', [
      error(CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DEFERRED_CLASS,
          48, 11),
    ]);

    final node = findNode.singleOnClause;
    assertResolvedNodeText(node, r'''
OnClause
  onKeyword: on
  superclassConstraints
    NamedType
      name: PrefixedIdentifier
        prefix: SimpleIdentifier
          token: math
          staticElement: self::@prefix::math
          staticType: null
        period: .
        identifier: SimpleIdentifier
          token: Random
          staticElement: dart:math::@class::Random
          staticType: null
        staticElement: dart:math::@class::Random
        staticType: null
      type: Random
''');
  }
}
