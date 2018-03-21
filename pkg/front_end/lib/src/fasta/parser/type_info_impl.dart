// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.parser.type_info_impl;

import '../../scanner/token.dart' show Token;

import 'identifier_context.dart' show IdentifierContext;

import 'listener.dart' show Listener;

import 'parser.dart' show Parser;

import 'type_info.dart' show TypeInfo, simpleTypeInfo;

import 'util.dart' show optional;

/// See documentation on the [noTypeInfo] const.
class NoTypeInfo implements TypeInfo {
  const NoTypeInfo();

  @override
  bool get couldBeExpression => false;

  @override
  Token parseType(Token token, Parser parser) {
    parser.listener.handleNoType(token);
    return token;
  }

  @override
  Token skipType(Token token) {
    return token;
  }
}

/// See documentation on the [prefixedTypeInfo] const.
class PrefixedTypeInfo implements TypeInfo {
  const PrefixedTypeInfo();

  @override
  bool get couldBeExpression => true;

  @override
  Token parseType(Token token, Parser parser) {
    Token start = token = token.next;
    assert(token.isKeywordOrIdentifier);
    Listener listener = parser.listener;
    listener.handleIdentifier(token, IdentifierContext.prefixedTypeReference);

    Token period = token = token.next;
    assert(optional('.', token));

    token = token.next;
    assert(token.isKeywordOrIdentifier);
    listener.handleIdentifier(
        token, IdentifierContext.typeReferenceContinuation);
    listener.handleQualified(period);

    listener.handleNoTypeArguments(token.next);
    listener.handleType(start, token.next);
    return token;
  }

  @override
  Token skipType(Token token) {
    return token.next.next.next;
  }
}

/// See documentation on the [simpleTypeArgumentsInfo] const.
class SimpleTypeArgumentsInfo implements TypeInfo {
  const SimpleTypeArgumentsInfo();

  @override
  bool get couldBeExpression => false;

  @override
  Token parseType(Token token, Parser parser) {
    Token start = token = token.next;
    assert(token.isKeywordOrIdentifier);
    Listener listener = parser.listener;
    listener.handleIdentifier(token, IdentifierContext.typeReference);

    Token begin = token = token.next;
    assert(optional('<', token));
    listener.beginTypeArguments(token);

    token = simpleTypeInfo.parseType(token, parser);

    token = token.next;
    assert(optional('>', token));
    assert(begin.endGroup == token);
    listener.endTypeArguments(1, begin, token);

    listener.handleType(start, token.next);
    return token;
  }

  @override
  Token skipType(Token token) {
    return token.next.next.endGroup;
  }
}

/// See documentation on the [simpleTypeInfo] const.
class SimpleTypeInfo implements TypeInfo {
  const SimpleTypeInfo();

  @override
  bool get couldBeExpression => true;

  @override
  Token parseType(Token token, Parser parser) {
    token = token.next;
    assert(token.isKeywordOrIdentifier);
    Listener listener = parser.listener;
    listener.handleIdentifier(token, IdentifierContext.typeReference);
    listener.handleNoTypeArguments(token.next);
    listener.handleType(token, token.next);
    return token;
  }

  @override
  Token skipType(Token token) {
    return token.next;
  }
}

/// See documentation on the [voidTypeInfo] const.
class VoidTypeInfo implements TypeInfo {
  const VoidTypeInfo();

  @override
  bool get couldBeExpression => false;

  @override
  Token parseType(Token token, Parser parser) {
    token = token.next;
    parser.listener.handleVoidKeyword(token);
    return token;
  }

  @override
  Token skipType(Token token) {
    return token.next;
  }
}

bool looksLikeName(Token next) => next.isIdentifier || optional('this', next);

Token skipTypeArguments(Token token) {
  assert(optional('<', token));
  Token endGroup = token.endGroup;

  // The scanner sets the endGroup in situations like this: C<T && T>U;
  // Scan the type arguments to assert there are no operators.
  // TODO(danrubel) Fix the scanner and remove this code.
  if (endGroup != null) {
    token = token.next;
    while (token != endGroup) {
      if (token.isOperator) {
        String value = token.stringValue;
        if (!identical(value, '<') &&
            !identical(value, '>') &&
            !identical(value, '>>')) {
          return null;
        }
      }
      token = token.next;
    }
  }

  return endGroup;
}
