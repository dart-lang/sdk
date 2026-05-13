// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveInterfaceInheritanceOnTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RecursiveInterfaceInheritanceOnTest extends PubPackageResolutionTest {
  test_1() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A on A {}
//    ^
// [diag.recursiveInterfaceInheritanceOn] 'A' can't use itself as a superclass constraint.
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_1_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {}
augment mixin A on A {}
''');
  }

  test_2() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A on B {}
//    ^
// [diag.recursiveInterfaceInheritance] 'A' can't be a superinterface of itself: B, A.
mixin B on A {}
//    ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: B, A.
''');
  }
}
