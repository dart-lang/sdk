// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinSubtypeOfBaseIsNotBaseTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MixinSubtypeOfBaseIsNotBaseTest extends PubPackageResolutionTest {
  test_class_implements() async {
    await resolveTestCodeWithDiagnostics(r'''
base class A {}
mixin B implements A {}
//    ^
// [diag.mixinSubtypeOfBaseIsNotBase] The mixin 'B' must be 'base' because the supertype 'A' is 'base'.
''');
  }

  test_class_implements_indirect() async {
    await resolveTestCodeWithDiagnostics(r'''
base class A {}
//         ^
// [context 1] The type 'B' is a subtype of 'A', and 'A' is defined here.
sealed class B implements A {}
mixin C implements B {}
//    ^
// [diag.mixinSubtypeOfBaseIsNotBase][context 1] The mixin 'C' must be 'base' because the supertype 'A' is 'base'.
''');
  }

  test_class_on() async {
    await resolveTestCodeWithDiagnostics(r'''
base class A {}
mixin B on A {}
//    ^
// [diag.mixinSubtypeOfBaseIsNotBase] The mixin 'B' must be 'base' because the supertype 'A' is 'base'.
''');
  }

  test_mixin_implements() async {
    await resolveTestCodeWithDiagnostics(r'''
base mixin A {}
mixin B implements A {}
//    ^
// [diag.mixinSubtypeOfBaseIsNotBase] The mixin 'B' must be 'base' because the supertype 'A' is 'base'.
''');
  }
}
