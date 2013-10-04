// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for encoding and decoding Unicode characters in UTF-8, UTF-16, and
 * UTF-32.
 */
library utf;

import "dart:async";
import "dart:collection";

part "utf_stream.dart";
part "utf8.dart";
part "utf16.dart";
part "utf32.dart";

// TODO(jmesserly): would be nice to have this on String (dartbug.com/6501).
/**
 * Provide a list of Unicode codepoints for a given string.
 */
List<int> stringToCodepoints(String str) {
  // Note: str.codeUnits gives us 16-bit code units on all Dart implementations.
  // So we need to convert.
  return _utf16CodeUnitsToCodepoints(str.codeUnits);
}

/**
 * Generate a string from the provided Unicode codepoints.
 *
 * *Deprecated* Use [String.fromCharCodes] instead.
 */
String codepointsToString(List<int> codepoints) {
  return new String.fromCharCodes(codepoints);
}

/**
 * Invalid codepoints or encodings may be substituted with the value U+fffd.
 */
const int UNICODE_REPLACEMENT_CHARACTER_CODEPOINT = 0xfffd;
const int UNICODE_BOM = 0xfeff;
const int UNICODE_UTF_BOM_LO = 0xff;
const int UNICODE_UTF_BOM_HI = 0xfe;

const int UNICODE_BYTE_ZERO_MASK = 0xff;
const int UNICODE_BYTE_ONE_MASK = 0xff00;
const int UNICODE_VALID_RANGE_MAX = 0x10ffff;
const int UNICODE_PLANE_ONE_MAX = 0xffff;
const int UNICODE_UTF16_RESERVED_LO = 0xd800;
const int UNICODE_UTF16_RESERVED_HI = 0xdfff;
const int UNICODE_UTF16_OFFSET = 0x10000;
const int UNICODE_UTF16_SURROGATE_UNIT_0_BASE = 0xd800;
const int UNICODE_UTF16_SURROGATE_UNIT_1_BASE = 0xdc00;
const int UNICODE_UTF16_HI_MASK = 0xffc00;
const int UNICODE_UTF16_LO_MASK = 0x3ff;

/**
 * Encode code points as UTF16 code units.
 */
List<int> _codepointsToUtf16CodeUnits(
    List<int> codepoints,
    [int offset = 0,
     int length,
     int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {

  _ListRange listRange = new _ListRange(codepoints, offset, length);
  int encodedLength = 0;
  for (int value in listRange) {
    if ((value >= 0 && value < UNICODE_UTF16_RESERVED_LO) ||
        (value > UNICODE_UTF16_RESERVED_HI && value <= UNICODE_PLANE_ONE_MAX)) {
      encodedLength++;
    } else if (value > UNICODE_PLANE_ONE_MAX &&
        value <= UNICODE_VALID_RANGE_MAX) {
      encodedLength += 2;
    } else {
      encodedLength++;
    }
  }

  List<int> codeUnitsBuffer = new List<int>(encodedLength);
  int j = 0;
  for (int value in listRange) {
    if ((value >= 0 && value < UNICODE_UTF16_RESERVED_LO) ||
        (value > UNICODE_UTF16_RESERVED_HI && value <= UNICODE_PLANE_ONE_MAX)) {
      codeUnitsBuffer[j++] = value;
    } else if (value > UNICODE_PLANE_ONE_MAX &&
        value <= UNICODE_VALID_RANGE_MAX) {
      int base = value - UNICODE_UTF16_OFFSET;
      codeUnitsBuffer[j++] = UNICODE_UTF16_SURROGATE_UNIT_0_BASE +
          ((base & UNICODE_UTF16_HI_MASK) >> 10);
      codeUnitsBuffer[j++] = UNICODE_UTF16_SURROGATE_UNIT_1_BASE +
          (base & UNICODE_UTF16_LO_MASK);
    } else if (replacementCodepoint != null) {
      codeUnitsBuffer[j++] = replacementCodepoint;
    } else {
      throw new ArgumentError("Invalid encoding");
    }
  }
  return codeUnitsBuffer;
}

/**
 * Decodes the utf16 codeunits to codepoints.
 */
List<int> _utf16CodeUnitsToCodepoints(
    List<int> utf16CodeUnits, [int offset = 0, int length,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  _ListRangeIterator source =
      (new _ListRange(utf16CodeUnits, offset, length)).iterator;
  Utf16CodeUnitDecoder decoder = new Utf16CodeUnitDecoder
      .fromListRangeIterator(source, replacementCodepoint);
  List<int> codepoints = new List<int>(source.remaining);
  int i = 0;
  while (decoder.moveNext()) {
    codepoints[i++] = decoder.current;
  }
  if (i == codepoints.length) {
    return codepoints;
  } else {
    List<int> codepointTrunc = new List<int>(i);
    codepointTrunc.setRange(0, i, codepoints);
    return codepointTrunc;
  }
}

/**
 * An Iterator<int> of codepoints built on an Iterator of UTF-16 code units.
 * The parameters can override the default Unicode replacement character. Set
 * the replacementCharacter to null to throw an ArgumentError
 * rather than replace the bad value.
 */
class Utf16CodeUnitDecoder implements Iterator<int> {
  final _ListRangeIterator utf16CodeUnitIterator;
  final int replacementCodepoint;
  int _current = null;

  Utf16CodeUnitDecoder(List<int> utf16CodeUnits, [int offset = 0, int length,
      int this.replacementCodepoint =
      UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) :
      utf16CodeUnitIterator =
          (new _ListRange(utf16CodeUnits, offset, length)).iterator;

  Utf16CodeUnitDecoder.fromListRangeIterator(
      _ListRangeIterator this.utf16CodeUnitIterator,
      int this.replacementCodepoint);

  Iterator<int> get iterator => this;

  int get current => _current;

  bool moveNext() {
    _current = null;
    if (!utf16CodeUnitIterator.moveNext()) return false;

    int value = utf16CodeUnitIterator.current;
    if (value < 0) {
      if (replacementCodepoint != null) {
        _current = replacementCodepoint;
      } else {
        throw new ArgumentError(
            "Invalid UTF16 at ${utf16CodeUnitIterator.position}");
      }
    } else if (value < UNICODE_UTF16_RESERVED_LO ||
        (value > UNICODE_UTF16_RESERVED_HI && value <= UNICODE_PLANE_ONE_MAX)) {
      // transfer directly
      _current = value;
    } else if (value < UNICODE_UTF16_SURROGATE_UNIT_1_BASE &&
        utf16CodeUnitIterator.moveNext()) {
      // merge surrogate pair
      int nextValue = utf16CodeUnitIterator.current;
      if (nextValue >= UNICODE_UTF16_SURROGATE_UNIT_1_BASE &&
          nextValue <= UNICODE_UTF16_RESERVED_HI) {
        value = (value - UNICODE_UTF16_SURROGATE_UNIT_0_BASE) << 10;
        value += UNICODE_UTF16_OFFSET +
            (nextValue - UNICODE_UTF16_SURROGATE_UNIT_1_BASE);
        _current = value;
      } else {
        if (nextValue >= UNICODE_UTF16_SURROGATE_UNIT_0_BASE &&
           nextValue < UNICODE_UTF16_SURROGATE_UNIT_1_BASE) {
          utf16CodeUnitIterator.backup();
        }
        if (replacementCodepoint != null) {
          _current = replacementCodepoint;
        } else {
          throw new ArgumentError(
              "Invalid UTF16 at ${utf16CodeUnitIterator.position}");
        }
      }
    } else if (replacementCodepoint != null) {
      _current = replacementCodepoint;
    } else {
      throw new ArgumentError(
          "Invalid UTF16 at ${utf16CodeUnitIterator.position}");
    }
    return true;
  }
}

/**
 * _ListRange in an internal type used to create a lightweight Interable on a
 * range within a source list. DO NOT MODIFY the underlying list while
 * iterating over it. The results of doing so are undefined.
 */
// TODO(floitsch): Consider removing the extend and switch to implements since
// that's cheaper to allocate.
class _ListRange extends IterableBase {
  final List _source;
  final int _offset;
  final int _length;

  _ListRange(source, [offset = 0, length]) :
      this._source = source,
      this._offset = offset,
      this._length = (length == null ? source.length - offset : length) {
    if (_offset < 0 || _offset > _source.length) {
      throw new RangeError.value(_offset);
    }
    if (_length != null && (_length < 0)) {
      throw new RangeError.value(_length);
    }
    if (_length + _offset > _source.length) {
      throw new RangeError.value(_length + _offset);
    }
  }

  _ListRangeIterator get iterator =>
      new _ListRangeIteratorImpl(_source, _offset, _offset + _length);

  int get length => _length;
}

/**
 * The _ListRangeIterator provides more capabilities than a standard iterator,
 * including the ability to get the current position, count remaining items,
 * and move forward/backward within the iterator.
 */
abstract class _ListRangeIterator implements Iterator<int> {
  bool moveNext();
  int get current;
  int get position;
  void backup([by]);
  int get remaining;
  void skip([count]);
}

class _ListRangeIteratorImpl implements _ListRangeIterator {
  final List<int> _source;
  int _offset;
  final int _end;

  _ListRangeIteratorImpl(this._source, int offset, this._end)
      : _offset = offset - 1;

  int get current => _source[_offset];

  bool moveNext() => ++_offset < _end;

  int get position => _offset;

  void backup([int by = 1]) {
    _offset -= by;
  }

  int get remaining => _end - _offset - 1;

  void skip([int count = 1]) {
    _offset += count;
  }
}

