// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryCastPatternTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnnecessaryCastPatternTest extends PubPackageResolutionTest {
  test_matchedIsSameAsRequired() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case var z as int) {}
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'z' isn't used.
//                 ^^
// [diag.unnecessaryCastPattern] Unnecessary cast pattern.
}
''');
  }

  test_matchedIsSubtypeOfRequired() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  if (x case var z as num) {}
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'z' isn't used.
//                 ^^
// [diag.unnecessaryCastPattern] Unnecessary cast pattern.
}
''');
  }

  test_matchedIsSupertypeOfRequired() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(num x) {
  if (x case var z as int) {}
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'z' isn't used.
}
''');
  }

  test_matchedIsUnrelatedToRequired() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}

void f(A x) {
  if (x case var z as B) {}
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'z' isn't used.
}
''');
  }
}
