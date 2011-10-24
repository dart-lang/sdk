// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class StringBase {
  static String createFromCharCodes(List<int> charCodes) native;

  static String join(List<String> strings, String separator) {
    String s = "";
    for (int i = 0; i < strings.length; i++) {
      if (i > 0) {
        s = s.concat(separator);
      }
      s = s.concat(strings[i]);
    }
    return s;
  }

  static String concatAll(List<String> strings) {
    return join(strings, "");
  }

}
