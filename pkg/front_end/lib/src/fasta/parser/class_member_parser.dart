// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.parser.class_member_parser;

import '../../scanner/token.dart' show Token;

import '../fasta_codes.dart' show FastaMessage;

import 'listener.dart' show Listener;

import 'parser.dart' show Assert, Parser;

/// Parser similar to [TopLevelParser] but also parses class members (excluding
/// their bodies).
class ClassMemberParser extends Parser {
  ClassMemberParser(Listener listener) : super(listener);

  @override
  Token parseExpression(Token token) => skipExpression(token);

  @override
  Token parseAssert(Token token, Assert kind) {
    if (kind == Assert.Statement) {
      return super.parseAssert(token, kind);
    } else {
      return skipExpression(token);
    }
  }

  Token parseRecoverExpression(Token token, FastaMessage message) {
    Token begin = token;
    token = skipExpression(token);
    listener.handleRecoverExpression(begin, message);
    return token;
  }

  // This method is overridden for two reasons:
  // 1. Avoid generating events for arguments.
  // 2. Avoid calling skip expression for each argument (which doesn't work).
  Token parseArgumentsOpt(Token token) => skipArgumentsOpt(token);

  Token parseFunctionBody(Token token, bool isExpression, bool allowAbstract) {
    return skipFunctionBody(token, isExpression, allowAbstract);
  }
}
