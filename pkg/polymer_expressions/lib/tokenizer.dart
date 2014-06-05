// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer_expressions.tokenizer;

const int _TAB = 9;
const int _LF = 10;
const int _VTAB = 11;
const int _FF = 12;
const int _CR = 13;
const int _SPACE = 32;
const int _BANG = 33;
const int _DQ = 34;
const int _$ = 36;
const int _PERCENT = 37;
const int _AMPERSAND = 38;
const int _SQ = 39;
const int _OPEN_PAREN = 40;
const int _CLOSE_PAREN = 41;
const int _STAR = 42;
const int _PLUS = 43;
const int _COMMA = 44;
const int _MINUS = 45;
const int _PERIOD = 46;
const int _SLASH = 47;
const int _0 = 48;
const int _9 = 57;
const int _COLON = 58;
const int _LT = 60;
const int _EQ = 61;
const int _GT = 62;
const int _QUESTION = 63;
const int _A = 65;
const int _Z = 90;
const int _OPEN_SQUARE_BRACKET = 91;
const int _BACKSLASH = 92;
const int _CLOSE_SQUARE_BRACKET = 93;
const int _CARET = 94;
const int _US = 95;
const int _a = 97;
const int _f = 102;
const int _n = 110;
const int _r = 114;
const int _t = 116;
const int _v = 118;
const int _z = 122;
const int _OPEN_CURLY_BRACKET = 123;
const int _BAR = 124;
const int _CLOSE_CURLY_BRACKET = 125;
const int _NBSP = 160;

const _OPERATORS = const [_PLUS, _MINUS, _STAR, _SLASH, _BANG, _AMPERSAND,
                          _PERCENT, _LT, _EQ, _GT, _QUESTION, _CARET, _BAR];

const _GROUPERS = const [_OPEN_PAREN, _CLOSE_PAREN,
                         _OPEN_SQUARE_BRACKET, _CLOSE_SQUARE_BRACKET,
                         _OPEN_CURLY_BRACKET, _CLOSE_CURLY_BRACKET];

const _TWO_CHAR_OPS = const ['==', '!=', '<=', '>=', '||', '&&'];

const KEYWORDS = const ['as', 'in', 'this'];

const _PRECEDENCE = const {
  '!':  0,
  ':':  0,
  ',':  0,
  ')':  0,
  ']':  0,
  '}':  0, // ?
  '?':  1,
  '||': 2,
  '&&': 3,
  '|':  4,
  '^':  5,
  '&':  6,

  // equality
  '!=': 7,
  '==': 7,
  '!==': 7,
  '===': 7,

  // relational
  '>=': 8,
  '>':  8,
  '<=': 8,
  '<':  8,

  // additive
  '+':  9,
  '-':  9,

  // multiplicative
  '%':  10,
  '/':  10,
  '*':  10,

  // postfix
  '(':  11,
  '[':  11,
  '.':  11,
  '{': 11, //not sure this is correct
};

const POSTFIX_PRECEDENCE = 11;

const int STRING_TOKEN = 1;
const int IDENTIFIER_TOKEN = 2;
const int DOT_TOKEN = 3;
const int COMMA_TOKEN = 4;
const int COLON_TOKEN = 5;
const int INTEGER_TOKEN = 6;
const int DECIMAL_TOKEN = 7;
const int OPERATOR_TOKEN = 8;
const int GROUPER_TOKEN = 9;
const int KEYWORD_TOKEN = 10;

bool isWhitespace(int next) => next == _SPACE || next == _TAB || next == _NBSP;

bool isIdentifierOrKeywordStart(int next) => (_a <= next && next <= _z) ||
    (_A <= next && next <= _Z) || next == _US || next == _$ || next > 127;

bool isIdentifier(int next) => (_a <= next && next <= _z) ||
    (_A <= next && next <= _Z) || (_0 <= next && next <= _9) ||
    next == _US || next == _$ || next > 127;

bool isQuote(int next) => next == _DQ || next == _SQ;

bool isNumber(int next) => _0 <= next && next <= _9;

bool isOperator(int next) => _OPERATORS.contains(next);

bool isGrouper(int next) => _GROUPERS.contains(next);

int escape(int c) {
  switch (c) {
    case _f: return _FF;
    case _n: return _LF;
    case _r: return _CR;
    case _t: return _TAB;
    case _v: return _VTAB;
    default: return c;
  }
}

class Token {
  final int kind;
  final String value;
  final int precedence;

  Token(this.kind, this.value, [this.precedence = 0]);

  String toString() => "($kind, '$value')";
}

class Tokenizer {
  final List<Token> _tokens = <Token>[];
  final StringBuffer _sb = new StringBuffer();
  final RuneIterator _iterator;

  int _next;

  Tokenizer(String input) : _iterator = new RuneIterator(input);

  _advance() {
    _next = _iterator.moveNext() ? _iterator.current : null;
  }

  List<Token> tokenize() {
    _advance();
    while(_next != null) {
      if (isWhitespace(_next)) {
        _advance();
      } else if (isQuote(_next)) {
        tokenizeString();
      } else if (isIdentifierOrKeywordStart(_next)) {
        tokenizeIdentifierOrKeyword();
      } else if (isNumber(_next)) {
        tokenizeNumber();
      } else if (_next == _PERIOD) {
        tokenizeDot();
      } else if (_next == _COMMA) {
        tokenizeComma();
      } else if (_next == _COLON) {
        tokenizeColon();
      } else if (isOperator(_next)) {
        tokenizeOperator();
      } else if (isGrouper(_next)) {
        tokenizeGrouper();
      } else {
        _advance();
      }
    }
    return _tokens;
  }

  tokenizeString() {
    int quoteChar = _next;
    _advance();
    while (_next != quoteChar) {
      if (_next == null) throw new ParseException("unterminated string");
      if (_next == _BACKSLASH) {
        _advance();
        if (_next == null) throw new ParseException("unterminated string");
        _sb.writeCharCode(escape(_next));
      } else {
        _sb.writeCharCode(_next);
      }
      _advance();
    }
    _tokens.add(new Token(STRING_TOKEN, _sb.toString()));
    _sb.clear();
    _advance();
  }

  tokenizeIdentifierOrKeyword() {
    while (_next != null && isIdentifier(_next)) {
      _sb.writeCharCode(_next);
      _advance();
    }
    var value = _sb.toString();
    if (KEYWORDS.contains(value)) {
      _tokens.add(new Token(KEYWORD_TOKEN, value));
    } else {
      _tokens.add(new Token(IDENTIFIER_TOKEN, value));
    }
    _sb.clear();
  }

  tokenizeNumber() {
    while (_next != null && isNumber(_next)) {
      _sb.writeCharCode(_next);
      _advance();
    }
    if (_next == _PERIOD) {
      tokenizeDot();
    } else {
      _tokens.add(new Token(INTEGER_TOKEN, _sb.toString()));
      _sb.clear();
    }
  }

  tokenizeDot() {
    _advance();
    if (isNumber(_next)) {
      tokenizeFraction();
    } else {
      _tokens.add(new Token(DOT_TOKEN, '.', POSTFIX_PRECEDENCE));
    }
  }

  tokenizeComma() {
    _advance();
    _tokens.add(new Token(COMMA_TOKEN, ','));
  }

  tokenizeColon() {
    _advance();
    _tokens.add(new Token(COLON_TOKEN, ':'));
  }

  tokenizeFraction() {
    _sb.writeCharCode(_PERIOD);
    while (_next != null && isNumber(_next)) {
      _sb.writeCharCode(_next);
      _advance();
    }
    _tokens.add(new Token(DECIMAL_TOKEN, _sb.toString()));
    _sb.clear();
  }

  tokenizeOperator() {
    int startChar = _next;
    _advance();
    var op;
    // check for 2 character operators
    if (isOperator(_next)) {
      var op2 = new String.fromCharCodes([startChar, _next]);
      if (_TWO_CHAR_OPS.contains(op2)) {
        op = op2;
        _advance();
        // kind of hacky check for === and !===, could be better / more general
        if (_next == _EQ && (startChar == _BANG || startChar == _EQ)) {
          op = op2 + '=';
          _advance();
        }
      } else {
        op = new String.fromCharCode(startChar);
      }
    } else {
      op = new String.fromCharCode(startChar);
    }
    _tokens.add(new Token(OPERATOR_TOKEN, op, _PRECEDENCE[op]));
  }

  tokenizeGrouper() {
    var value = new String.fromCharCode(_next);
    _tokens.add(new Token(GROUPER_TOKEN, value, _PRECEDENCE[value]));
    _advance();
  }
}

class ParseException implements Exception {
  final String message;
  ParseException(this.message);
  String toString() => "ParseException: $message";
}
