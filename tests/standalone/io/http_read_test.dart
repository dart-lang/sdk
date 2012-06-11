// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

#import("dart:isolate");
#import("dart:io");

class TestServerMain {
  TestServerMain()
      : _statusPort = new ReceivePort(),
        _serverPort = null {
    new TestServer().spawn().then((SendPort port) {
      _serverPort = port;
    });
  }

  void setServerStartedHandler(void startedCallback(int port)) {
    _startedCallback = startedCallback;
  }

  void start() {
    // Handle status messages from the server.
    _statusPort.receive((var status, SendPort replyTo) {
      if (status.isStarted) {
        _startedCallback(status.port);
      }
    });

    // Send server start message to the server.
    var command = new TestServerCommand.start();
    _serverPort.send(command, _statusPort.toSendPort());
  }

  void shutdown() {
    // Send server stop message to the server.
    _serverPort.send(new TestServerCommand.stop(), _statusPort.toSendPort());
    _statusPort.close();
  }

  void chunkedEncoding() {
    // Send chunked encoding message to the server.
    _serverPort.send(
        new TestServerCommand.chunkedEncoding(), _statusPort.toSendPort());
  }

  ReceivePort _statusPort;  // Port for receiving messages from the server.
  SendPort _serverPort;  // Port for sending messages to the server.
  var _startedCallback;
}


class TestServerCommand {
  static final START = 0;
  static final STOP = 1;
  static final CHUNKED_ENCODING = 2;

  TestServerCommand.start() : _command = START;
  TestServerCommand.stop() : _command = STOP;
  TestServerCommand.chunkedEncoding() : _command = CHUNKED_ENCODING;

  bool get isStart() => _command == START;
  bool get isStop() => _command == STOP;
  bool get isChunkedEncoding() => _command == CHUNKED_ENCODING;

  int _command;
}


class TestServerStatus {
  static final STARTED = 0;
  static final STOPPED = 1;
  static final ERROR = 2;

  TestServerStatus.started(this._port) : _state = STARTED;
  TestServerStatus.stopped() : _state = STOPPED;
  TestServerStatus.error() : _state = ERROR;

  bool get isStarted() => _state == STARTED;
  bool get isStopped() => _state == STOPPED;
  bool get isError() => _state == ERROR;

  int get port() => _port;

  int _state;
  int _port;
}


class TestServer extends Isolate {
  // Echo the request content back to the response.
  void _echoHandler(HttpRequest request, HttpResponse response) {
    Expect.equals("POST", request.method);
    response.contentLength = request.contentLength;
    request.inputStream.pipe(response.outputStream);
  }

  // Return a 404.
  void _notFoundHandler(HttpRequest request, HttpResponse response) {
    response.statusCode = HttpStatus.NOT_FOUND;
    response.headers.set("Content-Type", "text/html; charset=UTF-8");
    response.outputStream.writeString("Page not found");
    response.outputStream.close();
  }


  void main() {
    // Setup request handlers.
    _requestHandlers = new Map();
    _requestHandlers["/echo"] = (HttpRequest request, HttpResponse response) {
      _echoHandler(request, response);
    };

    this.port.receive((var message, SendPort replyTo) {
      if (message.isStart) {
        _server = new HttpServer();
        try {
          _server.listen("127.0.0.1", 0);
          _server.defaultRequestHandler = (HttpRequest req, HttpResponse rsp) {
            _requestReceivedHandler(req, rsp);
          };
          replyTo.send(new TestServerStatus.started(_server.port), null);
        } catch (var e) {
          replyTo.send(new TestServerStatus.error(), null);
        }
      } else if (message.isStop) {
        _server.close();
        this.port.close();
        replyTo.send(new TestServerStatus.stopped(), null);
      } else if (message.isChunkedEncoding) {
        _chunkedEncoding = true;
      }
    });
  }

  void _requestReceivedHandler(HttpRequest request, HttpResponse response) {
    var requestHandler =_requestHandlers[request.path];
    if (requestHandler != null) {
      requestHandler(request, response);
    } else {
      _notFoundHandler(request, response);
    }
  }

  HttpServer _server;  // HTTP server instance.
  Map _requestHandlers;
  bool _chunkedEncoding = false;
}

void testReadInto(bool chunkedEncoding) {
  String data = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  final int kMessageCount = 10;

  TestServerMain testServerMain = new TestServerMain();

  void runTest(int port) {
    int count = 0;
    HttpClient httpClient = new HttpClient();
    void sendRequest() {
      HttpClientConnection conn =
          httpClient.post("127.0.0.1", port, "/echo");
      conn.onRequest = (HttpClientRequest request) {
        if (chunkedEncoding) {
          request.outputStream.writeString(data.substring(0, 10));
          request.outputStream.writeString(data.substring(10, data.length));
        } else {
          request.contentLength = data.length;
          request.outputStream.write(data.charCodes());
        }
        request.outputStream.close();
      };
      conn.onResponse = (HttpClientResponse response) {
        Expect.equals(HttpStatus.OK, response.statusCode);
        InputStream stream = response.inputStream;
        List<int> body = new List<int>();
        stream.onData = () {
          List tmp = new List(3);
          int bytes = stream.readInto(tmp);
          body.addAll(tmp.getRange(0, bytes));
        };
        stream.onClosed = () {
          Expect.equals(data, new String.fromCharCodes(body));
          count++;
          if (count < kMessageCount) {
            sendRequest();
          } else {
            httpClient.shutdown();
            testServerMain.shutdown();
          }
        };
      };
    }

    sendRequest();
  }

  testServerMain.setServerStartedHandler(runTest);
  if (chunkedEncoding) {
    testServerMain.chunkedEncoding();
  }
  testServerMain.start();
}

void testReadShort(bool chunkedEncoding) {
  String data = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  final int kMessageCount = 10;

  TestServerMain testServerMain = new TestServerMain();

  void runTest(int port) {
    int count = 0;
    HttpClient httpClient = new HttpClient();
    void sendRequest() {
      HttpClientConnection conn =
          httpClient.post("127.0.0.1", port, "/echo");
      conn.onRequest = (HttpClientRequest request) {
        if (chunkedEncoding) {
          request.outputStream.writeString(data.substring(0, 10));
          request.outputStream.writeString(data.substring(10, data.length));
        } else {
          request.contentLength = data.length;
          request.outputStream.write(data.charCodes());
        }
        request.outputStream.close();
      };
      conn.onResponse = (HttpClientResponse response) {
        Expect.equals(HttpStatus.OK, response.statusCode);
        InputStream stream = response.inputStream;
        List<int> body = new List<int>();
        stream.onData = () {
          List tmp = stream.read(2);
          body.addAll(tmp);
        };
        stream.onClosed = () {
          Expect.equals(data, new String.fromCharCodes(body));
          count++;
          if (count < kMessageCount) {
            sendRequest();
          } else {
            httpClient.shutdown();
            testServerMain.shutdown();
          }
        };
      };
    }

    sendRequest();
  }

  testServerMain.setServerStartedHandler(runTest);
  if (chunkedEncoding) {
    testServerMain.chunkedEncoding();
  }
  testServerMain.start();
}

void main() {
  testReadInto(true);
  testReadInto(false);
  testReadShort(true);
  testReadShort(false);
}
