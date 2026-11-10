// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing double.maxSafeInteger and double.minSafeInteger.

import "package:expect/expect.dart";

const int maxSafe = double.maxSafeInteger;
const int minSafe = double.minSafeInteger;

void main() {
  Expect.equals(0x1F_FFFF_FFFF_FFFF, maxSafe); // 9007199254740991
  Expect.equals(-0x1F_FFFF_FFFF_FFFF, minSafe); // -9007199254740991
  Expect.equals(-maxSafe, minSafe);

  Expect.notEquals(maxSafe.toDouble(), (maxSafe + 1).toDouble());
  Expect.notEquals(maxSafe.toDouble(), (maxSafe - 1).toDouble());
  Expect.notEquals((maxSafe - 1).toDouble(), (maxSafe - 2).toDouble());
  Expect.equals((maxSafe + 2).toDouble(), (maxSafe + 1).toDouble());

  Expect.notEquals(minSafe.toDouble(), (minSafe - 1).toDouble());
  Expect.notEquals(minSafe.toDouble(), (minSafe + 1).toDouble());
  Expect.notEquals((minSafe + 1).toDouble(), (minSafe + 2).toDouble());
  Expect.equals((minSafe - 2).toDouble(), (minSafe - 1).toDouble());
}
