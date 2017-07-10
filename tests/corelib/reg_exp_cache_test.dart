// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Runs several similar regexps in a loop to see if an internal cache works (at
// least in easy conditions).

import "package:expect/expect.dart";

void main() {
  for (int j = 1; j < 50; j++) {
    for (int i = 0; i < 20 * j; i++) {
      var regExp = new RegExp("foo$i");
      var match = regExp.firstMatch("foo$i");
      Expect.isNotNull(match);
      Expect.equals("foo$i", match[0]);
    }
  }
}
