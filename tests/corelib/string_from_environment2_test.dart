// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=-Da=a -Da=bb -Db=bb -Dc=ccc -Da=ccc -Db=ccc

import "package:expect/expect.dart";

main() {
  Expect.equals('ccc', const String.fromEnvironment('a'));
  Expect.equals('ccc', const String.fromEnvironment('b'));
  Expect.equals('ccc', const String.fromEnvironment('c'));
}
