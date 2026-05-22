// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinSuperClassConstraintDeferredClassTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MixinSuperClassConstraintDeferredClassTest
    extends PubPackageResolutionTest {
  test_error_onClause_deferredClass() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' deferred as math;
mixin M on math.Random {}
//         ^^^^^^^^^^^
// [diag.mixinSuperClassConstraintDeferredClass] Deferred classes can't be used as superclass constraints.
''');

    var node = result.findNode.singleMixinOnClause;
    assertResolvedNodeText(node, r'''
MixinOnClause
  onKeyword: on
  superclassConstraints
    NamedType
      importPrefix: ImportPrefixReference
        name: math
        period: .
        element: <testLibraryFragment>::@prefix::math
      name: Random
      element: dart:math::@class::Random
      type: Random
''');
  }
}
