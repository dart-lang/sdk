// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NumberLiteralsWithSeparatorsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NumberLiteralsWithSeparatorsTest extends PubPackageResolutionTest {
  Future<void> test_double_with_separators_and_e() async {
    await resolveTestCodeWithDiagnostics('''
double x = 1.234_567e2;
''');
  }

  Future<void> test_missing_number_after_e_1() async {
    await resolveTestCodeWithDiagnostics('''
dynamic x = 1_234_567e;
//                   ^
// [diag.missingDigit] Decimal digit expected.
''');
  }

  Future<void> test_missing_number_after_e_2() async {
    await resolveTestCodeWithDiagnostics('''
dynamic x = 1.234_567e;
//                   ^
// [diag.missingDigit] Decimal digit expected.
''');
  }

  Future<void> test_other_erroneous_1() async {
    await resolveTestCodeWithDiagnostics('''
dynamic x = 1_1e;
//             ^
// [diag.missingDigit] Decimal digit expected.
''');
  }

  Future<void> test_other_erroneous_2() async {
    await resolveTestCodeWithDiagnostics('''
dynamic x = 1_e;
//          ^
// [diag.unexpectedSeparatorInNumber] Digit separators ('_') in a number literal can only be placed between two digits.
//            ^
// [diag.missingDigit] Decimal digit expected.
''');
  }

  Future<void> test_other_erroneous_3() async {
    await resolveTestCodeWithDiagnostics('''
dynamic x = 1e_;
//          ^
// [diag.unexpectedSeparatorInNumber] Digit separators ('_') in a number literal can only be placed between two digits.
//            ^
// [diag.missingDigit] Decimal digit expected.
''');
  }

  Future<void> test_other_erroneous_4() async {
    await resolveTestCodeWithDiagnostics('''
dynamic x = 1e-_;
//          ^
// [diag.unexpectedSeparatorInNumber] Digit separators ('_') in a number literal can only be placed between two digits.
//             ^
// [diag.missingDigit] Decimal digit expected.
''');
  }

  Future<void> test_other_erroneous_5() async {
    await resolveTestCodeWithDiagnostics('''
dynamic x = 1e-_1;
//          ^
// [diag.unexpectedSeparatorInNumber] Digit separators ('_') in a number literal can only be placed between two digits.
''');
  }

  Future<void> test_other_erroneous_6() async {
    await resolveTestCodeWithDiagnostics('''
dynamic x = 1e+_;
//          ^
// [diag.unexpectedSeparatorInNumber] Digit separators ('_') in a number literal can only be placed between two digits.
//             ^
// [diag.missingDigit] Decimal digit expected.
''');
  }

  Future<void> test_other_erroneous_7() async {
    await resolveTestCodeWithDiagnostics('''
dynamic x = 1e+_1;
//          ^
// [diag.unexpectedSeparatorInNumber] Digit separators ('_') in a number literal can only be placed between two digits.
''');
  }

  Future<void> test_simple_double_with_separators() async {
    await resolveTestCodeWithDiagnostics('''
double x = 1.234_567;
''');
  }

  Future<void> test_simple_int_with_separators() async {
    await resolveTestCodeWithDiagnostics('''
int x = 1_234_567;
''');
  }
}
