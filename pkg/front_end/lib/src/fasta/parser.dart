// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.parser;

import '../scanner/token.dart' show Token;

import 'parser/listener.dart' show Listener;

import 'parser/parser.dart' show Parser;

import 'parser/parser_error.dart' show ParserError;

import 'fasta_codes.dart' show Message, messageNativeClauseShouldBeAnnotation;

export 'parser/assert.dart' show Assert;

export 'parser/class_member_parser.dart' show ClassMemberParser;

export 'parser/formal_parameter_kind.dart' show FormalParameterKind;

export 'parser/identifier_context.dart' show IdentifierContext;

export 'parser/listener.dart' show Listener;

export 'parser/member_kind.dart' show MemberKind;

export 'parser/parser.dart' show Parser;

export 'parser/parser_error.dart' show ParserError;

export 'parser/top_level_parser.dart' show TopLevelParser;

export 'parser/util.dart'
    show lengthForToken, lengthOfSpan, offsetForToken, optional;

class ErrorCollectingListener extends Listener {
  final List<ParserError> recoverableErrors = <ParserError>[];

  void handleRecoverableError(
      Message message, Token startToken, Token endToken) {
    /// TODO(danrubel): Ignore this error until we deprecate `native` support.
    if (message == messageNativeClauseShouldBeAnnotation) {
      return;
    }
    recoverableErrors
        .add(new ParserError.fromTokens(startToken, endToken, message));
  }
}

List<ParserError> parse(Token tokens) {
  ErrorCollectingListener listener = new ErrorCollectingListener();
  Parser parser = new Parser(listener);
  parser.parseUnit(tokens);
  return listener.recoverableErrors;
}
