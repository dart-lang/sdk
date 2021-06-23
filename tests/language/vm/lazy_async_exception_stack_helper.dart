// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

bool stringContainsInOrder(String string, List<String> substrings) {
  var fromIndex = 0;
  for (var s in substrings) {
    fromIndex = string.indexOf(s, fromIndex);
    if (fromIndex < 0) {
      return false;
    }
  }
  return true;
}
