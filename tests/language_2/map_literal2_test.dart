// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test program for map literals.

import "package:expect/expect.dart";

int nextValCtr;

get nextVal {
  return nextValCtr++;
}

main() {
  // Map literals with string interpolation in keys.
  nextValCtr = 0;
  var map = {"a$nextVal": "Grey", "a$nextVal": "Poupon"};
  Expect.equals(true, map.containsKey("a0"));
  Expect.equals(true, map.containsKey("a1"));
  Expect.equals("Grey", map["a0"]);
  Expect.equals("Poupon", map["a1"]);
}
