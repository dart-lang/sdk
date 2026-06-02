// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedCatchStackTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnusedCatchStackTest extends PubPackageResolutionTest {
  test_on_unusedStack() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  try {} on String catch (exception, stackTrace) {
//                                   ^^^^^^^^^^
// [diag.unusedCatchStack] The stack trace variable 'stackTrace' isn't used and can be removed.
  }
}
''');
  }

  test_on_usedStack() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  try {} on String catch (exception, stackTrace) {
    print(stackTrace);
  }
}
''');
  }

  test_unusedStack() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  try {} catch (exception, stackTrace) {
//                         ^^^^^^^^^^
// [diag.unusedCatchStack] The stack trace variable 'stackTrace' isn't used and can be removed.
  }
}
''');
  }

  test_usedStack() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  try {} catch (exception, stackTrace) {
    print(stackTrace);
  }
}
''');
  }
}
