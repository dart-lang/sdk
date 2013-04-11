// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "package:expect/expect.dart";
import "dart:isolate";
import "dart:io";

class IsolatedHttpServer {
  IsolatedHttpServer()
      : _statusPort = new ReceivePort(),
        _serverPort = null {
    _serverPort = spawnFunction(startIsolatedHttpServer);
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
    var command = new IsolatedHttpServerCommand.start();
    _serverPort.send(command, _statusPort.toSendPort());
  }

  void shutdown() {
    // Send server stop message to the server.
    _serverPort.send(new IsolatedHttpServerCommand.stop(),
                     _statusPort.toSendPort());
    _statusPort.close();
  }

  void chunkedEncoding() {
    // Send chunked encoding message to the server.
    _serverPort.send(
        new IsolatedHttpServerCommand.chunkedEncoding(),
        _statusPort.toSendPort());
  }

  ReceivePort _statusPort;  // Port for receiving messages from the server.
  SendPort _serverPort;  // Port for sending messages to the server.
  var _startedCallback;
}


class IsolatedHttpServerCommand {
  static const START = 0;
  static const STOP = 1;
  static const CHUNKED_ENCODING = 2;

  IsolatedHttpServerCommand.start() : _command = START;
  IsolatedHttpServerCommand.stop() : _command = STOP;
  IsolatedHttpServerCommand.chunkedEncoding() : _command = CHUNKED_ENCODING;

  bool get isStart => _command == START;
  bool get isStop => _command == STOP;
  bool get isChunkedEncoding => _command == CHUNKED_ENCODING;

  int _command;
}


class IsolatedHttpServerStatus {
  static const STARTED = 0;
  static const STOPPED = 1;
  static const ERROR = 2;

  IsolatedHttpServerStatus.started(this._port) : _state = STARTED;
  IsolatedHttpServerStatus.stopped() : _state = STOPPED;
  IsolatedHttpServerStatus.error() : _state = ERROR;

  bool get isStarted => _state == STARTED;
  bool get isStopped => _state == STOPPED;
  bool get isError => _state == ERROR;

  int get port => _port;

  int _state;
  int _port;
}


void startIsolatedHttpServer() {
  var server = new TestServer();
  server.init();
  port.receive(server.dispatch);
}

class TestServer {
  // Echo the request content back to the response.
  void _echoHandler(HttpRequest request) {
    var response = request.response;
    Expect.equals("POST", request.method);
    response.contentLength = request.contentLength;
    request.pipe(response);
  }

  // Return a 404.
  void _notFoundHandler(HttpRequest request) {
    var response = request.response;
    response.statusCode = HttpStatus.NOT_FOUND;
    response.headers.set("Content-Type", "text/html; charset=UTF-8");
    response.write("Page not found");
    response.close();
  }


  void init() {
    // Setup request handlers.
    _requestHandlers = new Map();
    _requestHandlers["/echo"] = _echoHandler;
  }

  void dispatch(message, SendPort replyTo) {
    if (message.isStart) {
      try {
        HttpServer.bind().then((server) {
          _server = server;
          _server.listen(_requestReceivedHandler);
          replyTo.send(
              new IsolatedHttpServerStatus.started(_server.port), null);
        });
      } catch (e) {
        replyTo.send(new IsolatedHttpServerStatus.error(), null);
      }
    } else if (message.isStop) {
      _server.close();
      port.close();
      replyTo.send(new IsolatedHttpServerStatus.stopped(), null);
    } else if (message.isChunkedEncoding) {
      _chunkedEncoding = true;
    }
  }

  void _requestReceivedHandler(HttpRequest request) {
    var requestHandler =_requestHandlers[request.uri.path];
    if (requestHandler != null) {
      requestHandler(request);
    } else {
      _notFoundHandler(request);
    }
  }

  HttpServer _server;  // HTTP server instance.
  Map _requestHandlers;
  bool _chunkedEncoding = false;
}

void testRead(bool chunkedEncoding) {
  String data = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  final int kMessageCount = 10;

  IsolatedHttpServer server = new IsolatedHttpServer();

  void runTest(int port) {
    int count = 0;
    HttpClient httpClient = new HttpClient();
    void sendRequest() {
      httpClient.post("127.0.0.1", port, "/echo")
          .then((request) {
            if (chunkedEncoding) {
              request.write(data.substring(0, 10));
              request.write(data.substring(10, data.length));
            } else {
              request.contentLength = data.length;
              request.add(data.codeUnits);
            }
            return request.close();
          })
          .then((response) {
            Expect.equals(HttpStatus.OK, response.statusCode);
            List<int> body = new List<int>();
            response.listen(
                body.addAll,
                onDone: () {
                  Expect.equals(data, new String.fromCharCodes(body));
                  count++;
                  if (count < kMessageCount) {
                    sendRequest();
                  } else {
                    httpClient.close();
                    server.shutdown();
                  }
                });
          });
    }
    sendRequest();
  }

  server.setServerStartedHandler(runTest);
  if (chunkedEncoding) {
    server.chunkedEncoding();
  }
  server.start();
}

void main() {
  testRead(true);
  testRead(false);
}
