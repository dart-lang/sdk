// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Echo server test program for testing sockets.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

#library("EchoServerTest.dart");
#import("dart:io");
#import("dart:isolate");
#source("testing_server.dart");

class EchoServerTest {

  static void testMain() {
    EchoServerGame echoServerGame = new EchoServerGame.start();
  }
}

class EchoServerGame {

  static const MSGSIZE = 10;
  static const MESSAGES = 100;
  static const FIRSTCHAR = 65;

  EchoServerGame.start()
      : _receivePort = new ReceivePort(),
        _sendPort = null,
        _buffer = new List<int>(MSGSIZE),
        _messages = 0 {
    for (int i = 0; i < MSGSIZE; i++) {
      _buffer[i] = FIRSTCHAR + i;
    }
    _sendPort = spawnFunction(startEchoServer);
    initialize();
  }

  void sendData() {
    Socket _socket;

    void messageHandler() {

      List<int> bufferReceived = new List<int>(MSGSIZE);
      int bytesRead = 0;

      void handleRead() {
        bytesRead += _socket.readList(
            bufferReceived, bytesRead, MSGSIZE - bytesRead);
        if (bytesRead < MSGSIZE) {
          // We check every time the whole buffer to verify data integrity.
          for (int i = 0; i < bytesRead; i++) {
            Expect.equals(FIRSTCHAR + i, bufferReceived[i]);
          }
          _socket.onData = handleRead;
        } else {
          // We check every time the whole buffer to verify data integrity.
          for (int i = 0; i < MSGSIZE; i++) {
            Expect.equals(FIRSTCHAR + i, bufferReceived[i]);
          }
          _messages++;
          _socket.close();
          if (_messages < MESSAGES) {
            sendData();
          } else {
            shutdown();
          }
        }
      }

      handleRead();
    }

    void errorHandler(Exception e) {
      Expect.fail("Socket error $e");
    }

    void connectHandler() {

      void writeMessage() {
        int bytesWritten = 0;

        void handleWrite() {
          bytesWritten += _socket.writeList(
              _buffer, bytesWritten, MSGSIZE - bytesWritten);
          if (bytesWritten < MSGSIZE) {
            _socket.onWrite = handleWrite;
          }
        }

        handleWrite();
      }

      _socket.onData = messageHandler;
      _socket.onError = errorHandler;
      writeMessage();
    }

    _socket = new Socket(TestingServer.HOST, _port);
    if (_socket !== null) {
      _socket.onConnect = connectHandler;
    } else {
      Expect.fail("Socket creation failed");
    }
  }

  void initialize() {
    _receivePort.receive((var message, SendPort replyTo) {
      _port = message;
      sendData();
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
  List<int> _buffer;
  int _messages;
}


void startEchoServer() {
  var server = new EchoServer();
  port.receive(server.dispatch);
}

class EchoServer extends TestingServer {

  static const msgSize = EchoServerGame.MSGSIZE;

  void onConnection(Socket connection) {

    void messageHandler() {

      List<int> buffer = new List<int>(msgSize);
      int bytesRead = 0;

      void handleRead() {
        int read = connection.readList(buffer, bytesRead, msgSize - bytesRead);
        if (read > 0) {
          bytesRead += read;
          if (bytesRead < msgSize) {
            // We check every time the whole buffer to verify data integrity.
            for (int i = 0; i < bytesRead; i++) {
              Expect.equals(EchoServerGame.FIRSTCHAR + i, buffer[i]);
            }
            connection.onData = handleRead;
          } else {
            // We check every time the whole buffer to verify data integrity.
            for (int i = 0; i < msgSize; i++) {
              Expect.equals(EchoServerGame.FIRSTCHAR + i, buffer[i]);
            }

            void writeMessage() {

              int bytesWritten = 0;

              void handleWrite() {
                int written = connection.writeList(
                    buffer, bytesWritten, msgSize - bytesWritten);
                bytesWritten += written;
                if (bytesWritten < msgSize) {
                  connection.onWrite = handleWrite;
                } else {
                  connection.close(true);
                }
              }
              handleWrite();
            }
            writeMessage();
          }
        }
      }

      handleRead();
    }

    void closeHandler() {
      connection.close();
    }

    void errorHandler(Exception e) {
      Expect.fail("Socket error $e");
    }

    connection.onData = messageHandler;
    connection.onClosed = closeHandler;
    connection.onError = errorHandler;
  }
}

main() {
  EchoServerTest.testMain();
}
