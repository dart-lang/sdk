// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  var matches = new RegExp("(a(b)((c|de)+))").allMatches("abcde abcde abcde");
  var it = matches.iterator;
  int start = 0;
  int end = 5;
  while (it.moveNext()) {
    Match match = it.current;
    Expect.equals(start, match.start);
    Expect.equals(end, match.end);
    start += 6;
    end += 6;
  }
}
