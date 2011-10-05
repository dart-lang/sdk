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
  static final List<int> PATTERN =
      const [FIRSTCHAR + MSGSIZE - 2, FIRSTCHAR + MSGSIZE - 1];

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
      Logger.println("Socket error");
      _socket.close();
    }

    void connectHandler() {

      SocketOutputStream stream = _socket.outputStream;

      void dataSent() {
        SocketInputStream stream = _socket.inputStream;

        void dataReceived(List<int> buffer) {
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

        stream.readUntil(PATTERN, dataReceived);
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
  static final int FIRSTCHAR = EchoServerGame.FIRSTCHAR;
  static final List<int> PATTERN = EchoServerGame.PATTERN;

  void main() {

    void connectionHandler() {

      void messageHandler() {

        void dataReceived(List<int> buffer) {

          SocketOutputStream outputStream = _client.outputStream;

          void dataWritten() {
            _client.close();
          }

          for (int i = 0; i < MSGSIZE; i++) {
            Expect.equals(EchoServerGame.FIRSTCHAR + i, buffer[i]);
          }
          bool written = outputStream.write(buffer, 0, MSGSIZE, dataWritten);
          if (written) {
            dataWritten();
          }
        }

        SocketInputStream inputStream = _client.inputStream;
        inputStream.readUntil(PATTERN, dataReceived);
      }

      void closeHandler() {
        _socket.close();
      }

      void errorHandler() {
        Logger.println("Socket error");
        _socket.close();
      }

      _client = _server.accept();
      if (_client !== null) {
        _client.setDataHandler(messageHandler);
        _client.setCloseHandler(closeHandler);
        _client.setErrorHandler(errorHandler);
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
  Socket _client;
}
