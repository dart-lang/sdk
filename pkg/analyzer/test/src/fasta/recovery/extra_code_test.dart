// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'recovery_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MiscellaneousTest);
    defineReflectiveTests(ModifiersTest);
  });
}

/**
 * Test how well the parser recovers in other cases.
 */
@reflectiveTest
class MiscellaneousTest extends AbstractRecoveryTest {
  @failingTest
  void test_classTypeAlias_withBody() {
    // Parser crashes
    testRecovery('''
class B = Object with A {}
''', [ParserErrorCode.EXPECTED_TOKEN], '''
class B = Object with A;
''');
  }

  void test_getter_parameters() {
    testRecovery('''
int get g() => 0;
''', [ParserErrorCode.GETTER_WITH_PARAMETERS], '''
int get g => 0;
''');
  }
}

/**
 * Test how well the parser recovers when extra modifiers are provided.
 */
@reflectiveTest
class ModifiersTest extends AbstractRecoveryTest {
  void test_classDeclaration_static() {
    testRecovery('''
static class A {}
''', [ParserErrorCode.EXTRANEOUS_MODIFIER], '''
class A {}
''');
  }
}
