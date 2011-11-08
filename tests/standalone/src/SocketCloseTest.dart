// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test socket close events.


final SERVERSHUTDOWN = -1;
final ITERATIONS = 10;


// Run the close test in these different "modes".
// 0: Client closes without sending at all.
// 1: Client sends and closes.
// 2: Client sends. Server closes.
// 3: Client sends. Server responds and closes.
// 4: Client sends and half-closes. Server responds and closes.
// 5: Client sends. Server responds and half closes.
// 6: Client sends and half-closes. Server responds and half closes.
class SocketCloseTest {
  static void testMain() {
    new SocketClose.start(0);
    new SocketClose.start(1);
    new SocketClose.start(2);
    new SocketClose.start(3);
    new SocketClose.start(4);
    new SocketClose.start(5);
    new SocketClose.start(6);
  }
}


class SocketClose {

  SocketClose.start(mode)
      : _receivePort = new ReceivePort(),
        _sendPort = null,
        _dataEvents = 0,
        _closeEvents = 0,
        _errorEvents = 0,
        _iterations = 0,
        _mode = mode {
    new SocketCloseServer().spawn().then((SendPort port) {
      _sendPort = port;
      start();
    });
  }

  void proceed() {
    if (_iterations < ITERATIONS) {
      new Timer(sendData, 0, false);
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
          List<int> b = new List<int>(100);
          _socket.readList(b, 0, 100);
          _dataEvents++;
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

    void errorHandler() {
      _errorEvents++;
      _socket.close();
    }

    void connectHandler() {
      _socket.dataHandler = dataHandler;
      _socket.closeHandler = closeHandler;
      _socket.errorHandler = errorHandler;

      _iterations++;
      switch (_mode) {
        case 0:
          _socket.close();
          proceed();
          break;
        case 1:
          int bytesWritten = _socket.writeList("Hello".charCodes(), 0, 5);
          Expect.equals(5, bytesWritten);
          _socket.close();
          proceed();
          break;
        case 2:
        case 3:
          int bytesWritten = _socket.writeList("Hello".charCodes(), 0, 5);
          Expect.equals(5, bytesWritten);
          break;
        case 4:
          int bytesWritten = _socket.writeList("Hello".charCodes(), 0, 5);
          Expect.equals(5, bytesWritten);
          _socket.close(true);
          break;
        case 5:
          int bytesWritten = _socket.writeList("Hello".charCodes(), 0, 5);
          Expect.equals(5, bytesWritten);
          break;
        case 6:
          int bytesWritten = _socket.writeList("Hello".charCodes(), 0, 5);
          Expect.equals(5, bytesWritten);
          _socket.close(true);
          break;
        default:
          Expect.fail("Unknown test mode");
      }
    }

    _socket = new Socket(SocketCloseServer.HOST, _port);
    Expect.equals(true, _socket !== null);
    _socket.connectHandler = connectHandler;
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
    _receivePort.close();

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
  int _dataEvents;
  int _closeEvents;
  int _errorEvents;
  int _iterations;
  int _mode;
}

class SocketCloseServer extends Isolate {

  static final HOST = "127.0.0.1";

  SocketCloseServer() : super() {}

  void main() {

    void connectionHandler() {
      Socket _client;

      void dataHandler() {
        _dataEvents++;
        switch (_mode) {
          case 0:
            Expect.fail("No data expected");
            break;
          case 1:
            List<int> b = new List<int>(100);
            _client.readList(b, 0, 100);
            break;
          case 2:
            List<int> b = new List<int>(100);
            _client.readList(b, 0, 100);
            _client.close();
            break;
          case 3:
            List<int> b = new List<int>(100);
            _client.readList(b, 0, 100);
            _client.writeList("Hello".charCodes(), 0, 5);
            _client.close();
            break;
          case 4:
            List<int> b = new List<int>(100);
            _client.readList(b, 0, 100);
            _client.writeList("Hello".charCodes(), 0, 5);
            break;
          case 5:
          case 6:
            List<int> b = new List<int>(100);
            _client.readList(b, 0, 100);
            _client.writeList("Hello".charCodes(), 0, 5);
            _client.close(true);
            break;
          default:
            Expect.fail("Unknown test mode");
        }
      }

      void closeHandler() {
        _closeEvents++;
        _client.close();
      }

      void errorHandler() {
        Expect.fail("Socket error");
      }

      _client = _server.accept();
      _iterations++;

      _client.dataHandler = dataHandler;
      _client.closeHandler = closeHandler;
      _client.errorHandler = errorHandler;
    }

    void errorHandlerServer() {
      Expect.fail("Server socket error");
    }

    waitForResult(Timer timer) {
      // Make sure all iterations have been run. For mode 0 and 1 the
      // client just closes the socket and after the last iteration
      // signals the server. The server might now be finished just
      // because iterations have reached the limit as this number is
      // incremented just after accept. In that case wait for the last
      // close event.
      if (_iterations == ITERATIONS &&
          (_mode > 1 || _closeEvents == ITERATIONS)) {
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
        this.port.close();
      } else {
        new Timer(waitForResult, 100, false);
      }
    }

    this.port.receive((message, SendPort replyTo) {
      if (message != SERVERSHUTDOWN) {
        _errorEvents = 0;
        _dataEvents = 0;
        _closeEvents = 0;
        _iterations = 0;
        _mode = message;
        _server = new ServerSocket(HOST, 0, 10);
        Expect.equals(true, _server !== null);
        _server.connectionHandler = connectionHandler;
        _server.errorHandler = errorHandlerServer;
        replyTo.send(_server.port, null);
      } else {
        new Timer(waitForResult, 0, false);
      }
    });
  }

  ServerSocket _server;
  int _errorEvents;
  int _dataEvents;
  int _closeEvents;
  int _iterations;
  int _mode;
}


main() {
  SocketCloseTest.testMain();
}
