// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryCastPatternTest);
  });
}

@reflectiveTest
class UnnecessaryCastPatternTest extends PubPackageResolutionTest {
  test_matchedIsSameAsRequired() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  if (x case var z as int) {}
}
''',
      [
        error(diag.unusedLocalVariable, 33, 1),
        error(diag.unnecessaryCastPattern, 35, 2),
      ],
    );
  }

  test_matchedIsSubtypeOfRequired() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  if (x case var z as num) {}
}
''',
      [
        error(diag.unusedLocalVariable, 33, 1),
        error(diag.unnecessaryCastPattern, 35, 2),
      ],
    );
  }

  test_matchedIsSupertypeOfRequired() async {
    await assertErrorsInCode(
      r'''
void f(num x) {
  if (x case var z as int) {}
}
''',
      [error(diag.unusedLocalVariable, 33, 1)],
    );
  }

  test_matchedIsUnrelatedToRequired() async {
    await assertErrorsInCode(
      r'''
class A {}
class B {}

void f(A x) {
  if (x case var z as B) {}
}
''',
      [error(diag.unusedLocalVariable, 54, 1)],
    );
  }
}
