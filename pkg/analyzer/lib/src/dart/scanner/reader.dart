// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.dart.scanner.reader;

import 'package:front_end/src/scanner/reader.dart';

export 'package:front_end/src/scanner/reader.dart' show CharacterReader;

/**
 * A [CharacterReader] that reads a range of characters from another character
 * reader.
 */
class CharacterRangeReader extends CharacterReader {
  /**
   * The reader from which the characters are actually being read.
   */
  final CharacterReader baseReader;

  /**
   * The last character to be read.
   */
  final int endIndex;

  /**
   * Initialize a newly created reader to read the characters from the given
   * [baseReader] between the [startIndex] inclusive to [endIndex] exclusive.
   */
  CharacterRangeReader(this.baseReader, int startIndex, this.endIndex) {
    baseReader.offset = startIndex - 1;
  }

  @override
  int get offset => baseReader.offset;

  @override
  void set offset(int offset) {
    baseReader.offset = offset;
  }

  @override
  int advance() {
    if (baseReader.offset + 1 >= endIndex) {
      return -1;
    }
    return baseReader.advance();
  }

  @override
  String getString(int start, int endDelta) =>
      baseReader.getString(start, endDelta);

  @override
  int peek() {
    if (baseReader.offset + 1 >= endIndex) {
      return -1;
    }
    return baseReader.peek();
  }
}

/**
 * A [CharacterReader] that reads characters from a character sequence.
 */
class CharSequenceReader implements CharacterReader {
  /**
   * The sequence from which characters will be read.
   */
  final String _sequence;

  /**
   * The number of characters in the string.
   */
  int _stringLength;

  /**
   * The index, relative to the string, of the next character to be read.
   */
  int _charOffset;

  /**
   * Initialize a newly created reader to read the characters in the given
   * [_sequence].
   */
  CharSequenceReader(this._sequence) {
    this._stringLength = _sequence.length;
    this._charOffset = 0;
  }

  @override
  int get offset => _charOffset - 1;

  @override
  void set offset(int offset) {
    _charOffset = offset + 1;
  }

  @override
  int advance() {
    if (_charOffset >= _stringLength) {
      return -1;
    }
    return _sequence.codeUnitAt(_charOffset++);
  }

  @override
  String getString(int start, int endDelta) =>
      _sequence.substring(start, _charOffset + endDelta);

  @override
  int peek() {
    if (_charOffset >= _stringLength) {
      return -1;
    }
    return _sequence.codeUnitAt(_charOffset);
  }
}

/**
 * A [CharacterReader] that reads characters from a character sequence, but adds
 * a delta when reporting the current character offset so that the character
 * sequence can be a subsequence from a larger sequence.
 */
class SubSequenceReader extends CharSequenceReader {
  /**
   * The offset from the beginning of the file to the beginning of the source
   * being scanned.
   */
  final int _offsetDelta;

  /**
   * Initialize a newly created reader to read the characters in the given
   * [sequence]. The [_offsetDelta] is the offset from the beginning of the file
   * to the beginning of the source being scanned
   */
  SubSequenceReader(String sequence, this._offsetDelta) : super(sequence);

  @override
  int get offset => _offsetDelta + super.offset;

  @override
  void set offset(int offset) {
    super.offset = offset - _offsetDelta;
  }

  @override
  String getString(int start, int endDelta) =>
      super.getString(start - _offsetDelta, endDelta);
}
