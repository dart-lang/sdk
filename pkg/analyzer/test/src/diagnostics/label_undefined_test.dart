// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
      [error(diag.unusedLabel, 8, 2), error(diag.labelUndefined, 36, 1)],
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
      [error(diag.labelUndefined, 38, 1)],
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
      [error(diag.unusedLabel, 8, 2), error(diag.labelUndefined, 39, 1)],
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
      [error(diag.labelUndefined, 41, 1)],
    );
  }
}
