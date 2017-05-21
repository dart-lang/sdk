// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.scanner;

import 'dart:convert' show UNICODE_REPLACEMENT_CHARACTER_RUNE, UTF8;

import '../scanner/token.dart' show Token;

import 'scanner/string_scanner.dart' show StringScanner;

import 'scanner/utf8_bytes_scanner.dart' show Utf8BytesScanner;

import 'scanner/recover.dart' show defaultRecoveryStrategy;

export 'scanner/token.dart'
    show
        BeginGroupToken,
        StringToken,
        SymbolToken,
        isBinaryOperator,
        isMinusOperator,
        isTernaryOperator,
        isUnaryOperator,
        isUserDefinableOperator;

export 'scanner/error_token.dart'
    show ErrorToken, buildUnexpectedCharacterToken;

export 'scanner/token_constants.dart' show EOF_TOKEN;

export 'scanner/utf8_bytes_scanner.dart' show Utf8BytesScanner;

export 'scanner/string_scanner.dart' show StringScanner;

export '../scanner/token.dart' show Keyword, Token;

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
  final bool hasErrors;

  ScannerResult(this.tokens, this.lineStarts, this.hasErrors);
}

/// Scan/tokenize the given UTF8 [bytes].
/// If [recover] is null, then the [defaultRecoveryStrategy] is used.
ScannerResult scan(List<int> bytes,
    {bool includeComments: false,
    bool scanGenericMethodComments: false,
    Recover recover}) {
  if (bytes.last != 0) {
    throw new ArgumentError("[bytes]: the last byte must be null.");
  }
  Scanner scanner = new Utf8BytesScanner(bytes,
      includeComments: includeComments,
      scanGenericMethodComments: scanGenericMethodComments);
  return _tokenizeAndRecover(scanner, recover, bytes: bytes);
}

/// Scan/tokenize the given [source].
/// If [recover] is null, then the [defaultRecoveryStrategy] is used.
ScannerResult scanString(String source,
    {bool includeComments: false,
    bool scanGenericMethodComments: false,
    bool scanLazyAssignmentOperators: false,
    Recover recover}) {
  assert(source != null, 'source must not be null');
  StringScanner scanner = new StringScanner(source,
      includeComments: includeComments,
      scanGenericMethodComments: scanGenericMethodComments,
      scanLazyAssignmentOperators: scanLazyAssignmentOperators);
  return _tokenizeAndRecover(scanner, recover, source: source);
}

ScannerResult _tokenizeAndRecover(Scanner scanner, Recover recover,
    {List<int> bytes, String source}) {
  Token tokens = scanner.tokenize();
  if (scanner.hasErrors) {
    if (bytes == null) bytes = UTF8.encode(source);
    recover ??= defaultRecoveryStrategy;
    tokens = recover(bytes, tokens, scanner.lineStarts);
  }
  return new ScannerResult(tokens, scanner.lineStarts, scanner.hasErrors);
}
