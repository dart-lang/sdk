// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.scanner;

import 'dart:convert' show unicodeReplacementCharacterRune, utf8;

import 'fasta_codes.dart' show LocatedMessage;

import '../scanner/token.dart' show Token;

import 'scanner/string_scanner.dart' show StringScanner;

import 'scanner/utf8_bytes_scanner.dart' show Utf8BytesScanner;

import 'scanner/recover.dart' show defaultRecoveryStrategy;

export 'scanner/token.dart'
    show
        StringToken,
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

const int unicodeReplacementCharacter = unicodeReplacementCharacterRune;

typedef Token Recover(List<int> bytes, Token tokens, List<int> lineStarts);

abstract class Scanner {
  /// A list of errors that occured during [tokenize] or `null` if none.
  List<LocatedMessage> errors;

  /// Set true if errors should be reported via the [errors] list.
  // TODO(danrubel): Remove this once all scanner clients can process
  // errors reported via the [errors] list.
  bool reportErrors;

  /// Returns true if an error occured during [tokenize].
  bool get hasErrors;

  List<int> get lineStarts;

  Token tokenize();
}

class ScannerResult {
  final Token tokens;
  final List<int> lineStarts;
  final bool hasErrors;

  /// Returns a list of errors that occured during [tokenize] or `null` if none.
  final List<LocatedMessage> errors;

  ScannerResult(this.tokens, this.lineStarts, this.hasErrors, this.errors);
}

/// Scan/tokenize the given UTF8 [bytes].
/// If [recover] is null, then the [defaultRecoveryStrategy] is used.
ScannerResult scan(List<int> bytes,
    {bool includeComments: false, Recover recover}) {
  if (bytes.last != 0) {
    throw new ArgumentError("[bytes]: the last byte must be null.");
  }
  Scanner scanner =
      new Utf8BytesScanner(bytes, includeComments: includeComments);
  return _tokenizeAndRecover(scanner, recover, bytes: bytes);
}

/// Scan/tokenize the given [source].
/// If [recover] is null, then the [defaultRecoveryStrategy] is used.
ScannerResult scanString(String source,
    {bool enableGtGtGt: false,
    bool includeComments: false,
    bool scanLazyAssignmentOperators: false,
    Recover recover}) {
  // TODO(brianwilkerson): Remove the parameter `enableGtGtGt` after the feature
  // has been anabled by default.
  assert(source != null, 'source must not be null');
  StringScanner scanner =
      new StringScanner(source, includeComments: includeComments);
  scanner.enableGtGtGt = enableGtGtGt;
  return _tokenizeAndRecover(scanner, recover, source: source);
}

ScannerResult _tokenizeAndRecover(Scanner scanner, Recover recover,
    {List<int> bytes, String source}) {
  Token tokens = scanner.tokenize();
  if (scanner.hasErrors) {
    if (bytes == null) bytes = utf8.encode(source);
    recover ??= defaultRecoveryStrategy;
    tokens = recover(bytes, tokens, scanner.lineStarts);
  }
  return new ScannerResult(
      tokens, scanner.lineStarts, scanner.hasErrors, scanner.errors);
}
