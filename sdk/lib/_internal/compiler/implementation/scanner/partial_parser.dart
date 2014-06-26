// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of scanner;

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
      if ((identical(kind, EOF_TOKEN)) ||
          (identical(value, ';')) ||
          (identical(value, ',')) ||
          (identical(value, '}')) ||
          (identical(value, ')')) ||
          (identical(value, ']'))) {
        break;
      }
      if (identical(value, '=') ||
          identical(value, '?') ||
          identical(value, ':')) {
        var nextValue = token.next.stringValue;
        if (identical(nextValue, 'const')) {
          token = token.next;
          nextValue = token.next.stringValue;
        }
        if (identical(nextValue, '{')) {
          // Handle cases like this:
          // class Foo {
          //   var map;
          //   Foo() : map = {};
          //   Foo.x() : map = true ? {} : {};
          // }
          BeginGroupToken begin = token.next;
          token = (begin.endGroup != null) ? begin.endGroup : token;
          token = token.next;
          continue;
        }
        if (identical(nextValue, '<')) {
          // Handle cases like this:
          // class Foo {
          //   var map;
          //   Foo() : map = <String, Foo>{};
          //   Foo.x() : map = true ? <String, Foo>{} : <String, Foo>{};
          // }
          BeginGroupToken begin = token.next;
          token = (begin.endGroup != null) ? begin.endGroup : token;
          token = token.next;
          if (identical(token.stringValue, '{')) {
            begin = token;
            token = (begin.endGroup != null) ? begin.endGroup : token;
            token = token.next;
          }
          continue;
        }
      }
      if (!mayParseFunctionExpressions && identical(value, '{')) {
        break;
      }
      if (token is BeginGroupToken) {
        BeginGroupToken begin = token;
        token = (begin.endGroup != null) ? begin.endGroup : token;
      } else if (token is ErrorToken) {
        listener.reportErrorToken(token);
      }
      token = token.next;
    }
    return token;
  }

  Token skipClassBody(Token token) {
    if (!optional('{', token)) {
      return listener.expectedClassBodyToSkip(token);
    }
    BeginGroupToken beginGroupToken = token;
    Token endGroup = beginGroupToken.endGroup;
    if (endGroup == null) {
      return listener.unmatched(beginGroupToken);
    } else if (!identical(endGroup.kind, $CLOSE_CURLY_BRACKET)) {
      return listener.unmatched(beginGroupToken);
    }
    return endGroup;
  }

  Token parseFunctionBody(Token token, bool isExpression, bool allowAbstract) {
    assert(!isExpression);
    String value = token.stringValue;
    if (identical(value, ';')) {
      if (!allowAbstract) {
        listener.reportError(token, MessageKind.BODY_EXPECTED);
      }
      listener.handleNoFunctionBody(token);
    } else {
      if (identical(value, '=>')) {
        token = parseExpression(token.next);
        expectSemicolon(token);
      } else if (value == '=') {
        token = parseRedirectingFactoryBody(token);
        expectSemicolon(token);
      } else {
        token = skipBlock(token);
      }
      listener.skippedFunctionBody(token);
    }
    return token;
  }

  Token parseFormalParameters(Token token) => skipFormals(token);

  Token skipFormals(Token token) {
    listener.beginOptionalFormalParameters(token);
    if (!optional('(', token)) {
      if (optional(';', token)) {
        listener.recoverableError(token, "expected '('");
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
