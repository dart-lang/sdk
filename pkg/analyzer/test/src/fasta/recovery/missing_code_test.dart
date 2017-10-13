// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'recovery_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingCodeTest);
    defineReflectiveTests(ParameterListTest);
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

  @failingTest
  void test_asExpression_missingLeft() {
    testRecovery('''
convert(x) => as T;
''', [ParserErrorCode.EXPECTED_TYPE_NAME], '''
convert(x) => _s_ as T;
''');
  }

  void test_asExpression_missingRight() {
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

  void test_isExpression_missingLeft() {
    testRecovery('''
f() {
  if (is String) {
  }
}
''', [ParserErrorCode.MISSING_IDENTIFIER], '''
f() {
  if (_s_ is String) {
  }
}
''');
  }

  void test_isExpression_missingRight() {
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

  void test_prefixedIdentifier() {
    testRecovery('''
f() {
  var v = 'String';
  v.
}
''', [ParserErrorCode.MISSING_IDENTIFIER, ParserErrorCode.EXPECTED_TOKEN], '''
f() {
  var v = 'String';
  v._s_;
}
''');
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

/**
 * Test how well the parser recovers when tokens are missing in a parameter
 * list.
 */
@reflectiveTest
class ParameterListTest extends AbstractRecoveryTest {
  @failingTest
  void test_extraComma_named_last() {
    testRecovery('''
f({a, }) {}
''', [ParserErrorCode.MISSING_IDENTIFIER], '''
f({a, _s_}) {}
''');
  }

  @failingTest
  void test_extraComma_named_noLast() {
    testRecovery('''
f({a, , b}) {}
''', [ParserErrorCode.MISSING_IDENTIFIER], '''
f({a, _s_, b}) {}
''');
  }

  @failingTest
  void test_extraComma_positional_last() {
    testRecovery('''
f([a, ]) {}
''', [ParserErrorCode.MISSING_IDENTIFIER], '''
f([a, _s_]) {}
''');
  }

  @failingTest
  void test_extraComma_positional_noLast() {
    testRecovery('''
f([a, , b]) {}
''', [ParserErrorCode.MISSING_IDENTIFIER], '''
f([a, _s_, b]) {}
''');
  }

  @failingTest
  void test_extraComma_required_last() {
    testRecovery('''
f(a, ) {}
''', [ParserErrorCode.MISSING_IDENTIFIER], '''
f(a, _s_) {}
''');
  }

  @failingTest
  void test_extraComma_required_noLast() {
    testRecovery('''
f(a, , b) {}
''', [ParserErrorCode.MISSING_IDENTIFIER], '''
f(a, _s_, b) {}
''');
  }

  void test_fieldFormalParameter_noPeriod_last() {
    testRecovery('''
class C {
  int f;
  C(this);
}
''', [ParserErrorCode.UNEXPECTED_TOKEN, ParserErrorCode.MISSING_IDENTIFIER], '''
class C {
  int f;
  C(this._s_);
}
''');
  }

  void test_fieldFormalParameter_noPeriod_notLast() {
    testRecovery('''
class C {
  int f;
  C(this, p);
}
''', [ParserErrorCode.UNEXPECTED_TOKEN, ParserErrorCode.MISSING_IDENTIFIER], '''
class C {
  int f;
  C(this._s_, p);
}
''');
  }

  void test_fieldFormalParameter_period_last() {
    testRecovery('''
class C {
  int f;
  C(this.);
}
''', [ParserErrorCode.MISSING_IDENTIFIER], '''
class C {
  int f;
  C(this._s_);
}
''');
  }

  void test_fieldFormalParameter_period_notLast() {
    testRecovery('''
class C {
  int f;
  C(this., p);
}
''', [ParserErrorCode.MISSING_IDENTIFIER], '''
class C {
  int f;
  C(this._s_, p);
}
''');
  }

  @failingTest
  void test_incorrectlyTerminatedGroup_named_none() {
    testRecovery('''
f({a: 0) {}
''', [ParserErrorCode.MISSING_TERMINATOR_FOR_PARAMETER_GROUP], '''
f({a: 0}) {}
''');
  }

  @failingTest
  void test_incorrectlyTerminatedGroup_named_positional() {
    testRecovery('''
f({a: 0]) {}
''', [ParserErrorCode.WRONG_TERMINATOR_FOR_PARAMETER_GROUP], '''
f({a: 0}) {}
''');
  }

  @failingTest
  void test_incorrectlyTerminatedGroup_none_named() {
    testRecovery('''
f(a}) {}
''', [ParserErrorCode.UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP], '''
f(a) {}
''');
  }

  @failingTest
  void test_incorrectlyTerminatedGroup_none_positional() {
    testRecovery('''
f(a]) {}
''', [ParserErrorCode.UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP], '''
f(a) {}
''');
  }

  @failingTest
  void test_incorrectlyTerminatedGroup_positional_named() {
    testRecovery('''
f([a = 0}) {}
''', [ParserErrorCode.WRONG_TERMINATOR_FOR_PARAMETER_GROUP], '''
f([a = 0]) {}
''');
  }

  @failingTest
  void test_incorrectlyTerminatedGroup_positional_none() {
    // Maybe put in paired_tokens_test.dart.
    testRecovery('''
f([a = 0) {}
''', [ParserErrorCode.MISSING_TERMINATOR_FOR_PARAMETER_GROUP], '''
f([a = 0]) {}
''');
  }

  void test_missingDefault_named_last() {
    testRecovery('''
f({a: }) {}
''', [ParserErrorCode.MISSING_IDENTIFIER], '''
f({a: _s_}) {}
''');
  }

  void test_missingDefault_named_notLast() {
    testRecovery('''
f({a: , b}) {}
''', [ParserErrorCode.MISSING_IDENTIFIER], '''
f({a: _s_, b}) {}
''');
  }

  void test_missingDefault_positional_last() {
    testRecovery('''
f([a = ]) {}
''', [ParserErrorCode.MISSING_IDENTIFIER], '''
f([a = _s_]) {}
''');
  }

  void test_missingDefault_positional_notLast() {
    testRecovery('''
f([a = , b]) {}
''', [ParserErrorCode.MISSING_IDENTIFIER], '''
f([a = _s_, b]) {}
''');
  }

  @failingTest
  void test_multipleGroups_mixed() {
    // TODO(brianwilkerson) Figure out the best way to recover from this.
    testRecovery('''
f([a = 0], {b: 1}) {}
''', [ParserErrorCode.MIXED_PARAMETER_GROUPS], '''
f([a = 0]) {}
''');
  }

  @failingTest
  void test_multipleGroups_mixedAndMultiple() {
    // TODO(brianwilkerson) Figure out the best way to recover from this.
    testRecovery('''
f([a = 0], {b: 1}, [c = 2]) {}
''', [ParserErrorCode.MIXED_PARAMETER_GROUPS], '''
f([a = 0, c = 2]) {}
''');
  }

  @failingTest
  void test_multipleGroups_named() {
    testRecovery('''
f({a: 0}, {b: 1}) {}
''', [ParserErrorCode.MULTIPLE_NAMED_PARAMETER_GROUPS], '''
f({a: 0, b: 1}) {}
''');
  }

  @failingTest
  void test_multipleGroups_positional() {
    testRecovery('''
f([a = 0], [b = 1]) {}
''', [ParserErrorCode.MULTIPLE_POSITIONAL_PARAMETER_GROUPS], '''
f([a = 0, b = 1]) {}
''');
  }

  @failingTest
  void test_namedOutsideGroup() {
    testRecovery('''
f(a: 0) {}
''', [ParserErrorCode.NAMED_PARAMETER_OUTSIDE_GROUP], '''
f({a: 0}) {}
''');
  }

  @failingTest
  void test_positionalOutsideGroup() {
    testRecovery('''
f(a = 0) {}
''', [ParserErrorCode.POSITIONAL_PARAMETER_OUTSIDE_GROUP], '''
f([a = 0]) {}
''');
  }
}
