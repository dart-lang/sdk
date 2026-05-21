// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateIgnoreTest);
  });
}

@reflectiveTest
class DuplicateIgnoreTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageAnalysisOptionsFile(
      analysisOptionsContent(
        experiments: experiments,
        rules: ['avoid_types_as_parameter_names'],
      ),
    );
  }

  test_name_file() async {
    await resolveTestCodeWithDiagnostics(r'''
// ignore_for_file: unused_local_variable, unused_local_variable
//                                         ^^^^^^^^^^^^^^^^^^^^^
// [diag.duplicateIgnore] The diagnostic 'unused_local_variable' doesn't need to be ignored here because it's already being ignored.
void f() {
  var x = 0;
}
''');
  }

  test_name_line() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  // ignore: unused_local_variable, unused_local_variable
//                                  ^^^^^^^^^^^^^^^^^^^^^
// [diag.duplicateIgnore] The diagnostic 'unused_local_variable' doesn't need to be ignored here because it's already being ignored.
  var x = 0;
}
''');
  }

  test_name_lineAndFile() async {
    await resolveTestCodeWithDiagnostics(r'''
// ignore_for_file: unused_local_variable
void f() {
  // ignore: unused_local_variable
//           ^^^^^^^^^^^^^^^^^^^^^
// [diag.duplicateIgnore] The diagnostic 'unused_local_variable' doesn't need to be ignored here because it's already being ignored.
  var x = 0;
}
''');
  }

  test_type_file() async {
    await resolveTestCodeWithDiagnostics(r'''
// ignore_for_file: type=lint, TYPE=LINT
//                             ^^^^^^^^^
// [diag.duplicateIgnore] The diagnostic 'lint' doesn't need to be ignored here because it's already being ignored.
void f(arg1(int)) {} // AVOID_TYPES_AS_PARAMETER_NAMES
''');
  }

  test_type_line() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {}
// ignore: type=lint, TYPE=LINT
//                    ^^^^^^^^^
// [diag.duplicateIgnore] The diagnostic 'lint' doesn't need to be ignored here because it's already being ignored.
void g(arg1(int)) {} // AVOID_TYPES_AS_PARAMETER_NAMES
''');
  }

  test_type_lineAndFile() async {
    await resolveTestCodeWithDiagnostics(r'''
// ignore_for_file: type=lint
void f() {}
// ignore: type=lint
//         ^^^^^^^^^
// [diag.duplicateIgnore] The diagnostic 'lint' doesn't need to be ignored here because it's already being ignored.
void g(arg1(int)) {} // AVOID_TYPES_AS_PARAMETER_NAMES
''');
  }
}
