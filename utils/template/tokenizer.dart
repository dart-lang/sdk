// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Tokenizer extends TokenizerBase {
  TokenKind tmplTokens;

  bool _selectorParsing;

  Tokenizer(SourceFile source, bool skipWhitespace, [int index = 0])
    : super(source, skipWhitespace, index), _selectorParsing = false {
      tmplTokens = new TokenKind();
  }

  int get startIndex() => _startIndex;
  void set index(int idx) {
    _index = idx;
  }

  Token next([bool inTag = true]) {
    // keep track of our starting position
    _startIndex = _index;

    if (_interpStack != null && _interpStack.depth == 0) {
      var istack = _interpStack;
      _interpStack = _interpStack.pop();

      /* TODO(terry): Enable for variable and string interpolation.
       * if (istack.isMultiline) {
       *   return finishMultilineStringBody(istack.quote);
       * } else {
       *   return finishStringBody(istack.quote);
       * }
       */
    }

    int ch;
    ch = _nextChar();
    switch(ch) {
      case 0:
        return _finishToken(TokenKind.END_OF_FILE);
      case tmplTokens.tokens[TokenKind.SPACE]:
      case tmplTokens.tokens[TokenKind.TAB]:
      case tmplTokens.tokens[TokenKind.NEWLINE]:
      case tmplTokens.tokens[TokenKind.RETURN]:
        if (inTag) {
          return finishWhitespace();
        } else {
          return _finishToken(TokenKind.WHITESPACE);
        }
      case tmplTokens.tokens[TokenKind.END_OF_FILE]:
        return _finishToken(TokenKind.END_OF_FILE);
      case tmplTokens.tokens[TokenKind.LPAREN]:
        return _finishToken(TokenKind.LPAREN);
      case tmplTokens.tokens[TokenKind.RPAREN]:
        return _finishToken(TokenKind.RPAREN);
      case tmplTokens.tokens[TokenKind.COMMA]:
        return _finishToken(TokenKind.COMMA);
      case tmplTokens.tokens[TokenKind.LBRACE]:
        return _finishToken(TokenKind.LBRACE);
      case tmplTokens.tokens[TokenKind.RBRACE]:
        return _finishToken(TokenKind.RBRACE);
      case tmplTokens.tokens[TokenKind.LESS_THAN]:
        return _finishToken(TokenKind.LESS_THAN);
      case tmplTokens.tokens[TokenKind.GREATER_THAN]:
        return _finishToken(TokenKind.GREATER_THAN);
      case tmplTokens.tokens[TokenKind.EQUAL]:
        if (inTag) {
          if (_maybeEatChar(tmplTokens.tokens[TokenKind.SINGLE_QUOTE])) {
            return finishQuotedAttrValue(
              tmplTokens.tokens[TokenKind.SINGLE_QUOTE]);
          } else if (_maybeEatChar(tmplTokens.tokens[TokenKind.DOUBLE_QUOTE])) {
            return finishQuotedAttrValue(
              tmplTokens.tokens[TokenKind.DOUBLE_QUOTE]);
          } else if (TokenizerHelpers.isAttributeValueStart(_peekChar())) {
            return finishAttrValue();
          }
        }
        return _finishToken(TokenKind.EQUAL);
      case tmplTokens.tokens[TokenKind.SLASH]:
        if (_maybeEatChar(tmplTokens.tokens[TokenKind.GREATER_THAN])) {
          return _finishToken(TokenKind.END_NO_SCOPE_TAG);          // />
        } else if (_maybeEatChar(tmplTokens.tokens[TokenKind.ASTERISK])) {
          return finishMultiLineComment();
        } else {
          return _finishToken(TokenKind.SLASH);
        }
      case tmplTokens.tokens[TokenKind.DOLLAR]:
        if (_maybeEatChar(tmplTokens.tokens[TokenKind.LBRACE])) {
          if (_maybeEatChar(tmplTokens.tokens[TokenKind.HASH])) {
            return _finishToken(TokenKind.START_COMMAND);           // ${#
          } else if (_maybeEatChar(tmplTokens.tokens[TokenKind.SLASH])) {
            return _finishToken(TokenKind.END_COMMAND);             // ${/
          } else {
            return _finishToken(TokenKind.START_EXPRESSION);        // ${
          }
        } else {
          return _finishToken(TokenKind.DOLLAR);
        }

      default:
        if (TokenizerHelpers.isIdentifierStart(ch)) {
          return this.finishIdentifier();
        } else if (TokenizerHelpers.isDigit(ch)) {
          return this.finishNumber();
        } else {
          return _errorToken();
        }
    }
  }

  // TODO(jmesserly): we need a way to emit human readable error messages from
  // the tokenizer.
  Token _errorToken([String message = null]) {
    return _finishToken(TokenKind.ERROR);
  }

  int getIdentifierKind() {
    // Is the identifier an element?
    int tokId = TokenKind.matchElements(_text, _startIndex,
      _index - _startIndex);
    if (tokId == -1) {
      // No, is it an attribute?
//      tokId = TokenKind.matchAttributes(_text, _startIndex, _index - _startIndex);
    }
    if (tokId == -1) {
      tokId = TokenKind.matchKeywords(_text, _startIndex, _index - _startIndex);
    }

    return tokId >= 0 ? tokId : TokenKind.IDENTIFIER;
  }

  // Need to override so CSS version of isIdentifierPart is used.
  Token finishIdentifier() {
    while (_index < _text.length) {
//      if (!TokenizerHelpers.isIdentifierPart(_text.charCodeAt(_index++))) {
      if (!TokenizerHelpers.isIdentifierPart(_text.charCodeAt(_index))) {
//        _index--;
        break;
      } else {
        _index += 1;
      }
    }
    if (_interpStack != null && _interpStack.depth == -1) {
      _interpStack.depth = 0;
    }
    int kind = getIdentifierKind();
    if (kind == TokenKind.IDENTIFIER) {
      return _finishToken(TokenKind.IDENTIFIER);
    } else {
      return _finishToken(kind);
    }
  }

  Token _makeAttributeValueToken(List<int> buf) {
    final s = new String.fromCharCodes(buf);
    return new LiteralToken(TokenKind.ATTR_VALUE, _source, _startIndex, _index,
      s);
  }

  /* quote if -1 signals to read upto first whitespace otherwise read upto
   * single or double quote char.
   */
  Token finishQuotedAttrValue([int quote = -1]) {
    var buf = new List<int>();
    while (true) {
      int ch = _nextChar();
      if (ch == quote) {
        return _makeAttributeValueToken(buf);
      } else if (ch == 0) {
        return _errorToken();
      } else {
        buf.add(ch);
      }
    }
  }

  Token finishAttrValue() {
    var buf = new List<int>();
    while (true) {
      int ch = _peekChar();
      if (TokenizerHelpers.isWhitespace(ch) || TokenizerHelpers.isSlash(ch) ||
          TokenizerHelpers.isCloseTag(ch)) {
        return _makeAttributeValueToken(buf);
      } else if (ch == 0) {
        return _errorToken();
      } else {
        buf.add(_nextChar());
      }
    }
  }

  Token finishNumber() {
    eatDigits();

    if (_peekChar() == 46/*.*/) {
      // Handle the case of 1.toString().
      _nextChar();
      if (TokenizerHelpers.isDigit(_peekChar())) {
        eatDigits();
        return _finishToken(TokenKind.DOUBLE);
      } else {
        _index -= 1;
      }
    }

    return _finishToken(TokenKind.INTEGER);
  }

  bool maybeEatDigit() {
    if (_index < _text.length && TokenizerHelpers.isDigit(
        _text.charCodeAt(_index))) {
      _index += 1;
      return true;
    }
    return false;
  }

  void eatHexDigits() {
    while (_index < _text.length) {
     if (TokenizerHelpers.isHexDigit(_text.charCodeAt(_index))) {
       _index += 1;
     } else {
       return;
     }
    }
  }

  bool maybeEatHexDigit() {
    if (_index < _text.length && TokenizerHelpers.isHexDigit(
        _text.charCodeAt(_index))) {
      _index += 1;
      return true;
    }
    return false;
  }

  Token finishMultiLineComment() {
    while (true) {
      int ch = _nextChar();
      if (ch == 0) {
        return _finishToken(TokenKind.INCOMPLETE_COMMENT);
      } else if (ch == 42/*'*'*/) {
        if (_maybeEatChar(47/*'/'*/)) {
          if (_skipWhitespace) {
            return next();
          } else {
            return _finishToken(TokenKind.COMMENT);
          }
        }
      } else if (ch == tmplTokens.tokens[TokenKind.MINUS]) {
        /* Check if close part of Comment Definition --> (CDC). */
        if (_maybeEatChar(tmplTokens.tokens[TokenKind.MINUS])) {
          if (_maybeEatChar(tmplTokens.tokens[TokenKind.GREATER_THAN])) {
            if (_skipWhitespace) {
              return next();
            } else {
              return _finishToken(TokenKind.HTML_COMMENT);
            }
          }
        }
      }
    }
    return _errorToken();
  }

}


/** Static helper methods. */
class TokenizerHelpers {
  static bool isIdentifierStart(int c) {
    return ((c >= 97/*a*/ && c <= 122/*z*/) ||
        (c >= 65/*A*/ && c <= 90/*Z*/) || c == 95/*_*/);
  }

  static bool isDigit(int c) {
    return (c >= 48/*0*/ && c <= 57/*9*/);
  }

  static bool isHexDigit(int c) {
    return (isDigit(c) || (c >= 97/*a*/ && c <= 102/*f*/) ||
        (c >= 65/*A*/ && c <= 70/*F*/));
  }

  static bool isWhitespace(int c) {
    return (c == 32/*' '*/ || c == 9/*'\t'*/ || c == 10/*'\n'*/ ||
        c == 13/*'\r'*/);
  }

  static bool isIdentifierPart(int c) {
    return (isIdentifierStart(c) || isDigit(c) || c == 45/*-*/ ||
        c == 58/*:*/ || c == 46/*.*/);
  }

  static bool isInterpIdentifierPart(int c) {
    return (isIdentifierStart(c) || isDigit(c));
  }

  static bool isAttributeValueStart(int c) {
    return !isWhitespace(c) && !isSlash(c) && !isCloseTag(c);
  }

  static bool isSlash(int c) {
    return (c == 47/* / */);
  }

  static bool isCloseTag(int c) {
    return (c == 62/* > */);
  }
}
