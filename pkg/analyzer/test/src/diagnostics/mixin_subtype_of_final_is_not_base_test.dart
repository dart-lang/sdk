// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinSubtypeOfFinalIsNotBaseTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MixinSubtypeOfFinalIsNotBaseTest extends PubPackageResolutionTest {
  test_implements() async {
    await resolveTestCodeWithDiagnostics(r'''
final class A {}
mixin B implements A {}
//    ^
// [diag.mixinSubtypeOfFinalIsNotBase] The mixin 'B' must be 'base' because the supertype 'A' is 'final'.
''');
  }

  test_implements_indirect() async {
    await resolveTestCodeWithDiagnostics(r'''
final class A {}
//          ^
// [context 1] The type 'B' is a subtype of 'A', and 'A' is defined here.
sealed class B implements A {}
mixin C implements B {}
//    ^
// [diag.mixinSubtypeOfFinalIsNotBase][context 1] The mixin 'C' must be 'base' because the supertype 'A' is 'final'.
''');
  }

  test_on() async {
    await resolveTestCodeWithDiagnostics(r'''
final class A {}
mixin B on A {}
//    ^
// [diag.mixinSubtypeOfFinalIsNotBase] The mixin 'B' must be 'base' because the supertype 'A' is 'final'.
''');
  }
}
