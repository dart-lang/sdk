// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Regression test for http://code.google.com/p/dart/issues/detail?id=1925.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

#import("dart:io");
#import("dart:isolate");
#source("testing_server.dart");

class Regress1925TestServer extends TestingServer {

  void onConnection(Socket socket) {
    socket.onError = (e) => Expect.fail("Server socket error $e");
    socket.inputStream.onClosed = () => socket.outputStream.close();
    socket.inputStream.onData = () {
      var buffer = new List(1);
      var read = socket.inputStream.readInto(buffer);
      Expect.equals(1, read);
      socket.outputStream.writeFrom(buffer, 0, read);
    };
  }

  int _connections = 0;
}


class Regress1925Test extends TestingServerTest {
  Regress1925Test.start() : super.start(new Regress1925TestServer());

  void run() {

    var count = 0;
    var buffer = new List(5);
    Socket socket = new Socket(TestingServer.HOST, _port);
    socket.onConnect = () {
      socket.outputStream.write("12345".charCodes());
      socket.outputStream.close();
      socket.inputStream.onData = () {
        count += socket.inputStream.readInto(buffer, count);
      };
      socket.inputStream.onClosed = () {
        Expect.equals(5, count);
        shutdown();
      };
      socket.inputStream.onError = (e) => Expect.fail("Socket error $e");
    };
  }
}

main() {
  Regress1925Test test = new Regress1925Test.start();
}
