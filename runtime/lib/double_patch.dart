// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart core library.

// VM implementation of double.

patch class double {

  static double _native_parse(_OneByteString string) native "Double_parse";

  static double _parse(var str) {
    str = str.trim();

    if (str.length == 0) return null;

    final ccid = ClassID.getID(str);
    _OneByteString oneByteString;
    // TODO(floitsch): Allow _ExternalOneByteStrings. As of May 2013 they don't
    // have any _classId.
    if (ccid != _OneByteString._classId) {
      int length = str.length;
      var s = _OneByteString._allocate(length);
      for (int i = 0; i < length; i++) {
        int currentUnit = str.codeUnitAt(i);
        // All valid trimmed double strings must be ASCII.
        if (currentUnit < 128) {
          s._setAt(i, currentUnit);
        } else {
          return null;
        }
      }
      oneByteString = s;
    } else {
      oneByteString = str;
    }

    return _native_parse(oneByteString);
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
