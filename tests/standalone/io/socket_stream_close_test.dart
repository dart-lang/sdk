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

final SERVERSHUTDOWN = -1;
final ITERATIONS = 10;


class SocketClose {

  SocketClose.start(this._mode, this._donePort)
      : _receivePort = new ReceivePort(),
        _sendPort = null,
        _readBytes = 0,
        _dataEvents = 0,
        _closeEvents = 0,
        _errorEvents = 0,
        _iterations = 0 {
    new SocketCloseServer().spawn().then((SendPort port) {
      _sendPort = port;
      start();
    });
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
        case 7:
        case 8:
          var read = _socket.inputStream.read();
          _readBytes += read.length;
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
          break;
        case 2:
        case 3:
        case 4:
          _socket.outputStream.close();
          proceed();
          break;
        case 5:
          proceed();
          break;
        case 6:
          _socket.outputStream.close();
          proceed();
          break;
        case 7:
        case 8:
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
      _socket.inputStream.onData = dataHandler;
      _socket.inputStream.onClosed = closeHandler;
      _socket.onError = errorHandler;

      _iterations++;
      switch (_mode) {
        case 0:
          _socket.inputStream.close();
          proceed();
          break;
        case 1:
          _socket.outputStream.write("Hello".charCodes());
          _socket.outputStream.onNoPendingWrites = () {
            _socket.inputStream.close();
            proceed();
          };
          break;
        case 2:
        case 3:
        case 4:
          _socket.outputStream.write("Hello".charCodes());
          break;
        case 5:
          _socket.outputStream.write("Hello".charCodes());
          _socket.outputStream.onNoPendingWrites = () {
            _socket.outputStream.close();
          };
          break;
        case 6:
          _socket.outputStream.write("Hello".charCodes());
          break;
        case 7:
        case 8:
          _socket.outputStream.write("Hello".charCodes());
          _socket.outputStream.onNoPendingWrites = () {
            _socket.outputStream.close();
          };
          break;
        default:
          Expect.fail("Unknown test mode");
      }
    }

    _socket = new Socket(SocketCloseServer.HOST, _port);
    Expect.equals(true, _socket !== null);
    _socket.onConnect = connectHandler;
  }

  void start() {
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
        Expect.equals(ITERATIONS, _dataEvents);
        Expect.equals(ITERATIONS, _closeEvents);
        break;
      case 4:
        Expect.equals(ITERATIONS, _closeEvents);
        break;
      case 5:
      case 6:
      case 7:
      case 8:
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


class SocketCloseServer extends Isolate {

  static final HOST = "127.0.0.1";

  SocketCloseServer() : super() {}

  void main() {

    void connectionHandler(ConnectionData data) {
      var connection = data.connection;

      void readBytes(whenFiveBytes) {
        var read = connection.inputStream.read();
        data.readBytes += read.length;
        if (data.readBytes == 5) {
          whenFiveBytes();
        }
      }

      void dataHandler() {
        switch (_mode) {
          case 0:
            Expect.fail("No data expected");
            break;
          case 1:
            readBytes(() {
              _dataEvents++;
            });
            break;
          case 2:
            readBytes(() {
              _dataEvents++;
              connection.inputStream.close();
            });
            break;
          case 3:
            readBytes(() {
              _dataEvents++;
              connection.outputStream.write("Hello".charCodes());
              connection.outputStream.onNoPendingWrites = () {
                connection.inputStream.close();
              };
            });
            break;
          case 4:
            readBytes(() {
              _dataEvents++;
              connection.outputStream.write("Hello".charCodes());
              connection.inputStream.close();
            });
            break;
          case 5:
            readBytes(() {
              _dataEvents++;
              connection.outputStream.write("Hello".charCodes());
            });
            break;
          case 6:
          case 7:
            readBytes(() {
              _dataEvents++;
              connection.outputStream.write("Hello".charCodes());
              connection.outputStream.onNoPendingWrites = () {
                connection.outputStream.close();
              };
            });
            break;
          case 8:
            readBytes(() {
              _dataEvents++;
              connection.outputStream.write("Hello".charCodes());
              connection.outputStream.close();
            });
            break;
          default:
            Expect.fail("Unknown test mode");
        }
      }

      void closeHandler() {
        _closeEvents++;
        connection.outputStream.close();
      }

      void errorHandler(Exception e) {
        Expect.fail("Socket error $e");
      }

      _iterations++;

      connection.inputStream.onData = dataHandler;
      connection.inputStream.onClosed = closeHandler;
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
          (_closeEvents == ITERATIONS ||
           (_mode == 2 || _mode == 3 || _mode == 4))) {
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
          case 4:
            Expect.equals(ITERATIONS, _dataEvents);
            Expect.equals(0, _closeEvents);
            break;
          case 5:
          case 6:
          case 7:
          case 8:
            Expect.equals(ITERATIONS, _dataEvents);
            Expect.equals(ITERATIONS, _closeEvents);
            break;
          default:
            Expect.fail("Unknown test mode");
        }
        Expect.equals(0, _errorEvents);
        _server.close();
        this.port.close();
        _donePort.send(null);
      } else {
        new Timer(100, waitForResult);
      }
    }

    this.port.receive((message, SendPort replyTo) {
      _donePort = replyTo;
      if (message != SERVERSHUTDOWN) {
        _readBytes = 0;
        _errorEvents = 0;
        _dataEvents = 0;
        _closeEvents = 0;
        _iterations = 0;
        _mode = message;
        _server = new ServerSocket(HOST, 0, 10);
        Expect.equals(true, _server !== null);
        _server.onConnection = (connection) {
          var data = new ConnectionData(connection);
          connectionHandler(data);
        };
        _server.onError = errorHandlerServer;
        replyTo.send(_server.port, null);
      } else {
        new Timer(0, waitForResult);
      }
    });
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
  // 4: Client sends. Server responds and closes without waiting for everything
  //    being sent.
  // 5: Client sends and half-closes. Server responds and closes.
  // 6: Client sends. Server responds and half closes.
  // 7: Client sends and half-closes. Server responds and half closes.
  // 8: Client sends and half-closes. Server responds and half closes without
  //    explicitly waiting for everything being sent.
  var tests = 9;
  var port = new ReceivePort();
  var completed = 0;
  port.receive((message, ignore) {
    if (++completed == tests) port.close();
  });
  for (var i = 0; i < tests; i++) {
    new SocketClose.start(i, port.toSendPort());
  }
}
