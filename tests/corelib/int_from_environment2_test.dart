// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=-Da=x -Db=- -Dc=0xg -Dd=+ -Dd=

import "package:expect/expect.dart";

main() {
  Expect.equals(0, const int.fromEnvironment('a'));
  Expect.equals(0, const int.fromEnvironment('b'));
  Expect.equals(0, const int.fromEnvironment('c'));
  Expect.equals(0, const int.fromEnvironment('d'));
  Expect.equals(0, const int.fromEnvironment('e'));
}
