// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  Expect.equals('0: int', differentFinalityNotUsedInBody(0, 0));
  Expect.equals('1: final int', differentFinalityNotUsedInBody(1, 1));
  Expect.equals('2: var', differentFinalityNotUsedInBody(2, 2));
  Expect.equals('3: final', differentFinalityNotUsedInBody(3, 3));

  Expect.equals('0: int', differentTypeNotUsedInBody(0, 0));
  Expect.equals('true: bool', differentTypeNotUsedInBody(1, true));
  Expect.equals('s: var', differentTypeNotUsedInBody(2, 's'));

  Expect.equals('unique: unique', differentVariableNotUsedInBody(0, 'unique'));
  Expect.equals('in: inTwo', differentVariableNotUsedInBody(1, 'in'));
  Expect.equals('two: inTwo', differentVariableNotUsedInBody(2, 'two'));

  Expect.equals('one: var', sharedAnnotatedAndUnannotated(0, 'one'));
  Expect.equals('two: Object', sharedAnnotatedAndUnannotated(1, 'two'));

  Expect.equals('one: var', sharedAnnotatedAndPromotionInferred(0, 'one'));
  Expect.equals('two: String', sharedAnnotatedAndPromotionInferred(1, 'two'));

  Expect.equals('0: 0: list', sharedDifferentContext([0, true]));
  Expect.equals('1: 1: map', sharedDifferentContext({'a': 1, 'b': true}));
  Expect.equals('2: 2: record', sharedDifferentContext((a: 2, b: true)));
  Expect.equals('3: 3: nested', sharedDifferentContext((a: 3, b: [true])));
}

/// OK if variables in different cases have different finality if not used in
/// the body.
Object? differentFinalityNotUsedInBody(int caseKey, Object value) {
  switch ((caseKey, value)) {
    case (0, int x) when _guard(x, 'int'):
    case (1, final int x) when _guard(x, 'final int'):
    case (2, var x) when _guard(x, 'var'):
    case (3, final x) when _guard(x, 'final'):
      return _matchedCase();
    default:
      Expect.fail('Should not reach this.');
  }
}

/// OK if variables in different cases have different types if not used in the
/// body.
Object? differentTypeNotUsedInBody(int caseKey, Object value) {
  switch ((caseKey, value)) {
    case (0, int x) when _guard(x, 'int'):
    case (1, bool x) when _guard(x, 'bool'):
    case (2, var x) when _guard(x, 'var'): // Infer Object.
      return _matchedCase();
    default:
      Expect.fail('Should not reach this.');
  }
}

/// OK if some variables only exist in some cases if they aren't used in the
/// body.
Object? differentVariableNotUsedInBody(int caseKey, Object value) {
  switch ((caseKey, value)) {
    case (0, var unique) when _guard(unique, 'unique'):
    case (1, var inTwo) when _guard(inTwo, 'inTwo'):
    case (2, var inTwo) when _guard(inTwo, 'inTwo'):
      return _matchedCase();
    default:
      Expect.fail('Should not reach this.');
  }
}

/// Variables can be shared if not all are annotated as long as the inferred
/// type matches.
Object? sharedAnnotatedAndUnannotated(int caseKey, Object value) {
  switch ((caseKey, value)) {
    case (0, var a) when _guard(a, 'var'):
    case (1, Object a) when _guard(a, 'Object'):
      // Use pattern variable in body:
      Expect.equals(value, a);
      return _matchedCase();
    default:
      Expect.fail('Should not reach this.');
  }
}

/// Variables can be shared if not all are annotated as long as the type
/// inferred using promotion matches.
Object? sharedAnnotatedAndPromotionInferred(int caseKey, Object value) {
  // Promote value to String.
  if (value is String) {
    switch ((caseKey, value)) {
      case (0, var a) when _guard(a, 'var'):
      case (1, String a) when _guard(a, 'String'):
        // Use pattern variable in body:
        Expect.equals(value, a);
        return _matchedCase();
      default:
        Expect.fail('Should not reach this.');
    }
  }
}

/// Variables can be shared even when they occur in different contexts in their
/// respective patterns.
Object? sharedDifferentContext(Object value) {
  // OK, since inferred type is same as annotated.
  switch (value) {
    case [int a, bool b] when _guard(a, 'list'):
    case {'b': bool b, 'a': int a} when _guard(a, 'map'):
    case (a: int a, b: bool b) when _guard(a, 'record'):
    case (a: int a, b: [bool b]) when _guard(a, 'nested'):
      // Use pattern variables in body:
      return '$a: ${_matchedCase()}';
    default:
      Expect.fail('Should not reach this.');
  }
}

String _lastMatch = 'none';

bool _guard(Object guardVariable, String label) {
  _lastMatch = '$guardVariable: $label';
  return true;
}

String _matchedCase() {
  var result = _lastMatch;
  _lastMatch = 'none';
  return result;
}
