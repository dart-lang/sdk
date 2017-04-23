// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.scanner.precedence;

import '../../scanner/token.dart';
import '../../scanner/token.dart' as analyzer;
import 'token_constants.dart';

const int NO_PRECEDENCE = analyzer.NO_PRECEDENCE;
const int ASSIGNMENT_PRECEDENCE = analyzer.ASSIGNMENT_PRECEDENCE;
const int CASCADE_PRECEDENCE = analyzer.CASCADE_PRECEDENCE;
const int CONDITIONAL_PRECEDENCE = analyzer.CONDITIONAL_PRECEDENCE;
const int IF_NULL_PRECEDENCE = analyzer.IF_NULL_PRECEDENCE;
const int LOGICAL_OR_PRECEDENCE = analyzer.LOGICAL_OR_PRECEDENCE;
const int LOGICAL_AND_PRECEDENCE = analyzer.LOGICAL_AND_PRECEDENCE;
const int EQUALITY_PRECEDENCE = analyzer.EQUALITY_PRECEDENCE;
const int RELATIONAL_PRECEDENCE = analyzer.RELATIONAL_PRECEDENCE;
const int BITWISE_OR_PRECEDENCE = analyzer.BITWISE_OR_PRECEDENCE;
const int BITWISE_XOR_PRECEDENCE = analyzer.BITWISE_XOR_PRECEDENCE;
const int BITWISE_AND_PRECEDENCE = analyzer.BITWISE_AND_PRECEDENCE;
const int SHIFT_PRECEDENCE = analyzer.SHIFT_PRECEDENCE;
const int ADDITIVE_PRECEDENCE = analyzer.ADDITIVE_PRECEDENCE;
const int MULTIPLICATIVE_PRECEDENCE = analyzer.MULTIPLICATIVE_PRECEDENCE;
const int PREFIX_PRECEDENCE = analyzer.PREFIX_PRECEDENCE;
const int POSTFIX_PRECEDENCE = analyzer.POSTFIX_PRECEDENCE;

// TODO(ahe): The following are not tokens in Dart.
const TokenType BACKPING_INFO =
    const TokenType('`', 'BACKPING', NO_PRECEDENCE, BACKPING_TOKEN);
const TokenType BACKSLASH_INFO =
    const TokenType('\\', 'BACKSLASH', NO_PRECEDENCE, BACKSLASH_TOKEN);
const TokenType PERIOD_PERIOD_PERIOD_INFO = const TokenType(
    '...', 'PERIOD_PERIOD_PERIOD', NO_PRECEDENCE, PERIOD_PERIOD_PERIOD_TOKEN);

/**
 * The cascade operator has the lowest precedence of any operator
 * except assignment.
 */
const TokenType PERIOD_PERIOD_INFO = const TokenType(
    '..', 'PERIOD_PERIOD', CASCADE_PRECEDENCE, PERIOD_PERIOD_TOKEN,
    isOperator: true);

const TokenType BANG_INFO = const TokenType(
    '!', 'BANG', PREFIX_PRECEDENCE, BANG_TOKEN,
    isOperator: true);
const TokenType COLON_INFO =
    const TokenType(':', 'COLON', NO_PRECEDENCE, COLON_TOKEN);
const TokenType INDEX_INFO = const TokenType(
    '[]', 'INDEX', NO_PRECEDENCE, INDEX_TOKEN,
    isOperator: true, isUserDefinableOperator: true);
const TokenType MINUS_MINUS_INFO = const TokenType(
    '--', 'MINUS_MINUS', POSTFIX_PRECEDENCE, MINUS_MINUS_TOKEN,
    isOperator: true);
const TokenType PLUS_PLUS_INFO = const TokenType(
    '++', 'PLUS_PLUS', POSTFIX_PRECEDENCE, PLUS_PLUS_TOKEN,
    isOperator: true);
const TokenType TILDE_INFO = const TokenType(
    '~', 'TILDE', PREFIX_PRECEDENCE, TILDE_TOKEN,
    isOperator: true, isUserDefinableOperator: true);

const TokenType FUNCTION_INFO =
    const TokenType('=>', 'FUNCTION', NO_PRECEDENCE, FUNCTION_TOKEN);
const TokenType HASH_INFO =
    const TokenType('#', 'HASH', NO_PRECEDENCE, HASH_TOKEN);
const TokenType INDEX_EQ_INFO = const TokenType(
    '[]=', 'INDEX_EQ', NO_PRECEDENCE, INDEX_EQ_TOKEN,
    isOperator: true, isUserDefinableOperator: true);
const TokenType SEMICOLON_INFO =
    const TokenType(';', 'SEMICOLON', NO_PRECEDENCE, SEMICOLON_TOKEN);
const TokenType COMMA_INFO =
    const TokenType(',', 'COMMA', NO_PRECEDENCE, COMMA_TOKEN);

const TokenType AT_INFO = const TokenType('@', 'AT', NO_PRECEDENCE, AT_TOKEN);

// Assignment operators.
const TokenType AMPERSAND_EQ_INFO = const TokenType(
    '&=', 'AMPERSAND_EQ', ASSIGNMENT_PRECEDENCE, AMPERSAND_EQ_TOKEN,
    isOperator: true);
const TokenType BAR_EQ_INFO = const TokenType(
    '|=', 'BAR_EQ', ASSIGNMENT_PRECEDENCE, BAR_EQ_TOKEN,
    isOperator: true);
const TokenType CARET_EQ_INFO = const TokenType(
    '^=', 'CARET_EQ', ASSIGNMENT_PRECEDENCE, CARET_EQ_TOKEN,
    isOperator: true);
const TokenType EQ_INFO = const TokenType(
    '=', 'EQ', ASSIGNMENT_PRECEDENCE, EQ_TOKEN,
    isOperator: true);
const TokenType GT_GT_EQ_INFO = const TokenType(
    '>>=', 'GT_GT_EQ', ASSIGNMENT_PRECEDENCE, GT_GT_EQ_TOKEN,
    isOperator: true);
const TokenType LT_LT_EQ_INFO = const TokenType(
    '<<=', 'LT_LT_EQ', ASSIGNMENT_PRECEDENCE, LT_LT_EQ_TOKEN,
    isOperator: true);
const TokenType MINUS_EQ_INFO = const TokenType(
    '-=', 'MINUS_EQ', ASSIGNMENT_PRECEDENCE, MINUS_EQ_TOKEN,
    isOperator: true);
const TokenType PERCENT_EQ_INFO = const TokenType(
    '%=', 'PERCENT_EQ', ASSIGNMENT_PRECEDENCE, PERCENT_EQ_TOKEN,
    isOperator: true);
const TokenType PLUS_EQ_INFO = const TokenType(
    '+=', 'PLUS_EQ', ASSIGNMENT_PRECEDENCE, PLUS_EQ_TOKEN,
    isOperator: true);
const TokenType SLASH_EQ_INFO = const TokenType(
    '/=', 'SLASH_EQ', ASSIGNMENT_PRECEDENCE, SLASH_EQ_TOKEN,
    isOperator: true);
const TokenType STAR_EQ_INFO = const TokenType(
    '*=', 'STAR_EQ', ASSIGNMENT_PRECEDENCE, STAR_EQ_TOKEN,
    isOperator: true);
const TokenType TILDE_SLASH_EQ_INFO = const TokenType(
    '~/=', 'TILDE_SLASH_EQ', ASSIGNMENT_PRECEDENCE, TILDE_SLASH_EQ_TOKEN,
    isOperator: true);
const TokenType QUESTION_QUESTION_EQ_INFO = const TokenType('??=',
    'QUESTION_QUESTION_EQ', ASSIGNMENT_PRECEDENCE, QUESTION_QUESTION_EQ_TOKEN,
    isOperator: true);

const TokenType QUESTION_INFO = const TokenType(
    '?', 'QUESTION', CONDITIONAL_PRECEDENCE, QUESTION_TOKEN,
    isOperator: true);

const TokenType QUESTION_QUESTION_INFO = const TokenType(
    '??', 'QUESTION_QUESTION', IF_NULL_PRECEDENCE, QUESTION_QUESTION_TOKEN,
    isOperator: true);

const TokenType BAR_BAR_INFO = const TokenType(
    '||', 'BAR_BAR', LOGICAL_OR_PRECEDENCE, BAR_BAR_TOKEN,
    isOperator: true);

const TokenType AMPERSAND_AMPERSAND_INFO = const TokenType('&&',
    'AMPERSAND_AMPERSAND', LOGICAL_AND_PRECEDENCE, AMPERSAND_AMPERSAND_TOKEN,
    isOperator: true);

const TokenType BAR_INFO = const TokenType(
    '|', 'BAR', BITWISE_OR_PRECEDENCE, BAR_TOKEN,
    isOperator: true, isUserDefinableOperator: true);

const TokenType CARET_INFO = const TokenType(
    '^', 'CARET', BITWISE_XOR_PRECEDENCE, CARET_TOKEN,
    isOperator: true, isUserDefinableOperator: true);

const TokenType AMPERSAND_INFO = const TokenType(
    '&', 'AMPERSAND', BITWISE_AND_PRECEDENCE, AMPERSAND_TOKEN,
    isOperator: true, isUserDefinableOperator: true);

// Equality operators.
const TokenType BANG_EQ_EQ_INFO =
    const TokenType('!==', 'BANG_EQ_EQ', EQUALITY_PRECEDENCE, BANG_EQ_EQ_TOKEN);
const TokenType BANG_EQ_INFO = const TokenType(
    '!=', 'BANG_EQ', EQUALITY_PRECEDENCE, BANG_EQ_TOKEN,
    isOperator: true);
const TokenType EQ_EQ_EQ_INFO =
    const TokenType('===', 'EQ_EQ_EQ', EQUALITY_PRECEDENCE, EQ_EQ_EQ_TOKEN);
const TokenType EQ_EQ_INFO = const TokenType(
    '==', 'EQ_EQ', EQUALITY_PRECEDENCE, EQ_EQ_TOKEN,
    isOperator: true, isUserDefinableOperator: true);

// Relational operators.
const TokenType GT_EQ_INFO = const TokenType(
    '>=', 'GT_EQ', RELATIONAL_PRECEDENCE, GT_EQ_TOKEN,
    isOperator: true, isUserDefinableOperator: true);
const TokenType GT_INFO = const TokenType(
    '>', 'GT', RELATIONAL_PRECEDENCE, GT_TOKEN,
    isOperator: true, isUserDefinableOperator: true);
const TokenType IS_INFO =
    const TokenType('is', 'IS', RELATIONAL_PRECEDENCE, KEYWORD_TOKEN);
const TokenType AS_INFO =
    const TokenType('as', 'AS', RELATIONAL_PRECEDENCE, KEYWORD_TOKEN);
const TokenType LT_EQ_INFO = const TokenType(
    '<=', 'LT_EQ', RELATIONAL_PRECEDENCE, LT_EQ_TOKEN,
    isOperator: true, isUserDefinableOperator: true);
const TokenType LT_INFO = const TokenType(
    '<', 'LT', RELATIONAL_PRECEDENCE, LT_TOKEN,
    isOperator: true, isUserDefinableOperator: true);

// Shift operators.
const TokenType GT_GT_INFO = const TokenType(
    '>>', 'GT_GT', SHIFT_PRECEDENCE, GT_GT_TOKEN,
    isOperator: true, isUserDefinableOperator: true);
const TokenType LT_LT_INFO = const TokenType(
    '<<', 'LT_LT', SHIFT_PRECEDENCE, LT_LT_TOKEN,
    isOperator: true, isUserDefinableOperator: true);

// Additive operators.
const TokenType MINUS_INFO = const TokenType(
    '-', 'MINUS', ADDITIVE_PRECEDENCE, MINUS_TOKEN,
    isOperator: true, isUserDefinableOperator: true);
const TokenType PLUS_INFO = const TokenType(
    '+', 'PLUS', ADDITIVE_PRECEDENCE, PLUS_TOKEN,
    isOperator: true, isUserDefinableOperator: true);

// Multiplicative operators.
const TokenType PERCENT_INFO = const TokenType(
    '%', 'PERCENT', MULTIPLICATIVE_PRECEDENCE, PERCENT_TOKEN,
    isOperator: true, isUserDefinableOperator: true);
const TokenType SLASH_INFO = const TokenType(
    '/', 'SLASH', MULTIPLICATIVE_PRECEDENCE, SLASH_TOKEN,
    isOperator: true, isUserDefinableOperator: true);
const TokenType STAR_INFO = const TokenType(
    '*', 'STAR', MULTIPLICATIVE_PRECEDENCE, STAR_TOKEN,
    isOperator: true, isUserDefinableOperator: true);
const TokenType TILDE_SLASH_INFO = const TokenType(
    '~/', 'TILDE_SLASH', MULTIPLICATIVE_PRECEDENCE, TILDE_SLASH_TOKEN,
    isOperator: true, isUserDefinableOperator: true);

const TokenType PERIOD_INFO =
    const TokenType('.', 'PERIOD', POSTFIX_PRECEDENCE, PERIOD_TOKEN);
const TokenType QUESTION_PERIOD_INFO = const TokenType(
    '?.', 'QUESTION_PERIOD', POSTFIX_PRECEDENCE, QUESTION_PERIOD_TOKEN,
    isOperator: true);

const TokenType KEYWORD_INFO =
    const TokenType('keyword', 'KEYWORD', NO_PRECEDENCE, KEYWORD_TOKEN);

const TokenType EOF_INFO = const TokenType('', 'EOF', NO_PRECEDENCE, EOF_TOKEN);

/// Precedence info used by synthetic tokens that are created during parser
/// recovery (non-analyzer use case).
const TokenType RECOVERY_INFO =
    const TokenType('recovery', 'RECOVERY', NO_PRECEDENCE, RECOVERY_TOKEN);

const TokenType IDENTIFIER_INFO = const TokenType(
    'identifier', 'STRING_INT', NO_PRECEDENCE, IDENTIFIER_TOKEN);

const TokenType SCRIPT_INFO =
    const TokenType('script', 'SCRIPT_TAG', NO_PRECEDENCE, SCRIPT_TOKEN);

const TokenType BAD_INPUT_INFO = const TokenType(
    'malformed input', 'BAD_INPUT', NO_PRECEDENCE, BAD_INPUT_TOKEN);

const TokenType OPEN_PAREN_INFO =
    const TokenType('(', 'OPEN_PAREN', POSTFIX_PRECEDENCE, OPEN_PAREN_TOKEN);

const TokenType CLOSE_PAREN_INFO =
    const TokenType(')', 'CLOSE_PAREN', NO_PRECEDENCE, CLOSE_PAREN_TOKEN);

const TokenType OPEN_CURLY_BRACKET_INFO = const TokenType(
    '{', 'OPEN_CURLY_BRACKET', NO_PRECEDENCE, OPEN_CURLY_BRACKET_TOKEN);

const TokenType CLOSE_CURLY_BRACKET_INFO = const TokenType(
    '}', 'CLOSE_CURLY_BRACKET', NO_PRECEDENCE, CLOSE_CURLY_BRACKET_TOKEN);

const TokenType INT_INFO =
    const TokenType('int', 'INT', NO_PRECEDENCE, INT_TOKEN);

const TokenType STRING_INFO =
    const TokenType('string', 'STRING', NO_PRECEDENCE, STRING_TOKEN);

const TokenType OPEN_SQUARE_BRACKET_INFO = const TokenType(
    '[', 'OPEN_SQUARE_BRACKET', POSTFIX_PRECEDENCE, OPEN_SQUARE_BRACKET_TOKEN);

const TokenType CLOSE_SQUARE_BRACKET_INFO = const TokenType(
    ']', 'CLOSE_SQUARE_BRACKET', NO_PRECEDENCE, CLOSE_SQUARE_BRACKET_TOKEN);

const TokenType DOUBLE_INFO =
    const TokenType('double', 'DOUBLE', NO_PRECEDENCE, DOUBLE_TOKEN);

const TokenType STRING_INTERPOLATION_INFO = const TokenType(
    '\${',
    'STRING_INTERPOLATION_EXPRESSION',
    NO_PRECEDENCE,
    STRING_INTERPOLATION_TOKEN);

const TokenType STRING_INTERPOLATION_IDENTIFIER_INFO = const TokenType(
    '\$',
    'STRING_INTERPOLATION_IDENTIFIER',
    NO_PRECEDENCE,
    STRING_INTERPOLATION_IDENTIFIER_TOKEN);

const TokenType HEXADECIMAL_INFO = const TokenType(
    'hexadecimal', 'HEXADECIMAL', NO_PRECEDENCE, HEXADECIMAL_TOKEN);

const TokenType SINGLE_LINE_COMMENT_INFO = const TokenType(
    'comment', 'SINGLE_LINE_COMMENT', NO_PRECEDENCE, COMMENT_TOKEN);

const TokenType MULTI_LINE_COMMENT_INFO = const TokenType(
    'comment', 'MULTI_LINE_COMMENT', NO_PRECEDENCE, COMMENT_TOKEN);

const TokenType GENERIC_METHOD_TYPE_ASSIGN = const TokenType(
    'generic_comment_assign',
    'GENERIC_METHOD_TYPE_ASSIGN',
    NO_PRECEDENCE,
    GENERIC_METHOD_TYPE_ASSIGN_TOKEN);

const TokenType GENERIC_METHOD_TYPE_LIST = const TokenType(
    'generic_comment_list',
    'GENERIC_METHOD_TYPE_LIST',
    NO_PRECEDENCE,
    GENERIC_METHOD_TYPE_LIST_TOKEN);
