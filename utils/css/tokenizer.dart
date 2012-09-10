// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Tokenizer extends CSSTokenizerBase {
  TokenKind cssTokens;

  bool _selectorParsing;

  Tokenizer(SourceFile source, bool skipWhitespace, [int index = 0])
    : super(source, skipWhitespace, index), _selectorParsing = false {
    cssTokens = new TokenKind();
  }

  int get startIndex => _startIndex;

  Token next() {
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
      case cssTokens.tokens[TokenKind.SPACE]:
      case cssTokens.tokens[TokenKind.TAB]:
      case cssTokens.tokens[TokenKind.NEWLINE]:
      case cssTokens.tokens[TokenKind.RETURN]:
        return finishWhitespace();
      case cssTokens.tokens[TokenKind.END_OF_FILE]:
        return _finishToken(TokenKind.END_OF_FILE);
      case cssTokens.tokens[TokenKind.AT]:
        return _finishToken(TokenKind.AT);
      case cssTokens.tokens[TokenKind.DOT]:
        int start = _startIndex;             // Start where the dot started.
        if (maybeEatDigit()) {
          // looks like a number dot followed by digit(s).
          Token number = finishNumber();
          if (number.kind == TokenKind.INTEGER) {
            // It's a number but it's preceeded by a dot, so make it a double.
            _startIndex = start;
            return _finishToken(TokenKind.DOUBLE);
          } else {
            // Don't allow dot followed by a double (e.g,  '..1').
            return _errorToken();
          }
        } else {
          // It's really a dot.
          return _finishToken(TokenKind.DOT);
        }
      case cssTokens.tokens[TokenKind.LPAREN]:
        return _finishToken(TokenKind.LPAREN);
      case cssTokens.tokens[TokenKind.RPAREN]:
        return _finishToken(TokenKind.RPAREN);
      case cssTokens.tokens[TokenKind.LBRACE]:
        return _finishToken(TokenKind.LBRACE);
      case cssTokens.tokens[TokenKind.RBRACE]:
        return _finishToken(TokenKind.RBRACE);
      case cssTokens.tokens[TokenKind.LBRACK]:
        return _finishToken(TokenKind.LBRACK);
      case cssTokens.tokens[TokenKind.RBRACK]:
        return _finishToken(TokenKind.RBRACK);
      case cssTokens.tokens[TokenKind.HASH]:
        return _finishToken(TokenKind.HASH);
      case cssTokens.tokens[TokenKind.PLUS]:
        if (maybeEatDigit()) {
          return finishNumber();
        } else {
          return _finishToken(TokenKind.PLUS);
        }
      case cssTokens.tokens[TokenKind.MINUS]:
        if (maybeEatDigit()) {
          return finishNumber();
        } else if (TokenizerHelpers.isIdentifierStart(ch)) {
          return this.finishIdentifier(ch);
        } else {
          return _finishToken(TokenKind.MINUS);
        }
      case cssTokens.tokens[TokenKind.GREATER]:
        return _finishToken(TokenKind.GREATER);
      case cssTokens.tokens[TokenKind.TILDE]:
        if (_maybeEatChar(cssTokens.tokens[TokenKind.EQUALS])) {
          return _finishToken(TokenKind.INCLUDES);          // ~=
        } else {
          return _finishToken(TokenKind.TILDE);
        }
      case cssTokens.tokens[TokenKind.ASTERISK]:
        if (_maybeEatChar(cssTokens.tokens[TokenKind.EQUALS])) {
          return _finishToken(TokenKind.SUBSTRING_MATCH);   // *=
        } else {
          return _finishToken(TokenKind.ASTERISK);
        }
      case cssTokens.tokens[TokenKind.NAMESPACE]:
        return _finishToken(TokenKind.NAMESPACE);
      case cssTokens.tokens[TokenKind.COLON]:
        return _finishToken(TokenKind.COLON);
      case cssTokens.tokens[TokenKind.COMMA]:
        return _finishToken(TokenKind.COMMA);
      case cssTokens.tokens[TokenKind.SEMICOLON]:
        return _finishToken(TokenKind.SEMICOLON);
      case cssTokens.tokens[TokenKind.PERCENT]:
        return _finishToken(TokenKind.PERCENT);
      case cssTokens.tokens[TokenKind.SINGLE_QUOTE]:
        return _finishToken(TokenKind.SINGLE_QUOTE);
      case cssTokens.tokens[TokenKind.DOUBLE_QUOTE]:
        return _finishToken(TokenKind.DOUBLE_QUOTE);
      case cssTokens.tokens[TokenKind.SLASH]:
        if (_maybeEatChar(cssTokens.tokens[TokenKind.ASTERISK])) {
          return finishMultiLineComment();
        } else {
          return _finishToken(TokenKind.SLASH);
        }
      case  cssTokens.tokens[TokenKind.LESS]:      // <!--
        if (_maybeEatChar(cssTokens.tokens[TokenKind.BANG]) &&
            _maybeEatChar(cssTokens.tokens[TokenKind.MINUS]) &&
            _maybeEatChar(cssTokens.tokens[TokenKind.MINUS])) {
          return finishMultiLineComment();
        } else {
          return _finishToken(TokenKind.LESS);
        }
      case cssTokens.tokens[TokenKind.EQUALS]:
        return _finishToken(TokenKind.EQUALS);
      case cssTokens.tokens[TokenKind.OR]:
        if (_maybeEatChar(cssTokens.tokens[TokenKind.EQUALS])) {
          return _finishToken(TokenKind.DASH_MATCH);      // |=
        } else {
          return _finishToken(TokenKind.OR);
        }
      case cssTokens.tokens[TokenKind.CARET]:
        if (_maybeEatChar(cssTokens.tokens[TokenKind.EQUALS])) {
          return _finishToken(TokenKind.PREFIX_MATCH);    // ^=
        } else {
          return _finishToken(TokenKind.CARET);
        }
      case cssTokens.tokens[TokenKind.DOLLAR]:
        if (_maybeEatChar(cssTokens.tokens[TokenKind.EQUALS])) {
          return _finishToken(TokenKind.SUFFIX_MATCH);    // $=
        } else {
          return _finishToken(TokenKind.DOLLAR);
        }
      case cssTokens.tokens[TokenKind.BANG]:
        Token tok = finishIdentifier(ch);
        return (tok == null) ? _finishToken(TokenKind.BANG) : tok;
      default:
        if (TokenizerHelpers.isIdentifierStart(ch)) {
          return this.finishIdentifier(ch);
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
    // Is the identifier a unit type?
    int tokId = TokenKind.matchUnits(_text, _startIndex, _index - _startIndex);
    if (tokId == -1) {
      // No, is it a directive?
      tokId = TokenKind.matchDirectives(
          _text, _startIndex, _index - _startIndex);
    }
    if (tokId == -1) {
      tokId = (_text.substring(_startIndex, _index) == '!important') ?
          TokenKind.IMPORTANT : -1;
    }

    return tokId >= 0 ? tokId : TokenKind.IDENTIFIER;
  }

  // Need to override so CSS version of isIdentifierPart is used.
  Token finishIdentifier(int ch) {
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

  Token finishImportant() {
    
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
    if (_index < _text.length
        && TokenizerHelpers.isDigit(_text.charCodeAt(_index))) {
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
    if (_index < _text.length
        && TokenizerHelpers.isHexDigit(_text.charCodeAt(_index))) {
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
      } else if (ch == cssTokens.tokens[TokenKind.MINUS]) {
        /* Check if close part of Comment Definition --> (CDC). */
        if (_maybeEatChar(cssTokens.tokens[TokenKind.MINUS])) {
          if (_maybeEatChar(cssTokens.tokens[TokenKind.GREATER])) {
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
/** Static helper methods. */
class TokenizerHelpers {
  
  static bool isIdentifierStart(int c) {
    return ((c >= 97/*a*/ && c <= 122/*z*/) || (c >= 65/*A*/ && c <= 90/*Z*/) ||
        c == 95/*_*/ || c == 45 /*-*/);
  }

  static bool isDigit(int c) {
    return (c >= 48/*0*/ && c <= 57/*9*/);
  }

  static bool isHexDigit(int c) {
    return (isDigit(c) || (c >= 97/*a*/ && c <= 102/*f*/)
        || (c >= 65/*A*/ && c <= 70/*F*/));
  }

  static bool isIdentifierPart(int c) {
    return (isIdentifierStart(c) || isDigit(c) || c == 45 /*-*/);
  }
}

