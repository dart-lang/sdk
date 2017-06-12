// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.diet_parser;

import '../fasta_codes.dart' show codeExpectedOpenParens;

import '../parser/class_member_parser.dart' show ClassMemberParser;

import '../parser/listener.dart' show Listener;

import '../parser/parser.dart' show MemberKind, optional;

import '../../scanner/token.dart' show BeginToken, Token;

// TODO(ahe): Move this to parser package.
class DietParser extends ClassMemberParser {
  DietParser(Listener listener) : super(listener);

  Token parseFormalParameters(Token token, MemberKind kind) {
    return skipFormals(token, kind);
  }

  Token skipFormals(Token token, MemberKind kind) {
    listener.beginOptionalFormalParameters(token);
    if (!optional('(', token)) {
      if (optional(';', token)) {
        reportRecoverableErrorCode(token, codeExpectedOpenParens);
        return token;
      }
      return reportUnexpectedToken(token).next;
    }
    BeginToken beginGroupToken = token;
    Token endToken = beginGroupToken.endGroup;
    listener.endFormalParameters(0, token, endToken, kind);
    return endToken.next;
  }
}
