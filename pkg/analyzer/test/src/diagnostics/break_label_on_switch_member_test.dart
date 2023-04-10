// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BreakLabelOnSwitchMemberTest);
  });
}

@reflectiveTest
class BreakLabelOnSwitchMemberTest extends PubPackageResolutionTest {
  test_it() async {
    await assertErrorsInCode(r'''
void f(int x) {
  switch (x) {
    L: case 0:
      break;
    case 1:
      break L;
  }
}
''', [
      error(CompileTimeErrorCode.BREAK_LABEL_ON_SWITCH_MEMBER, 83, 1),
    ]);
  }

  test_it_language219() async {
    await assertErrorsInCode(r'''
// @dart = 2.19
void f(int x) {
  switch (x) {
    L: case 0:
      break;
    case 1:
      break L;
  }
}
''', [
      error(CompileTimeErrorCode.BREAK_LABEL_ON_SWITCH_MEMBER, 99, 1),
    ]);
  }
}
