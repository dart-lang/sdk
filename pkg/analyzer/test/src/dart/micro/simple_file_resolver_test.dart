// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'file_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileResolverTest);
  });
}

@reflectiveTest
class FileResolverTest extends FileResolutionTest {
  test_analysisOptions_default_fromPackageUri() async {
    newFile('/workspace/dart/analysis_options/lib/default.yaml', content: r'''
analyzer:
  strong-mode:
    implicit-casts: false
''');

    await assertErrorsInCode(r'''
num a = 0;
int b = a;
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 19, 1),
    ]);
  }

  test_analysisOptions_file_inPackage() async {
    newFile('/workspace/dart/test/analysis_options.yaml', content: r'''
analyzer:
  strong-mode:
    implicit-casts: false
''');

    await assertErrorsInCode(r'''
num a = 0;
int b = a;
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 19, 1),
    ]);
  }

  test_analysisOptions_lints() async {
    newFile('/workspace/dart/analysis_options/lib/default.yaml', content: r'''
linter:
  rules:
    - omit_local_variable_types
''');

    var rule = Registry.ruleRegistry.getRule('omit_local_variable_types');

    await assertErrorsInCode(r'''
main() {
  int a = 0;
  a;
}
''', [
      error(rule.lintCode, 11, 9),
    ]);
  }

  test_analysisOptions_no() async {
    await assertNoErrorsInCode(r'''
num a = 0;
int b = a;
''');
  }

  test_basic() async {
    await assertNoErrorsInCode(r'''
int a = 0;
var b = 1 + 2;
''');
    assertType(findElement.topVar('a').type, 'int');
    assertElement(findNode.simple('int a'), intElement);

    assertType(findElement.topVar('b').type, 'int');
  }
}
