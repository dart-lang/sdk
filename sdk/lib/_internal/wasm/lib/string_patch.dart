// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_error_utils" show RangeErrorUtils;
import "dart:_internal" show patch, unsafeCast;
import "dart:_string";

@patch
class String {
  @patch
  factory String.fromCharCodes(
    Iterable<int> charCodes, [
    int start = 0,
    int? end,
  ]) {
    RangeErrorUtils.checkNotNegative(start, "start");
    if (end != null && end < start) {
      throw RangeError.range(end, start, null, "end");
    }
    return StringBase.createFromCharCodes(charCodes, start, end);
  }

  @patch
  factory String.fromCharCode(int charCode) {
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(charCode, 0x10ffff);
    if (charCode <= 0xff) {
      final string = OneByteString.withLength(1);
      string.setUnchecked(0, charCode);
      return string;
    }
    if (charCode <= 0xffff) {
      final string = TwoByteString.withLength(1);
      string.setUnchecked(0, charCode);
      return string;
    }
    assert(charCode <= 0x10ffff);
    int low = 0xDC00 | (charCode & 0x3ff);
    int bits = charCode - 0x10000;
    int high = 0xD800 | (bits >> 10);
    final string = TwoByteString.withLength(2);
    string.setUnchecked(0, high);
    string.setUnchecked(1, low);
    return string;
  }

  @patch
  external const factory String.fromEnvironment(
    String name, {
    String defaultValue = "",
  });
}

extension _StringExt on String {
  int firstNonWhitespace() {
    final value = this;
    if (value is StringBase) return value.firstNonWhitespace();
    return unsafeCast<JSStringImpl>(value).firstNonWhitespace();
  }

  int lastNonWhitespace() {
    final value = this;
    if (value is StringBase) return value.lastNonWhitespace();
    return unsafeCast<JSStringImpl>(value).lastNonWhitespace();
  }
}
