// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IntegerLiteralImpreciseAsDoubleTest);
  });
}

@reflectiveTest
class IntegerLiteralImpreciseAsDoubleTest extends PubPackageResolutionTest {
  test_excessiveExponent() async {
    await assertErrorsInCode(
      'double x = 0xfffffffffffff8000000000000000000000000000000000000000000000'
      '000000000000000000000000000000000000000000000000000000000000000000000000'
      '000000000000000000000000000000000000000000000000000000000000000000000000'
      '000000000000000000000000000000000000000000000000000000;',
      [
        error(
          CompileTimeErrorCode.INTEGER_LITERAL_IMPRECISE_AS_DOUBLE,
          11,
          259,
          correctionContains:
              // We suggest the max double instead.
              '1797693134862315708145274237317043567980705675258449965989174768'
              '0315726078002853876058955863276687817154045895351438246423432132'
              '6889464182768467546703537516986049910576551282076245490090389328'
              '9440758685084551339423045832369032229481658085593321233482747978'
              '26204144723168738177180919299881250404026184124858368',
        ),
      ],
    );
  }

  test_excessiveMantissa() async {
    await assertErrorsInCode('''
double x = 9223372036854775809;
''', [
      error(
        CompileTimeErrorCode.INTEGER_LITERAL_IMPRECISE_AS_DOUBLE, 11, 19,
        // We suggest a valid double instead.
        correctionContains: '9223372036854775808',
      ),
    ]);
  }

  test_excessiveMantissa_withSeparators() async {
    await assertErrorsInCode('''
double x = 9_223_372_036_854_775_809;
''', [
      error(
        CompileTimeErrorCode.INTEGER_LITERAL_IMPRECISE_AS_DOUBLE, 11, 25,
        // We suggest a valid double instead.
        // TODO(srawlins): This number should have separators that match the
        // existing number literal.
        correctionContains: '9223372036854775808',
      ),
    ]);
  }
}
