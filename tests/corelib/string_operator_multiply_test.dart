// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  Expect.equals('', 'a' * -11);
  Expect.equals('', 'α' * -11);
  Expect.equals('', '∀' * -11);

  Expect.equals('', 'a' * 0);
  Expect.equals('', 'α' * 0);
  Expect.equals('', '∀' * 0);

  Expect.equals('a', 'a' * 1);
  Expect.equals('α', 'α' * 1);
  Expect.equals('∀', '∀' * 1);

  Expect.equals('aa', 'a' * 2);
  Expect.equals('αα', 'α' * 2);
  Expect.equals('∀∀', '∀' * 2);

  Expect.equals('aaa', 'a' * 3);
  Expect.equals('ααα', 'α' * 3);
  Expect.equals('∀∀∀', '∀' * 3);

  Expect.equals('', '' * 0x4000000000000000);

  Expect.throws(() => 'a' * 0x4000000000000000);
  Expect.throws(() => 'α' * 0x4000000000000000);
  Expect.throws(() => '∀' * 0x4000000000000000);

  for (final string in ['a', 'α', '∀', 'hello world', 'abc', 'α∀α']) {
    for (final count in [0, 1, 10, 100, 255, 256, 257, 1000, 100000]) {
      final expected = List.filled(count, string).join();
      final actual = string * count;
      Expect.equals(expected, actual);
    }
  }

  // http://dartbug.com/49289
  Expect.throws(() => 'abcd' * 0x4000000000000000);
  Expect.throws(() => 'αxyz' * 0x4000000000000000);
  Expect.throws(() => '∀pqr' * 0x4000000000000000);

  Expect.throws(() => 'abcd' * (0x4000000000000000 + 1));
  Expect.throws(() => 'αxyz' * (0x4000000000000000 + 1));
  Expect.throws(() => '∀pqr' * (0x4000000000000000 + 1));
}
