// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.parser.util;

import '../scanner.dart' show Token;

import '../../scanner/token.dart' show BeginToken;

/// Returns true if [token] is the symbol or keyword [value].
bool optional(String value, Token token) {
  return identical(value, token.stringValue);
}

/// Returns the close brace, bracket, or parenthesis of [left]. For '<', it may
/// return null.
Token closeBraceTokenFor(BeginToken left) => left.endToken;

/// Returns the token before the close brace, bracket, or parenthesis
/// associated with [left]. For '<', it may return `null`.
Token beforeCloseBraceTokenFor(BeginToken left) {
  Token endToken = left.endToken;
  if (endToken == null) {
    return null;
  }
  Token token = left;
  Token next = token.next;
  while (next != endToken && next != next.next) {
    token = next;
    next = token.next;
  }
  return token;
}
