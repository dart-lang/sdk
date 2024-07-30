// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IntegerLiteralOutOfRangeTest);
  });
}

@reflectiveTest
class IntegerLiteralOutOfRangeTest extends PubPackageResolutionTest {
  test_hex() async {
    await assertErrorsInCode('''
int x = 0xFFFF_FFFF_FFFF_FFFF_FFFF;
''', [
      error(
        CompileTimeErrorCode.INTEGER_LITERAL_OUT_OF_RANGE,
        8,
        26,
        messageContains: [RegExp('0xFFFF_FFFF_FFFF_FFFF_FFFF')],
      ),
    ]);
  }

  test_negative() async {
    await assertErrorsInCode('''
int x = -9223372036854775809;
''', [
      error(CompileTimeErrorCode.INTEGER_LITERAL_OUT_OF_RANGE, 9, 19),
    ]);
  }

  test_positive() async {
    await assertErrorsInCode('''
int x = 9223372036854775808;
''', [
      error(CompileTimeErrorCode.INTEGER_LITERAL_OUT_OF_RANGE, 8, 19),
    ]);
  }

  test_separators() async {
    await assertErrorsInCode('''
int x = 9_223_372_036_854_775_808;
''', [
      error(
        CompileTimeErrorCode.INTEGER_LITERAL_OUT_OF_RANGE,
        8,
        25,
        messageContains: [RegExp('9_223_372_036_854_775_808')],
      ),
    ]);
  }
}
