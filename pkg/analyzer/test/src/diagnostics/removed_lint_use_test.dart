// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/lint_registration_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemovedLintUseTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RemovedLintUseTest extends PubPackageResolutionTest
    with LintRegistrationMixin {
  @override
  void setUp() {
    super.setUp();

    // TODO(paulberry): remove as part of fixing
    // https://github.com/dart-lang/sdk/issues/62040.
    writeTestPackageAnalysisOptionsFile('''
linter:
  rules:
    - unnecessary_ignore
''');
  }

  test_file() async {
    await resolveTestCodeWithDiagnostics(r'''
// ignore_for_file: super_goes_last
//                  ^^^^^^^^^^^^^^^
// [diag.removedLintUse] 'super_goes_last' was removed in Dart '3.0.0'

void f() { }
''');
  }

  test_line() async {
    await resolveTestCodeWithDiagnostics(r'''
// ignore: super_goes_last
//         ^^^^^^^^^^^^^^^
// [diag.removedLintUse] 'super_goes_last' was removed in Dart '3.0.0'
void f() { }
''');
  }
}
