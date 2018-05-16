// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.parser.util;

import 'package:kernel/ast.dart' show TreeNode;

import '../fasta_codes.dart' show noLength;

import '../scanner.dart' show Token;

import '../../scanner/token.dart' show BeginToken;

/// Returns true if [token] is the symbol or keyword [value].
bool optional(String value, Token token) {
  return identical(value, token.stringValue);
}

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

/// A null-aware alternative to `token.offset`.  If [token] is `null`, returns
/// `TreeNode.noOffset`.
int offsetForToken(Token token) {
  return token == null ? TreeNode.noOffset : token.offset;
}

/// A null-aware alternative to `token.length`.  If [token] is `null`, returns
/// [noLength].
int lengthForToken(Token token) {
  return token == null ? noLength : token.length;
}

/// Returns the length of the span from [begin] to [end] (inclusive). If both
/// tokens are null, return [noLength]. If one of the tokens are null, return
/// the length of the other token.
int lengthOfSpan(Token begin, Token end) {
  if (begin == null) return lengthForToken(end);
  if (end == null) return lengthForToken(begin);
  return end.offset + end.length - begin.offset;
}

Token skipMetadata(Token token) {
  token = token.next;
  assert(optional('@', token));
  Token next = token.next;
  if (next.isIdentifier) {
    token = next;
    next = token.next;
    while (optional('.', next)) {
      token = next;
      next = token.next;
      if (next.isIdentifier) {
        token = next;
        next = token.next;
      }
    }
    if (optional('(', next)) {
      token = next.endGroup;
      next = token.next;
    }
  }
  return token;
}
