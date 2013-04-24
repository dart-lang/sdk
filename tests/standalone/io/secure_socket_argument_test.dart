// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:io";

void testInitialzeArguments() {
  Expect.throws(() => SecureSocket.initialize(database: "foo.txt"));
  Expect.throws(() => SecureSocket.initialize(password: false));
  Expect.throws(() => SecureSocket.initialize(useBuiltinRoots: 7));
}

void testServerSocketArguments() {
  Expect.throws(() =>
      SecureServerSocket.bind(SERVER_ADDRESS, 65536, 5, CERTIFICATE));
  Expect.throws(() =>
      SecureServerSocket.bind(SERVER_ADDRESS, -1, CERTIFICATE));
  Expect.throws(() =>
      SecureServerSocket.bind(SERVER_ADDRESS, 0, -1, CERTIFICATE));
}

void main() {
  testInitialzeArguments();
  SecureSocket.initialize();
  testServerSocketArguments();
}
