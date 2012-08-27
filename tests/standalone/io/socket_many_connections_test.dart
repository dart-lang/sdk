// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test creating a large number of socket connections.

#import("dart:io");
#import("dart:isolate");
#source("testing_server.dart");

const CONNECTIONS = 200;

class SocketManyConnectionsTest {

  SocketManyConnectionsTest.start()
      : _receivePort = new ReceivePort(),
        _sendPort = null,
        _connections = 0,
        _sockets = new List<Socket>(CONNECTIONS) {
    _sendPort = spawnFunction(startTestServer);
    start();
  }

  void run() {

    void connectHandler() {
      _connections++;
      if (_connections == CONNECTIONS) {
        for (int i = 0; i < CONNECTIONS; i++) {
          _sockets[i].close();
        }
        shutdown();
      }
    }

    for (int i = 0; i < CONNECTIONS; i++) {
      _sockets[i] = new Socket(TestingServer.HOST, _port);
      if (_sockets[i] !== null) {
        _sockets[i].onConnect = connectHandler;
      } else {
        Expect.fail("socket creation failed");
      }
    }
  }

  void start() {
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

    void errorHandler(Exception e) {
      print("Socket error $e");
      connection.close();
    }

    _connections++;
    connection.onClosed = closeHandler;
    connection.onError = errorHandler;
  }

  int _connections = 0;
}

main() {
  SocketManyConnectionsTest test = new SocketManyConnectionsTest.start();
}
