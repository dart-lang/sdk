// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=triple-shift

main() {
  const dynamic i1 = 3;
  const dynamic i2 = 2;
  const dynamic d1 = 3.3;
  const dynamic d2 = 2.2;

  const sum = 0 + //
      (i1 | i2) + //# ii1: ok
      (i1 & i2) + //# ii2: ok
      (i1 ^ i2) + //# ii3: ok
      (i1 << i2) + //# ii4: ok
      (i1 >> i2) + //# ii5: ok
      (i1 >>> i2) + //# ii6: ok
      (i1 | d2) + //# id1: compile-time error
      (i1 & d2) + //# id2: compile-time error
      (i1 ^ d2) + //# id3: compile-time error
      (i1 << d2) + //# id4: compile-time error
      (i1 >> d2) + //# id5: compile-time error
      (i1 >>> d2) + //# id6: compile-time error
      (d1 | i2) + //# di1: compile-time error
      (d1 & i2) + //# di2: compile-time error
      (d1 ^ i2) + //# di3: compile-time error
      (d1 << i2) + //# di4: compile-time error
      (d1 >> i2) + //# di5: compile-time error
      (d1 >>> i2) + //# di6: compile-time error
      (d1 | d2) + //# dd1: compile-time error
      (d1 & d2) + //# dd2: compile-time error
      (d1 ^ d2) + //# dd3: compile-time error
      (d1 << d2) + //# dd4: compile-time error
      (d1 >> d2) + //# dd5: compile-time error
      (d1 >>> d2) + //# dd6: compile-time error
      0;
  print(sum);
}
