// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=-Da=true -Db=false

import "package:expect/expect.dart";

main() {
  Expect.isTrue(const bool.fromEnvironment('a'));
  Expect.isFalse(const bool.fromEnvironment('b'));
}
