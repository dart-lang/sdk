// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=-Da=1 -Db=-12 -Dc=0x123 -Dd=-0x1234 -De=+0x112296 -Df=-9007199254740991 -Dg=9007199254740991 -Dh=-0x8000000000000000 -Di=0x8000000000000000 -Dj=0xDEADBEEFCAFE0000

import "package:expect/expect.dart";

main() {
  Expect.equals(1, const int.fromEnvironment('a'));
  Expect.equals(-12, const int.fromEnvironment('b'));
  Expect.equals(0x123, const int.fromEnvironment('c'));
  Expect.equals(-0x1234, const int.fromEnvironment('d'));
  Expect.equals(0x112296, const int.fromEnvironment('e'));
  Expect.equals(-9007199254740991, const int.fromEnvironment('f'));
  Expect.equals(9007199254740991, const int.fromEnvironment('g'));
  Expect.equals(-0x8000000000000000, const int.fromEnvironment('h'));
  Expect.equals(0x8000000000000000, const int.fromEnvironment('i'));
  Expect.equals(0xDEADBEEFCAFE0000, const int.fromEnvironment('j'));
}
