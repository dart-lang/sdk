// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.scanner;

import 'dart:convert' show
    UNICODE_REPLACEMENT_CHARACTER_RUNE;

import 'scanner/token.dart' show
    Token;

import 'scanner/utf8_bytes_scanner.dart' show
    Utf8BytesScanner;

import 'scanner/recover.dart' show
    defaultRecoveryStrategy;

export 'scanner/token.dart' show
    BeginGroupToken,
    KeywordToken,
    StringToken,
    SymbolToken,
    Token,
    isBinaryOperator,
    isMinusOperator,
    isTernaryOperator,
    isUnaryOperator,
    isUserDefinableOperator;

export 'scanner/error_token.dart' show
    ErrorToken,
    buildUnexpectedCharacterToken;

export 'scanner/token_constants.dart' show
    EOF_TOKEN;

export 'scanner/utf8_bytes_scanner.dart' show
    Utf8BytesScanner;

export 'scanner/string_scanner.dart' show
    StringScanner;

export 'scanner/keyword.dart' show
    Keyword;

const int unicodeReplacementCharacter = UNICODE_REPLACEMENT_CHARACTER_RUNE;

typedef Token Recover(List<int> bytes, Token tokens, List<int> lineStarts);

abstract class Scanner {
  /// Returns true if an error occured during [tokenize].
  bool get hasErrors;

  List<int> get lineStarts;

  Token tokenize();
}

class ScannerResult {
  final Token tokens;
  final List<int> lineStarts;

  ScannerResult(this.tokens, this.lineStarts);
}

ScannerResult scan(List<int> bytes,
    {bool includeComments: false, Recover recover}) {
  if (bytes.last != 0) {
    throw new ArgumentError("[bytes]: the last byte must be null.");
  }
  Scanner scanner =
      new Utf8BytesScanner(bytes, includeComments: includeComments);
  Token tokens = scanner.tokenize();
  if (scanner.hasErrors) {
    recover ??= defaultRecoveryStrategy;
    tokens = recover(bytes, tokens, scanner.lineStarts);
  }
  return new ScannerResult(tokens, scanner.lineStarts);
}
