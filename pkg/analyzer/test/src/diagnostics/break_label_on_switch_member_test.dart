// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BreakLabelOnSwitchMemberTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class BreakLabelOnSwitchMemberTest extends PubPackageResolutionTest {
  test_it() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  switch (x) {
    L: case 0:
      break;
    case 1:
      break L;
//          ^
// [diag.breakLabelOnSwitchMember] A break label resolves to the 'case' or 'default' statement.
  }
}
''');
  }

  test_it_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
void f(int x) {
  switch (x) {
    L: case 0:
      break;
    case 1:
      break L;
//          ^
// [diag.breakLabelOnSwitchMember] A break label resolves to the 'case' or 'default' statement.
  }
}
''');
  }
}
