// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.parser;

import '../scanner/token.dart' show Token;

import 'parser/listener.dart' show Listener;

import 'parser/parser.dart' show Parser;

import 'parser/parser_error.dart' show ParserError;

export 'parser/assert.dart' show Assert;

export 'parser/class_member_parser.dart' show ClassMemberParser;

export 'parser/formal_parameter_kind.dart' show FormalParameterKind;

export 'parser/identifier_context.dart' show IdentifierContext;

export 'parser/listener.dart' show Listener;

export 'parser/member_kind.dart' show MemberKind;

export 'parser/parser.dart' show Parser;

export 'parser/parser_error.dart' show ParserError;

export 'parser/top_level_parser.dart' show TopLevelParser;

export 'parser/util.dart' show closeBraceTokenFor, optional;

List<ParserError> parse(Token tokens) {
  Listener listener = new Listener();
  Parser parser = new Parser(listener);
  parser.parseUnit(tokens);
  return listener.recoverableErrors;
}
