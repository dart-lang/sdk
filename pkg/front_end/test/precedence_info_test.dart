// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/scanner/precedence.dart';
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
  var allTokenTypes = new Set<TokenType>.from(const [
    TokenType.EOF,
    TokenType.DOUBLE,
    TokenType.HEXADECIMAL,
    TokenType.IDENTIFIER,
    TokenType.INT,
    TokenType.KEYWORD,
    TokenType.MULTI_LINE_COMMENT,
    TokenType.SCRIPT_TAG,
    TokenType.SINGLE_LINE_COMMENT,
    TokenType.STRING,
    TokenType.AMPERSAND,
    TokenType.AMPERSAND_AMPERSAND,
    TokenType.AMPERSAND_EQ,
    TokenType.AT,
    TokenType.BANG,
    TokenType.BANG_EQ,
    TokenType.BAR,
    TokenType.BAR_BAR,
    TokenType.BAR_EQ,
    TokenType.COLON,
    TokenType.COMMA,
    TokenType.CARET,
    TokenType.CARET_EQ,
    TokenType.CLOSE_CURLY_BRACKET,
    TokenType.CLOSE_PAREN,
    TokenType.CLOSE_SQUARE_BRACKET,
    TokenType.EQ,
    TokenType.EQ_EQ,
    TokenType.FUNCTION,
    TokenType.GT,
    TokenType.GT_EQ,
    TokenType.GT_GT,
    TokenType.GT_GT_EQ,
    TokenType.HASH,
    TokenType.INDEX,
    TokenType.INDEX_EQ,
    TokenType.LT,
    TokenType.LT_EQ,
    TokenType.LT_LT,
    TokenType.LT_LT_EQ,
    TokenType.MINUS,
    TokenType.MINUS_EQ,
    TokenType.MINUS_MINUS,
    TokenType.OPEN_CURLY_BRACKET,
    TokenType.OPEN_PAREN,
    TokenType.OPEN_SQUARE_BRACKET,
    TokenType.PERCENT,
    TokenType.PERCENT_EQ,
    TokenType.PERIOD,
    TokenType.PERIOD_PERIOD,
    TokenType.PLUS,
    TokenType.PLUS_EQ,
    TokenType.PLUS_PLUS,
    TokenType.QUESTION,
    TokenType.QUESTION_PERIOD,
    TokenType.QUESTION_QUESTION,
    TokenType.QUESTION_QUESTION_EQ,
    TokenType.SEMICOLON,
    TokenType.SLASH,
    TokenType.SLASH_EQ,
    TokenType.STAR,
    TokenType.STAR_EQ,
    TokenType.STRING_INTERPOLATION_EXPRESSION,
    TokenType.STRING_INTERPOLATION_IDENTIFIER,
    TokenType.TILDE,
    TokenType.TILDE_SLASH,
    TokenType.TILDE_SLASH_EQ,
    TokenType.BACKPING,
    TokenType.BACKSLASH,
    TokenType.PERIOD_PERIOD_PERIOD,
    TokenType.GENERIC_METHOD_TYPE_LIST,
    TokenType.GENERIC_METHOD_TYPE_ASSIGN,

    // These are not yet part of the language and not supported by fasta
    //TokenType.AMPERSAND_AMPERSAND_EQ,
    //TokenType.BAR_BAR_EQ,
  ]);

  void assertInfo(check(String source, fasta.Token token),
      {bool includeLazyAssignmentOperators: true}) {
    void assertLexeme(String source) {
      if (source == null || source.isEmpty) return;
      var scanner = new StringScanner(source, includeComments: true);
      var token = scanner.tokenize();
      check(source, token);
    }

    for (PrecedenceInfo info in PrecedenceInfo.all) {
      assertLexeme(info.value);
    }
    for (TokenType tt in allTokenTypes) {
      assertLexeme(tt.lexeme);
    }
    assertLexeme('1.0'); // DOUBLE
    assertLexeme('0xA'); // HEXADECIMAL
    assertLexeme('1'); // INT
    assertLexeme('var'); // KEYWORD
    assertLexeme('#!/'); // SCRIPT_TAG
    assertLexeme('"foo"'); // STRING
    assertLexeme('bar'); // IDENTIFIER
    if (includeLazyAssignmentOperators) {
      assertLexeme('&&=');
      assertLexeme('||=');
    }
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

    assertInfo((String source, fasta.Token token) {
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
    assertInfo((String source, fasta.Token token) {
      expect(token.type.isAdditiveOperator, additiveLexemes.contains(source),
          reason: source);
    });
  }

  void test_isAssignmentOperator() {
    const assignmentLexemes = const [
      '&=',
      '|=',
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
    assertInfo((String source, fasta.Token token) {
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
    assertInfo((String source, fasta.Token token) {
      expect(
          token.type.isAssociativeOperator, associativeLexemes.contains(source),
          reason: source);
    }, includeLazyAssignmentOperators: false);
  }

  void test_isEqualityOperator() {
    const equalityLexemes = const [
      '!=',
      '==',
    ];
    assertInfo((String source, fasta.Token token) {
      expect(token.type.isEqualityOperator, equalityLexemes.contains(source),
          reason: source);
    });
  }

  void test_isIncrementOperator() {
    const incrementLexemes = const [
      '--',
      '++',
    ];
    assertInfo((String source, fasta.Token token) {
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
    assertInfo((String source, fasta.Token token) {
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
    assertInfo((String source, fasta.Token token) {
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
    assertInfo((String source, fasta.Token token) {
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
    ];
    assertInfo((String source, fasta.Token token) {
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
    assertInfo((String source, fasta.Token token) {
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
    assertInfo((String source, fasta.Token token) {
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
        expect(token.info.precedence, precedence, reason: source);
      }
    });
  }

  void test_identity() {
    var exceptions = <TokenType>[
      // Null lexeme - no corresponding PrecedenceInfo
      TokenType.MULTI_LINE_COMMENT,
      TokenType.SINGLE_LINE_COMMENT,
      TokenType.GENERIC_METHOD_TYPE_LIST,
      TokenType.GENERIC_METHOD_TYPE_ASSIGN,

      // Manually compared below
      TokenType.DOUBLE,
      TokenType.HEXADECIMAL,
      TokenType.INT,
      TokenType.KEYWORD,
      TokenType.SCRIPT_TAG,
      TokenType.STRING,
      TokenType.STRING_INTERPOLATION_EXPRESSION,
      TokenType.STRING_INTERPOLATION_IDENTIFIER,
    ];

    void assertLexeme(String source, TokenType tt) {
      var scanner = new StringScanner(source, includeComments: true);
      var token = scanner.tokenize();
      expect(token.type, same(tt), reason: source);
    }

    for (TokenType tt in allTokenTypes) {
      if (!exceptions.contains(tt)) {
        assertLexeme(tt.lexeme, tt);
      }
    }
    expect(DOUBLE_INFO, same(TokenType.DOUBLE));
    expect(HEXADECIMAL_INFO, same(TokenType.HEXADECIMAL));
    expect(INT_INFO, same(TokenType.INT));
    expect(KEYWORD_INFO, same(TokenType.KEYWORD));
    expect(SCRIPT_INFO, same(TokenType.SCRIPT_TAG));
    expect(STRING_INFO, same(TokenType.STRING));

    assertLexeme('1.0', TokenType.DOUBLE);
    assertLexeme('0xA', TokenType.HEXADECIMAL);
    assertLexeme('1', TokenType.INT);
    assertLexeme('var', TokenType.KEYWORD);
    assertLexeme('#!/', TokenType.SCRIPT_TAG);
    assertLexeme('"foo"', TokenType.STRING);

    expect(STRING_INTERPOLATION_INFO,
        same(TokenType.STRING_INTERPOLATION_EXPRESSION));
    expect(STRING_INTERPOLATION_IDENTIFIER_INFO,
        same(TokenType.STRING_INTERPOLATION_IDENTIFIER));
  }
}
