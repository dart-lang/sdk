// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 26543

class C {
  var x, y;
  C()
      : x = null ?? <int, int>{},
        y = 0 {}
}

main() {
  print(new C());
}
