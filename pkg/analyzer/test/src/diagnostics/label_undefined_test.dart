// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LabelUndefinedTest);
  });
}

@reflectiveTest
class LabelUndefinedTest extends PubPackageResolutionTest {
  test_break() async {
    await assertErrorsInCode(
      r'''
f() {
  x: while (true) {
    break y;
  }
}
''',
      [
        error(WarningCode.unusedLabel, 8, 2),
        error(CompileTimeErrorCode.labelUndefined, 36, 1),
      ],
    );
  }

  test_break_notLabel() async {
    await assertErrorsInCode(
      r'''
f(int x) {
  while (true) {
    break x;
  }
}
''',
      [error(CompileTimeErrorCode.labelUndefined, 38, 1)],
    );
  }

  test_continue() async {
    await assertErrorsInCode(
      r'''
f() {
  x: while (true) {
    continue y;
  }
}
''',
      [
        error(WarningCode.unusedLabel, 8, 2),
        error(CompileTimeErrorCode.labelUndefined, 39, 1),
      ],
    );
  }

  test_continue_notLabel() async {
    await assertErrorsInCode(
      r'''
f(int x) {
  while (true) {
    continue x;
  }
}
''',
      [error(CompileTimeErrorCode.labelUndefined, 41, 1)],
    );
  }
}
