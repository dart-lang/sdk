// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Echo server test program to test socket streams.

class EchoServerStreamTest {

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

    void closeHandler() {
      _socket.close();
    }

    void errorHandler() {
      print("Socket error");
      _socket.close();
    }

    void connectHandler() {

      SocketOutputStream stream = _socket.outputStream;

      void dataSent() {
        // Reset buffer
        for (int i = 0; i < MSGSIZE; i++) {
          _buffer[i] = 1;
        }
        SocketInputStream stream = _socket.inputStream;

        void dataReceived() {
          for (int i = 0; i < MSGSIZE; i++) {
            Expect.equals(FIRSTCHAR + i, _buffer[i]);
          }
          _messages++;
          _socket.close();
          if (_messages < MESSAGES) {
            sendData();
          } else {
            shutdown();
          }
        }

        bool read = stream.read(_buffer, 0, MSGSIZE, dataReceived);
        if (read) {
          dataReceived();
        }
      }

      _socket.setCloseHandler(closeHandler);
      _socket.setErrorHandler(errorHandler);
      bool written = stream.write(_buffer, 0, MSGSIZE, dataSent);
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
  Socket _socket;
  List<int> _buffer;
  int _messages;
}

class EchoServer extends Isolate {

  static final HOST = "127.0.0.1";
  static final int MSGSIZE = EchoServerGame.MSGSIZE;

  void main() {

    void connectionHandler() {
      Socket _client;

      void messageHandler() {

        List<int> buffer = new List<int>(MSGSIZE);

        void dataReceived() {

          SocketOutputStream outputStream = _client.outputStream;

          for (int i = 0; i < MSGSIZE; i++) {
            Expect.equals(EchoServerGame.FIRSTCHAR + i, buffer[i]);
          }
          outputStream.write(buffer, 0, MSGSIZE, null);
        }

        SocketInputStream inputStream = _client.inputStream;
        bool read = inputStream.read(buffer, 0, MSGSIZE, dataReceived);
        if (read) {
          dataReceived();
        }
      }

      void closeHandler() {
        _client.close();
      }

      void errorHandler() {
        print("Socket error");
        _client.close();
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
}

main() {
  EchoServerStreamTest.testMain();
}
