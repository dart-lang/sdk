// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test program for array literals.

import "package:expect/expect.dart";

class ListLiteralTest {
  static const LAUREL = 1;
  static const HARDY = 2;

  static testMain() {
    var funny = <int>[
      LAUREL,
      HARDY,
    ]; // Check that trailing comma works.
    Expect.equals(2, funny.length);

    List<int> m = <int>[101, 102, 100 + 3];
    Expect.equals(3, m.length);
    Expect.equals(101, m[0]);
    Expect.equals(103, m[2]);

    var d = m[2] - m[1];
    Expect.equals(1, d);

    dynamic e2 = [5.1, -55, 555, 5555][2];
    Expect.equals(555, e2);

    e2 = <num>[5.1, -55, 555, 5555][2];
    Expect.equals(555, e2);

    e2 = const <num>[5.1, -55, 555, 5555][2];
    Expect.equals(555, e2);

    e2 = (const [
      5.1,
      const <num>[-55, 555],
      5555
    ][1] as dynamic)[1];
    Expect.equals(555, e2);

    Expect.equals(0, [].length);
    Expect.equals(0, <String>[].length);
    Expect.equals(0, const <String>[].length);
    Expect.equals(0, const [].length);

    e2 = [1, 2.0, 0x03, 2.0e5];
    Expect.equals(1, e2[0]);
    Expect.equals(2.0, e2[1]);
    Expect.equals(3, e2[2]);
    Expect.equals(200000.0, e2[3]);
  }
}

main() {
  ListLiteralTest.testMain();
}
