// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NumberLiteralsWithSeparatorsTest);
  });
}

@reflectiveTest
class NumberLiteralsWithSeparatorsTest extends PubPackageResolutionTest {
  Future<void> assertHasErrors(String code) async {
    addTestFile(code);
    await resolveTestFile();
    expect(result.diagnostics, isNotEmpty);
  }

  Future<void> test_double_with_separators_and_e() async {
    await assertNoErrorsInCode('double x = 1.234_567e2;');
  }

  Future<void> test_missing_number_after_e_1() async {
    await assertErrorsInCode('dynamic x = 1_234_567e;', [
      error(ScannerErrorCode.missingDigit, 21, 1),
    ]);
  }

  Future<void> test_missing_number_after_e_2() async {
    await assertErrorsInCode('dynamic x = 1.234_567e;', [
      error(ScannerErrorCode.missingDigit, 21, 1),
    ]);
  }

  Future<void> test_other_erroneous_1() async {
    await assertHasErrors('dynamic x = 1_1e;');
  }

  Future<void> test_other_erroneous_2() async {
    await assertHasErrors('dynamic x = 1_e;');
  }

  Future<void> test_other_erroneous_3() async {
    await assertHasErrors('dynamic x = 1e_;');
  }

  Future<void> test_other_erroneous_4() async {
    await assertHasErrors('dynamic x = 1e-_;');
  }

  Future<void> test_other_erroneous_5() async {
    await assertHasErrors('dynamic x = 1e-_1;');
  }

  Future<void> test_other_erroneous_6() async {
    await assertHasErrors('dynamic x = 1e+_;');
  }

  Future<void> test_other_erroneous_7() async {
    await assertHasErrors('dynamic x = 1e+_1;');
  }

  Future<void> test_simple_double_with_separators() async {
    await assertNoErrorsInCode('double x = 1.234_567;');
  }

  Future<void> test_simple_int_with_separators() async {
    await assertNoErrorsInCode('int x = 1_234_567;');
  }
}
