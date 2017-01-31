// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.parser;

import 'package:front_end/src/fasta/scanner/token.dart' show
    Token;

import 'parser/listener.dart' show
    Listener;

import 'parser/parser.dart' show
    Parser;

import 'parser/listener.dart' show
    ParserError;

export 'parser/parser.dart' show
    Parser,
    closeBraceFor,
    optional;

export 'parser/listener.dart' show
    Listener,
    ParserError;

export 'parser/error_kind.dart' show
    ErrorKind;

export 'parser/top_level_parser.dart' show
    TopLevelParser;

export 'parser/class_member_parser.dart' show
    ClassMemberParser;

List<ParserError> parse(Token tokens) {
  Listener listener = new Listener();
  Parser parser = new Parser(listener);
  parser.parseUnit(tokens);
  return listener.recoverableErrors;
}
