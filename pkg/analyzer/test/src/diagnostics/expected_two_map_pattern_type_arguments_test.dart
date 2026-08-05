// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExpectedTwoMapPatternTypeArgumentsTest);
  });
}

@reflectiveTest
class ExpectedTwoMapPatternTypeArgumentsTest extends PubPackageResolutionTest {
  test_0() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case {0: _}) {}
}
''');
  }

  test_1() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case <int>{0: _}) {}
//           ^^^^^
// [diag.expectedTwoMapPatternTypeArguments] Map patterns require two type arguments or none, but 1 found.
}
''');
  }

  test_2() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case <bool, int>{0: _}) {}
}
''');
  }

  test_3() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case <bool, int, String>{0: _}) {}
//           ^^^^^^^^^^^^^^^^^^^
// [diag.expectedTwoMapPatternTypeArguments] Map patterns require two type arguments or none, but 3 found.
}
''');
  }
}
