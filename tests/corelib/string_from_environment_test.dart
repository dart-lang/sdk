// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=-Da=a -Db=bb -Dc=ccc -Dd=

import "package:expect/expect.dart";

main() {
  Expect.equals('a', const String.fromEnvironment('a'));
  Expect.equals('bb', const String.fromEnvironment('b'));
  Expect.equals('ccc', const String.fromEnvironment('c'));
  Expect.equals('', const String.fromEnvironment('d'));
}
