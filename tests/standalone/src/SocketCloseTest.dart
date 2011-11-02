// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test socket close events.

class SocketCloseTest {

  static void testMain() {
    SocketClose socketClose = new SocketClose.start();
  }
}

class SocketClose {

  static final SERVERINIT = 0;
  static final SERVERSHUTDOWN = -1;
  static final ITERATIONS = 100;

  SocketClose.start()
      : _receivePort = new ReceivePort(),
        _sendPort = null,
        _dataEvents = 0,
        _closeEvents = 0,
        _errorEvents = 0,
        _iterations = 0 {
    new SocketCloseServer().spawn().then((SendPort port) {
      _sendPort = port;
      start();
    });
  }

  void sendData() {

    void dataHandler() {
      _dataEvents++;
    }

    void closeHandler() {
      _closeEvents++;
      _iterations++;
      _socket.close();
      if (_iterations < ITERATIONS) {
        sendData();
      } else {
        shutdown();
      }
    }

    void errorHandler() {
      _errorEvents++;
      _socket.close();
    }

    void connectHandler() {
      _socket.dataHandler = dataHandler;
      _socket.closeHandler = closeHandler;
      _socket.errorHandler = errorHandler;

      if ((_iterations % 2) == 0) {
        _socket.writeList("Hello".charCodes(), 0, 5);
      }
    }

    _socket = new Socket(SocketCloseServer.HOST, _port);
    Expect.equals(true, _socket !== null);
    _socket.connectHandler = connectHandler;
  }

  void start() {
    _receivePort.receive((var message, SendPort replyTo) {
      _port = message;
      sendData();
    });
    _sendPort.send(SERVERINIT, _receivePort.toSendPort());
  }

  void shutdown() {
    _sendPort.send(SERVERSHUTDOWN, _receivePort.toSendPort());
    _receivePort.close();

    /*
     * Note that it is not guaranteed that _dataEvents == 0 due to spurious
     * wakeups.
     */
    Expect.equals(ITERATIONS, _closeEvents);
    Expect.equals(0, _errorEvents);
  }

  int _port;
  ReceivePort _receivePort;
  SendPort _sendPort;
  Socket _socket;
  List<int> _buffer;
  int _dataEvents;
  int _closeEvents;
  int _errorEvents;
  int _iterations;
}

class SocketCloseServer extends Isolate {

  static final HOST = "127.0.0.1";

  SocketCloseServer() : super() {}

  void main() {

    void connectionHandler() {
      Socket _client;

      void messageHandler() {
        _dataEvents++;
        _client.close();
      }

      void closeHandler() {
        _closeEvents++;
        _client.close();
      }

      void errorHandler() {
        _errorEvents++;
        _client.close();
      }

      _client = _server.accept();
      if ((_iterations % 2) == 1) {
        _client.close();
      }
      _client.dataHandler = messageHandler;
      _client.closeHandler = closeHandler;
      _client.errorHandler = errorHandler;
      _iterations++;
    }

    void errorHandlerServer() {
      _server.close();
    }

    this.port.receive((message, SendPort replyTo) {
      if (message == SocketClose.SERVERINIT) {
        _errorEvents = 0;
        _dataEvents = 0;
        _closeEvents = 0;
        _iterations = 0;
        _server = new ServerSocket(HOST, 0, 10);
        Expect.equals(true, _server !== null);
        _server.connectionHandler = connectionHandler;
        _server.errorHandler = errorHandlerServer;
        replyTo.send(_server.port, null);
      } else if (message == SocketClose.SERVERSHUTDOWN) {
        Expect.equals(SocketClose.ITERATIONS/2, _dataEvents);
        Expect.equals(0, _closeEvents);
        Expect.equals(0, _errorEvents);
        _server.close();
        this.port.close();
      }
    });
  }

  ServerSocket _server;
  int _errorEvents;
  int _dataEvents;
  int _closeEvents;
  int _iterations;
}


main() {
  SocketCloseTest.testMain();
}
