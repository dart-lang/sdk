// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer.token_utils;

import 'package:front_end/src/scanner/token.dart' show Token;

import 'package:front_end/src/fasta/scanner/token_constants.dart';

import 'package:front_end/src/scanner/errors.dart' show translateErrorToken;

import 'package:front_end/src/scanner/errors.dart' as analyzer
    show ScannerErrorCode;

/// Class capable of converting a stream of Fasta tokens to a stream of analyzer
/// tokens.
///
/// This is a class rather than an ordinary method so that it can be subclassed
/// in tests.
class ToAnalyzerTokenStreamConverter {
  /// Converts a stream of Fasta tokens (starting with [token] and continuing to
  /// EOF) to a stream of analyzer tokens. This modifies the fasta token stream
  /// to be an analyzer token stream by removing error tokens and reporting
  /// those errors to the associated error listener.
  Token convertTokens(Token firstToken) {
    Token previous = new Token.eof(-1);
    Token token = firstToken;
    token.previous = previous;
    previous.next = token;
    while (!token.isEof) {
      if (token.type.kind == BAD_INPUT_TOKEN) {
        translateErrorToken(token, reportError);
        previous.next = token.next;
        token.next.previous = previous;
      } else {
        previous = token;
      }
      token = token.next;
    }
    return firstToken;
  }

  /// Handles an error found during [convertTokens].
  ///
  /// Intended to be overridden by derived classes; by default, does nothing.
  void reportError(analyzer.ScannerErrorCode errorCode, int offset,
      List<Object> arguments) {}
}
