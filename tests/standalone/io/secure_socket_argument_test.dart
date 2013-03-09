// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:io";

void main() {
  Expect.throws(() => SecureSocket.initialize(database: "foo.txt"));
  Expect.throws(() => SecureSocket.initialize(password: false));
  Expect.throws(() => SecureSocket.initialize(useBuiltinRoots: 7));
  SecureSocket.initialize();
}
