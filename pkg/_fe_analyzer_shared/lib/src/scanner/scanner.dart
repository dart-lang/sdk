// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.scanner;

import 'dart:convert' show unicodeReplacementCharacterRune;
import 'dart:typed_data' show Uint8List;

import 'abstract_scanner.dart'
    show LanguageVersionChanged, ScannerConfiguration;
import 'string_scanner.dart' show StringScanner;
import 'token.dart' show Token;
import 'utf8_bytes_scanner.dart' show Utf8BytesScanner;

export 'abstract_scanner.dart'
    show LanguageVersionChanged, ScannerConfiguration;
export 'error_token.dart' show ErrorToken, buildUnexpectedCharacterToken;
export 'string_scanner.dart' show StringScanner;
export 'token.dart'
    show LanguageVersionToken, Keyword, Token, TokenIsAExtension;
export 'token_constants.dart' show EOF_TOKEN;
export 'token_impl.dart'
    show
        StringTokenImpl,
        isBinaryOperator,
        isMinusOperator,
        isTernaryOperator,
        isUnaryOperator,
        isUserDefinableOperator;
export 'utf8_bytes_scanner.dart' show Utf8BytesScanner;

const int unicodeReplacementCharacter = unicodeReplacementCharacterRune;

abstract class Scanner {
  /// Returns true if an error occurred during [tokenize].
  bool get hasErrors;

  List<int> get lineStarts;

  /// Configure which tokens are produced.
  set configuration(ScannerConfiguration config);

  Token tokenize();
}

class ScannerResult {
  final Token tokens;
  final List<int> lineStarts;
  final bool hasErrors;

  ScannerResult(this.tokens, this.lineStarts, this.hasErrors);
}

/// Scan/tokenize the given UTF8 [bytes].
ScannerResult scan(
  Uint8List bytes, {
  ScannerConfiguration? configuration,
  bool includeComments = false,
  LanguageVersionChanged? languageVersionChanged,
  bool allowLazyStrings = true,
}) {
  Utf8BytesScanner scanner = new Utf8BytesScanner(
    bytes,
    configuration: configuration,
    includeComments: includeComments,
    languageVersionChanged: languageVersionChanged,
    allowLazyStrings: allowLazyStrings,
  );
  Token tokens = scanner.tokenize();
  if (scanner.hasErrors) {
    // If there was a single missing `}` and the scanner can identify a good
    // candidate for better recovery, create a new scanner and instruct it to
    // do that recovery.
    int? offsetForCurlyBracketRecoveryStart = scanner
        .getOffsetForCurlyBracketRecoveryStart();
    if (offsetForCurlyBracketRecoveryStart != null) {
      scanner = new Utf8BytesScanner(
        bytes,
        configuration: configuration,
        includeComments: includeComments,
        languageVersionChanged: languageVersionChanged,
        allowLazyStrings: allowLazyStrings,
      );
      scanner.offsetForCurlyBracketRecoveryStart =
          offsetForCurlyBracketRecoveryStart;
      tokens = scanner.tokenize();
    }
  }
  return new ScannerResult(tokens, scanner.lineStarts, scanner.hasErrors);
}

/// Scan/tokenize the given [source].
ScannerResult scanString(
  String source, {
  ScannerConfiguration? configuration,
  bool includeComments = false,
  LanguageVersionChanged? languageVersionChanged,
}) {
  StringScanner scanner = new StringScanner(
    source,
    configuration: configuration,
    includeComments: includeComments,
    languageVersionChanged: languageVersionChanged,
  );
  Token tokens = scanner.tokenize();
  if (scanner.hasErrors) {
    // If there was a single missing `}` and the scanner can identify a good
    // candidate for better recovery, create a new scanner and instruct it to
    // do that recovery.
    int? offsetForCurlyBracketRecoveryStart = scanner
        .getOffsetForCurlyBracketRecoveryStart();
    if (offsetForCurlyBracketRecoveryStart != null) {
      scanner = new StringScanner(
        source,
        configuration: configuration,
        includeComments: includeComments,
        languageVersionChanged: languageVersionChanged,
      );
      scanner.offsetForCurlyBracketRecoveryStart =
          offsetForCurlyBracketRecoveryStart;
      tokens = scanner.tokenize();
    }
  }
  return new ScannerResult(tokens, scanner.lineStarts, scanner.hasErrors);
}
