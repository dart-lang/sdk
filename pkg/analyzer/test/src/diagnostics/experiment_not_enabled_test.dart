// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExperimentNotEnabledTest);
  });
}

@reflectiveTest
class ExperimentNotEnabledTest extends PubPackageResolutionTest {
  test_nonFunctionTypeAliases_disabled() async {
    await assertErrorsInCode(r'''
// @dart = 2.12
typedef A = int;
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 26, 1),
    ]);
  }

  test_nonFunctionTypeAliases_disabled_nullable() async {
    await assertErrorsInCode(r'''
// @dart = 2.12
typedef A = int?;
''', [
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 26, 1),
    ]);
  }
}
