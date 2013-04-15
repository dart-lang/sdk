// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test creating a large number of socket connections.
library ServerTest;

import "package:expect/expect.dart";
import "dart:io";
import "dart:isolate";
part "testing_server.dart";

const CONNECTIONS = 200;

class SocketManyConnectionsTest {

  SocketManyConnectionsTest.start()
      : _receivePort = new ReceivePort(),
        _sendPort = null,
        _connections = 0,
        _sockets = new List<Socket>(CONNECTIONS) {
    _sendPort = spawnFunction(startTestServer);
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
    _receivePort.receive((var message, SendPort replyTo) {
      _port = message;
      run();
    });
    _sendPort.send(TestingServer.INIT, _receivePort.toSendPort());
  }

  void close() {
    _sendPort.send(TestingServer.SHUTDOWN, _receivePort.toSendPort());
    _receivePort.close();
  }

  int _port;
  ReceivePort _receivePort;
  SendPort _sendPort;
  List<Socket> _sockets;
  int _connections;
}


void startTestServer() {
  var server = new TestServer();
  port.receive(server.dispatch);
}

class TestServer extends TestingServer {

  void onConnection(Socket connection) {
    Socket _client;

    void closeHandler() {
      connection.close();
    }

    void errorHandler(e) {
      String msg = "Socket error $e";
      var trace = getAttachedStackTrace(e);
      if (trace != null) msg += "\nStackTrace: $trace";
      print(msg);
      connection.close();
    }

    _connections++;
    connection.listen(
        (data) {},
        onDone: closeHandler,
        onError: errorHandler);
  }

  int _connections = 0;
}

main() {
  SocketManyConnectionsTest test = new SocketManyConnectionsTest.start();
}
