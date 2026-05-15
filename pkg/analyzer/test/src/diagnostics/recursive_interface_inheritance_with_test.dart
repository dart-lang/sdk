// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveInterfaceInheritanceWithTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RecursiveInterfaceInheritanceWithTest extends PubPackageResolutionTest {
  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A extends Object {}
augment class A with A {}
''');
  }

  test_classTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class M = Object with M;
//          ^
// [diag.recursiveInterfaceInheritanceWith] 'M' can't use itself as a mixin.
''');
  }
}
