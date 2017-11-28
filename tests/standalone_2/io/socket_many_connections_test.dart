// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test creating a large number of socket connections.
library ServerTest;

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import "dart:async";
import "dart:io";
import "dart:isolate";
part "testing_server.dart";

const CONNECTIONS = 200;

class SocketManyConnectionsTest {
  SocketManyConnectionsTest.start()
      : _connections = 0,
        _sockets = new List<Socket>(CONNECTIONS) {
    initialize();
  }

  void run() {
    void connectHandler() {
      _connections++;
      if (_connections == CONNECTIONS) {
        for (int i = 0; i < CONNECTIONS; i++) {
          _sockets[i].destroy();
        }
        close();
      }
    }

    for (int i = 0; i < CONNECTIONS; i++) {
      Socket.connect(TestingServer.HOST, _port).then((socket) {
        Expect.isNotNull(socket);
        _sockets[i] = socket;
        connectHandler();
      });
    }
  }

  void initialize() {
    var receivePort = new ReceivePort();
    var remote = Isolate.spawn(startTestServer, receivePort.sendPort);
    receivePort.first.then((msg) {
      this._port = msg[0];
      this._closeSendPort = msg[1];
      run();
    });
  }

  void close() {
    _closeSendPort.send(null);
    asyncEnd();
  }

  int _port;
  SendPort _closeSendPort;
  List<Socket> _sockets;
  int _connections;
}

void startTestServer(SendPort replyPort) {
  var server = new TestServer();
  server.init().then((port) {
    replyPort.send([port, server.closeSendPort]);
  });
}

class TestServer extends TestingServer {
  void onConnection(Socket connection) {
    Socket _client;

    void closeHandler() {
      connection.close();
    }

    void errorHandler(e, trace) {
      String msg = "Socket error $e";
      if (trace != null) msg += "\nStackTrace: $trace";
      print(msg);
      connection.close();
    }

    _connections++;
    connection.listen((data) {}, onDone: closeHandler, onError: errorHandler);
  }

  int _connections = 0;
}

main() {
  asyncStart();
  SocketManyConnectionsTest test = new SocketManyConnectionsTest.start();
}
