// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/parser.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'recovery_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingCodeTest);
  });
}

/**
 * Tests that test how well Fasta recovers when valid syntactic elements are out
 * of order but could still be understood.
 */
@reflectiveTest
class MissingCodeTest extends AbstractRecoveryTest {
  @failingTest
  void test_conditionalExpression_missingThen() {
    testRecovery('''
f(x, z) => x ? : z
''', [ParserErrorCode.MISSING_IDENTIFIER], '''
f(x, z) => x ? _s_ : z
''');
  }

  void test_expectedTypeName_as() {
    testRecovery('''
convert(x) => x as ;
''', [ParserErrorCode.EXPECTED_TYPE_NAME], '''
convert(x) => x as _s_;
''');
  }
}
