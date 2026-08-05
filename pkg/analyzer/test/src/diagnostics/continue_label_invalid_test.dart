// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContinueLabelInvalidTest);
  });
}

@reflectiveTest
class ContinueLabelInvalidTest extends PubPackageResolutionTest {
  test_onBlock() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  L:
  {
    for (var i in []) {
//           ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
      continue L;
//    ^^^^^^^^^^^
// [diag.continueLabelInvalid] The label used in a 'continue' statement must be defined on either a loop or a switch member.
    }
  }
}
''');
  }

  test_onSwitchStatement() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  L: switch (x) {
    case 0:
      continue L;
//    ^^^^^^^^^^^
// [diag.continueLabelInvalid] The label used in a 'continue' statement must be defined on either a loop or a switch member.
  }
}
''');
  }

  test_onSwitchStatement_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
void f(int x) {
  L: switch (x) {
    case 0:
      continue L;
//    ^^^^^^^^^^^
// [diag.continueLabelInvalid] The label used in a 'continue' statement must be defined on either a loop or a switch member.
  }
}
''');
  }
}
