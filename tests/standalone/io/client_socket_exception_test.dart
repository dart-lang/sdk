// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests socket exceptions.

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void clientSocketExceptionTest() {
  bool exceptionCaught = false;
  bool wrongExceptionCaught = false;

  ServerSocket.bind("127.0.0.1", 0).then((server) {
    Expect.isNotNull(server);
    int port = server.port;
    Socket.connect("127.0.0.1", port).then((client) {
      Expect.isNotNull(client);
      client.close();
      // First calls for which exceptions are note expected.
      try {
        client.close();
      } on SocketException catch (ex) {
        exceptionCaught = true;
      } catch (ex) {
        wrongExceptionCaught = true;
      }
      Expect.isFalse(exceptionCaught);
      Expect.isFalse(wrongExceptionCaught);
      try {
        client.destroy();
      } on SocketException catch (ex) {
        exceptionCaught = true;
      } catch (ex) {
        wrongExceptionCaught = true;
      }
      Expect.isFalse(exceptionCaught);
      Expect.isFalse(wrongExceptionCaught);
      try {
        List<int> buffer = new List<int>.filled(10, 0);
        client.add(buffer);
      } on StateError catch (ex) {
        exceptionCaught = true;
      } catch (ex) {
        wrongExceptionCaught = true;
      }
      Expect.isTrue(exceptionCaught);
      Expect.isFalse(wrongExceptionCaught);

      // From here exceptions are expected.
      exceptionCaught = false;
      try {
        client.port;
      } on SocketException catch (ex) {
        exceptionCaught = true;
      } catch (ex) {
        wrongExceptionCaught = true;
      }
      Expect.isTrue(exceptionCaught);
      Expect.isFalse(wrongExceptionCaught);
      exceptionCaught = false;
      try {
        client.remotePort;
      } on SocketException catch (ex) {
        exceptionCaught = true;
      } catch (ex) {
        wrongExceptionCaught = true;
      }
      Expect.isTrue(exceptionCaught);
      Expect.isFalse(wrongExceptionCaught);
      exceptionCaught = false;
      try {
        client.address;
      } on SocketException catch (ex) {
        exceptionCaught = true;
      } catch (ex) {
        wrongExceptionCaught = true;
      }
      Expect.isTrue(exceptionCaught);
      Expect.isFalse(wrongExceptionCaught);
      exceptionCaught = false;
      try {
        client.remoteAddress;
      } on SocketException catch (ex) {
        exceptionCaught = true;
      } catch (ex) {
        wrongExceptionCaught = true;
      }
      Expect.isTrue(exceptionCaught);
      Expect.isFalse(wrongExceptionCaught);

      server.close();
    });
  });
}

main() {
  asyncStart();
  clientSocketExceptionTest();
  asyncEnd();
}
