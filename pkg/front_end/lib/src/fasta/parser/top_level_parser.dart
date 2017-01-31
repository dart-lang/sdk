// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.parser.top_level_parser;

import 'package:front_end/src/fasta/scanner/token.dart' show
    Token;

import 'listener.dart' show
    Listener;

import 'class_member_parser.dart' show
    ClassMemberParser;

/// Parser which only parses top-level elements, but ignores their bodies.
/// Use [Parser] to parse everything.
class TopLevelParser extends ClassMemberParser {
  TopLevelParser(Listener listener, {bool asyncAwaitKeywordsEnabled: false})
      : super(listener, asyncAwaitKeywordsEnabled: asyncAwaitKeywordsEnabled);

  Token parseClassBody(Token token) => skipClassBody(token);
}
