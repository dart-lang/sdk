// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=-Da=true -Db=false -Dc=NOTBOOL -Dd=True

import "package:expect/expect.dart";

main() {
  Expect.isTrue(const bool.fromEnvironment('a'));
  Expect.isFalse(const bool.fromEnvironment('b'));
  Expect.isTrue(const bool.fromEnvironment('c', defaultValue: true));
  Expect.isFalse(const bool.fromEnvironment('c', defaultValue: false));
  Expect.isFalse(const bool.fromEnvironment('d', defaultValue: false));
  Expect.equals(const bool.fromEnvironment('dart.isVM'), !identical(1.0, 1));
}
