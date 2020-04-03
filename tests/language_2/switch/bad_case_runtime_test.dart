// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test reporting a compile-time error if case expressions do not all have
// the same type or are of type double.

import "package:expect/expect.dart";

void main() {
  Expect.equals("IV", caesarSays(4));
  Expect.equals(null, caesarSays(2));
  Expect.equals(null, archimedesSays(3.14));
}

caesarSays(n) {
  switch (n) {
    case 1:
      return "I";
    case 4:
      return "IV";


  }
  return null;
}

archimedesSays(n) {






  return null;
}
