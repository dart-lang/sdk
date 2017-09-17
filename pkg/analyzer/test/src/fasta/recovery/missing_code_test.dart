// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'recovery_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingCodeTest);
  });
}

/**
 * Test how well the parser recovers when non-paired tokens are missing.
 */
@reflectiveTest
class MissingCodeTest extends AbstractRecoveryTest {
  @failingTest
  void test_ampersand() {
    // Parser crashes
    testBinaryExpression('&');
  }

  @failingTest
  void test_ampersand_super() {
    // Parser crashes
    testUserDefinableOperatorWithSuper('&');
  }

  void test_asExpression() {
    testRecovery('''
convert(x) => x as ;
''', [ParserErrorCode.EXPECTED_TYPE_NAME], '''
convert(x) => x as _s_;
''');
  }

  @failingTest
  void test_assignmentExpression() {
    // Parser crashes
    testRecovery('''
f() {
  var x;
  x = 
}
''', [ParserErrorCode.MISSING_IDENTIFIER], '''
f() {
  var x;
  x = _s_;
}
''');
  }

  @failingTest
  void test_bar() {
    // Parser crashes
    testBinaryExpression('|');
  }

  @failingTest
  void test_bar_super() {
    // Parser crashes
    testUserDefinableOperatorWithSuper('|');
  }

  @failingTest
  void test_combinatorsBeforePrefix() {
    //Expected 1 errors of type ParserErrorCode.MISSING_PREFIX_IN_DEFERRED_IMPORT, found 0
    testRecovery('''
import 'bar.dart' deferred;
''', [ParserErrorCode.MISSING_PREFIX_IN_DEFERRED_IMPORT], '''
import 'bar.dart' deferred as _s_;
''');
  }

  @failingTest
  void test_conditionalExpression_else() {
    // Parser crashes
    testRecovery('''
f() => x ? y : 
''', [ParserErrorCode.MISSING_IDENTIFIER], '''
f() => x ? y : _s_;
''');
  }

  @failingTest
  void test_conditionalExpression_then() {
    // Parser crashes
    testRecovery('''
f() => x ? : z
''', [ParserErrorCode.MISSING_IDENTIFIER], '''
f() => x ? _s_ : z;
''');
  }

  @failingTest
  void test_equalEqual() {
    // Parser crashes
    testBinaryExpression('==');
  }

  @failingTest
  void test_equalEqual_super() {
    // Parser crashes
    testUserDefinableOperatorWithSuper('==');
  }

  @failingTest
  void test_greaterThan() {
    // Parser crashes
    testBinaryExpression('>');
  }

  @failingTest
  void test_greaterThan_super() {
    // Parser crashes
    testUserDefinableOperatorWithSuper('>');
  }

  @failingTest
  void test_greaterThanGreaterThan() {
    // Parser crashes
    testBinaryExpression('>>');
  }

  @failingTest
  void test_greaterThanGreaterThan_super() {
    // Parser crashes
    testUserDefinableOperatorWithSuper('>>');
  }

  @failingTest
  void test_greaterThanOrEqual() {
    // Parser crashes
    testBinaryExpression('>=');
  }

  @failingTest
  void test_greaterThanOrEqual_super() {
    // Parser crashes
    testUserDefinableOperatorWithSuper('>=');
  }

  @failingTest
  void test_hat() {
    // Parser crashes
    testBinaryExpression('^');
  }

  @failingTest
  void test_hat_super() {
    // Parser crashes
    testUserDefinableOperatorWithSuper('^');
  }

  void test_isExpression() {
    testRecovery('''
f(x) {
  if (x is ) {}
}
''', [ParserErrorCode.EXPECTED_TYPE_NAME], '''
f(x) {
  if (x is _s_) {}
}
''');
  }

  @failingTest
  void test_lessThan() {
    // Parser crashes
    testBinaryExpression('<');
  }

  @failingTest
  void test_lessThan_super() {
    // Parser crashes
    testUserDefinableOperatorWithSuper('<');
  }

  @failingTest
  void test_lessThanLessThan() {
    // Parser crashes
    testBinaryExpression('<<');
  }

  @failingTest
  void test_lessThanLessThan_super() {
    // Parser crashes
    testUserDefinableOperatorWithSuper('<<');
  }

  @failingTest
  void test_lessThanOrEqual() {
    // Parser crashes
    testBinaryExpression('<=');
  }

  @failingTest
  void test_lessThanOrEqual_super() {
    // Parser crashes
    testUserDefinableOperatorWithSuper('<=');
  }

  @failingTest
  void test_minus() {
    // Parser crashes
    testBinaryExpression('-');
  }

  @failingTest
  void test_minus_super() {
    // Parser crashes
    testUserDefinableOperatorWithSuper('-');
  }

  @failingTest
  void test_percent() {
    // Parser crashes
    testBinaryExpression('%');
  }

  @failingTest
  void test_percent_super() {
    // Parser crashes
    testUserDefinableOperatorWithSuper('%');
  }

  @failingTest
  void test_plus() {
    // Parser crashes
    testBinaryExpression('+');
  }

  @failingTest
  void test_plus_super() {
    // Parser crashes
    testUserDefinableOperatorWithSuper('+');
  }

  @failingTest
  void test_slash() {
    // Parser crashes
    testBinaryExpression('/');
  }

  @failingTest
  void test_slash_super() {
    // Parser crashes
    testUserDefinableOperatorWithSuper('/');
  }

  @failingTest
  void test_star() {
    // Parser crashes
    testBinaryExpression('*');
  }

  @failingTest
  void test_star_super() {
    // Parser crashes
    testUserDefinableOperatorWithSuper('*');
  }

  @failingTest
  void test_tildeSlash() {
    // Parser crashes
    testBinaryExpression('~/');
  }

  @failingTest
  void test_tildeSlash_super() {
    // Parser crashes
    testUserDefinableOperatorWithSuper('~/');
  }

  void testBinaryExpression(String operator) {
    testRecovery('''
f() => x $operator
''', [ParserErrorCode.MISSING_IDENTIFIER], '''
f() => x $operator _s_;
''');
  }

  void testUserDefinableOperatorWithSuper(String operator) {
    testRecovery('''
class C {
  int operator $operator(x) => super $operator
}
''', [ParserErrorCode.MISSING_IDENTIFIER], '''
class C {
  int operator $operator(x) => super $operator _s_;
}
''');
  }
}
