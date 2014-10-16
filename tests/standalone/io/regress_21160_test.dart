// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:path/path.dart";
import "package:async_helper/async_helper.dart";

import "dart:async";
import "dart:io";
import "dart:typed_data";

// 10 KiB of i%256 data.
Uint8List DATA = new Uint8List.fromList(
    new List.generate(10 * 1024, (i) => i % 256));

Future<SecureServerSocket> startServer() {
  return SecureServerSocket.bind("localhost",
                                 0,
                                 'localhost_cert').then((server) {
    server.listen((SecureSocket request) {
      request.drain().then((_) {
        request
            ..add(DATA)
            ..close();
      });
    });
    return server;
  });
}

void InitializeSSL() {
  var testPkcertDatabase = Platform.script.resolve('pkcert').toFilePath();
  SecureSocket.initialize(database: testPkcertDatabase,
                          password: 'dartdart');
}

void main() {
  InitializeSSL();

  asyncStart();
  startServer().then((SecureServerSocket server) {
    RawSecureSocket.connect("localhost", server.port).then((socket) {
      List<int> body = <int>[];

      // Close our end, since we're not sending data.
      socket.shutdown(SocketDirection.SEND);

      socket.listen((RawSocketEvent event) {
            switch (event) {
              case RawSocketEvent.READ:
                // NOTE: We have a very low prime number here. The internal
                // ring buffers will not have a size of 3. This means that
                // we'll reach the point where we would like to read 1/2 bytes
                // at the end and then wrap around and read the next 2/1 bytes.
                // [This will ensure we trigger the bug.]
                body.addAll(socket.read(3));
                break;
              case RawSocketEvent.WRITE:
                break;
              case RawSocketEvent.READ_CLOSED:
                break;
              default: throw "Unexpected event $event";
            }
          },
          onError: (e, _) {
            Expect.fail('Unexpected error: $e');
          },
          onDone: () {
            Expect.equals(body.length, DATA.length);
            for (int i = 0; i < body.length; i++) {
              Expect.equals(body[i], DATA[i]);
            }
            server.close();
            asyncEnd();
          });
    });
  });
}
