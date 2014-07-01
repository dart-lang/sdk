// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart core library.

// VM implementation of double.

patch class double {

  static double _nativeParse(String str,
                             int start, int end) native "Double_parse";

  static double _parse(var str) {
    int len = str.length;
    int start = str._firstNonWhitespace();
    if (start == len) return null;  // All whitespace.
    int end = str._lastNonWhitespace() + 1;
    assert(start < end);

    return _nativeParse(str, start, end);
  }

  /* patch */ static double parse(String str,
                                  [double onError(String str)]) {
    var result = _parse(str);
    if (result == null) {
      if (onError == null) throw new FormatException(str);
      return onError(str);
    }
    return result;
  }
}
