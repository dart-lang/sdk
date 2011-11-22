// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Tokenizer extends lang.TokenizerBase {
  TokenKind cssTokens;

  bool _selectorParsing;

  Tokenizer(lang.SourceFile source, bool skipWhitespace, [int index = 0])
    : super(source, skipWhitespace, index), _selectorParsing = false {
    cssTokens = new TokenKind();
  }

  lang.Token next() {
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
        return _finishToken(TokenKind.DOT);
      case cssTokens.tokens[TokenKind.LBRACE]:
        return _finishToken(TokenKind.LBRACE);
      case cssTokens.tokens[TokenKind.RBRACE]:
        return _finishToken(TokenKind.RBRACE);
      case cssTokens.tokens[TokenKind.HASH]:
        return _finishToken(TokenKind.HASH);
      case cssTokens.tokens[TokenKind.COMBINATOR_PLUS]:
        return _finishToken(TokenKind.COMBINATOR_PLUS);
      case cssTokens.tokens[TokenKind.COMBINATOR_GREATER]:
        return _finishToken(TokenKind.COMBINATOR_GREATER);
      case cssTokens.tokens[TokenKind.COMBINATOR_TILDE]:
        return _finishToken(TokenKind.COMBINATOR_TILDE);
      case cssTokens.tokens[TokenKind.ASTERISK]:
        return _finishToken(TokenKind.ASTERISK);
      case cssTokens.tokens[TokenKind.NAMESPACE]:
        return _finishToken(TokenKind.NAMESPACE);
      case cssTokens.tokens[TokenKind.PSEUDO]:
        return _finishToken(TokenKind.PSEUDO);
      case cssTokens.tokens[TokenKind.COMMA]:
        return _finishToken(TokenKind.COMMA);

      default:
        if (isIdentifierStart(ch)) {
          return this.finishIdentifier();
        } else if (isDigit(ch)) {
          return this.finishNumber();
        } else {
          return _errorToken();
        }
    }
  }

  // TODO(jmesserly): we need a way to emit human readable error messages from
  // the tokenizer.
  lang.Token _errorToken() {
    return _finishToken(TokenKind.ERROR);
  }

  int getIdentifierKind() {
    return TokenKind.IDENTIFIER;
  }

  // Need to override so CSS version of isIdentifierPart is used.
  lang.Token finishIdentifier() {
    while (_index < _text.length) {
      if (!TokenizerHelpers.isIdentifierPart(_text.charCodeAt(_index++))) {
        _index--;
        break;
      }
    }
    int kind = getIdentifierKind();
    if (_interpStack != null && _interpStack.depth == -1) {
      _interpStack.depth = 0;
    }
    if (kind == TokenKind.IDENTIFIER) {
      return _finishToken(TokenKind.IDENTIFIER);
    } else {
      return _finishToken(kind);
    }
  }
}

/** Static helper methods. */
class TokenizerHelpers {
  static bool isIdentifierStart(int c) =>
      lang.TokenizerHelpers.isIdentifierStart(c) || c == 95 /*_*/;

  static bool isDigit(int c) => lang.TokenizerHelpers.isDigit(c);

  static bool isHexDigit(int c) => lang.TokenizerHelpers.isHexDigit(c);

  static bool isWhitespace(int c) => lang.TokenizerHelpers.isWhitespace(c);

  static bool isIdentifierPart(int c) =>
      lang.TokenizerHelpers.isIdentifierPart(c) || c == 45 /*-*/;
}
