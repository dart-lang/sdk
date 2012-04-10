// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:io");
#import("dart:isolate");

class ExpectedDataOutputStream implements OutputStream {
  ExpectedDataOutputStream(List<int> this._data,
                           int this._cutoff,
                           bool this._closeAsError,
                           SocketMock this._socket);

  void set onNoPendingWrites(void callback()) {
    _onNoPendingWrites = callback;
  }

  bool write(List data, [bool copyBuffer = true]) {
    _onData(data);
    return true;
  }

  bool writeFrom(List data, [int offset = 0, int len]) {
    if (len === null) len = data.length - offset;
    _onData(data.getRange(offset, len));
    return true;
  }

  void close() {
    _socket.close(true);
  }

  void _onData(List<int> data) {
    // TODO(ajohnsen): To be removed, since the socket should not be written to
    //                 after close.
    if (_socket._closed) return;
    Expect.isFalse(_written > _cutoff);
    Expect.listEquals(data, _data.getRange(0, data.length));
    _data = _data.getRange(data.length, _data.length - data.length);
    _written += data.length;
    if (_written >= _cutoff) {
      // Tell HttpServer that the socket have closed.
      _socket._closeInternal(_closeAsError);
    }
  }

  Function _onNoPendingWrites;
  List<int> _data;
  int _written = 0;
  int _cutoff;
  bool _closeAsError;
  SocketMock _socket;
}

class SocketMock implements Socket {
  SocketMock(List<int> this._data,
             List<int> expected,
             int cutoff,
             bool closeAsError) :
      _hashCode = (Math.random() * (1 << 32)).toInt(),
      _read = [] {
    _outputStream =
        new ExpectedDataOutputStream(expected, cutoff, closeAsError, this);
  }

  int available() {
    return _data.length;
  }

  void _closeInternal([bool asError = false]) {
    Expect.isFalse(_closed);
    _closed = true;
    _onClosedInternal();
    if (asError) {
      _onError(new Exception("Socket closed unexpected"));
    } else {
      _onClosed();
    }
  }

  int readList(List<int> buffer, int offset, int count) {
    int max = Math.min(count, _data.length);
    buffer.setRange(offset, max, _data);
    _data = _data.getRange(max, _data.length - max);
    return max;
  }

  void close([bool halfClose = false]) {
    if (!halfClose && !_closed) _closeInternal();
  }

  void set onData(void callback()) {
    _onData = callback;
  }

  void set onClosed(void callback()) {
    _onClosed = callback;
  }

  void set onError(void callback(Exception error)) {
    _onError = callback;
  }

  OutputStream get outputStream() => _outputStream;

  int hashCode() => _hashCode;

  List<int> _read;
  bool _closed = false;
  int _hashCode;
  Function _onData;
  Function _onClosed;
  Function _onError;
  Function _onClosedInternal;
  List<int> _data;
  ExpectedDataOutputStream _outputStream;
}

class ServerSocketMock implements ServerSocket {
  ServerSocketMock(String addr, int this._port, int backlog) :
      _sockets = new Set<Socket>();

  void spawnSocket(var data, String response, int cutOff, bool closeAsError) {
    if (data is String) data = data.charCodes();
    SocketMock socket = new SocketMock(data,
                                       response.charCodes(),
                                       cutOff,
                                       closeAsError);
    _sockets.add(socket);
    ReceivePort port = new ReceivePort();
    socket._onClosedInternal = () {
      // The server should always close the connection.
      _sockets.remove(socket);
      port.close();
    };
    // Tell HttpServer that a connection have come to life.
    _onConnection(socket);
    // Start 'sending' data.
    socket._onData();
  }

  void close() {
    Expect.fail("Don't close the connection, we attach to this socket");
  }

  void set onConnection(void callback(Socket connection)) {
    _onConnection = callback;
  }

  void set onError(void callback()) {
    _onError = callback;
  }

  int get port() => _port;

  int _port;
  Function _onConnection;
  Function _onError;
  Set<Socket> _sockets;
}

void testSocketClose() {
  ServerSocketMock serverSocket = new ServerSocketMock("0.0.0.0", 5432, 5);

  HttpServer server = new HttpServer();
  server.listenOn(serverSocket);
  void testContent(String request,
                   String response,
                   [int okayFrom = 0,
                    bool expectError = true]) {
    // Inner callback to actually run a given setting.
    void runSettings(int cutoff,
                     bool closeAsError,
                     bool expectError) {
      server.onRequest = (HttpRequest request, HttpResponse response) {
        request.inputStream.onData = () {
        };
        request.inputStream.onClosed = () {
          response.outputStream.close();
        };
      };

      if (expectError) {
        ReceivePort port = new ReceivePort();
        server.onError = (Exception error) {
          port.close();
        };
      } else {
        server.onError = (Exception error) {
          Expect.fail("An error was not expected: $error");
        };
      }

      serverSocket.spawnSocket(request, response, cutoff, closeAsError);
      // TODO(ajohnsen): Validate HttpServers number of connections.
    }
    for (int i = 1; i < response.length; i++) {
      bool _expectError = expectError && i < response.length - okayFrom;
      runSettings(i, false, _expectError);
      runSettings(i, true, _expectError);
    }
  }
  testContent(
      "GET / HTTP/1.1\r\nKeep-Alive: False\r\n\r\n",
      "HTTP/1.1 200 OK\r\ntransfer-encoding: chunked\r\nconnection: close" +
      "\r\n\r\n0\r\n\r\n");

  server.close();
}

void main() {
  testSocketClose();
}
