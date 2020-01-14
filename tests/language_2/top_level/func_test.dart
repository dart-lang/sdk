// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program testing top-level variables.

import "package:expect/expect.dart";

class TopLevelFuncTest {
  static testMain() {
    var z = [1, 10, 100, 1000];
    Expect.equals(Sum(z), 1111);

    var w = Window;
    Expect.equals(w, "window");

    Expect.equals(null, rgb);
    Color = "ff0000";
    Expect.equals(rgb, "#ff0000");
    CheckColor("#ff0000");

    Expect.equals("5", digits[5]);

    var e1 = Enumerator;
    var e2 = Enumerator;
    Expect.equals(0, e1());
    Expect.equals(1, e1());
    Expect.equals(2, e1());
    Expect.equals(0, e2());
  }
}

void CheckColor(String expected) {
  Expect.equals(expected, rgb);
}

int Sum(List<int> v) {
  int s = 0;
  for (int i = 0; i < v.length; i++) {
    s += v[i];
  }
  return s;
}

get Window {
  return "win" "dow";
}

String rgb;

void set Color(col) {
  rgb = "#$col";
}

List<String> get digits {
  return ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
}

Function get Enumerator {
  int k = 0;
  return () => k++;
}

main() {
  TopLevelFuncTest.testMain();
}
