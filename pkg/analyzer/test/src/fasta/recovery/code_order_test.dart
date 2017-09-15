// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/parser.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'recovery_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CodeOrderTest);
  });
}

/**
 * Tests that test how well Fasta recovers when valid syntactic elements are out
 * of order but could still be understood.
 */
@reflectiveTest
class CodeOrderTest extends AbstractRecoveryTest {
  @failingTest
  void test_implementsBeforeExtends() {
    testRecovery('''
class A implements B extends C {}
''', [ParserErrorCode.IMPLEMENTS_BEFORE_EXTENDS], '''
class A extends C implements B {}
''');
  }
}
