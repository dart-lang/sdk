// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class TestingServer extends Isolate {

  static final HOST = "127.0.0.1";
  static final INIT = 0;
  static final SHUTDOWN = -1;

  abstract void connectionHandler();

  void main() {
    void errorHandlerServer() {
      Expect.fail("Server socket error");
    }

    this.port.receive((message, SendPort replyTo) {
      if (message == INIT) {
        _server = new ServerSocket(HOST, 0, 10);
        Expect.equals(true, _server !== null);
        _server.connectionHandler = connectionHandler;
        _server.errorHandler = errorHandlerServer;
        replyTo.send(_server.port, null);
      } else if (message == SHUTDOWN) {
        _server.close();
        this.port.close();
      }
    });
  }

  ServerSocket _server;
}
