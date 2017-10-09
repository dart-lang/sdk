// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Echo server test program to test socket streams.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

library ServerTest;

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import "dart:async";
import "dart:io";
import "dart:isolate";
part "testing_server.dart";

class EchoServerGame {
  static const MSGSIZE = 10;
  static const MESSAGES = 100;
  static const FIRSTCHAR = 65;

  EchoServerGame.start()
      : _buffer = new List<int>(MSGSIZE),
        _messages = 0 {
    for (int i = 0; i < MSGSIZE; i++) {
      _buffer[i] = FIRSTCHAR + i;
    }
    initialize();
  }

  void sendData() {
    int offset = 0;
    List<int> data;

    void onData(List<int> data) {
      int bytesRead = data.length;
      for (int i = 0; i < data.length; i++) {
        Expect.equals(FIRSTCHAR + i + offset, data[i]);
      }
      offset += bytesRead;
    }

    void onClosed() {
      Expect.equals(MSGSIZE, offset);
      _messages++;
      if (_messages < MESSAGES) {
        sendData();
      } else {
        shutdown();
      }
    }

    void errorHandler(e, trace) {
      String msg = "Socket error $e";
      if (trace != null) msg += "\nStackTrace: $trace";
      Expect.fail(msg);
    }

    void connectHandler() {
      _socket.listen(onData, onError: errorHandler, onDone: onClosed);
      _socket.add(_buffer);
      _socket.close();
      data = new List<int>(MSGSIZE);
    }

    Socket.connect(TestingServer.HOST, _port).then((s) {
      _socket = s;
      connectHandler();
    });
  }

  void initialize() {
    var receivePort = new ReceivePort();
    var remote = Isolate.spawn(startEchoServer, receivePort.sendPort);
    receivePort.first.then((msg) {
      this._port = msg[0];
      this._closeSendPort = msg[1];
      sendData();
    });
  }

  void shutdown() {
    _closeSendPort.send(null);
    asyncEnd();
  }

  int _port;
  SendPort _closeSendPort;
  Socket _socket;
  List<int> _buffer;
  int _messages;
}

void startEchoServer(SendPort replyPort) {
  var server = new EchoServer();
  server.init().then((port) {
    replyPort.send([port, server.closeSendPort]);
  });
}

class EchoServer extends TestingServer {
  static const int MSGSIZE = EchoServerGame.MSGSIZE;

  void onConnection(Socket connection) {
    List<int> buffer = new List<int>(MSGSIZE);
    int offset = 0;

    void dataReceived(List<int> data) {
      int bytesRead;
      bytesRead = data.length;
      if (bytesRead > 0) {
        buffer.setRange(offset, offset + data.length, data);
        offset += bytesRead;
        for (int i = 0; i < offset; i++) {
          Expect.equals(EchoServerGame.FIRSTCHAR + i, buffer[i]);
        }
        if (offset == MSGSIZE) {
          connection.add(buffer);
          connection.close();
        }
      }
    }

    void errorHandler(e, trace) {
      String msg = "Socket error $e";
      if (trace != null) msg += "\nStackTrace: $trace";
      Expect.fail(msg);
    }

    connection.listen(dataReceived, onError: errorHandler);
  }
}

main() {
  asyncStart();
  EchoServerGame echoServerGame = new EchoServerGame.start();
}
