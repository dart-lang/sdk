// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.scanner.precedence;

import '../../scanner/token.dart';
import 'token_constants.dart';

class PrecedenceInfo extends TokenType {
  const PrecedenceInfo(String value, String name, int precedence, int kind,
      {bool isOperator: false, bool isUserDefinableOperator: false})
      : super(value, name, precedence, kind,
            isOperator: isOperator,
            isUserDefinableOperator: isUserDefinableOperator);

  toString() => 'PrecedenceInfo($value, $name, $precedence, $kind)';

  static const List<PrecedenceInfo> all = const <PrecedenceInfo>[
    BACKPING_INFO,
    BACKSLASH_INFO,
    PERIOD_PERIOD_PERIOD_INFO,
    PERIOD_PERIOD_INFO,
    BANG_INFO,
    COLON_INFO,
    INDEX_INFO,
    MINUS_MINUS_INFO,
    PLUS_PLUS_INFO,
    TILDE_INFO,
    FUNCTION_INFO,
    HASH_INFO,
    INDEX_EQ_INFO,
    SEMICOLON_INFO,
    COMMA_INFO,
    AT_INFO,
    AMPERSAND_EQ_INFO,
    BAR_EQ_INFO,
    CARET_EQ_INFO,
    EQ_INFO,
    GT_GT_EQ_INFO,
    LT_LT_EQ_INFO,
    MINUS_EQ_INFO,
    PERCENT_EQ_INFO,
    PLUS_EQ_INFO,
    SLASH_EQ_INFO,
    STAR_EQ_INFO,
    TILDE_SLASH_EQ_INFO,
    QUESTION_QUESTION_EQ_INFO,
    QUESTION_INFO,
    QUESTION_QUESTION_INFO,
    BAR_BAR_INFO,
    AMPERSAND_AMPERSAND_INFO,
    BAR_INFO,
    CARET_INFO,
    AMPERSAND_INFO,
    BANG_EQ_EQ_INFO,
    BANG_EQ_INFO,
    EQ_EQ_EQ_INFO,
    EQ_EQ_INFO,
    GT_EQ_INFO,
    GT_INFO,
    IS_INFO,
    AS_INFO,
    LT_EQ_INFO,
    LT_INFO,
    GT_GT_INFO,
    LT_LT_INFO,
    MINUS_INFO,
    PLUS_INFO,
    PERCENT_INFO,
    SLASH_INFO,
    STAR_INFO,
    TILDE_SLASH_INFO,
    PERIOD_INFO,
    QUESTION_PERIOD_INFO,
    KEYWORD_INFO,
    EOF_INFO,
    IDENTIFIER_INFO,
    BAD_INPUT_INFO,
    OPEN_PAREN_INFO,
    CLOSE_PAREN_INFO,
    OPEN_CURLY_BRACKET_INFO,
    CLOSE_CURLY_BRACKET_INFO,
    INT_INFO,
    STRING_INFO,
    OPEN_SQUARE_BRACKET_INFO,
    CLOSE_SQUARE_BRACKET_INFO,
    DOUBLE_INFO,
    STRING_INTERPOLATION_INFO,
    STRING_INTERPOLATION_IDENTIFIER_INFO,
    HEXADECIMAL_INFO,
    SINGLE_LINE_COMMENT_INFO,
    MULTI_LINE_COMMENT_INFO,
    GENERIC_METHOD_TYPE_ASSIGN,
    GENERIC_METHOD_TYPE_LIST,
  ];
}

const int NO_PRECEDENCE = 0;
const int ASSIGNMENT_PRECEDENCE = 1;
const int CASCADE_PRECEDENCE = 2;
const int CONDITIONAL_PRECEDENCE = 3;
const int IF_NULL_PRECEDENCE = 4;
const int LOGICAL_OR_PRECEDENCE = 5;
const int LOGICAL_AND_PRECEDENCE = 6;
const int EQUALITY_PRECEDENCE = 7;
const int RELATIONAL_PRECEDENCE = 8;
const int BITWISE_OR_PRECEDENCE = 9;
const int BITWISE_XOR_PRECEDENCE = 10;
const int BITWISE_AND_PRECEDENCE = 11;
const int SHIFT_PRECEDENCE = 12;
const int ADDITIVE_PRECEDENCE = 13;
const int MULTIPLICATIVE_PRECEDENCE = 14;
const int PREFIX_PRECEDENCE = 15;
const int POSTFIX_PRECEDENCE = 16;

// TODO(ahe): The following are not tokens in Dart.
const PrecedenceInfo BACKPING_INFO =
    const PrecedenceInfo('`', 'BACKPING', NO_PRECEDENCE, BACKPING_TOKEN);
const PrecedenceInfo BACKSLASH_INFO =
    const PrecedenceInfo('\\', 'BACKSLASH', NO_PRECEDENCE, BACKSLASH_TOKEN);
const PrecedenceInfo PERIOD_PERIOD_PERIOD_INFO = const PrecedenceInfo(
    '...', 'PERIOD_PERIOD_PERIOD', NO_PRECEDENCE, PERIOD_PERIOD_PERIOD_TOKEN);

/**
 * The cascade operator has the lowest precedence of any operator
 * except assignment.
 */
const PrecedenceInfo PERIOD_PERIOD_INFO = const PrecedenceInfo(
    '..', 'PERIOD_PERIOD', CASCADE_PRECEDENCE, PERIOD_PERIOD_TOKEN,
    isOperator: true);

const PrecedenceInfo BANG_INFO = const PrecedenceInfo(
    '!', 'BANG', PREFIX_PRECEDENCE, BANG_TOKEN,
    isOperator: true);
const PrecedenceInfo COLON_INFO =
    const PrecedenceInfo(':', 'COLON', NO_PRECEDENCE, COLON_TOKEN);
const PrecedenceInfo INDEX_INFO = const PrecedenceInfo(
    '[]', 'INDEX', NO_PRECEDENCE, INDEX_TOKEN,
    isOperator: true, isUserDefinableOperator: true);
const PrecedenceInfo MINUS_MINUS_INFO = const PrecedenceInfo(
    '--', 'MINUS_MINUS', POSTFIX_PRECEDENCE, MINUS_MINUS_TOKEN,
    isOperator: true);
const PrecedenceInfo PLUS_PLUS_INFO = const PrecedenceInfo(
    '++', 'PLUS_PLUS', POSTFIX_PRECEDENCE, PLUS_PLUS_TOKEN,
    isOperator: true);
const PrecedenceInfo TILDE_INFO = const PrecedenceInfo(
    '~', 'TILDE', PREFIX_PRECEDENCE, TILDE_TOKEN,
    isOperator: true, isUserDefinableOperator: true);

const PrecedenceInfo FUNCTION_INFO =
    const PrecedenceInfo('=>', 'FUNCTION', NO_PRECEDENCE, FUNCTION_TOKEN);
const PrecedenceInfo HASH_INFO =
    const PrecedenceInfo('#', 'HASH', NO_PRECEDENCE, HASH_TOKEN);
const PrecedenceInfo INDEX_EQ_INFO = const PrecedenceInfo(
    '[]=', 'INDEX_EQ', NO_PRECEDENCE, INDEX_EQ_TOKEN,
    isOperator: true, isUserDefinableOperator: true);
const PrecedenceInfo SEMICOLON_INFO =
    const PrecedenceInfo(';', 'SEMICOLON', NO_PRECEDENCE, SEMICOLON_TOKEN);
const PrecedenceInfo COMMA_INFO =
    const PrecedenceInfo(',', 'COMMA', NO_PRECEDENCE, COMMA_TOKEN);

const PrecedenceInfo AT_INFO =
    const PrecedenceInfo('@', 'AT', NO_PRECEDENCE, AT_TOKEN);

// Assignment operators.
const PrecedenceInfo AMPERSAND_EQ_INFO = const PrecedenceInfo(
    '&=', 'AMPERSAND_EQ', ASSIGNMENT_PRECEDENCE, AMPERSAND_EQ_TOKEN,
    isOperator: true);
const PrecedenceInfo BAR_EQ_INFO = const PrecedenceInfo(
    '|=', 'BAR_EQ', ASSIGNMENT_PRECEDENCE, BAR_EQ_TOKEN,
    isOperator: true);
const PrecedenceInfo CARET_EQ_INFO = const PrecedenceInfo(
    '^=', 'CARET_EQ', ASSIGNMENT_PRECEDENCE, CARET_EQ_TOKEN,
    isOperator: true);
const PrecedenceInfo EQ_INFO = const PrecedenceInfo(
    '=', 'EQ', ASSIGNMENT_PRECEDENCE, EQ_TOKEN,
    isOperator: true);
const PrecedenceInfo GT_GT_EQ_INFO = const PrecedenceInfo(
    '>>=', 'GT_GT_EQ', ASSIGNMENT_PRECEDENCE, GT_GT_EQ_TOKEN,
    isOperator: true);
const PrecedenceInfo LT_LT_EQ_INFO = const PrecedenceInfo(
    '<<=', 'LT_LT_EQ', ASSIGNMENT_PRECEDENCE, LT_LT_EQ_TOKEN,
    isOperator: true);
const PrecedenceInfo MINUS_EQ_INFO = const PrecedenceInfo(
    '-=', 'MINUS_EQ', ASSIGNMENT_PRECEDENCE, MINUS_EQ_TOKEN,
    isOperator: true);
const PrecedenceInfo PERCENT_EQ_INFO = const PrecedenceInfo(
    '%=', 'PERCENT_EQ', ASSIGNMENT_PRECEDENCE, PERCENT_EQ_TOKEN,
    isOperator: true);
const PrecedenceInfo PLUS_EQ_INFO = const PrecedenceInfo(
    '+=', 'PLUS_EQ', ASSIGNMENT_PRECEDENCE, PLUS_EQ_TOKEN,
    isOperator: true);
const PrecedenceInfo SLASH_EQ_INFO = const PrecedenceInfo(
    '/=', 'SLASH_EQ', ASSIGNMENT_PRECEDENCE, SLASH_EQ_TOKEN,
    isOperator: true);
const PrecedenceInfo STAR_EQ_INFO = const PrecedenceInfo(
    '*=', 'STAR_EQ', ASSIGNMENT_PRECEDENCE, STAR_EQ_TOKEN,
    isOperator: true);
const PrecedenceInfo TILDE_SLASH_EQ_INFO = const PrecedenceInfo(
    '~/=', 'TILDE_SLASH_EQ', ASSIGNMENT_PRECEDENCE, TILDE_SLASH_EQ_TOKEN,
    isOperator: true);
const PrecedenceInfo QUESTION_QUESTION_EQ_INFO = const PrecedenceInfo('??=',
    'QUESTION_QUESTION_EQ', ASSIGNMENT_PRECEDENCE, QUESTION_QUESTION_EQ_TOKEN,
    isOperator: true);

const PrecedenceInfo QUESTION_INFO = const PrecedenceInfo(
    '?', 'QUESTION', CONDITIONAL_PRECEDENCE, QUESTION_TOKEN,
    isOperator: true);

const PrecedenceInfo QUESTION_QUESTION_INFO = const PrecedenceInfo(
    '??', 'QUESTION_QUESTION', IF_NULL_PRECEDENCE, QUESTION_QUESTION_TOKEN,
    isOperator: true);

const PrecedenceInfo BAR_BAR_INFO = const PrecedenceInfo(
    '||', 'BAR_BAR', LOGICAL_OR_PRECEDENCE, BAR_BAR_TOKEN,
    isOperator: true);

const PrecedenceInfo AMPERSAND_AMPERSAND_INFO = const PrecedenceInfo('&&',
    'AMPERSAND_AMPERSAND', LOGICAL_AND_PRECEDENCE, AMPERSAND_AMPERSAND_TOKEN,
    isOperator: true);

const PrecedenceInfo BAR_INFO = const PrecedenceInfo(
    '|', 'BAR', BITWISE_OR_PRECEDENCE, BAR_TOKEN,
    isOperator: true, isUserDefinableOperator: true);

const PrecedenceInfo CARET_INFO = const PrecedenceInfo(
    '^', 'CARET', BITWISE_XOR_PRECEDENCE, CARET_TOKEN,
    isOperator: true, isUserDefinableOperator: true);

const PrecedenceInfo AMPERSAND_INFO = const PrecedenceInfo(
    '&', 'AMPERSAND', BITWISE_AND_PRECEDENCE, AMPERSAND_TOKEN,
    isOperator: true, isUserDefinableOperator: true);

// Equality operators.
const PrecedenceInfo BANG_EQ_EQ_INFO = const PrecedenceInfo(
    '!==', 'BANG_EQ_EQ', EQUALITY_PRECEDENCE, BANG_EQ_EQ_TOKEN);
const PrecedenceInfo BANG_EQ_INFO = const PrecedenceInfo(
    '!=', 'BANG_EQ', EQUALITY_PRECEDENCE, BANG_EQ_TOKEN,
    isOperator: true);
const PrecedenceInfo EQ_EQ_EQ_INFO = const PrecedenceInfo(
    '===', 'EQ_EQ_EQ', EQUALITY_PRECEDENCE, EQ_EQ_EQ_TOKEN);
const PrecedenceInfo EQ_EQ_INFO = const PrecedenceInfo(
    '==', 'EQ_EQ', EQUALITY_PRECEDENCE, EQ_EQ_TOKEN,
    isOperator: true, isUserDefinableOperator: true);

// Relational operators.
const PrecedenceInfo GT_EQ_INFO = const PrecedenceInfo(
    '>=', 'GT_EQ', RELATIONAL_PRECEDENCE, GT_EQ_TOKEN,
    isOperator: true, isUserDefinableOperator: true);
const PrecedenceInfo GT_INFO = const PrecedenceInfo(
    '>', 'GT', RELATIONAL_PRECEDENCE, GT_TOKEN,
    isOperator: true, isUserDefinableOperator: true);
const PrecedenceInfo IS_INFO =
    const PrecedenceInfo('is', 'IS', RELATIONAL_PRECEDENCE, KEYWORD_TOKEN);
const PrecedenceInfo AS_INFO =
    const PrecedenceInfo('as', 'AS', RELATIONAL_PRECEDENCE, KEYWORD_TOKEN);
const PrecedenceInfo LT_EQ_INFO = const PrecedenceInfo(
    '<=', 'LT_EQ', RELATIONAL_PRECEDENCE, LT_EQ_TOKEN,
    isOperator: true, isUserDefinableOperator: true);
const PrecedenceInfo LT_INFO = const PrecedenceInfo(
    '<', 'LT', RELATIONAL_PRECEDENCE, LT_TOKEN,
    isOperator: true, isUserDefinableOperator: true);

// Shift operators.
const PrecedenceInfo GT_GT_INFO = const PrecedenceInfo(
    '>>', 'GT_GT', SHIFT_PRECEDENCE, GT_GT_TOKEN,
    isOperator: true, isUserDefinableOperator: true);
const PrecedenceInfo LT_LT_INFO = const PrecedenceInfo(
    '<<', 'LT_LT', SHIFT_PRECEDENCE, LT_LT_TOKEN,
    isOperator: true, isUserDefinableOperator: true);

// Additive operators.
const PrecedenceInfo MINUS_INFO = const PrecedenceInfo(
    '-', 'MINUS', ADDITIVE_PRECEDENCE, MINUS_TOKEN,
    isOperator: true, isUserDefinableOperator: true);
const PrecedenceInfo PLUS_INFO = const PrecedenceInfo(
    '+', 'PLUS', ADDITIVE_PRECEDENCE, PLUS_TOKEN,
    isOperator: true, isUserDefinableOperator: true);

// Multiplicative operators.
const PrecedenceInfo PERCENT_INFO = const PrecedenceInfo(
    '%', 'PERCENT', MULTIPLICATIVE_PRECEDENCE, PERCENT_TOKEN,
    isOperator: true, isUserDefinableOperator: true);
const PrecedenceInfo SLASH_INFO = const PrecedenceInfo(
    '/', 'SLASH', MULTIPLICATIVE_PRECEDENCE, SLASH_TOKEN,
    isOperator: true, isUserDefinableOperator: true);
const PrecedenceInfo STAR_INFO = const PrecedenceInfo(
    '*', 'STAR', MULTIPLICATIVE_PRECEDENCE, STAR_TOKEN,
    isOperator: true, isUserDefinableOperator: true);
const PrecedenceInfo TILDE_SLASH_INFO = const PrecedenceInfo(
    '~/', 'TILDE_SLASH', MULTIPLICATIVE_PRECEDENCE, TILDE_SLASH_TOKEN,
    isOperator: true, isUserDefinableOperator: true);

const PrecedenceInfo PERIOD_INFO =
    const PrecedenceInfo('.', 'PERIOD', POSTFIX_PRECEDENCE, PERIOD_TOKEN);
const PrecedenceInfo QUESTION_PERIOD_INFO = const PrecedenceInfo(
    '?.', 'QUESTION_PERIOD', POSTFIX_PRECEDENCE, QUESTION_PERIOD_TOKEN,
    isOperator: true);

const PrecedenceInfo KEYWORD_INFO =
    const PrecedenceInfo('keyword', 'KEYWORD', NO_PRECEDENCE, KEYWORD_TOKEN);

const PrecedenceInfo EOF_INFO =
    const PrecedenceInfo('', 'EOF', NO_PRECEDENCE, EOF_TOKEN);

/// Precedence info used by synthetic tokens that are created during parser
/// recovery (non-analyzer use case).
const PrecedenceInfo RECOVERY_INFO =
    const PrecedenceInfo('recovery', 'RECOVERY', NO_PRECEDENCE, RECOVERY_TOKEN);

const PrecedenceInfo IDENTIFIER_INFO = const PrecedenceInfo(
    'identifier', 'STRING_INT', NO_PRECEDENCE, IDENTIFIER_TOKEN);

const PrecedenceInfo SCRIPT_INFO =
    const PrecedenceInfo('script', 'SCRIPT_TAG', NO_PRECEDENCE, SCRIPT_TOKEN);

const PrecedenceInfo BAD_INPUT_INFO = const PrecedenceInfo(
    'malformed input', 'BAD_INPUT', NO_PRECEDENCE, BAD_INPUT_TOKEN);

const PrecedenceInfo OPEN_PAREN_INFO = const PrecedenceInfo(
    '(', 'OPEN_PAREN', POSTFIX_PRECEDENCE, OPEN_PAREN_TOKEN);

const PrecedenceInfo CLOSE_PAREN_INFO =
    const PrecedenceInfo(')', 'CLOSE_PAREN', NO_PRECEDENCE, CLOSE_PAREN_TOKEN);

const PrecedenceInfo OPEN_CURLY_BRACKET_INFO = const PrecedenceInfo(
    '{', 'OPEN_CURLY_BRACKET', NO_PRECEDENCE, OPEN_CURLY_BRACKET_TOKEN);

const PrecedenceInfo CLOSE_CURLY_BRACKET_INFO = const PrecedenceInfo(
    '}', 'CLOSE_CURLY_BRACKET', NO_PRECEDENCE, CLOSE_CURLY_BRACKET_TOKEN);

const PrecedenceInfo INT_INFO =
    const PrecedenceInfo('int', 'INT', NO_PRECEDENCE, INT_TOKEN);

const PrecedenceInfo STRING_INFO =
    const PrecedenceInfo('string', 'STRING', NO_PRECEDENCE, STRING_TOKEN);

const PrecedenceInfo OPEN_SQUARE_BRACKET_INFO = const PrecedenceInfo(
    '[', 'OPEN_SQUARE_BRACKET', POSTFIX_PRECEDENCE, OPEN_SQUARE_BRACKET_TOKEN);

const PrecedenceInfo CLOSE_SQUARE_BRACKET_INFO = const PrecedenceInfo(
    ']', 'CLOSE_SQUARE_BRACKET', NO_PRECEDENCE, CLOSE_SQUARE_BRACKET_TOKEN);

const PrecedenceInfo DOUBLE_INFO =
    const PrecedenceInfo('double', 'DOUBLE', NO_PRECEDENCE, DOUBLE_TOKEN);

const PrecedenceInfo STRING_INTERPOLATION_INFO = const PrecedenceInfo(
    '\${',
    'STRING_INTERPOLATION_EXPRESSION',
    NO_PRECEDENCE,
    STRING_INTERPOLATION_TOKEN);

const PrecedenceInfo STRING_INTERPOLATION_IDENTIFIER_INFO =
    const PrecedenceInfo('\$', 'STRING_INTERPOLATION_IDENTIFIER', NO_PRECEDENCE,
        STRING_INTERPOLATION_IDENTIFIER_TOKEN);

const PrecedenceInfo HEXADECIMAL_INFO = const PrecedenceInfo(
    'hexadecimal', 'HEXADECIMAL', NO_PRECEDENCE, HEXADECIMAL_TOKEN);

const PrecedenceInfo SINGLE_LINE_COMMENT_INFO = const PrecedenceInfo(
    'comment', 'SINGLE_LINE_COMMENT', NO_PRECEDENCE, COMMENT_TOKEN);

const PrecedenceInfo MULTI_LINE_COMMENT_INFO = const PrecedenceInfo(
    'comment', 'MULTI_LINE_COMMENT', NO_PRECEDENCE, COMMENT_TOKEN);

const PrecedenceInfo GENERIC_METHOD_TYPE_ASSIGN = const PrecedenceInfo(
    'generic_comment_assign',
    'GENERIC_METHOD_TYPE_ASSIGN',
    NO_PRECEDENCE,
    GENERIC_METHOD_TYPE_ASSIGN_TOKEN);

const PrecedenceInfo GENERIC_METHOD_TYPE_LIST = const PrecedenceInfo(
    'generic_comment_list',
    'GENERIC_METHOD_TYPE_LIST',
    NO_PRECEDENCE,
    GENERIC_METHOD_TYPE_LIST_TOKEN);
