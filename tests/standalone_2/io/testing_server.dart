// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ServerTest;

abstract class TestingServer {
  static const HOST = "127.0.0.1";
  static const INIT = 0;
  static const SHUTDOWN = -1;

  void onConnection(Socket connection); // Abstract.

  void errorHandlerServer(e, trace) {
    String msg = "Server socket error $e";
    if (trace != null) msg += "\nStackTrace: $trace";
    Expect.fail(msg);
  }

  SendPort get closeSendPort => _closePort.sendPort;

  Future<int> init() {
    _closePort = new ReceivePort();
    _closePort.first.then((_) {
      close();
    });
    return ServerSocket.bind(HOST, 0).then((server) {
      _server = server;
      _server.listen(onConnection, onError: errorHandlerServer);
      return _server.port;
    });
  }

  void close() {
    _server.close();
  }

  ServerSocket _server;
  ReceivePort _closePort;
}
