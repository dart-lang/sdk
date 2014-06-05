// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library parser_test;

import 'package:polymer_expressions/parser.dart';
import 'package:polymer_expressions/expression.dart';
import 'package:unittest/unittest.dart';

expectParse(String s, Expression e) =>
    expect(new Parser(s).parse(), e, reason: s);

main() {

  group('parser', () {

    test('should parse an empty expression', () {
      expectParse('', empty());
    });

    test('should parse an identifier', () {
      expectParse('abc', ident('abc'));
    });

    test('should parse a string literal', () {
      expectParse('"abc"', literal('abc'));
    });

    test('should parse a bool literal', () {
      expectParse('true', literal(true));
      expectParse('false', literal(false));
    });

    test('should parse a null literal', () {
      expectParse('null', literal(null));
    });

    test('should parse an integer literal', () {
      expectParse('123', literal(123));
    });

    test('should parse a double literal', () {
      expectParse('1.23', literal(1.23));
    });

    test('should parse a positive double literal', () {
      expectParse('+1.23', literal(1.23));
    });

    test('should parse a negative double literal', () {
      expectParse('-1.23', literal(-1.23));
    });

    test('should parse binary operators', () {
      var operators = ['+', '-', '*', '/', '%', '^', '==', '!=', '>', '<',
          '>=', '<=', '||', '&&', '&', '===', '!=='];
      for (var op in operators) {
        expectParse('a $op b', binary(ident('a'), op, ident('b')));
        expectParse('1 $op 2', binary(literal(1), op, literal(2)));
        expectParse('this $op null', binary(ident('this'), op, literal(null)));
      }
    });

    test('should give multiply higher associativity than plus', () {
      expectParse('a + b * c',
          binary(ident('a'), '+', binary(ident('b'), '*', ident('c'))));
      expectParse('a * b + c',
          binary(binary(ident('a'), '*', ident('b')), '+', ident('c')));
    });

    test('should parse a dot operator', () {
      expectParse('a.b', getter(ident('a'), 'b'));
    });

    test('should parse chained dot operators', () {
      expectParse('a.b.c', getter(getter(ident('a'), 'b'), 'c'));
    });

    test('should give dot high associativity', () {
      expectParse('a * b.c', binary(ident('a'), '*', getter(ident('b'), 'c')));
    });

    test('should parse a function with no arguments', () {
      expectParse('a()', invoke(ident('a'), null, []));
    });

    test('should parse a single function argument', () {
      expectParse('a(b)', invoke(ident('a'), null, [ident('b')]));
    });

    test('should parse a function call as a subexpression', () {
      expectParse('a() + 1',
          binary(
              invoke(ident('a'), null, []),
              '+',
              literal(1)));
    });

    test('should parse multiple function arguments', () {
      expectParse('a(b, c)',
          invoke(ident('a'), null, [ident('b'), ident('c')]));
    });

    test('should parse nested function calls', () {
      expectParse('a(b(c))', invoke(ident('a'), null, [
          invoke(ident('b'), null, [ident('c')])]));
    });

    test('should parse an empty method call', () {
      expectParse('a.b()', invoke(ident('a'), 'b', []));
    });

    test('should parse a method call with a single argument', () {
      expectParse('a.b(c)', invoke(ident('a'), 'b', [ident('c')]));
    });

    test('should parse a method call with multiple arguments', () {
      expectParse('a.b(c, d)',
          invoke(ident('a'), 'b', [ident('c'), ident('d')]));
    });

    test('should parse chained method calls', () {
      expectParse('a.b().c()', invoke(invoke(ident('a'), 'b', []), 'c', []));
    });

    test('should parse chained function calls', () {
      expectParse('a()()', invoke(invoke(ident('a'), null, []), null, []));
    });

    test('should parse parenthesized expression', () {
      expectParse('(a)', paren(ident('a')));
      expectParse('(( 3 * ((1 + 2)) ))', paren(paren(
          binary(literal(3), '*', paren(paren(
              binary(literal(1), '+', literal(2))))))));
    });

    test('should parse an index operator', () {
      expectParse('a[b]', index(ident('a'), ident('b')));
      expectParse('a.b[c]', index(getter(ident('a'), 'b'), ident('c')));
    });

    test('should parse chained index operators', () {
      expectParse('a[][]', index(index(ident('a'), null), null));
    });

    test('should parse multiple index operators', () {
      expectParse('a[b] + c[d]', binary(
          index(ident('a'), ident('b')),
          '+',
          index(ident('c'), ident('d'))));
    });

    test('should parse ternary operators', () {
      expectParse('a ? b : c', ternary(ident('a'), ident('b'), ident('c')));
      expectParse('a.a ? b.a : c.a', ternary(getter(ident('a'), 'a'),
          getter(ident('b'), 'a'), getter(ident('c'), 'a')));
      expect(() => parse('a + 1 ? b + 1 :: c.d + 3'), throws);
    });

    test('ternary operators have lowest associativity', () {
      expectParse('a == b ? c + d : e - f', ternary(
            binary(ident('a'), '==', ident('b')),
            binary(ident('c'), '+', ident('d')),
            binary(ident('e'), '-', ident('f'))));

      expectParse('a.x == b.y ? c + d : e - f', ternary(
            binary(getter(ident('a'), 'x'), '==', getter(ident('b'), 'y')),
            binary(ident('c'), '+', ident('d')),
            binary(ident('e'), '-', ident('f'))));

      expectParse('a.x == b.y ? c + d : e - f', ternary(
            binary(getter(ident('a'), 'x'), '==', getter(ident('b'), 'y')),
            binary(ident('c'), '+', ident('d')),
            binary(ident('e'), '-', ident('f'))));
    });

    test('should parse a filter chain', () {
      expectParse('a | b | c', binary(binary(ident('a'), '|', ident('b')),
          '|', ident('c')));
    });

    test('should parse "in" expression', () {
      expectParse('a in b', inExpr(ident('a'), ident('b')));
      expectParse('a in b.c',
          inExpr(ident('a'), getter(ident('b'), 'c')));
      expectParse('a in b + c',
          inExpr(ident('a'), binary(ident('b'), '+', ident('c'))));
    });

    test('should reject comprehension with non-assignable left expression', () {
      expect(() => parse('a + 1 in b'), throwsException);
    });

    test('should parse "as" expressions', () {
      expectParse('a as b', asExpr(ident('a'), ident('b')));
    });

    skip_test('should reject keywords as identifiers', () {
      expect(() => parse('a.in'), throws);
      expect(() => parse('a.as'), throws);
      // TODO: re-enable when 'this' is a keyword
//      expect(() => parse('a.this'), throws);
    });

    test('should parse map literals', () {
      expectParse("{'a': 1}",
          mapLiteral([mapLiteralEntry(literal('a'), literal(1))]));
      expectParse("{'a': 1, 'b': 2 + 3}",
          mapLiteral([
              mapLiteralEntry(literal('a'), literal(1)),
              mapLiteralEntry(literal('b'),
                  binary(literal(2), '+', literal(3)))]));
      expectParse("{'a': foo()}",
          mapLiteral([mapLiteralEntry(
              literal('a'), invoke(ident('foo'), null, []))]));
      expectParse("{'a': foo('a')}",
          mapLiteral([mapLiteralEntry(
              literal('a'), invoke(ident('foo'), null, [literal('a')]))]));
    });

    test('should parse map literals with method calls', () {
      expectParse("{'a': 1}.length",
          getter(mapLiteral([mapLiteralEntry(literal('a'), literal(1))]),
              'length'));
    });

    test('should parse list literals', () {
      expectParse('[1, "a", b]',
          listLiteral([literal(1), literal('a'), ident('b')]));
      expectParse('[[1, 2], [3, 4]]',
          listLiteral([listLiteral([literal(1), literal(2)]),
                       listLiteral([literal(3), literal(4)])]));
    });
  });
}
