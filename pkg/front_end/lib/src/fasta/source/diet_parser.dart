// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.diet_parser;

import '../../scanner/token.dart' show Token;

import '../fasta_codes.dart' show messageExpectedOpenParens;

import '../parser.dart'
    show ClassMemberParser, Listener, MemberKind, closeBraceTokenFor, optional;

// TODO(ahe): Move this to parser package.
class DietParser extends ClassMemberParser {
  DietParser(Listener listener) : super(listener);

  Token parseFormalParameters(Token token, MemberKind kind) {
    return skipFormals(token, kind);
  }

  // TODO(brianwilkerson): Move this method to Parser, and, if possible, merge
  // it with skipFormalParameters.
  Token skipFormals(Token token, MemberKind kind) {
    token = token.next;
    listener.beginOptionalFormalParameters(token);
    if (!optional('(', token)) {
      if (optional(';', token)) {
        reportRecoverableError(token, messageExpectedOpenParens);
        listener.endFormalParameters(0, token, token, kind);
        // TODO(brianwilkerson): Until this method accepts the last consumed
        // token, this returns the wrong token (it should be the token before
        // `token`).
        return token;
      }
      return reportUnexpectedToken(token);
    }
    Token closeBrace = closeBraceTokenFor(token);
    listener.endFormalParameters(0, token, closeBrace, kind);
    return closeBrace;
  }
}
