// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library FfiTest;

import 'dart:convert';
import 'dart:ffi' as ffi;

/// Sample non-struct subtype of Pointer for dart:ffi library.
class CString extends ffi.Pointer<ffi.Uint8> {
  CString elementAt(int index) => super.elementAt(index).cast();

  String fromUtf8() {
    List<int> units = [];
    int len = 0;
    while (true) {
      int char = elementAt(len++).load<int>();
      if (char == 0) break;
      units.add(char);
    }
    return Utf8Decoder().convert(units);
  }

  factory CString.toUtf8(String s) {
    CString result = ffi.allocate<ffi.Uint8>(count: s.length + 1).cast();
    List<int> units = Utf8Encoder().convert(s);
    for (int i = 0; i < s.length; i++) result.elementAt(i).store(units[i]);
    result.elementAt(s.length).store(0);
    return result;
  }
}
