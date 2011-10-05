// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Echo server test program for testing sockets.

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

    void messageHandler() {

      List<int> bufferReceived = new List<int>(MSGSIZE);
      int bytesRead = 0;

      void handleRead() {

        if (_socket.available() > 0) {
          bytesRead += _socket.readList(
              bufferReceived, bytesRead, MSGSIZE - bytesRead);
        }
        if (bytesRead < MSGSIZE) {
          /*
           * We check every time the whole buffer to verify data integrity.
           */
          for (int i = 0; i < bytesRead; i++) {
            Expect.equals(FIRSTCHAR + i, bufferReceived[i]);
          }
          _socket.setDataHandler(handleRead);
        }
        else {
          /*
           * We check every time the whole buffer to verify data integrity.
           */
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
            _socket.setWriteHandler(handleWrite);
          }
        }

        handleWrite();
      }

      _socket.setDataHandler(messageHandler);
      _socket.setCloseHandler(closeHandler);
      _socket.setErrorHandler(errorHandler);
      writeMessage();
    }

    _socket = new Socket(EchoServer.HOST, _port);
    if (_socket !== null) {
      _socket.setConnectHandler(connectHandler);
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
  Socket _socket;
  List<int> _buffer;
  int _messages;
}

class EchoServer extends Isolate {

  static final HOST = "127.0.0.1";
  static final msgSize = EchoServerGame.MSGSIZE;


  // TODO(hpayer): can be removed as soon as we have default constructors
  EchoServer() : super() { }

  void main() {

    void connectionHandler() {

      void messageHandler() {

        List<int> buffer = new List<int>(msgSize);
        int bytesRead = 0;

        void handleRead() {
          if (_client.available() > 0) {
            bytesRead += _client.readList(buffer, bytesRead, msgSize - bytesRead);
          }
          if (bytesRead < msgSize) {
            /*
             * We check every time the whole buffer to verify data integrity.
             */
            for (int i = 0; i < bytesRead; i++) {
              Expect.equals(EchoServerGame.FIRSTCHAR + i, buffer[i]);
            }
            _client.setDataHandler(handleRead);
          }
          else {
            _client.setDataHandler(null);
            /*
             * We check every time the whole buffer to verify data integrity.
             */
            for (int i = 0; i < msgSize; i++) {
              Expect.equals(EchoServerGame.FIRSTCHAR + i, buffer[i]);
            }

            void writeMessage() {

              int bytesWritten = 0;

              void handleWrite() {
                bytesWritten += _client.writeList(
                      buffer, bytesWritten, msgSize - bytesWritten);
                if (bytesWritten < msgSize) {
                  _client.setWriteHandler(handleWrite);
                } else {
                  _client.close();
                }
              }
              handleWrite();
            }
            writeMessage();
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

      _client = _server.accept();
      _client.setDataHandler(messageHandler);
      _client.setCloseHandler(closeHandler);
      _client.setErrorHandler(errorHandler);
    }

    void errorHandlerServer() {
      print("Server socket error");
      _server.close();
    }

    this.port.receive((message, SendPort replyTo) {
      if (message == EchoServerGame.SERVERINIT) {
        _server = new ServerSocket(HOST, 0, 10);
        Expect.equals(true, _server !== null);
        _server.setConnectionHandler(connectionHandler);
        _server.setErrorHandler(errorHandlerServer);
        replyTo.send(_server.port, null);
      } else if (message == EchoServerGame.SERVERSHUTDOWN) {
        _server.close();
        this.port.close();
      }
    });
  }

  ServerSocket _server;
  Socket _client;
}

main() {
  EchoServerTest.testMain();
}
