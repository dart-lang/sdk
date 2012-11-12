// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write
//
// Test socket close events.

#import("dart:io");
#import("dart:isolate");

const SERVERSHUTDOWN = -1;
const ITERATIONS = 10;


class SocketClose {

  SocketClose.start(this._mode, this._donePort)
      : _receivePort = new ReceivePort(),
        _sendPort = null,
        _readBytes = 0,
        _dataEvents = 0,
        _closeEvents = 0,
        _errorEvents = 0,
        _iterations = 0 {
    _sendPort = spawnFunction(startSocketCloseServer);
    initialize();
  }

  void proceed() {
    if (_iterations < ITERATIONS) {
      new Timer(0, sendData);
    } else {
      shutdown();
    }
  }

  void sendData(Timer timer) {

    void dataHandler() {
      switch (_mode) {
        case 0:
        case 1:
        case 2:
          Expect.fail("No data expected");
          break;
        case 3:
        case 4:
        case 5:
        case 6:
          List<int> b = new List<int>(5);
          _readBytes += _socket.readList(b, 0, 5);
          if ((_readBytes % 5) == 0) {
            _dataEvents++;
          }
          break;
        default:
          Expect.fail("Unknown test mode");
      }
    }

    void closeHandler() {
      _closeEvents++;
      switch (_mode) {
        case 0:
        case 1:
          Expect.fail("No close expected");
          break;
        case 2:
        case 3:
          _socket.close();
          proceed();
          break;
        case 4:
          proceed();
          break;
        case 5:
          _socket.close();
          proceed();
          break;
        case 6:
          proceed();
          break;
        default:
          Expect.fail("Unknown test mode");
      }
    }

    void errorHandler(Exception e) {
      _errorEvents++;
      _socket.close();
    }

    void connectHandler() {
      _socket.onData = dataHandler;
      _socket.onClosed = closeHandler;
      _socket.onError = errorHandler;

      void writeHello() {
        int bytesWritten = 0;
        while (bytesWritten != 5) {
          bytesWritten += _socket.writeList("Hello".charCodes,
                                            bytesWritten,
                                            5 - bytesWritten);
        }
      }

      _iterations++;
      switch (_mode) {
        case 0:
          _socket.close();
          proceed();
          break;
        case 1:
          writeHello();
          _socket.close();
          proceed();
          break;
        case 2:
        case 3:
          writeHello();
          break;
        case 4:
          writeHello();
          _socket.close(true);
          break;
        case 5:
          writeHello();
          break;
        case 6:
          writeHello();
          _socket.close(true);
          break;
        default:
          Expect.fail("Unknown test mode");
      }
    }

    _socket = new Socket(SocketCloseServer.HOST, _port);
    Expect.equals(true, _socket != null);
    _socket.onConnect = connectHandler;
  }

  void initialize() {
    _receivePort.receive((var message, SendPort replyTo) {
      _port = message;
      proceed();
    });
    _sendPort.send(_mode, _receivePort.toSendPort());
  }

  void shutdown() {
    _sendPort.send(SERVERSHUTDOWN, _receivePort.toSendPort());
    _receivePort.receive((message, ignore) {
      _donePort.send(null);
      _receivePort.close();
    });

    switch (_mode) {
      case 0:
      case 1:
        Expect.equals(0, _dataEvents);
        Expect.equals(0, _closeEvents);
        break;
      case 2:
        Expect.equals(0, _dataEvents);
        Expect.equals(ITERATIONS, _closeEvents);
        break;
      case 3:
      case 4:
      case 5:
      case 6:
        Expect.equals(ITERATIONS, _dataEvents);
        Expect.equals(ITERATIONS, _closeEvents);
        break;
      default:
        Expect.fail("Unknown test mode");
    }
    Expect.equals(0, _errorEvents);
  }

  int _port;
  ReceivePort _receivePort;
  SendPort _sendPort;
  Socket _socket;
  List<int> _buffer;
  int _readBytes;
  int _dataEvents;
  int _closeEvents;
  int _errorEvents;
  int _iterations;
  int _mode;
  SendPort _donePort;
}


class ConnectionData {
  ConnectionData(Socket this.connection) : readBytes = 0;
  Socket connection;
  int readBytes;
}


void startSocketCloseServer() {
  var server = new SocketCloseServer();
  port.receive(server.dispatch);
}

class SocketCloseServer {

  static const HOST = "127.0.0.1";

  SocketCloseServer() : super() {}

  void connectionHandler(ConnectionData data) {
    var connection = data.connection;

    void readBytes(whenFiveBytes) {
      List<int> b = new List<int>(5);
      data.readBytes += connection.readList(b, 0, 5);
      if (data.readBytes == 5) {
        whenFiveBytes();
      }
    }

    void writeHello() {
      int bytesWritten = 0;
      while (bytesWritten != 5) {
        bytesWritten += connection.writeList("Hello".charCodes,
                                             bytesWritten,
                                             5 - bytesWritten);
      }
    }

    void dataHandler() {
      switch (_mode) {
        case 0:
          Expect.fail("No data expected");
          break;
        case 1:
          readBytes(() { _dataEvents++; });
          break;
        case 2:
          readBytes(() {
            _dataEvents++;
            connection.close();
          });
          break;
        case 3:
          readBytes(() {
            _dataEvents++;
            writeHello();
            connection.close();
          });
          break;
        case 4:
          readBytes(() {
            _dataEvents++;
            writeHello();
          });
          break;
        case 5:
        case 6:
          readBytes(() {
            _dataEvents++;
            writeHello();
            connection.close(true);
          });
          break;
        default:
          Expect.fail("Unknown test mode");
      }
    }

    void closeHandler() {
      _closeEvents++;
      connection.close();
    }

    void errorHandler(Exception e) {
      Expect.fail("Socket error $e");
    }

    _iterations++;

    connection.onData = dataHandler;
    connection.onClosed = closeHandler;
    connection.onError = errorHandler;
  }

  void errorHandlerServer(Exception e) {
    Expect.fail("Server socket error");
  }

  waitForResult(Timer timer) {
    // Make sure all iterations have been run. In multiple of these
    // scenarios it is possible to get the SERVERSHUTDOWN message
    // before we have received the last close event on the
    // server. In these cases we wait for the correct number of
    // close events.
    if (_iterations == ITERATIONS &&
        (_closeEvents == ITERATIONS || (_mode == 2 || _mode == 3))) {
      switch (_mode) {
        case 0:
          Expect.equals(0, _dataEvents);
          Expect.equals(ITERATIONS, _closeEvents);
          break;
        case 1:
          Expect.equals(ITERATIONS, _dataEvents);
          Expect.equals(ITERATIONS, _closeEvents);
          break;
        case 2:
        case 3:
          Expect.equals(ITERATIONS, _dataEvents);
          Expect.equals(0, _closeEvents);
          break;
        case 4:
        case 5:
        case 6:
          Expect.equals(ITERATIONS, _dataEvents);
          Expect.equals(ITERATIONS, _closeEvents);
          break;
        default:
          Expect.fail("Unknown test mode");
      }
      Expect.equals(0, _errorEvents);
      _server.close();
      port.close();
      _donePort.send(null);
    } else {
      new Timer(100, waitForResult);
    }
  }

  void dispatch(message, SendPort replyTo) {
    _donePort = replyTo;
    if (message != SERVERSHUTDOWN) {
      _readBytes = 0;
      _errorEvents = 0;
      _dataEvents = 0;
      _closeEvents = 0;
      _iterations = 0;
      _mode = message;
      _server = new ServerSocket(HOST, 0, 10);
      Expect.equals(true, _server != null);
      _server.onConnection = (connection) {
        var data = new ConnectionData(connection);
        connectionHandler(data);
      };
      _server.onError = errorHandlerServer;
      replyTo.send(_server.port, null);
    } else {
      new Timer(0, waitForResult);
    }
  }

  ServerSocket _server;
  SendPort _donePort;
  int _readBytes;
  int _errorEvents;
  int _dataEvents;
  int _closeEvents;
  int _iterations;
  int _mode;
}


main() {
  // Run the close test in these different "modes".
  // 0: Client closes without sending at all.
  // 1: Client sends and closes.
  // 2: Client sends. Server closes.
  // 3: Client sends. Server responds and closes.
  // 4: Client sends and half-closes. Server responds and closes.
  // 5: Client sends. Server responds and half closes.
  // 6: Client sends and half-closes. Server responds and half closes.
  var tests = 7;
  var port = new ReceivePort();
  var completed = 0;
  port.receive((message, ignore) {
    if (++completed == tests) port.close();
  });
  for (var i = 0; i < tests; i++) {
    new SocketClose.start(i, port.toSendPort());
  }
}
