// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test program for array literals.

import "package:expect/expect.dart";

class ArrayLiteral2Test {
  static const int LAUREL = 1965;
  static const int HARDY = 1957;

  static const LUCKY_DOG = const <int>[1919, 1921];
  static const MUSIC_BOX = const [LAUREL, HARDY];

  static testMain() {
    Expect.equals(2, LUCKY_DOG.length);
    Expect.equals(2, MUSIC_BOX.length);

    Expect.equals(1919, LUCKY_DOG[0]);
    Expect.equals(1921, LUCKY_DOG[1]);

    Expect.equals(LAUREL, MUSIC_BOX[0]);
    Expect.equals(HARDY, MUSIC_BOX[1]);
  }
}

main() {
  ArrayLiteral2Test.testMain();
}
