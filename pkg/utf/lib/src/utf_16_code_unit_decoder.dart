// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utf.utf_16_code_unit_decoder;

import 'constants.dart';
import 'list_range.dart';

/**
 * An Iterator<int> of codepoints built on an Iterator of UTF-16 code units.
 * The parameters can override the default Unicode replacement character. Set
 * the replacementCharacter to null to throw an ArgumentError
 * rather than replace the bad value.
 */
class Utf16CodeUnitDecoder implements Iterator<int> {
  // TODO(kevmoo): should this field be private?
  final ListRangeIterator utf16CodeUnitIterator;
  final int replacementCodepoint;
  int _current = null;

  Utf16CodeUnitDecoder(List<int> utf16CodeUnits, [int offset = 0, int length,
      int this.replacementCodepoint =
      UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) :
      utf16CodeUnitIterator =
          (new ListRange(utf16CodeUnits, offset, length)).iterator;

  Utf16CodeUnitDecoder.fromListRangeIterator(
      ListRangeIterator this.utf16CodeUnitIterator,
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

