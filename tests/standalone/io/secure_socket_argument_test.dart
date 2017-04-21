// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:io";

void testServerSocketArguments() {
  Expect.throws(() => SecureServerSocket.bind(SERVER_ADDRESS, 65536, null));
  Expect.throws(() => SecureServerSocket.bind(SERVER_ADDRESS, -1, null));
  Expect.throws(
      () => SecureServerSocket.bind(SERVER_ADDRESS, 0, "not a context"));
}

void main() {
  testServerSocketArguments();
}
