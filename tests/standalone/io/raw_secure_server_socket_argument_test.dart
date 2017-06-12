// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "package:expect/expect.dart";
import "package:path/path.dart";
import "dart:async";
import "dart:io";
import "dart:isolate";

const SERVER_ADDRESS = "127.0.0.1";
const CERTIFICATE = "localhost_cert";

void testArguments() {
  bool isArgOrTypeError(e) => e is ArgumentError || e is TypeError;
  Expect.throws(() => RawSecureServerSocket.bind(SERVER_ADDRESS, 65536, null),
      isArgOrTypeError);
  Expect.throws(() => RawSecureServerSocket.bind(SERVER_ADDRESS, -1, null),
      isArgOrTypeError);
  Expect.throws(
      () => RawSecureServerSocket.bind(SERVER_ADDRESS, 0, null, backlog: -1),
      isArgOrTypeError);
  Expect.throws(
      () => RawSecureSocket.connect(SERVER_ADDRESS, null), isArgOrTypeError);
  Expect.throws(
      () => RawSecureSocket.connect(SERVER_ADDRESS, -1), isArgOrTypeError);
  Expect.throws(
      () => RawSecureSocket.connect(SERVER_ADDRESS, 345656), isArgOrTypeError);
  Expect.throws(
      () => RawSecureSocket.connect(SERVER_ADDRESS, 'hest'), isArgOrTypeError);
  Expect.throws(() => RawSecureSocket.connect(null, 0), isArgOrTypeError);
  Expect.throws(
      () =>
          RawSecureSocket.connect(SERVER_ADDRESS, 0, onBadCertificate: 'hund'),
      isArgOrTypeError);
}

main() {
  testArguments();
}
