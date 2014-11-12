// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of scanner;

/**
 * Scanner that reads from a UTF-8 encoded list of bytes and creates tokens
 * that points to substrings.
 */
class Utf8BytesScanner extends ArrayBasedScanner {
  /** The file content. */
  List<int> bytes;

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

  /**
   * Creates a new Utf8BytesScanner. The source file is expected to be a
   * [Utf8BytesSourceFile] that holds a list of UTF-8 bytes. Otherwise the
   * string text of the source file is decoded.
   *
   * The list of UTF-8 bytes [file.slowUtf8Bytes()] is expected to return an
   * array whose last element is '0' to signal the end of the file. If this
   * is not the case, the entire array is copied before scanning.
   */
  Utf8BytesScanner(SourceFile file, {bool includeComments: false})
      : bytes = file.slowUtf8Bytes(),
        super(file, includeComments) {
    ensureZeroTermination();
    // Skip a leading BOM.
    if (_containsBomAt(0)) byteOffset += 3;
  }

  /**
   * Creates a new Utf8BytesScanner from a list of UTF-8 bytes.
   *
   * The last element of the list is expected to be '0' to signal the end of
   * the file. If this is not the case, the entire array is copied before
   * scanning.
   */
  Utf8BytesScanner.fromBytes(this.bytes, {bool includeComments: false})
      : super(null, includeComments) {
    ensureZeroTermination();
  }

  void ensureZeroTermination() {
    if (bytes.isEmpty || bytes[bytes.length - 1] != 0) {
      // TODO(lry): abort instead of copying the array, or warn?
      var newBytes =  new Uint8List(bytes.length + 1);
      for (int i = 0; i < bytes.length; i++) {
        newBytes[i] = bytes[i];
      }
      newBytes[bytes.length] = 0;
      bytes = newBytes;
    }
  }

  bool _containsBomAt(int offset) {
    const BOM_UTF8 = const [0xEF, 0xBB, 0xBF];

    return offset + 3 < bytes.length &&
        bytes[offset] == BOM_UTF8[0] &&
        bytes[offset + 1] == BOM_UTF8[1] &&
        bytes[offset + 2] == BOM_UTF8[2];
  }

  int advance() => bytes[++byteOffset];

  int peek() => bytes[byteOffset + 1];

  /**
   * Returns the unicode code point starting at the byte offset [startOffset]
   * with the byte [nextByte]. If [advance] is true the current [byteOffset]
   * is advanced to the last byte of the code point.
   */
  int nextCodePoint(int startOffset, int nextByte, bool advance) {
    // The number of 1s in the first byte indicate the number of bytes, at
    // least 2.
    int numBytes = 2;
    int bit = 0x20;
    while ((nextByte & bit) != 0) {
      numBytes++;
      bit >>= 1;
    }
    int end = startOffset + numBytes;
    if (advance) {
      byteOffset = end - 1;
    }
    // TODO(lry): measurably slow, decode creates first a Utf8Decoder and a
    // _Utf8Decoder instance. Also the sublist is eagerly allocated.
    String codePoint = UTF8.decode(bytes.sublist(startOffset, end));
    if (codePoint.length == 0) {
      // The UTF-8 decoder discards leading BOM characters.
      // TODO(floitsch): don't just assume that removed characters were the
      // BOM.
      assert(_containsBomAt(startOffset));
      codePoint = new String.fromCharCode(UNICODE_BOM_CHARACTER_RUNE);
    }
    if (codePoint.length == 1) {
      if (advance) {
        utf8Slack += (numBytes - 1);
        scanSlack = numBytes - 1;
        scanSlackOffset = byteOffset;
      }
      return codePoint.codeUnitAt(0);
    } else if (codePoint.length == 2) {
      if (advance) {
        utf8Slack += (numBytes - 2);
        scanSlack = numBytes - 1;
        scanSlackOffset = byteOffset;
        stringOffsetSlackOffset = byteOffset;
      }
      // In case of a surrogate pair, return a single code point.
      return codePoint.runes.single;
    } else {
      throw "Invalid UTF-8 byte sequence: ${bytes.sublist(startOffset, end)}";
    }
  }

  int lastUnicodeOffset = -1;
  int currentAsUnicode(int next) {
    if (next < 128) return next;
    // Check if currentAsUnicode was already invoked.
    if (byteOffset == lastUnicodeOffset) return next;
    int res = nextCodePoint(byteOffset, next, true);
    lastUnicodeOffset = byteOffset;
    return res;
  }

  void handleUnicode(int startScanOffset) {
    int end = byteOffset;
    // TODO(lry): this measurably slows down the scanner for files with unicode.
    String s = UTF8.decode(bytes.sublist(startScanOffset, end));
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

  int get stringOffset {
    if (stringOffsetSlackOffset == byteOffset) {
      return byteOffset - utf8Slack - 1;
    } else {
      return byteOffset - utf8Slack;
    }
  }

  Token firstToken() => tokens.next;
  Token previousToken() => tail;

  void appendSubstringToken(PrecedenceInfo info, int start, bool asciiOnly,
                            [int extraOffset = 0]) {
    tail.next = new StringToken.fromUtf8Bytes(
        info, bytes, start, byteOffset + extraOffset, asciiOnly, tokenStart);
    tail = tail.next;
  }

  bool atEndOfFile() => byteOffset >= bytes.length - 1;
}
