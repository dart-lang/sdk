// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Echo server test program for testing sockets.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

class EchoServerTest {

  static void testMain() {
    EchoServerGame echoServerGame = new EchoServerGame.start();
  }
}

class EchoServerGame {

  static final MSGSIZE = 10;
  static final SERVERINIT = 0;
  static final SERVERSHUTDOWN = -1;
  static final MESSAGES = 200;
  static final FIRSTCHAR = 65;

  EchoServerGame.start()
      : _receivePort = new ReceivePort(),
        _sendPort = null,
        _buffer = new List<int>(MSGSIZE),
        _messages = 0 {
    for (int i = 0; i < MSGSIZE; i++) {
      _buffer[i] = FIRSTCHAR + i;
    }
    new EchoServer().spawn().then((SendPort port) {
      _sendPort = port;
      start();
    });
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
          _socket.dataHandler = handleRead;
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

    void closeHandler() {
      _socket.close();
    }

    void errorHandler() {
      print("Socket error");
      _socket.close();
    }

    void connectHandler() {

      void writeMessage() {
        int bytesWritten = 0;

        void handleWrite() {
          bytesWritten += _socket.writeList(
              _buffer, bytesWritten, MSGSIZE - bytesWritten);
          if (bytesWritten < MSGSIZE) {
            _socket.writeHandler = handleWrite;
          }
        }

        handleWrite();
      }

      _socket.dataHandler = messageHandler;
      _socket.closeHandler = closeHandler;
      _socket.errorHandler = errorHandler;
      writeMessage();
    }

    _socket = new Socket(EchoServer.HOST, _port);
    if (_socket !== null) {
      _socket.connectHandler = connectHandler;
    } else {
      Expect.fail("socket creation failed");
    }
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
  }

  int _port;
  ReceivePort _receivePort;
  SendPort _sendPort;
  List<int> _buffer;
  int _messages;
}

class EchoServer extends Isolate {

  static final HOST = "127.0.0.1";
  static final msgSize = EchoServerGame.MSGSIZE;


  void main() {

    void connectionHandler() {
      Socket _client;

      void messageHandler() {

        List<int> buffer = new List<int>(msgSize);
        int bytesRead = 0;

        void handleRead() {
          int read = _client.readList(buffer, bytesRead, msgSize - bytesRead);
          if (read > 0) {
            bytesRead += read;
            if (bytesRead < msgSize) {
              // We check every time the whole buffer to verify data integrity.
              for (int i = 0; i < bytesRead; i++) {
                Expect.equals(EchoServerGame.FIRSTCHAR + i, buffer[i]);
              }
              _client.dataHandler = handleRead;
            } else {
              // We check every time the whole buffer to verify data integrity.
              for (int i = 0; i < msgSize; i++) {
                Expect.equals(EchoServerGame.FIRSTCHAR + i, buffer[i]);
              }

              void writeMessage() {

                int bytesWritten = 0;

                void handleWrite() {
                  int written = _client.writeList(
                        buffer, bytesWritten, msgSize - bytesWritten);
                  bytesWritten += written;
                  if (bytesWritten < msgSize) {
                    _client.writeHandler = handleWrite;
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
        _client.close();
      }

      void errorHandler() {
        print("Socket error");
        _client.close();
      }

      _client = _server.accept();
      _client.dataHandler = messageHandler;
      _client.closeHandler = closeHandler;
      _client.errorHandler = errorHandler;
    }

    void errorHandlerServer() {
      print("Server socket error");
      _server.close();
    }

    this.port.receive((message, SendPort replyTo) {
      if (message == EchoServerGame.SERVERINIT) {
        _server = new ServerSocket(HOST, 0, 10);
        Expect.equals(true, _server !== null);
        _server.connectionHandler = connectionHandler;
        _server.errorHandler = errorHandlerServer;
        replyTo.send(_server.port, null);
      } else if (message == EchoServerGame.SERVERSHUTDOWN) {
        _server.close();
        this.port.close();
      }
    });
  }

  ServerSocket _server;
}

main() {
  EchoServerTest.testMain();
}
