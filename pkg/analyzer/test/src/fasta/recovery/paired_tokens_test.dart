// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'recovery_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AngleBracketsTest);
    defineReflectiveTests(BracesTest);
    defineReflectiveTests(BracketsTest);
    defineReflectiveTests(ParenthesesTest);
  });
}

/**
 * Test how well the parser recovers when angle brackets (`<` and `>`) are
 * mismatched.
 */
@reflectiveTest
class AngleBracketsTest extends AbstractRecoveryTest {
  @failingTest
  void test_typeArguments_inner_last() {
    // Parser crashes
    testRecovery('''
List<List<int>
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
List<List<int>> _s_;
''');
  }

  @failingTest
  void test_typeArguments_inner_notLast() {
    // Parser crashes
    testRecovery('''
Map<List<int, List<String>>
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
Map<List<int>, List<String>> _s_;
''');
  }

  @failingTest
  void test_typeArguments_outer_last() {
    // Parser crashes
    testRecovery('''
List<int
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
List<int> _s_;
''');
  }
}

/**
 * Test how well the parser recovers when curly braces are mismatched.
 */
@reflectiveTest
class BracesTest extends AbstractRecoveryTest {
  void test_statement_if_last() {
    testRecovery('''
f(x) {
  if (x != null) {
}
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
f(x) {
  if (x != null) {}
}
''');
  }

  @failingTest
  void test_statement_if_while() {
    // Expected a list of length 2; found a list of length 1
    testRecovery('''
f(x) {
  if (x != null) {
  while (x == null) {}
}
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
f(x) {
  if (x != null) {}
  while (x == null) {}
}
''');
  }

  @failingTest
  void test_unit_functionBody_class() {
    // Parser crashes
    testRecovery('''
f(x) {
class C {}
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
f(x) {}
class C {}
''');
  }

  @failingTest
  void test_unit_functionBody_function() {
    // Expected a list of length 2; found a list of length 1
    testRecovery('''
f(x) {
g(y) => y;
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
f(x) {}
g(y) => y;
''');
  }

  void test_unit_functionBody_last() {
    testRecovery('''
f(x) {
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
f(x) {}
''');
  }

  @failingTest
  void test_unit_functionBody_variable() {
    // Expected a list of length 2; found a list of length 1
    testRecovery('''
f(x) {
int y = 0;
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
f(x) {}
int y = 0;
''');
  }
}

/**
 * Test how well the parser recovers when square brackets are mismatched.
 */
@reflectiveTest
class BracketsTest extends AbstractRecoveryTest {
  @failingTest
  void test_indexOperator() {
    // Parser crashes
    testRecovery('''
f(x) => l[x
''', [ScannerErrorCode.EXPECTED_TOKEN, ScannerErrorCode.EXPECTED_TOKEN], '''
f(x) => l[x];
''');
  }

  @failingTest
  void test_listLiteral_inner_last() {
    // Parser crashes
    testRecovery('''
var x = [[0], [1];
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
var x = [[0], [1]];
''');
  }

  @failingTest
  void test_listLiteral_inner_notLast() {
    // Parser crashes
    testRecovery('''
var x = [[0], [1, [2]];
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
var x = [[0], [1], [2]];
''');
  }

  @failingTest
  void test_listLiteral_outer_last() {
    // Parser crashes
    testRecovery('''
var x = [0, 1
''', [ScannerErrorCode.EXPECTED_TOKEN, ScannerErrorCode.EXPECTED_TOKEN], '''
var x = [0, 1];
''');
  }
}

/**
 * Test how well the parser recovers when parentheses are mismatched.
 */
@reflectiveTest
class ParenthesesTest extends AbstractRecoveryTest {
  @failingTest
  void test_if_last() {
    // Parser crashes
    testRecovery('''
f(x) {
  if (x
}
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
f(x) {
  if (x);
}
''');
  }

  @failingTest
  void test_if_while() {
    // Parser crashes
    testRecovery('''
f(x) {
  if (x
  while(x != null) {}
}
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
f(x) {
  if (x);
  while(x != null) {}
}
''');
  }

  @failingTest
  void test_parameterList_class() {
    // Parser crashes
    testRecovery('''
f(x
class C {}
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
f(x) {}
class C {}
''');
  }

  @failingTest
  void test_parameterList_eof() {
    // Parser crashes
    testRecovery('''
f(x
''', [ScannerErrorCode.EXPECTED_TOKEN], '''
f(x) {}
''');
  }
}
