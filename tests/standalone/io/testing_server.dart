// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ServerTest;

abstract class TestingServer {

  static const HOST = "127.0.0.1";
  static const INIT = 0;
  static const SHUTDOWN = -1;

  void onConnection(Socket connection);  // Abstract.

  void errorHandlerServer(e) {
    String msg = "Server socket error $e";
    var trace = getAttachedStackTrace(e);
    if (trace != null) msg += "\nStackTrace: $trace";
    Expect.fail(msg);
  }

  void dispatch(message, SendPort replyTo) {
    if (message == INIT) {
      ServerSocket.bind(HOST, 0, 10).then((server) {
        _server = server;
        _server.listen(
            onConnection,
            onError: errorHandlerServer);
        replyTo.send(_server.port, null);
      });
    } else if (message == SHUTDOWN) {
      _server.close();
      port.close();
    }
  }

  ServerSocket _server;
}

abstract class TestingServerTest {

  TestingServerTest.start(SendPort port)
      : _receivePort = new ReceivePort(),
        _sendPort = port {
    initialize();
  }

  void run();  // Abstract.

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
