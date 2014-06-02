// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tokenizer_test;

import 'package:polymer_expressions/tokenizer.dart';
import 'package:unittest/unittest.dart';

main() {

  group('tokenizer', () {

    test('should tokenize an empty expression', () {
      expectTokens('', []);
    });

    test('should tokenize an identifier', () {
      expectTokens('abc', [t(IDENTIFIER_TOKEN, 'abc')]);
    });

    test('should tokenize a double quoted String', () {
      expectTokens('"abc"', [t(STRING_TOKEN, 'abc')]);
    });

    test('should tokenize a single quoted String', () {
      expectTokens("'abc'", [t(STRING_TOKEN, 'abc')]);
    });

    test('should tokenize a String with escaping', () {
      expectTokens('"a\\b\\\\c\\\'\\""', [t(STRING_TOKEN, 'ab\\c\'"')]);
    });

    test('should tokenize a dot operator', () {
      expectTokens('a.b', [
          t(IDENTIFIER_TOKEN, 'a'),
          t(DOT_TOKEN, '.'),
          t(IDENTIFIER_TOKEN, 'b')]);
    });

    test('should tokenize a unary plus operator', () {
      expectTokens('+a', [
          t(OPERATOR_TOKEN, '+'),
          t(IDENTIFIER_TOKEN, 'a')]);
    });

    test('should tokenize a binary plus operator', () {
      expectTokens('a + b', [
          t(IDENTIFIER_TOKEN, 'a'),
          t(OPERATOR_TOKEN, '+'),
          t(IDENTIFIER_TOKEN, 'b')]);
    });

    test('should tokenize a logical and operator', () {
      expectTokens('a && b', [
          t(IDENTIFIER_TOKEN, 'a'),
          t(OPERATOR_TOKEN, '&&'),
          t(IDENTIFIER_TOKEN, 'b')]);
    });

    test('should tokenize a ternary operator', () {
      expectTokens('a ? b : c', [
          t(IDENTIFIER_TOKEN, 'a'),
          t(OPERATOR_TOKEN, '?'),
          t(IDENTIFIER_TOKEN, 'b'),
          t(COLON_TOKEN, ':'),
          t(IDENTIFIER_TOKEN, 'c')]);
    });

    test('should tokenize "in" expressions', () {
      expectTokens('item in items', [
          t(IDENTIFIER_TOKEN, 'item'),
          t(KEYWORD_TOKEN, 'in'),
          t(IDENTIFIER_TOKEN, 'items')]);
    });

    test('should takenize an "as" expression', () {
      expectTokens('a as b', [
          t(IDENTIFIER_TOKEN, 'a'),
          t(KEYWORD_TOKEN, 'as'),
          t(IDENTIFIER_TOKEN, 'b')]);
    });

    test('should tokenize keywords', () {
      expectTokens('in', [t(KEYWORD_TOKEN, 'in')]);
      expectTokens('as', [t(KEYWORD_TOKEN, 'as')]);
      expectTokens('this', [t(KEYWORD_TOKEN, 'this')]);
    });

    test('should tokenize groups', () {
      expectTokens('a(b)[]{}', [
          t(IDENTIFIER_TOKEN, 'a'),
          t(GROUPER_TOKEN, '('),
          t(IDENTIFIER_TOKEN, 'b'),
          t(GROUPER_TOKEN, ')'),
          t(GROUPER_TOKEN, '['),
          t(GROUPER_TOKEN, ']'),
          t(GROUPER_TOKEN, '{'),
          t(GROUPER_TOKEN, '}')]);
    });

    test('should tokenize argument lists', () {
      expectTokens('(a, b)', [
          t(GROUPER_TOKEN, '('),
          t(IDENTIFIER_TOKEN, 'a'),
          t(COMMA_TOKEN, ','),
          t(IDENTIFIER_TOKEN, 'b'),
          t(GROUPER_TOKEN, ')')]);
    });

    test('should tokenize maps', () {
      expectTokens("{'a': b}", [
          t(GROUPER_TOKEN, '{'),
          t(STRING_TOKEN, 'a'),
          t(COLON_TOKEN, ':'),
          t(IDENTIFIER_TOKEN, 'b'),
          t(GROUPER_TOKEN, '}')]);
    });

    test('should tokenize lists', () {
      expectTokens("[1, 'a', b]", [
          t(GROUPER_TOKEN, '['),
          t(INTEGER_TOKEN, '1'),
          t(COMMA_TOKEN, ','),
          t(STRING_TOKEN, 'a'),
          t(COMMA_TOKEN, ','),
          t(IDENTIFIER_TOKEN, 'b'),
          t(GROUPER_TOKEN, ']')]);
    });

    test('should tokenize integers', () {
      expectTokens('123', [t(INTEGER_TOKEN, '123')]);
      expectTokens('+123', [t(OPERATOR_TOKEN, '+'), t(INTEGER_TOKEN, '123')]);
      expectTokens('-123', [t(OPERATOR_TOKEN, '-'), t(INTEGER_TOKEN, '123')]);
    });

    test('should tokenize decimals', () {
      expectTokens('1.23', [t(DECIMAL_TOKEN, '1.23')]);
      expectTokens('+1.23', [t(OPERATOR_TOKEN, '+'), t(DECIMAL_TOKEN, '1.23')]);
      expectTokens('-1.23', [t(OPERATOR_TOKEN, '-'), t(DECIMAL_TOKEN, '1.23')]);
    });

    test('should tokenize booleans as identifiers', () {
      expectTokens('true', [t(IDENTIFIER_TOKEN, 'true')]);
      expectTokens('false', [t(IDENTIFIER_TOKEN, 'false')]);
    });

  });
}

TokenMatcher isToken(int index, String text) => new TokenMatcher(index, text);

class TokenMatcher extends Matcher {
  final int kind;
  final String value;

  TokenMatcher(this.kind, this.value);

  bool matches(Token t, Map m) => t.kind == kind && t.value == value;

  Description describe(Description d) => d.add('isToken($kind, $value) ');
}

expectTokens(String s, List<Token> expected) {
  var tokens = new Tokenizer(s).tokenize();
  var matchers = expected.map((t) => isToken(t.kind, t.value)).toList();
  expect(tokens, matchList(matchers), reason: s);
}

Token t(int kind, String value) => new Token(kind, value);

MatcherList matchList(List matchers) => new MatcherList(matchers);

class MatcherList extends Matcher {
  final List<Matcher> matchers;

  MatcherList(this.matchers);

  bool matches(List o, Map matchState) {
    if (o.length != matchers.length) return false;
    for (int i = 0; i < o.length; i++) {
      var state = new Map();
      if (!matchers[i].matches(o[i], state)) {
        matchState.addAll({
          'index': i,
          'value': o[i],
          'state': state,
        });
        return false;
      }
    }
    return true;
  }

  Description describe(Description d) {
    d.add('matches all: ');
    matchers.forEach((m) => m.describe(d));
  }

  Description describeMismatch(item, Description mismatchDescription,
      Map matchState, bool verbose) {
    if (matchState != null) {
      var index = matchState['index'];
      var value = matchState['value'];
      var state = matchState['state'];
      var matcher = matchers[index];
      mismatchDescription.add("Mismatch at index $index: ");
      matcher.describeMismatch(value, mismatchDescription, state, verbose);
    } else {
      if (item.length != matchers.length) {
        mismatchDescription.add('wrong lengths');
      } else {
        mismatchDescription.add('was ').addDescriptionOf(item);
      }
    }
  }

}
