// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

// This test repeats a subtest from raw_secure_server_socket_test 100 times.
// This may help to reproduce a reported crash in issue dartbug.com/8798.
// This test should be removed within a week (2013/3/8), if it always succeeds.

import "dart:async";
import "dart:io";
import "dart:isolate";

const SERVER_ADDRESS = "127.0.0.1";
const HOST_NAME = "localhost";
const CERTIFICATE = "localhost_cert";

void testSimpleConnectFail(String certificate) {
  ReceivePort port = new ReceivePort();
  RawSecureServerSocket.bind(SERVER_ADDRESS, 0, 5, certificate).then((server) {
    var clientEndFuture = RawSecureSocket.connect(HOST_NAME, server.port)
      .then((clientEnd) {
        Expect.fail("No client connection expected.");
      })
      .catchError((e) {
        Expect.isTrue(e is AsyncError);
        Expect.isTrue(e.error is SocketIOException);
      });
    server.listen((serverEnd) {
      Expect.fail("No server connection expected.");
    },
    onError: (e) {
      Expect.isTrue(e is AsyncError);
      Expect.isTrue(e.error is SocketIOException);
      clientEndFuture.then((_) => port.close());
    });
  });
}

main() {
  Path scriptDir = new Path(new Options().script).directoryPath;
  Path certificateDatabase = scriptDir.append('pkcert');
  SecureSocket.initialize(database: certificateDatabase.toNativePath(),
                          password: 'dartdart',
                          useBuiltinRoots: false);
  for (int i = 0; i < 100; ++i) {
    testSimpleConnectFail("not_a_nickname");
    testSimpleConnectFail("CN=notARealDistinguishedName");
  }
}
