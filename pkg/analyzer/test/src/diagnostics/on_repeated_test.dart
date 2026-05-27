// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OnRepeatedTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class OnRepeatedTest extends PubPackageResolutionTest {
  test_2times() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin M on A, A {}
//            ^
// [diag.onRepeated] The type 'A' can be included in the superclass constraints only once.
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_2times_augmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin M on A {}
augment mixin M on A {}
''');
  }

  test_2times_viaTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
typedef B = A;
mixin M on A, B {}
//            ^
// [diag.onRepeated] The type 'A' can be included in the superclass constraints only once.
''');
  }
}
