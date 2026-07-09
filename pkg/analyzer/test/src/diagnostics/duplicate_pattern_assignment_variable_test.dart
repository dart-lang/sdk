// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicatePatternAssignmentVariableTest);
  });
}

@reflectiveTest
class DuplicatePatternAssignmentVariableTest extends PubPackageResolutionTest {
  test_nested() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int a;
  (a && int(sign: a)) = 0;
// ^
// [context 1] The first assigned variable pattern.
//                ^
// [diag.duplicatePatternAssignmentVariable][context 1] The variable 'a' is already assigned in this pattern.
  a;
}
''');
  }

  test_record_2() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int a;
  (a, a) = (1, 2);
// ^
// [context 1] The first assigned variable pattern.
//    ^
// [diag.duplicatePatternAssignmentVariable][context 1] The variable 'a' is already assigned in this pattern.
  a;
}
''');
  }

  test_record_3() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int a;
  (a, a, a) = (1, 2, 3);
// ^
// [context 1] The first assigned variable pattern.
// [context 2] The first assigned variable pattern.
//    ^
// [diag.duplicatePatternAssignmentVariable][context 1] The variable 'a' is already assigned in this pattern.
//       ^
// [diag.duplicatePatternAssignmentVariable][context 2] The variable 'a' is already assigned in this pattern.
  a;
}
''');
  }

  test_separate() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int a;
  (a) = 1;
  (a) = 2;
  a;
}
''');
  }
}
