// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

String test(int n) {
  String s = "$n";
  a:
  {
    b:
    {
      try {
        if (n == 1) {
          break a;
        } else {
          break b;
        }
        s += "/";
      } finally {
        s += "-";
      }
      s += "*";
    }
    return s + "b";
  }
  return s + "a";
}

main() {
  Expect.equals("1-a", test(1));
  Expect.equals("2-b", test(2));
}
