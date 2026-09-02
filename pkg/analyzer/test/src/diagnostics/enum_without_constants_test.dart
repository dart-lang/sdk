// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumWithoutConstantsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class EnumWithoutConstantsTest extends PubPackageResolutionTest {
  test_hasConstants_inAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {}
augment enum E {
  v
}
''');
  }

  test_noConstants() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {}
//   ^
// [diag.enumWithoutConstants] The enum must have at least one enum constant.
''');
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_noConstants_hasAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {}
augment enum E {}
''');
  }
}
