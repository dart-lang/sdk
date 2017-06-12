// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write
//
// Test socket close events.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

const SERVERSHUTDOWN = -1;
const ITERATIONS = 10;

Future sendReceive(SendPort port, message) {
  ReceivePort receivePort = new ReceivePort();
  port.send([message, receivePort.sendPort]);
  return receivePort.first;
}

class SocketClose {
  SocketClose.start(this._mode, this._done)
      : _sendPort = null,
        _readBytes = 0,
        _dataEvents = 0,
        _closeEvents = 0,
        _errorEvents = 0,
        _iterations = 0 {
    initialize();
  }

  void proceed() {
    if (_iterations < ITERATIONS) {
      Timer.run(sendData);
    } else {
      shutdown();
    }
  }

  void sendData() {
    void dataHandler(bytes) {
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
          _readBytes += bytes.length;
          if ((_readBytes % 5) == 0) {
            _dataEvents++;
          }
          break;
        default:
          Expect.fail("Unknown test mode");
      }
    }

    void closeHandler(socket) {
      _closeEvents++;
      switch (_mode) {
        case 0:
        case 1:
          socket.close();
          break;
        case 2:
        case 3:
          socket.close();
          proceed();
          break;
        case 4:
          proceed();
          break;
        case 5:
          socket.close();
          proceed();
          break;
        case 6:
          proceed();
          break;
        default:
          Expect.fail("Unknown test mode");
      }
    }

    void errorHandler(Socket socket) {
      _errorEvents++;
      socket.close();
    }

    void connectHandler(socket) {
      socket.listen(dataHandler,
          onDone: () => closeHandler(socket),
          onError: (error) => errorHandler(socket));

      void writeHello() {
        socket.write("Hello");
      }

      _iterations++;
      switch (_mode) {
        case 0:
          socket.destroy();
          proceed();
          break;
        case 1:
          writeHello();
          socket.destroy();
          proceed();
          break;
        case 2:
        case 3:
          writeHello();
          break;
        case 4:
          writeHello();
          socket.close(); // Half close.
          break;
        case 5:
          writeHello();
          break;
        case 6:
          writeHello();
          socket.close(); // Half close.
          break;
        default:
          Expect.fail("Unknown test mode");
      }
    }

    Socket.connect(SocketCloseServer.HOST, _port).then(connectHandler);
  }

  void initialize() {
    ReceivePort receivePort = new ReceivePort();
    var remote = Isolate.spawn(startSocketCloseServer, receivePort.sendPort);

    receivePort.first.then((message) {
      this._sendPort = message;
      sendReceive(_sendPort, _mode).then((int port) {
        this._port = port;
        proceed();
      });
    });
  }

  void shutdown() {
    sendReceive(_sendPort, SERVERSHUTDOWN).then((_) {
      _done();
    });

    switch (_mode) {
      case 0:
      case 1:
        Expect.equals(0, _dataEvents);
        Expect.equals(ITERATIONS, _closeEvents);
        break;
      case 2:
        Expect.equals(0, _dataEvents);
        Expect.equals(ITERATIONS, _closeEvents);
        break;
      case 3:
      case 4:
        Expect.isTrue(_dataEvents <= ITERATIONS);
        Expect.isTrue(_dataEvents >= 0);
        Expect.equals(ITERATIONS, _closeEvents);
        break;
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
  SendPort _sendPort;
  List<int> _buffer;
  int _readBytes;
  int _dataEvents;
  int _closeEvents;
  int _errorEvents;
  int _iterations;
  int _mode;
  Function _done;
}

class ConnectionData {
  ConnectionData(Socket this.connection) : readBytes = 0;
  Socket connection;
  int readBytes;
}

void startSocketCloseServer(SendPort replyTo) {
  var server = new SocketCloseServer();
  replyTo.send(server.dispatchSendPort);
}

class SocketCloseServer {
  static const HOST = "127.0.0.1";

  SocketCloseServer() : _dispatchPort = new ReceivePort() {
    _dispatchPort.listen(dispatch);
  }

  void connectionHandler(ConnectionData data) {
    var connection = data.connection;

    void readBytes(bytes, whenFiveBytes) {
      data.readBytes += bytes.length;
      Expect.isTrue(data.readBytes <= 5);
      if (data.readBytes == 5) {
        whenFiveBytes();
      }
    }

    void writeHello() {
      connection.write("Hello");
    }

    void dataHandler(bytes) {
      switch (_mode) {
        case 0:
          Expect.fail("No data expected");
          break;
        case 1:
          readBytes(bytes, () {
            _dataEvents++;
          });
          break;
        case 2:
          readBytes(bytes, () {
            _dataEvents++;
            connection.destroy();
          });
          break;
        case 3:
          readBytes(bytes, () {
            _dataEvents++;
            writeHello();
            connection.destroy();
          });
          break;
        case 4:
          readBytes(bytes, () {
            _dataEvents++;
            writeHello();
          });
          break;
        case 5:
        case 6:
          readBytes(bytes, () {
            _dataEvents++;
            writeHello();
            connection.close(); // Half close.
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

    void errorHandler(e) {
      Expect.fail("Socket error $e");
    }

    _iterations++;

    connection.listen(dataHandler, onDone: closeHandler, onError: errorHandler);
  }

  void errorHandlerServer(e) {
    Expect.fail("Server socket error");
  }

  waitForResult() {
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
          Expect.isTrue(_dataEvents <= ITERATIONS);
          Expect.isTrue(_dataEvents >= 0);
          Expect.equals(ITERATIONS, _closeEvents);
          break;
        case 2:
        case 3:
          Expect.equals(ITERATIONS, _dataEvents);
          Expect.equals(ITERATIONS, _closeEvents);
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
      _dispatchPort.close();
      _donePort.send(null);
    } else {
      new Timer(new Duration(milliseconds: 100), waitForResult);
    }
  }

  SendPort get dispatchSendPort => _dispatchPort.sendPort;

  void dispatch(message) {
    var command = message[0];
    SendPort replyTo = message[1];
    _donePort = replyTo;
    if (command != SERVERSHUTDOWN) {
      _readBytes = 0;
      _errorEvents = 0;
      _dataEvents = 0;
      _closeEvents = 0;
      _iterations = 0;
      _mode = command;
      ServerSocket.bind("127.0.0.1", 0).then((server) {
        _server = server;
        _server.listen((socket) {
          var data = new ConnectionData(socket);
          connectionHandler(data);
        }, onError: errorHandlerServer);
        replyTo.send(_server.port);
      });
    } else {
      Timer.run(waitForResult);
    }
  }

  ServerSocket _server;
  final ReceivePort _dispatchPort;
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
  // 1: Client sends and destroys.
  // 2: Client sends. Server destroys.
  // 3: Client sends. Server responds and destroys.
  // 4: Client sends and half-closes. Server responds and destroys.
  // 5: Client sends. Server responds and half closes.
  // 6: Client sends and half-closes. Server responds and half closes.
  var tests = 7;
  for (var i = 0; i < tests; i++) {
    asyncStart();
    new SocketClose.start(i, asyncEnd);
  }
}
