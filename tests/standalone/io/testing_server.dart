// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class TestingServer {

  static const HOST = "127.0.0.1";
  static const INIT = 0;
  static const SHUTDOWN = -1;

  abstract void onConnection(Socket connection);

  void errorHandlerServer(Exception e) {
    Expect.fail("Server socket error $e");
  }

  void dispatch(message, SendPort replyTo) {
    if (message == INIT) {
      _server = new ServerSocket(HOST, 0, 10);
      Expect.equals(true, _server != null);
      _server.onConnection = onConnection;
      _server.onError = errorHandlerServer;
      replyTo.send(_server.port, null);
    } else if (message == SHUTDOWN) {
      _server.close();
      port.close();
    }
  }

  ServerSocket _server;
}

class TestingServerTest {

  TestingServerTest.start(SendPort port)
      : _receivePort = new ReceivePort(),
        _sendPort = port {
    initialize();
  }

  abstract void run();

  void initialize() {
    _receivePort.receive((var message, SendPort replyTo) {
      _port = message;
      run();
    });
    _sendPort.send(TestingServer.INIT, _receivePort.toSendPort());
  }

  void shutdown() {
    _sendPort.send(TestingServer.SHUTDOWN, _receivePort.toSendPort());
    _receivePort.close();
  }

  int _port;
  ReceivePort _receivePort;
  SendPort _sendPort;
}
