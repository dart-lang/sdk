// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=8

import "package:expect/expect.dart";

main() {
  // Make instance-of polymorphic.
  isNum([]);
  isNumRaw([]);
  isNotNum([]);
  isNotInt([]);
  for (int i = 0; i < 20; i++) {
    Expect.isTrue(isNum(i));
    Expect.isTrue(isNumRaw(i));
    Expect.isFalse(isNotNum(i));
    Expect.isFalse(isNotInt(i));
  }
}

isNum(a) {
  return a is Comparable<num>;
}

isNumRaw(a) {
  return a is Comparable;
}

isNotNum(a) {
  return a is Comparable<String>;
}

isNotInt(a) {
  return a is Comparable<double>;
}
