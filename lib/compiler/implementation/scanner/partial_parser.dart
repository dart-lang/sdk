// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class PartialParser extends Parser {
  PartialParser(Listener listener) : super(listener);

  Token parseClassBody(Token token) => skipClassBody(token);

  Token fullParseClassBody(Token token) => super.parseClassBody(token);

  Token parseExpression(Token token) => skipExpression(token);

  Token parseArgumentsOpt(Token token) {
    // This method is overridden for two reasons:
    // 1. Avoid generating events for arguments.
    // 2. Avoid calling skip expression for each argument (which doesn't work).
    if (optional('(', token)) {
      BeginGroupToken begin = token;
      return begin.endGroup.next;
    } else {
      return token;
    }
  }

  Token skipExpression(Token token) {
    while (true) {
      final kind = token.kind;
      final value = token.stringValue;
      if ((kind === EOF_TOKEN) ||
          (value === ';') ||
          (value === ',') ||
          (value === ']'))
        return token;
      if (value === '=') {
        var nextValue = token.next.stringValue;
        if (nextValue === 'const') {
          token = token.next;
          nextValue = token.next.stringValue;
        }
        if (nextValue === '{') {
          // Handle cases like this:
          // class Foo {
          //   var map;
          //   Foo() : map = {};
          // }
          BeginGroupToken begin = token.next;
          token = (begin.endGroup !== null) ? begin.endGroup : token;
          token = token.next;
          continue;
        }
        if (nextValue === '<') {
          // Handle cases like this:
          // class Foo {
          //   var map;
          //   Foo() : map = <String, Foo>{};
          // }
          BeginGroupToken begin = token.next;
          token = (begin.endGroup !== null) ? begin.endGroup : token;
          token = token.next;
          if (token.stringValue === '{') {
            begin = token;
            token = (begin.endGroup !== null) ? begin.endGroup : token;
            token = token.next;
          }
          continue;
        }
      }
      if (!mayParseFunctionExpressions && value === '{') return token;
      if (token is BeginGroupToken) {
        BeginGroupToken begin = token;
        token = (begin.endGroup !== null) ? begin.endGroup : token;
      }
      token = token.next;
    }
  }

  Token skipClassBody(Token token) {
    if (!optional('{', token)) {
      return listener.expectedClassBodyToSkip(token);
    }
    BeginGroupToken beginGroupToken = token;
    assert(beginGroupToken.endGroup === null ||
           beginGroupToken.endGroup.kind === $CLOSE_CURLY_BRACKET);
    return beginGroupToken.endGroup;
  }

  Token parseFunctionBody(Token token, bool isExpression) {
    assert(!isExpression);
    String value = token.stringValue;
    if (value === ';') {
      // No body.
    } else if (value === '=>') {
      token = parseExpression(token.next);
      expectSemicolon(token);
    } else {
      token = skipBlock(token);
    }
    // There is no "skipped function body event", so we use
    // handleNoFunctionBody instead.
    listener.handleNoFunctionBody(token);
    return token;
  }

  Token parseFormalParameters(Token token) => skipFormals(token);

  Token skipFormals(Token token) {
    listener.beginOptionalFormalParameters(token);
    if (!optional('(', token)) {
      if (optional(';', token)) {
        listener.recoverableError("expected '('", token: token);
        return token;
      }
      return listener.unexpected(token);
    }
    BeginGroupToken beginGroupToken = token;
    Token endToken = beginGroupToken.endGroup;
    listener.endFormalParameters(0, token, endToken);
    return endToken.next;
  }
}
