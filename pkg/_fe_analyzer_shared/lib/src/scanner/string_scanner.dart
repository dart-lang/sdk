// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.scanner.string_scanner;

import 'characters.dart' show $CR, $EOF, $LF, $SPACE;

import 'internal_utils.dart' show isIdentifierChar;

import 'token.dart'
    show
        CommentToken,
        LanguageVersionToken,
        SyntheticStringToken,
        Token,
        TokenType;

import 'token.dart' as analyzer show StringToken;

import 'abstract_scanner.dart'
    show AbstractScanner, LanguageVersionChanged, ScannerConfiguration;

import 'string_canonicalizer.dart'
    show canonicalizeString, canonicalizeSubString;

import 'token_impl.dart'
    show
        CommentTokenImpl,
        DartDocToken,
        LanguageVersionTokenImpl,
        StringTokenImpl;

import 'error_token.dart' show ErrorToken;

/**
 * Scanner that reads from a String and creates tokens that points to
 * substrings.
 */
class StringScanner extends AbstractScanner {
  /** The file content. */
  final String _string;
  final int _stringLengthMinusOne;

  /** The current offset in [_string]. */
  @override
  int scanOffset = -1;

  StringScanner(
    this._string, {
    ScannerConfiguration? configuration,
    bool includeComments = false,
    LanguageVersionChanged? languageVersionChanged,
  }) : _stringLengthMinusOne = _string.length - 1,
       super(
         configuration,
         includeComments,
         languageVersionChanged,
         numberOfBytesHint: _string.length,
       );

  StringScanner.recoveryOptionScanner(StringScanner super.copyFrom)
    : _string = copyFrom._string,
      _stringLengthMinusOne = copyFrom._stringLengthMinusOne,
      scanOffset = copyFrom.scanOffset,
      super.recoveryOptionScanner();

  @override
  StringScanner createRecoveryOptionScanner() {
    return new StringScanner.recoveryOptionScanner(this);
  }

  static bool isLegalIdentifier(String identifier) {
    StringScanner scanner = new StringScanner(identifier);
    Token startToken = scanner.tokenize();
    return startToken is! ErrorToken && startToken.next!.isEof;
  }

  @override
  @pragma('vm:unsafe:no-bounds-checks')
  int advance() {
    // Always increment so scanOffset goes past the end.
    ++scanOffset;
    if (scanOffset > _stringLengthMinusOne) return $EOF;
    return _string.codeUnitAt(scanOffset);
  }

  @override
  @pragma('vm:unsafe:no-bounds-checks')
  int current() {
    if (scanOffset > _stringLengthMinusOne) return $EOF;
    return _string.codeUnitAt(scanOffset);
  }

  @override
  int passIdentifierCharAllowDollar() {
    while (true) {
      int next = advance();
      if (!isIdentifierChar(next, /* allowDollar = */ true)) {
        return next;
      }
    }
  }

  @override
  bool scanUntilLineEnd() {
    bool asciiOnly = true;
    int next = advance();
    while (true) {
      if (next > 127) asciiOnly = false;
      if ($LF == next || $CR == next || $EOF == next) {
        return asciiOnly;
      }
      next = advance();
    }
  }

  @override
  @pragma("vm:prefer-inline")
  int skipSpaces() {
    int next = advance();
    // Sequences of spaces are common, so advance through them fast.
    while (next == $SPACE) {
      // We don't invoke [:appendWhiteSpace(next):] here for efficiency,
      // assuming that it does not do anything for space characters.
      next = advance();
    }
    return next;
  }

  @override
  @pragma('vm:unsafe:no-bounds-checks')
  int peek() {
    int next = scanOffset + 1;
    if (next > _stringLengthMinusOne) return $EOF;
    return _string.codeUnitAt(next);
  }

  @override
  int get stringOffset => scanOffset;

  @override
  int currentAsUnicode(int next) => next;

  @override
  void handleUnicode(int startScanOffset) {}

  @override
  analyzer.StringToken createSubstringToken(
    TokenType type,
    int start,
    bool asciiOnly,
    int extraOffset,
    bool allowLazy,
  ) {
    return new StringTokenImpl.fromSubstring(
      type,
      _string,
      start,
      scanOffset + extraOffset,
      tokenStart,
      canonicalize: true,
      precedingComments: comments,
      allowLazy: allowLazy,
    );
  }

  @override
  analyzer.StringToken createSyntheticSubstringToken(
    TokenType type,
    int start,
    bool asciiOnly,
    String syntheticChars,
  ) {
    String value = syntheticChars.length == 0
        ? canonicalizeSubString(_string, start, scanOffset)
        : canonicalizeString(
            _string.substring(start, scanOffset) + syntheticChars,
          );
    return new SyntheticStringToken(
      type,
      value,
      tokenStart,
      value.length - syntheticChars.length,
    );
  }

  @override
  CommentToken createCommentToken(
    TokenType type,
    int start,
    bool asciiOnly, [
    int extraOffset = 0,
  ]) {
    return new CommentTokenImpl.fromSubstring(
      type,
      _string,
      start,
      scanOffset + extraOffset,
      tokenStart,
      canonicalize: true,
    );
  }

  @override
  DartDocToken createDartDocToken(
    TokenType type,
    int start,
    bool asciiOnly, [
    int extraOffset = 0,
  ]) {
    return new DartDocToken.fromSubstring(
      type,
      _string,
      start,
      scanOffset + extraOffset,
      tokenStart,
      canonicalize: true,
    );
  }

  @override
  LanguageVersionToken createLanguageVersionToken(
    int start,
    int major,
    int minor,
  ) {
    return new LanguageVersionTokenImpl.fromSubstring(
      _string,
      start,
      scanOffset,
      tokenStart,
      major,
      minor,
      canonicalize: true,
    );
  }

  @override
  // This class used to enforce zero-terminated input, so we only return true
  // once advance has been out of bounds.
  // TODO(jensj): This should probably change.
  // It's at least used in tests (where the eof token has its offset reduced
  // by one to 'fix' this.)
  bool atEndOfFile() => scanOffset > _stringLengthMinusOne;
}
