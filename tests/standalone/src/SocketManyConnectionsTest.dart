// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test creating a large number of socket connections.

final SERVERINIT = 0;
final SERVERSHUTDOWN = -1;
final CONNECTIONS = 200;
final HOST = "127.0.0.1";

class SocketManyConnectionsTest {

  SocketManyConnectionsTest.start()
      : _receivePort = new ReceivePort(),
        _sendPort = null,
        _connections = 0,
        _sockets = new List<Socket>(CONNECTIONS) {
    new TestServer().spawn().then((SendPort port) {
      _sendPort = port;
      start();
    });
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
      _sockets[i] = new Socket(HOST, _port);
      if (_sockets[i] !== null) {
        _sockets[i].connectHandler = connectHandler;
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
    _sendPort.send(SERVERINIT, _receivePort.toSendPort());
  }

  void shutdown() {
    _sendPort.send(SERVERSHUTDOWN, _receivePort.toSendPort());
    _receivePort.close();
  }

  int _port;
  ReceivePort _receivePort;
  SendPort _sendPort;
  List<Socket> _sockets;
  int _connections;
}

class TestServer extends Isolate {

  void main() {

    void connectionHandler() {
      Socket _client;

      void closeHandler() {
        _client.close();
      }

      void errorHandler() {
        print("Socket error");
        _client.close();
      }

      _client = _server.accept();
      _connections++;
      _client.closeHandler = closeHandler;
      _client.errorHandler = errorHandler;
    }

    void errorHandlerServer() {
      print("Server socket error");
      _server.close();
    }

    this.port.receive((message, SendPort replyTo) {
      if (message == SERVERINIT) {
        _server = new ServerSocket(HOST, 0, 10);
        Expect.equals(true, _server !== null);
        _server.connectionHandler = connectionHandler;
        _server.errorHandler = errorHandlerServer;
        replyTo.send(_server.port, null);
      } else if (message == SERVERSHUTDOWN) {
        _server.close();
        this.port.close();
      }
    });
  }

  ServerSocket _server;
  int _connections = 0;
}

main() {
  SocketManyConnectionsTest test = new SocketManyConnectionsTest.start();
}
