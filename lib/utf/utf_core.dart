// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Provide a list of Unicode codepoints for a given string.
 */
List<int> stringToCodepoints(String str) {
  List<int> codepoints;
  // TODO _is16BitCodeUnit() is used to work around a bug with frog/dartc
  // (http://code.google.com/p/dart/issues/detail?id=1357). Consider
  // removing after this issue is resolved.
  if (_is16BitCodeUnit()) {
    codepoints = _utf16CodeUnitsToCodepoints(str.charCodes());
  } else {
    codepoints = str.charCodes();
  }
  return codepoints;
}

/**
 * Generate a string from the provided Unicode codepoints.
 */
String codepointsToString(List<int> codepoints) {
  // TODO _is16BitCodeUnit() is used to work around a bug with frog/dartc
  // (http://code.google.com/p/dart/issues/detail?id=1357). Consider
  // removing after this issue is resolved.
  if (_is16BitCodeUnit()) {
    return new String.fromCharCodes(
        _codepointsToUtf16CodeUnits(codepoints));
  } else {
    return new String.fromCharCodes(codepoints);
  }
}

/*
 * Test for presence of bug related to the use of UTF-16 code units for
 * Dart compiled to JS.
 */
bool _test16BitCodeUnit = null;
// TODO _is16BitCodeUnit() is used to work around a bug with frog/dartc
// (http://code.google.com/p/dart/issues/detail?id=1357). Consider
// removing after this issue is resolved.
bool _is16BitCodeUnit() {
  if (_test16BitCodeUnit == null) {
    _test16BitCodeUnit = (new String.fromCharCodes([0x1D11E])) ==
        (new String.fromCharCodes([0xD11E]));
  }
  return _test16BitCodeUnit;
}

/**
 * Invalid codepoints or encodings may be substituted with the value U+fffd.
 */
final int UNICODE_REPLACEMENT_CHARACTER_CODEPOINT = 0xfffd;
final int UNICODE_BOM = 0xfeff;
final int UNICODE_UTF_BOM_LO = 0xff;
final int UNICODE_UTF_BOM_HI = 0xfe;

final int UNICODE_BYTE_ZERO_MASK = 0xff;
final int UNICODE_BYTE_ONE_MASK = 0xff00;
final int UNICODE_VALID_RANGE_MAX = 0x10ffff;
final int UNICODE_PLANE_ONE_MAX = 0xffff;
final int UNICODE_UTF16_RESERVED_LO = 0xd800;
final int UNICODE_UTF16_RESERVED_HI = 0xdfff;
final int UNICODE_UTF16_OFFSET = 0x10000;
final int UNICODE_UTF16_SURROGATE_UNIT_0_BASE = 0xd800;
final int UNICODE_UTF16_SURROGATE_UNIT_1_BASE = 0xdc00;
final int UNICODE_UTF16_HI_MASK = 0xffc00;
final int UNICODE_UTF16_LO_MASK = 0x3ff;

/**
 * Encode code points as UTF16 code units.
 */
List<int> _codepointsToUtf16CodeUnits(
    List<int> codepoints, [int offset = 0, int length,
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
      throw new IllegalArgumentException("Invalid encoding");
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
      (new _ListRange(utf16CodeUnits, offset, length)).iterator();
  Utf16CodeUnitDecoder decoder = new Utf16CodeUnitDecoder
      .fromListRangeIterator(source, replacementCodepoint);
  List<int> codepoints = new List<int>(source.remaining);
  int i = 0;
  while (decoder.hasNext()) {
    codepoints[i++] = decoder.next();
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
 * the replacementCharacter to null to throw an IllegalArgumentException
 * rather than replace the bad value.
 */
class Utf16CodeUnitDecoder implements Iterator<int> {
  final _ListRangeIterator utf16CodeUnitIterator;
  final int replacementCodepoint;

  Utf16CodeUnitDecoder(List<int> utf16CodeUnits, [int offset = 0, int length,
      int this.replacementCodepoint =
      UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) :
      utf16CodeUnitIterator = (new _ListRange(utf16CodeUnits, offset, length))
          .iterator();

  Utf16CodeUnitDecoder.fromListRangeIterator(
      _ListRangeIterator this.utf16CodeUnitIterator,
      int this.replacementCodepoint);

  Iterator<int> iterator() => this;

  bool hasNext() => utf16CodeUnitIterator.hasNext();

  int next() {
    int value = utf16CodeUnitIterator.next();
    if (value < 0) {
      if (replacementCodepoint != null) {
        return replacementCodepoint;
      } else {
        throw new IllegalArgumentException(
            "Invalid UTF16 at ${utf16CodeUnitIterator.position}");
      }
    } else if (value < UNICODE_UTF16_RESERVED_LO ||
        (value > UNICODE_UTF16_RESERVED_HI && value <= UNICODE_PLANE_ONE_MAX)) {
      // transfer directly
      return value;
    } else if (value < UNICODE_UTF16_SURROGATE_UNIT_1_BASE &&
        utf16CodeUnitIterator.hasNext()) {
      // merge surrogate pair
      int nextValue = utf16CodeUnitIterator.next();
      if (nextValue >= UNICODE_UTF16_SURROGATE_UNIT_1_BASE &&
          nextValue <= UNICODE_UTF16_RESERVED_HI) {
        value = (value - UNICODE_UTF16_SURROGATE_UNIT_0_BASE) << 10;
        value += UNICODE_UTF16_OFFSET +
            (nextValue - UNICODE_UTF16_SURROGATE_UNIT_1_BASE);
        return value;
      } else {
        if (nextValue >= UNICODE_UTF16_SURROGATE_UNIT_0_BASE &&
           nextValue < UNICODE_UTF16_SURROGATE_UNIT_1_BASE) {
          utf16CodeUnitIterator.backup();
        }
        if (replacementCodepoint != null) {
          return replacementCodepoint;
        } else {
          throw new IllegalArgumentException(
              "Invalid UTF16 at ${utf16CodeUnitIterator.position}");
        }
      }
    } else if (replacementCodepoint != null) {
      return replacementCodepoint;
    } else {
      throw new IllegalArgumentException(
          "Invalid UTF16 at ${utf16CodeUnitIterator.position}");
    }
  }
}

/**
 * _ListRange in an internal type used to create a lightweight Interable on a
 * range within a source list. DO NOT MODIFY the underlying list while
 * iterating over it. The results of doing so are undefined.
 */
class _ListRange implements Iterable {
  final List _source;
  final int _offset;
  final int _length;

  _ListRange(source, [offset = 0, length]) :
      this._source = source,
      this._offset = offset,
      this._length = (length == null ? source.length - offset : length) {
    if (_offset < 0 || _offset > _source.length) {
      throw new IndexOutOfRangeException("offset out of range (< 0)");
    }
    if (_length != null && (_length < 0)) {
      throw new IndexOutOfRangeException("length out of range (< 0)");
    }
    if (_length + _offset > _source.length) {
      throw new IndexOutOfRangeException("offset + length > source.length");
    }
  }

  _ListRangeIterator iterator() =>
      new _ListRangeIteratorImpl(_source, _offset, _offset + _length);

  int get length() => _length;
}

/**
 * The _ListRangeIterator provides more capabilities than a standard iterator,
 * including the ability to get the current position, count remaining items,
 * and move forward/backward within the iterator.
 */
interface _ListRangeIterator extends Iterator<int> {
  bool hasNext();
  int next();
  int get position();
  void backup([by]);
  int get remaining();
  void skip([count]);
}

class _ListRangeIteratorImpl implements _ListRangeIterator {
  final List<int> _source;
  int _offset;
  final int _end;

  _ListRangeIteratorImpl(this._source, this._offset, this._end);

  bool hasNext() => _offset < _end;

  int next() => _source[_offset++];

  int get position() => _offset;

  void backup([int by = 1]) {
    _offset -= by;
  }

  int get remaining() => _end - _offset;

  void skip([int count = 1]) {
    _offset += count;
  }
}

