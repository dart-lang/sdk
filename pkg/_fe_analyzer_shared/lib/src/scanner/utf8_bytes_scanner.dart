// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:compiler/src/io/source_file.dart';
library _fe_analyzer_shared.scanner.utf8_bytes_scanner;

import 'dart:typed_data' show Uint8List;

import 'dart:convert' show unicodeBomCharacterRune, utf8;

import 'characters.dart';

import 'internal_utils.dart' show isIdentifierCharAllowDollarTableLookup;

import 'token.dart' show LanguageVersionToken, SyntheticStringToken, TokenType;

import 'token.dart' as analyzer;

import 'scanner.dart' show unicodeReplacementCharacter;

import 'abstract_scanner.dart'
    show AbstractScanner, LanguageVersionChanged, ScannerConfiguration;

import 'string_canonicalizer.dart'
    show canonicalizeUtf8SubString, canonicalizeString, decodeString;

import 'token_impl.dart'
    show
        CommentTokenImpl,
        DartDocToken,
        LanguageVersionTokenImpl,
        StringTokenImpl;

/**
 * Scanner that reads from a UTF-8 encoded list of bytes and creates tokens
 * that points to substrings.
 */
class Utf8BytesScanner extends AbstractScanner {
  /// The raw file content.
  final Uint8List _bytes;
  final int _bytesLengthMinusOne;

  /**
   * Points to the offset of the last byte returned by [advance].
   *
   * After invoking [currentAsUnicode], the [byteOffset] points to the last
   * byte that is part of the (unicode or ASCII) character. That way, [advance]
   * can always increase the byte offset by 1.
   */
  int byteOffset = -1;

  /**
   * The getter [scanOffset] is expected to return the index where the current
   * character *starts*. In case of a non-ascii character, after invoking
   * [currentAsUnicode], the byte offset points to the *last* byte.
   *
   * This field keeps track of the number of bytes for the current unicode
   * character. For example, if bytes 7,8,9 encode one unicode character, the
   * [byteOffset] is 9 (after invoking [currentAsUnicode]). The [scanSlack]
   * will be 2, so that [scanOffset] returns 7.
   */
  int scanSlack = 0;

  /**
   * Holds the [byteOffset] value for which the current [scanSlack] is valid.
   */
  int scanSlackOffset = -1;

  /**
   * Returns the byte offset of the first byte that belongs to the current
   * character.
   */
  @override
  int get scanOffset {
    if (byteOffset == scanSlackOffset) {
      return byteOffset - scanSlack;
    } else {
      return byteOffset;
    }
  }

  /**
   * The difference between the number of bytes and the number of corresponding
   * string characters, up to the current [byteOffset].
   */
  int utf8Slack = 0;

  Utf8BytesScanner(
    this._bytes, {
    ScannerConfiguration? configuration,
    bool includeComments = false,
    LanguageVersionChanged? languageVersionChanged,
    bool allowLazyStrings = true,
  }) : _bytesLengthMinusOne = _bytes.length - 1,
       super(
         configuration,
         includeComments,
         languageVersionChanged,
         numberOfBytesHint: _bytes.length,
         allowLazyStrings: allowLazyStrings,
       ) {
    // Skip a leading BOM.
    if (containsBomAt(/* offset = */ 0)) {
      byteOffset += 3;
      utf8Slack += 3;
    }
  }

  Utf8BytesScanner.createRecoveryOptionScanner(Utf8BytesScanner copyFrom)
    : _bytes = copyFrom._bytes,
      _bytesLengthMinusOne = copyFrom._bytesLengthMinusOne,
      super.recoveryOptionScanner(copyFrom) {
    this.byteOffset = copyFrom.byteOffset;
    this.scanSlack = copyFrom.scanSlack;
    this.scanSlackOffset = copyFrom.scanSlackOffset;
    this.utf8Slack = copyFrom.utf8Slack;
  }

  @override
  Utf8BytesScanner createRecoveryOptionScanner() {
    return new Utf8BytesScanner.createRecoveryOptionScanner(this);
  }

  bool containsBomAt(int offset) {
    const List<int> BOM_UTF8 = const [0xEF, 0xBB, 0xBF];

    return offset + 2 < _bytes.length &&
        _bytes[offset] == BOM_UTF8[0] &&
        _bytes[offset + 1] == BOM_UTF8[1] &&
        _bytes[offset + 2] == BOM_UTF8[2];
  }

  @override
  @pragma('vm:unsafe:no-bounds-checks')
  int advance() {
    // Always increment so byteOffset goes past the end.
    ++byteOffset;
    if (byteOffset > _bytesLengthMinusOne) return $EOF;
    return _bytes[byteOffset];
  }

  @pragma('vm:unsafe:no-bounds-checks')
  @pragma("vm:prefer-inline")
  int _advanceNoBoundsCheck() {
    ++byteOffset;
    return _bytes[byteOffset];
  }

  @override
  @pragma('vm:unsafe:no-bounds-checks')
  int current() {
    if (byteOffset > _bytesLengthMinusOne) return $EOF;
    return _bytes[byteOffset];
  }

  @override
  @pragma('vm:unsafe:no-bounds-checks')
  int passIdentifierCharAllowDollar() {
    int localByteOffset = byteOffset;
    while (localByteOffset + 10 < _bytesLengthMinusOne) {
      // Here we can access bytes without checks
      int next = _bytes[++localByteOffset];
      if (isIdentifierCharAllowDollarTableLookup(next) &&
          isIdentifierCharAllowDollarTableLookup(
            next = _bytes[++localByteOffset],
          ) &&
          isIdentifierCharAllowDollarTableLookup(
            next = _bytes[++localByteOffset],
          ) &&
          isIdentifierCharAllowDollarTableLookup(
            next = _bytes[++localByteOffset],
          ) &&
          isIdentifierCharAllowDollarTableLookup(
            next = _bytes[++localByteOffset],
          ) &&
          isIdentifierCharAllowDollarTableLookup(
            next = _bytes[++localByteOffset],
          ) &&
          isIdentifierCharAllowDollarTableLookup(
            next = _bytes[++localByteOffset],
          ) &&
          isIdentifierCharAllowDollarTableLookup(
            next = _bytes[++localByteOffset],
          ) &&
          isIdentifierCharAllowDollarTableLookup(
            next = _bytes[++localByteOffset],
          ) &&
          isIdentifierCharAllowDollarTableLookup(
            next = _bytes[++localByteOffset],
          )) {
        continue;
      }
      // If we got here the latest value into next returned false.
      byteOffset = localByteOffset;
      return next;
    }

    // Less than 10 bytes left in stream.
    while (true) {
      int next = advance();
      if (next == $EOF || !isIdentifierCharAllowDollarTableLookup(next)) {
        return next;
      }
    }
  }

  @pragma("vm:prefer-inline")
  bool _isEolChar(int next) {
    const List<bool> table = [
      // format hack.
      false, false, false, false, false, false, false, false,
      false, false, true, false, false, true, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      false, false, false, false, false, false, false, false,
      // format hack.
    ];
    return table[next];
  }

  @override
  bool scanUntilLineEnd() {
    // The localByteOffset optimization from [passIdentifierCharAllowDollar]
    // makes things slower here. (it does reduce the instructions executed, but
    // seemingly increases the L1 instruction cache misses by ~15% making the
    // whole thing slower).
    int nonAsciiCount = 0;
    while (byteOffset + 10 < _bytesLengthMinusOne) {
      // Here we can access bytes without checks
      // 1.
      int next = _advanceNoBoundsCheck();
      nonAsciiCount |= next;
      if (_isEolChar(next)) return nonAsciiCount & 128 == 0;

      // 2.
      next = _advanceNoBoundsCheck();
      nonAsciiCount |= next;
      if (_isEolChar(next)) return nonAsciiCount & 128 == 0;

      // 3.
      next = _advanceNoBoundsCheck();
      nonAsciiCount |= next;
      if (_isEolChar(next)) return nonAsciiCount & 128 == 0;

      // 4.
      next = _advanceNoBoundsCheck();
      nonAsciiCount |= next;
      if (_isEolChar(next)) return nonAsciiCount & 128 == 0;

      // 5.
      next = _advanceNoBoundsCheck();
      nonAsciiCount |= next;
      if (_isEolChar(next)) return nonAsciiCount & 128 == 0;

      // 6.
      next = _advanceNoBoundsCheck();
      nonAsciiCount |= next;
      if (_isEolChar(next)) return nonAsciiCount & 128 == 0;

      // 7.
      next = _advanceNoBoundsCheck();
      nonAsciiCount |= next;
      if (_isEolChar(next)) return nonAsciiCount & 128 == 0;

      // 8.
      next = _advanceNoBoundsCheck();
      nonAsciiCount |= next;
      if (_isEolChar(next)) return nonAsciiCount & 128 == 0;

      // 9.
      next = _advanceNoBoundsCheck();
      nonAsciiCount |= next;
      if (_isEolChar(next)) return nonAsciiCount & 128 == 0;

      // 10.
      next = _advanceNoBoundsCheck();
      nonAsciiCount |= next;
      if (_isEolChar(next)) return nonAsciiCount & 128 == 0;
    }
    // Less than 10 bytes left.
    int next = advance();
    while (true) {
      nonAsciiCount |= next;
      if ($LF == next || $CR == next || $EOF == next) {
        return nonAsciiCount & 128 == 0;
      }
      next = advance();
    }
  }

  @override
  @pragma("vm:prefer-inline")
  int skipSpaces() {
    // Not having a loop possibly saves us (at least) a
    // CheckStackOverflow (2 instructions).
    if (byteOffset + 10 < _bytesLengthMinusOne) {
      // Here we can access bytes without checks
      int next = _advanceNoBoundsCheck();
      if (next == $SPACE &&
          (next = _advanceNoBoundsCheck()) == $SPACE &&
          (next = _advanceNoBoundsCheck()) == $SPACE &&
          (next = _advanceNoBoundsCheck()) == $SPACE &&
          (next = _advanceNoBoundsCheck()) == $SPACE &&
          (next = _advanceNoBoundsCheck()) == $SPACE &&
          (next = _advanceNoBoundsCheck()) == $SPACE &&
          (next = _advanceNoBoundsCheck()) == $SPACE &&
          (next = _advanceNoBoundsCheck()) == $SPACE &&
          (next = _advanceNoBoundsCheck()) == $SPACE) {
      } else {
        // If we got here the latest value into next returned false.
        return next;
      }
    }

    while (byteOffset + 10 < _bytesLengthMinusOne) {
      // Here we can access bytes without checks
      int next = _advanceNoBoundsCheck();
      if (next == $SPACE &&
          (next = _advanceNoBoundsCheck()) == $SPACE &&
          (next = _advanceNoBoundsCheck()) == $SPACE &&
          (next = _advanceNoBoundsCheck()) == $SPACE &&
          (next = _advanceNoBoundsCheck()) == $SPACE &&
          (next = _advanceNoBoundsCheck()) == $SPACE &&
          (next = _advanceNoBoundsCheck()) == $SPACE &&
          (next = _advanceNoBoundsCheck()) == $SPACE &&
          (next = _advanceNoBoundsCheck()) == $SPACE &&
          (next = _advanceNoBoundsCheck()) == $SPACE) {
        continue;
      }
      // If we got here the latest value into next returned false.
      return next;
    }
    // Less than 10 bytes left.
    int next = advance();
    while (next == $SPACE) {
      next = advance();
    }
    return next;
  }

  @override
  @pragma('vm:unsafe:no-bounds-checks')
  int peek() {
    int next = byteOffset + 1;
    if (next > _bytesLengthMinusOne) return $EOF;
    return _bytes[next];
  }

  /// Returns the unicode code point starting at the byte offset [startOffset]
  /// with the byte [nextByte].
  int nextCodePoint(int startOffset, int nextByte) {
    int expectedHighBytes;
    if (nextByte < 0xC2) {
      expectedHighBytes = 1; // Bad code unit.
    } else if (nextByte < 0xE0) {
      expectedHighBytes = 2;
    } else if (nextByte < 0xF0) {
      expectedHighBytes = 3;
    } else if (nextByte < 0xF5) {
      expectedHighBytes = 4;
    } else {
      expectedHighBytes = 1; // Bad code unit.
    }
    int numBytes = 0;
    for (int i = 0; i < expectedHighBytes; i++) {
      int next = byteOffset + i;
      if (next > _bytesLengthMinusOne) break;
      if (_bytes[next] < 0x80) {
        break;
      }
      numBytes++;
    }
    int end = startOffset + numBytes;
    byteOffset = end - 1;
    if (expectedHighBytes == 1 || numBytes != expectedHighBytes) {
      return unicodeReplacementCharacter;
    }
    // TODO(lry): measurably slow, decode creates first a Utf8Decoder and a
    // _Utf8Decoder instance. Also the sublist is eagerly allocated.
    String codePoint = utf8.decode(
      _bytes.sublist(startOffset, end),
      allowMalformed: true,
    );
    if (codePoint.length == 0) {
      // The UTF-8 decoder discards leading BOM characters.
      // TODO(floitsch): don't just assume that removed characters were the
      // BOM.
      assert(containsBomAt(startOffset));
      codePoint = new String.fromCharCode(unicodeBomCharacterRune);
    }
    if (codePoint.length == 1) {
      utf8Slack += (numBytes - 1);
      scanSlack = numBytes - 1;
      scanSlackOffset = byteOffset;
      return codePoint.codeUnitAt(/* index = */ 0);
    } else if (codePoint.length == 2) {
      utf8Slack += (numBytes - 2);
      scanSlack = numBytes - 1;
      scanSlackOffset = byteOffset;
      stringOffsetSlackOffset = byteOffset;
      // In case of a surrogate pair, return a single code point.
      // Gracefully degrade given invalid UTF-8.
      RuneIterator runes = codePoint.runes.iterator;
      if (!runes.moveNext()) return unicodeReplacementCharacter;
      int codeUnit = runes.current;
      return !runes.moveNext() ? codeUnit : unicodeReplacementCharacter;
    } else {
      return unicodeReplacementCharacter;
    }
  }

  int lastUnicodeOffset = -1;
  @override
  int currentAsUnicode(int next) {
    if (next < 128) return next;
    // Check if currentAsUnicode was already invoked.
    if (byteOffset == lastUnicodeOffset) return next;
    int res = nextCodePoint(byteOffset, next);
    lastUnicodeOffset = byteOffset;
    return res;
  }

  @override
  void handleUnicode(int startScanOffset) {
    int end = byteOffset;
    // TODO(lry): this measurably slows down the scanner for files with unicode.
    String s = utf8.decode(
      _bytes.sublist(startScanOffset, end),
      allowMalformed: true,
    );
    utf8Slack += (end - startScanOffset) - s.length;
  }

  /**
   * This field remembers the byte offset of the last character decoded with
   * [nextCodePoint] that used two code units in UTF-16.
   *
   * [nextCodePoint] returns a single code point for each unicode character,
   * even if it needs two code units in UTF-16.
   *
   * For example, '\u{1d11e}' uses 4 bytes in UTF-8, and two code units in
   * UTF-16. The [utf8Slack] is therefore 2. After invoking [nextCodePoint], the
   * [byteOffset] points to the last (of 4) bytes. The [stringOffset] should
   * return the offset of the first one, which is one position more left than
   * the [utf8Slack].
   */
  int stringOffsetSlackOffset = -1;

  @override
  int get stringOffset {
    if (stringOffsetSlackOffset == byteOffset) {
      return byteOffset - utf8Slack - 1;
    } else {
      return byteOffset - utf8Slack;
    }
  }

  @override
  analyzer.StringToken createSubstringToken(
    TokenType type,
    int start,
    bool asciiOnly,
    int extraOffset,
    bool allowLazy,
  ) {
    return new StringTokenImpl.fromUtf8Bytes(
      type,
      _bytes,
      start,
      byteOffset + extraOffset,
      asciiOnly,
      tokenStart,
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
        ? canonicalizeUtf8SubString(_bytes, start, byteOffset, asciiOnly)
        : canonicalizeString(
            decodeString(_bytes, start, byteOffset, asciiOnly) + syntheticChars,
          );
    return new SyntheticStringToken(
      type,
      value,
      tokenStart,
      value.length - syntheticChars.length,
    );
  }

  @override
  analyzer.CommentToken createCommentToken(
    TokenType type,
    int start,
    bool asciiOnly, [
    int extraOffset = 0,
  ]) {
    return new CommentTokenImpl.fromUtf8Bytes(
      type,
      _bytes,
      start,
      byteOffset + extraOffset,
      asciiOnly,
      tokenStart,
    );
  }

  @override
  DartDocToken createDartDocToken(
    TokenType type,
    int start,
    bool asciiOnly, [
    int extraOffset = 0,
  ]) {
    return new DartDocToken.fromUtf8Bytes(
      type,
      _bytes,
      start,
      byteOffset + extraOffset,
      asciiOnly,
      tokenStart,
    );
  }

  @override
  LanguageVersionToken createLanguageVersionToken(
    int start,
    int major,
    int minor,
  ) {
    return new LanguageVersionTokenImpl.fromUtf8Bytes(
      _bytes,
      start,
      byteOffset,
      tokenStart,
      major,
      minor,
    );
  }

  @override
  // This class used to require zero-terminated input, so we only return true
  // once advance has been out of bounds.
  // TODO(jensj): This should probably change.
  // It's at least used in tests (where the eof token has its offset reduced
  // by one to 'fix' this.)
  bool atEndOfFile() => byteOffset > _bytesLengthMinusOne;
}
