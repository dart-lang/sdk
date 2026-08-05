// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedCatchClauseTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnusedCatchClauseTest extends PubPackageResolutionTest {
  test_on_unusedException() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  try {
  } on String catch (exception) {
//                   ^^^^^^^^^
// [diag.unusedCatchClause] The exception variable 'exception' isn't used, so the 'catch' clause can be removed.
  }
}
''');
  }

  test_on_unusedStack_underscores() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  try {
  } on String catch (exception, __) {
//                              ^^
// [diag.unusedCatchStack] The stack trace variable '__' isn't used and can be removed.
  }
}
''');
  }

  test_on_usedException() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  try {
  } on String catch (exception) {
    print(exception);
  }
}
''');
  }

  test_unusedException() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  try {
  } catch (exception) {
  }
}
''');
  }

  test_unusedException_underscores() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  try {
  } catch (__) {
  }
}
''');
  }

  test_unusedException_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  try {
  } catch (_) {
  }
}
''');
  }

  test_usedException() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  try {
  } catch (exception) {
    print(exception);
  }
}
''');
  }
}
