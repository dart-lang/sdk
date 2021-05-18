// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/lint_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

/// TODO(scheglov) Remove the file after fixing the linter.
/// https://github.com/dart-lang/sdk/issues/46039
main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidTypesAsParameterNamesTest);
  });
}

@reflectiveTest
class AvoidTypesAsParameterNamesTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        lints: [
          'avoid_types_as_parameter_names',
        ],
      ),
    );
  }

  test_fieldFormalParameter() async {
    await assertNoErrorsInCode(r'''
class A {
  final int num;
  const A(this.num);
}
''');
  }

  test_simpleFormalParameter_function() async {
    await assertErrorsInCode(r'''
void f(int) {}
''', [
      error(LintCode('avoid_types_as_parameter_names', ''), 7, 3),
    ]);
  }
}
