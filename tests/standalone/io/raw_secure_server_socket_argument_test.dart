// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";
import "dart:isolate";

const SERVER_ADDRESS = "127.0.0.1";
const CERTIFICATE = "localhost_cert";


void testArguments() {
  Expect.throws(() =>
      RawSecureServerSocket.bind(SERVER_ADDRESS, 65536, 5, CERTIFICATE));
  Expect.throws(() =>
      RawSecureServerSocket.bind(SERVER_ADDRESS, -1, CERTIFICATE));
  Expect.throws(() =>
      RawSecureServerSocket.bind(SERVER_ADDRESS, 0, -1, CERTIFICATE));
}


main() {
  Path scriptDir = new Path(Platform.script).directoryPath;
  Path certificateDatabase = scriptDir.append('pkcert');
  SecureSocket.initialize(database: certificateDatabase.toNativePath(),
                          password: 'dartdart',
                          useBuiltinRoots: false);
  testArguments();
}
