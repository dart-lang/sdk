// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.parser.top_level_parser;

import '../../scanner/token.dart' show Token;

import 'class_kind.dart' show ClassKind;

import 'class_member_parser.dart' show ClassMemberParser;

import 'listener.dart' show Listener;

/// Parser which only parses top-level elements, but ignores their bodies.
/// Use [Parser] to parse everything.
class TopLevelParser extends ClassMemberParser {
  TopLevelParser(Listener listener) : super(listener);

  Token parseClassOrMixinOrExtensionBody(Token token, ClassKind kind) =>
      skipClassOrMixinOrExtensionBody(token);
}
