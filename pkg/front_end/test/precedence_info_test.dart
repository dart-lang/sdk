// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/scanner/string_scanner.dart';
import 'package:front_end/src/fasta/scanner/token.dart' as fasta;
import 'package:front_end/src/scanner/token.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrecedenceInfoTest);
  });
}

/// Assert that fasta PrecedenceInfo implements analyzer TokenType.
@reflectiveTest
class PrecedenceInfoTest {
  void assertInfo(check(String source, Token token)) {
    void assertLexeme(String source) {
      if (source == null || source.isEmpty) return;
      var scanner = new StringScanner(source, includeComments: true);
      var token = scanner.tokenize();
      check(source, token);
    }

    for (TokenType type in TokenType.all) {
      assertLexeme(type.value);
    }
    assertLexeme('1.0'); // DOUBLE
    assertLexeme('0xA'); // HEXADECIMAL
    assertLexeme('1'); // INT
    assertLexeme('var'); // KEYWORD
    assertLexeme('#!/'); // SCRIPT_TAG
    assertLexeme('"foo"'); // STRING
    assertLexeme('bar'); // IDENTIFIER
    assertLexeme('&&=');
    assertLexeme('||=');
  }

  void test_isOperator() {
    var operatorLexemes = new Set<String>.from(const [
      '&',
      '&&',
      '&&=',
      '&=',
      '!',
      '!=',
      '|',
      '||',
      '||=',
      '|=',
      '^',
      '^=',
      '=',
      '==',
      '>',
      '>=',
      '>>',
      '>>=',
      '[]',
      '[]=',
      '<',
      '<=',
      '<<',
      '<<=',
      '-',
      '-=',
      '--',
      '%',
      '%=',
      '..',
      '+',
      '+=',
      '++',
      '?',
      '?.',
      '??',
      '??=',
      '/',
      '/=',
      '*',
      '*=',
      '~',
      '~/',
      '~/=',
    ]);

    assertInfo((String source, Token token) {
      expect(token.isOperator, operatorLexemes.contains(source),
          reason: source);
      expect(token.type.isOperator, operatorLexemes.contains(source),
          reason: source);
    });
  }

  void test_isAdditiveOperator() {
    var additiveLexemes = [
      '-',
      '+',
    ];
    assertInfo((String source, Token token) {
      expect(token.type.isAdditiveOperator, additiveLexemes.contains(source),
          reason: source);
    });
  }

  void test_isAssignmentOperator() {
    const assignmentLexemes = const [
      '&=',
      '&&=',
      '|=',
      '||=',
      '^=',
      '=',
      '>>=',
      '<<=',
      '-=',
      '%=',
      '+=',
      '??=',
      '/=',
      '*=',
      '~/=',
    ];
    assertInfo((String source, Token token) {
      expect(
          token.type.isAssignmentOperator, assignmentLexemes.contains(source),
          reason: source);
    });
  }

  void test_isAssociativeOperator() {
    const associativeLexemes = const [
      '&',
      '&&',
      '|',
      '||',
      '^',
      '+',
      '*',
    ];
    assertInfo((String source, Token token) {
      expect(
          token.type.isAssociativeOperator, associativeLexemes.contains(source),
          reason: source);
    });
  }

  void test_isEqualityOperator() {
    const equalityLexemes = const [
      '!=',
      '==',
    ];
    assertInfo((String source, Token token) {
      expect(token.type.isEqualityOperator, equalityLexemes.contains(source),
          reason: source);
    });
  }

  void test_isIncrementOperator() {
    const incrementLexemes = const [
      '--',
      '++',
    ];
    assertInfo((String source, Token token) {
      expect(token.type.isIncrementOperator, incrementLexemes.contains(source),
          reason: source);
    });
  }

  void test_isMultiplicativeOperator() {
    const multiplicativeLexemes = const [
      '%',
      '/',
      '*',
      '~/',
    ];
    assertInfo((String source, Token token) {
      expect(token.type.isMultiplicativeOperator,
          multiplicativeLexemes.contains(source),
          reason: source);
    });
  }

  void test_isRelationalOperator() {
    const relationalLexemes = const [
      '>',
      '>=',
      '<',
      '<=',
    ];
    assertInfo((String source, Token token) {
      expect(
          token.type.isRelationalOperator, relationalLexemes.contains(source),
          reason: source);
    });
  }

  void test_isShiftOperator() {
    const shiftLexemes = const [
      '>>',
      '<<',
    ];
    assertInfo((String source, Token token) {
      expect(token.type.isShiftOperator, shiftLexemes.contains(source),
          reason: source);
    });
  }

  void test_isUnaryPostfixOperator() {
    const unaryPostfixLexemes = const [
      '--',
      '(',
      '[',
      '.',
      '++',
      '?.',
      '[]',
    ];
    assertInfo((String source, Token token) {
      expect(token.type.isUnaryPostfixOperator,
          unaryPostfixLexemes.contains(source),
          reason: source);
    });
  }

  void test_isUnaryPrefixOperator() {
    const unaryPrefixLexemes = const [
      '!',
      '--',
      '++',
      '~',
    ];
    assertInfo((String source, Token token) {
      expect(
          token.type.isUnaryPrefixOperator, unaryPrefixLexemes.contains(source),
          reason: source);
    });
  }

  void test_isUserDefinableOperator() {
    const userDefinableOperatorLexemes = const [
      '&',
      '|',
      '^',
      '==',
      '>',
      '>=',
      '>>',
      '[]',
      '[]=',
      '<',
      '<=',
      '<<',
      '-',
      '%',
      '+',
      '/',
      '*',
      '~',
      '~/',
    ];
    assertInfo((String source, Token token) {
      var userDefinable = userDefinableOperatorLexemes.contains(source);
      expect(token.type.isUserDefinableOperator, userDefinable, reason: source);
      expect(token.isUserDefinableOperator, userDefinable, reason: source);
      expect(fasta.isUserDefinableOperator(token.lexeme), userDefinable,
          reason: source);
    });
  }

  void test_name() {
    void assertName(String source, String name, {int offset: 0}) {
      if (source == null || source.isEmpty) return;
      var scanner = new StringScanner(source, includeComments: true);
      var token = scanner.tokenize();
      while (token.offset < offset) {
        token = token.next;
      }
      expect(token.type.name, name,
          reason: 'source: $source\ntoken: ${token.lexeme}');
    }

    assertName('&', 'AMPERSAND');
    assertName('&&', 'AMPERSAND_AMPERSAND');
    assertName('&=', 'AMPERSAND_EQ');
    assertName('@', 'AT');
    assertName('!', 'BANG');
    assertName('!=', 'BANG_EQ');
    assertName('|', 'BAR');
    assertName('||', 'BAR_BAR');
    assertName('|=', 'BAR_EQ');
    assertName(':', 'COLON');
    assertName(',', 'COMMA');
    assertName('^', 'CARET');
    assertName('^=', 'CARET_EQ');
    assertName('}', 'CLOSE_CURLY_BRACKET');
    assertName(')', 'CLOSE_PAREN');
    assertName(']', 'CLOSE_SQUARE_BRACKET');
    assertName('=', 'EQ');
    assertName('==', 'EQ_EQ');
    assertName('=>', 'FUNCTION');
    assertName('>', 'GT');
    assertName('>=', 'GT_EQ');
    assertName('>>', 'GT_GT');
    assertName('>>=', 'GT_GT_EQ');
    assertName('#', 'HASH');
    assertName('[]', 'INDEX');
    assertName('[]=', 'INDEX_EQ');
    assertName('<', 'LT');
    assertName('<=', 'LT_EQ');
    assertName('<<', 'LT_LT');
    assertName('<<=', 'LT_LT_EQ');
    assertName('-', 'MINUS');
    assertName('-=', 'MINUS_EQ');
    assertName('--', 'MINUS_MINUS');
    assertName('{', 'OPEN_CURLY_BRACKET');
    assertName('(', 'OPEN_PAREN');
    assertName('[', 'OPEN_SQUARE_BRACKET');
    assertName('%', 'PERCENT');
    assertName('%=', 'PERCENT_EQ');
    assertName('.', 'PERIOD');
    assertName('..', 'PERIOD_PERIOD');
    assertName('+', 'PLUS');
    assertName('+=', 'PLUS_EQ');
    assertName('++', 'PLUS_PLUS');
    assertName('?', 'QUESTION');
    assertName('?.', 'QUESTION_PERIOD');
    assertName('??', 'QUESTION_QUESTION');
    assertName('??=', 'QUESTION_QUESTION_EQ');
    assertName(';', 'SEMICOLON');
    assertName('/', 'SLASH');
    assertName('/=', 'SLASH_EQ');
    assertName('*', 'STAR');
    assertName('*=', 'STAR_EQ');
    assertName('"\${', 'STRING_INTERPOLATION_EXPRESSION', offset: 1);
    assertName('"\$', 'STRING_INTERPOLATION_IDENTIFIER', offset: 1);
    assertName('~', 'TILDE');
    assertName('~/', 'TILDE_SLASH');
    assertName('~/=', 'TILDE_SLASH_EQ');
    assertName('`', 'BACKPING');
    assertName('\\', 'BACKSLASH');
    assertName('...', 'PERIOD_PERIOD_PERIOD');
  }

  /// Assert precedence as per the Dart language spec
  ///
  /// Prefix "++" and "--" are excluded from the prefix (15) list
  /// because they are interpreted as being in the postfix (16) list.
  /// Leading "-" is excluded from the precedence 15 list
  /// because it is interpreted as a minus token (precedence 13).
  void test_precedence() {
    const precedenceTable = const <int, List<String>>{
      16: const <String>['.', '?.', '++', '--', '[', '('],
      15: const <String>['!', '~'], // excluded '-', '++', '--'
      14: const <String>['*', '/', '~/', '%'],
      13: const <String>['+', '-'],
      12: const <String>['<<', '>>'],
      11: const <String>['&'],
      10: const <String>['^'],
      9: const <String>['|'],
      8: const <String>['<', '>', '<=', '>=', 'as', 'is', 'is!'],
      7: const <String>['==', '!='],
      6: const <String>['&&'],
      5: const <String>['||'],
      4: const <String>['??'],
      3: const <String>['? :'],
      2: const <String>['..'],
      1: const <String>['=', '*=', '/=', '+=', '-=', '&=', '^='],
    };
    precedenceTable.forEach((precedence, lexemes) {
      for (String source in lexemes) {
        var scanner = new StringScanner(source, includeComments: true);
        var token = scanner.tokenize();
        expect(token.type.precedence, precedence, reason: source);
      }
    });
  }

  void test_type() {
    void assertLexeme(String source, TokenType tt) {
      var scanner = new StringScanner(source, includeComments: true);
      var token = scanner.tokenize();
      expect(token.type, same(tt), reason: source);
    }

    assertLexeme('1.0', TokenType.DOUBLE);
    assertLexeme('0xA', TokenType.HEXADECIMAL);
    assertLexeme('1', TokenType.INT);
    assertLexeme('var', Keyword.VAR);
    assertLexeme('#!/', TokenType.SCRIPT_TAG);
    assertLexeme('foo', TokenType.IDENTIFIER);
    assertLexeme('"foo"', TokenType.STRING);
  }
}
