// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnignorableIgnoreTest);
  });
}

@reflectiveTest
class UnignorableIgnoreTest extends PubPackageResolutionTest {
  test_file_lowerCase() async {
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(unignorableNames: ['undefined_annotation']),
    );
    await assertErrorsInCode(r'''
// ignore_for_file: undefined_annotation
@x int a = 0;
''', [
      error(CompileTimeErrorCode.UNDEFINED_ANNOTATION, 41, 2),
    ]);
  }

  test_file_upperCase() async {
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(unignorableNames: ['UNDEFINED_ANNOTATION']),
    );
    await assertErrorsInCode(r'''
// ignore_for_file: UNDEFINED_ANNOTATION
@x int a = 0;
''', [
      error(CompileTimeErrorCode.UNDEFINED_ANNOTATION, 41, 2),
    ]);
  }

  test_line() async {
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(unignorableNames: ['undefined_annotation']),
    );
    await assertErrorsInCode(r'''
// ignore: undefined_annotation
@x int a = 0;
''', [
      error(CompileTimeErrorCode.UNDEFINED_ANNOTATION, 32, 2),
    ]);
  }
}
