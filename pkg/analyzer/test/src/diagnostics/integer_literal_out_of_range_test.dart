// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
int x = 0xFFFF_FFFF_FFFF_FFFF_FFFF;
//      ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.integerLiteralOutOfRange] The integer literal 0xFFFF_FFFF_FFFF_FFFF_FFFF can't be represented in 64 bits.
''');
  }

  test_negative() async {
    await resolveTestCodeWithDiagnostics(r'''
int x = -9223372036854775809;
//       ^^^^^^^^^^^^^^^^^^^
// [diag.integerLiteralOutOfRange] The integer literal -9223372036854775809 can't be represented in 64 bits.
''');
  }

  test_positive() async {
    await resolveTestCodeWithDiagnostics(r'''
int x = 9223372036854775808;
//      ^^^^^^^^^^^^^^^^^^^
// [diag.integerLiteralOutOfRange] The integer literal 9223372036854775808 can't be represented in 64 bits.
''');
  }

  test_separators() async {
    await resolveTestCodeWithDiagnostics(r'''
int x = 9_223_372_036_854_775_808;
//      ^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.integerLiteralOutOfRange] The integer literal 9_223_372_036_854_775_808 can't be represented in 64 bits.
''');
  }
}
