// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/scanner/interner.dart';

class StringUtilities {
  static Interner INTERNER = new NullInterner();

  static bool endsWith3(String str, int c1, int c2, int c3) {
    var length = str.length;
    return length >= 3 &&
        str.codeUnitAt(length - 3) == c1 &&
        str.codeUnitAt(length - 2) == c2 &&
        str.codeUnitAt(length - 1) == c3;
  }

  static String intern(String string) => INTERNER.intern(string);

  static bool startsWith3(String str, int start, int c1, int c2, int c3) {
    return str.length - start >= 3 &&
        str.codeUnitAt(start) == c1 &&
        str.codeUnitAt(start + 1) == c2 &&
        str.codeUnitAt(start + 2) == c3;
  }
}
