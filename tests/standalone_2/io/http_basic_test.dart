// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--trace_shutdown
// VMOptions=--trace_shutdown --short_socket_read
// VMOptions=--trace_shutdown --short_socket_write
// VMOptions=--trace_shutdown --short_socket_read --short_socket_write

import "package:expect/expect.dart";
import "dart:isolate";
import "dart:io";

class TestServerMain {
  TestServerMain()
      : _statusPort = new ReceivePort(),
        _serverPort = null;

  void setServerStartedHandler(void startedCallback(int port)) {
    _startedCallback = startedCallback;
  }

  void start([bool chunkedEncoding = false]) {
    ReceivePort receivePort = new ReceivePort();
    var remote = Isolate.spawn(startTestServer, receivePort.sendPort);
    receivePort.first.then((port) {
      _serverPort = port;

      if (chunkedEncoding) {
        // Send chunked encoding message to the server.
        port.send(
            [new TestServerCommand.chunkedEncoding(), _statusPort.sendPort]);
      }

      // Send server start message to the server.
      var command = new TestServerCommand.start();
      port.send([command, _statusPort.sendPort]);
    });

    // Handle status messages from the server.
    _statusPort.listen((var status) {
      if (status.isStarted) {
        _startedCallback(status.port);
      }
    });
  }

  void close() {
    // Send server stop message to the server.
    _serverPort.send([new TestServerCommand.stop(), _statusPort.sendPort]);
    _statusPort.close();
  }

  ReceivePort _statusPort; // Port for receiving messages from the server.
  SendPort _serverPort; // Port for sending messages to the server.
  var _startedCallback;
}

class TestServerCommand {
  static const START = 0;
  static const STOP = 1;
  static const CHUNKED_ENCODING = 2;

  TestServerCommand.start() : _command = START;
  TestServerCommand.stop() : _command = STOP;
  TestServerCommand.chunkedEncoding() : _command = CHUNKED_ENCODING;

  bool get isStart => _command == START;
  bool get isStop => _command == STOP;
  bool get isChunkedEncoding => _command == CHUNKED_ENCODING;

  int _command;
}

class TestServerStatus {
  static const STARTED = 0;
  static const STOPPED = 1;
  static const ERROR = 2;

  TestServerStatus.started(this._port) : _state = STARTED;
  TestServerStatus.stopped() : _state = STOPPED;
  TestServerStatus.error() : _state = ERROR;

  bool get isStarted => _state == STARTED;
  bool get isStopped => _state == STOPPED;
  bool get isError => _state == ERROR;

  int get port => _port;

  int _state;
  int _port;
}

void startTestServer(Object replyToObj) {
  SendPort replyTo = replyToObj;
  var server = new TestServer();
  server.init();
  replyTo.send(server.dispatchSendPort);
}

class TestServer {
  // Echo the request content back to the response.
  void _echoHandler(HttpRequest request) {
    var response = request.response;
    Expect.equals("POST", request.method);
    response.contentLength = request.contentLength;
    request.pipe(response);
  }

  // Echo the request content back to the response.
  void _zeroToTenHandler(HttpRequest request) {
    var response = request.response;
    Expect.equals("GET", request.method);
    request.listen((_) {}, onDone: () {
      response.write("01234567890");
      response.close();
    });
  }

  // Return a 404.
  void _notFoundHandler(HttpRequest request) {
    var response = request.response;
    response.statusCode = HttpStatus.NOT_FOUND;
    response.headers.set("Content-Type", "text/html; charset=UTF-8");
    response.write("Page not found");
    response.close();
  }

  // Return a 301 with a custom reason phrase.
  void _reasonForMovingHandler(HttpRequest request) {
    var response = request.response;
    response.statusCode = HttpStatus.MOVED_PERMANENTLY;
    response.reasonPhrase = "Don't come looking here any more";
    response.close();
  }

  // Check the "Host" header.
  void _hostHandler(HttpRequest request) {
    var response = request.response;
    Expect.equals(1, request.headers["Host"].length);
    Expect.equals("www.dartlang.org:1234", request.headers["Host"][0]);
    Expect.equals("www.dartlang.org", request.headers.host);
    Expect.equals(1234, request.headers.port);
    response.statusCode = HttpStatus.OK;
    response.close();
  }

  void init() {
    // Setup request handlers.
    _requestHandlers = new Map();
    _requestHandlers["/echo"] = _echoHandler;
    _requestHandlers["/0123456789"] = _zeroToTenHandler;
    _requestHandlers["/reasonformoving"] = _reasonForMovingHandler;
    _requestHandlers["/host"] = _hostHandler;
    _dispatchPort = new ReceivePort();
    _dispatchPort.listen(dispatch);
  }

  SendPort get dispatchSendPort => _dispatchPort.sendPort;

  void dispatch(var message) {
    TestServerCommand command = message[0];
    SendPort replyTo = message[1];
    if (command.isStart) {
      try {
        HttpServer.bind("127.0.0.1", 0).then((server) {
          _server = server;
          _server.listen(_requestReceivedHandler);
          replyTo.send(new TestServerStatus.started(_server.port));
        });
      } catch (e) {
        replyTo.send(new TestServerStatus.error());
      }
    } else if (command.isStop) {
      _server.close();
      _dispatchPort.close();
      replyTo.send(new TestServerStatus.stopped());
    } else if (command.isChunkedEncoding) {
      _chunkedEncoding = true;
    }
  }

  void _requestReceivedHandler(HttpRequest request) {
    var requestHandler = _requestHandlers[request.uri.path];
    if (requestHandler != null) {
      requestHandler(request);
    } else {
      _notFoundHandler(request);
    }
  }

  HttpServer _server; // HTTP server instance.
  ReceivePort _dispatchPort;
  Map _requestHandlers;
  bool _chunkedEncoding = false;
}

void testStartStop() {
  TestServerMain testServerMain = new TestServerMain();
  testServerMain.setServerStartedHandler((int port) {
    testServerMain.close();
  });
  testServerMain.start();
}

void testGET() {
  TestServerMain testServerMain = new TestServerMain();
  testServerMain.setServerStartedHandler((int port) {
    HttpClient httpClient = new HttpClient();
    httpClient
        .get("127.0.0.1", port, "/0123456789")
        .then((request) => request.close())
        .then((response) {
      Expect.equals(HttpStatus.OK, response.statusCode);
      StringBuffer body = new StringBuffer();
      response.listen((data) => body.write(new String.fromCharCodes(data)),
          onDone: () {
        Expect.equals("01234567890", body.toString());
        httpClient.close();
        testServerMain.close();
      });
    });
  });
  testServerMain.start();
}

void testPOST(bool chunkedEncoding) {
  String data = "ABCDEFGHIJKLMONPQRSTUVWXYZ";
  final int kMessageCount = 10;

  TestServerMain testServerMain = new TestServerMain();

  void runTest(int port) {
    int count = 0;
    HttpClient httpClient = new HttpClient();
    void sendRequest() {
      httpClient.post("127.0.0.1", port, "/echo").then((request) {
        if (chunkedEncoding) {
          request.write(data.substring(0, 10));
          request.write(data.substring(10, data.length));
        } else {
          request.contentLength = data.length;
          request.write(data);
        }
        return request.close();
      }).then((response) {
        Expect.equals(HttpStatus.OK, response.statusCode);
        StringBuffer body = new StringBuffer();
        response.listen((data) => body.write(new String.fromCharCodes(data)),
            onDone: () {
          Expect.equals(data, body.toString());
          count++;
          if (count < kMessageCount) {
            sendRequest();
          } else {
            httpClient.close();
            testServerMain.close();
          }
        });
      });
    }

    sendRequest();
  }

  testServerMain.setServerStartedHandler(runTest);
  testServerMain.start(chunkedEncoding);
}

void test404() {
  TestServerMain testServerMain = new TestServerMain();
  testServerMain.setServerStartedHandler((int port) {
    HttpClient httpClient = new HttpClient();
    httpClient
        .get("127.0.0.1", port, "/thisisnotfound")
        .then((request) => request.close())
        .then((response) {
      Expect.equals(HttpStatus.NOT_FOUND, response.statusCode);
      var body = new StringBuffer();
      response.listen((data) => body.write(new String.fromCharCodes(data)),
          onDone: () {
        Expect.equals("Page not found", body.toString());
        httpClient.close();
        testServerMain.close();
      });
    });
  });
  testServerMain.start();
}

void testReasonPhrase() {
  TestServerMain testServerMain = new TestServerMain();
  testServerMain.setServerStartedHandler((int port) {
    HttpClient httpClient = new HttpClient();
    httpClient.get("127.0.0.1", port, "/reasonformoving").then((request) {
      request.followRedirects = false;
      return request.close();
    }).then((response) {
      Expect.equals(HttpStatus.MOVED_PERMANENTLY, response.statusCode);
      Expect.equals("Don't come looking here any more", response.reasonPhrase);
      response.listen((data) => Expect.fail("No data expected"), onDone: () {
        httpClient.close();
        testServerMain.close();
      });
    });
  });
  testServerMain.start();
}

void main() {
  testStartStop();
  testGET();
  testPOST(true);
  testPOST(false);
  test404();
  testReasonPhrase();
}
