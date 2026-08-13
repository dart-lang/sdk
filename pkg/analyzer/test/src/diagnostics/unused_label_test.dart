// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license[diff_block_end]
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedLabelTest);
    defineReflectiveTests(UnusedLabelTest_Language219);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnusedLabelTest extends PubPackageResolutionTest
    with UnusedLabelTestCases {}

@reflectiveTest
class UnusedLabelTest_Language219 extends PubPackageResolutionTest
    with WithLanguage219Mixin, UnusedLabelTestCases {}

mixin UnusedLabelTestCases on PubPackageResolutionTest {
  test_unused_inSwitch() async {
    await resolveTestCodeWithDiagnostics(r'''
f(x) {
  switch (x) {
    label: case 0:
//  ^^^^^^
// [diag.unusedLabel] The label 'label' isn't used.
      break;
    default:
      break;
  }
}
''');
  }

  test_unused_onWhile() async {
    await resolveTestCodeWithDiagnostics(r'''
f(condition()) {
  label: while (condition()) {
//^^^^^^
// [diag.unusedLabel] The label 'label' isn't used.
    break;
  }
}
''');
  }

  test_used_inSwitch() async {
    await resolveTestCodeWithDiagnostics(r'''
f(x) {
  switch (x) {
    label: case 0:
      break;
    default:
      continue label;
  }
}
''');
  }

  test_used_onWhile() async {
    await resolveTestCodeWithDiagnostics(r'''
f(condition()) {
  label: while (condition()) {
    break label;
  }
}
''');
  }
}
