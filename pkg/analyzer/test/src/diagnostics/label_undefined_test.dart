// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LabelUndefinedTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class LabelUndefinedTest extends PubPackageResolutionTest {
  test_break() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  x: while (true) {
//^^
// [diag.unusedLabel] The label 'x' isn't used.
    break y;
//        ^
// [diag.labelUndefined] Can't reference an undefined label 'y'.
  }
}
''');
  }

  test_break_notLabel() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int x) {
  while (true) {
    break x;
//        ^
// [diag.labelUndefined] Can't reference an undefined label 'x'.
  }
}
''');
  }

  test_continue() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  x: while (true) {
//^^
// [diag.unusedLabel] The label 'x' isn't used.
    continue y;
//           ^
// [diag.labelUndefined] Can't reference an undefined label 'y'.
  }
}
''');
  }

  test_continue_notLabel() async {
    await resolveTestCodeWithDiagnostics(r'''
f(int x) {
  while (true) {
    continue x;
//           ^
// [diag.labelUndefined] Can't reference an undefined label 'x'.
  }
}
''');
  }
}
