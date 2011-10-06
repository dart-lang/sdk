// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Echo server test program to test socket stream read until functionality.

main() {
  EchoServerStreamReadUntilTest.testMain();
}

class EchoServerStreamReadUntilTest {

  static void testMain() {
    EchoServerGame echoServerGame = new EchoServerGame.start();
  }
}

class EchoServerGame {

  static final MSGSIZE = 10;
  static final SERVERINIT = 0;
  static final SERVERSHUTDOWN = -1;
  static final MESSAGES = 200;
  // Char "A".
  static final FIRSTCHAR = 65;

  // First pattern is the third and second last character of the message.
  static final List<int> PATTERN1 =
      const [FIRSTCHAR + MSGSIZE - 3, FIRSTCHAR + MSGSIZE - 2];
  // Second pattern is the last character of the message.
  static final List<int> PATTERN2 = const [FIRSTCHAR + MSGSIZE - 1];

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

    void closeHandler() {
      _socket.close();
    }

    void errorHandler() {
      print("Socket error");
      Expect.equals(true, false);
      _socket.close();
    }

    void connectHandler() {
      SocketInputStream inputStream = _socket.inputStream;
      SocketOutputStream outputStream = _socket.outputStream;

      void dataSent() {

        void dataReceived(List<int> buffer) {
          if (buffer.length == MSGSIZE - 1) {
            for (int i = 0; i < MSGSIZE - 1; i++) {
              Expect.equals(FIRSTCHAR + i, _buffer[i]);
            }
            inputStream.readUntil(PATTERN2, dataReceived);
          } else {
            Expect.equals(1, buffer.length);
            _messages++;
            _socket.close();
            if (_messages < MESSAGES) {
              sendData();
            } else {
              shutdown();
            }
          }
        }

        // Write data and continue in dataSent.
        inputStream.readUntil(PATTERN1, dataReceived);
      }

      _socket.setCloseHandler(closeHandler);
      _socket.setErrorHandler(errorHandler);

      // Write data and continue in dataSent.
      bool written = outputStream.write(_buffer, 0, MSGSIZE, dataSent);
      if (written) {
        dataSent();
      }
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
  List<int> _buffer;
  int _messages;
}

class EchoServer extends Isolate {

  static final HOST = "127.0.0.1";
  static final int MSGSIZE = EchoServerGame.MSGSIZE;
  static final int FIRSTCHAR = EchoServerGame.FIRSTCHAR;
  static final List<int> PATTERN1 = EchoServerGame.PATTERN1;
  static final List<int> PATTERN2 = EchoServerGame.PATTERN2;

  void main() {

    void connectionHandler() {
      Socket _client;

      void messageHandler() {
        SocketInputStream inputStream = _client.inputStream;
        SocketOutputStream outputStream = _client.outputStream;

        // Data is expected to arrive in two chunks. First all but the
        // last character and second a single character.
        void dataReceived(List<int> buffer) {

          if (buffer.length == MSGSIZE - 1) {
            for (int i = 0; i < MSGSIZE - 1; i++) {
              Expect.equals(EchoServerGame.FIRSTCHAR + i, buffer[i]);
            }
            outputStream.write(buffer, 0, buffer.length, null);
            inputStream.readUntil(PATTERN2, dataReceived);
          } else {
            Expect.equals(1, buffer.length);
            outputStream.write(buffer, 0, buffer.length, null);
            inputStream.readUntil(PATTERN2, dataReceived);
          }
        }

        void closeHandler() {
          _client.close();
        }

        void errorHandler() {
          print("Socket error");
          Expect.equals(true, false);
          _client.close();
        }

        _client.setCloseHandler(closeHandler);
        _client.setErrorHandler(errorHandler);

        inputStream.readUntil(PATTERN1, dataReceived);
      }

      _client = _server.accept();
      if (_client !== null) {
        messageHandler();
      }
    }

    void errorHandlerServer() {
      Logger.println("Server socket error");
      _server.close();
    }

    this.port.receive((message, SendPort replyTo) {
      if (message == EchoServerGame.SERVERINIT) {
        _server = new ServerSocket(HOST, 0, 10);
        Expect.equals(true, _server !== null);
        int port = _server.port;
        _server.setConnectionHandler(connectionHandler);
        _server.setErrorHandler(errorHandlerServer);
        replyTo.send(port, null);
      } else if (message == EchoServerGame.SERVERSHUTDOWN) {
        _server.close();
        this.port.close();
      }
    });
  }

  ServerSocket _server;
}
