// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

class IsolatedHttpServer {
  IsolatedHttpServer()
      : _statusPort = new ReceivePort(),
        _serverPort = null;

  void setServerStartedHandler(void startedCallback(int port)) {
    _startedCallback = startedCallback;
  }

  void start() {
    ReceivePort receivePort = new ReceivePort();
    var remote = Isolate.spawn(startIsolatedHttpServer, receivePort.sendPort);
    receivePort.first.then((port) {
      _serverPort = port;

      // Send server start message to the server.
      var command = new IsolatedHttpServerCommand.start();
      port.send([command, _statusPort.sendPort]);
    });

    // Handle status messages from the server.
    _statusPort.listen((var status) {
      if (status.isStarted) {
        _startedCallback(status.port);
      }
    });
  }

  void shutdown() {
    // Send server stop message to the server.
    _serverPort
        .send([new IsolatedHttpServerCommand.stop(), _statusPort.sendPort]);
    _statusPort.close();
  }

  void chunkedEncoding() {
    // Send chunked encoding message to the server.
    _serverPort.send([
      new IsolatedHttpServerCommand.chunkedEncoding(),
      _statusPort.sendPort
    ]);
  }

  ReceivePort _statusPort; // Port for receiving messages from the server.
  SendPort _serverPort; // Port for sending messages to the server.
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

void startIsolatedHttpServer(Object replyToObj) {
  SendPort replyTo = replyToObj;
  var server = new TestServer();
  server.init();
  replyTo.send(server.dispatchSendPort);
}

class TestServer {
  // Return a 404.
  void _notFoundHandler(HttpRequest request) {
    var response = request.response;
    response.statusCode = HttpStatus.NOT_FOUND;
    response.headers.set("Content-Type", "text/html; charset=UTF-8");
    response.write("Page not found");
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

  // Set the "Expires" header using the expires property.
  void _expires1Handler(HttpRequest request) {
    var response = request.response;
    DateTime date = new DateTime.utc(1999, DateTime.june, 11, 18, 46, 53, 0);
    response.headers.expires = date;
    Expect.equals(date, response.headers.expires);
    response.close();
  }

  // Set the "Expires" header.
  void _expires2Handler(HttpRequest request) {
    var response = request.response;
    response.headers.set("Expires", "Fri, 11 Jun 1999 18:46:53 GMT");
    DateTime date = new DateTime.utc(1999, DateTime.june, 11, 18, 46, 53, 0);
    Expect.equals(date, response.headers.expires);
    response.close();
  }

  void _contentType1Handler(HttpRequest request) {
    var response = request.response;
    Expect.equals("text/html", request.headers.contentType.value);
    Expect.equals("text", request.headers.contentType.primaryType);
    Expect.equals("html", request.headers.contentType.subType);
    Expect.equals("utf-8", request.headers.contentType.parameters["charset"]);

    ContentType contentType = new ContentType("text", "html", charset: "utf-8");
    response.headers.contentType = contentType;
    response.close();
  }

  void _contentType2Handler(HttpRequest request) {
    var response = request.response;
    Expect.equals("text/html", request.headers.contentType.value);
    Expect.equals("text", request.headers.contentType.primaryType);
    Expect.equals("html", request.headers.contentType.subType);
    Expect.equals("utf-8", request.headers.contentType.parameters["charset"]);

    response.headers
        .set(HttpHeaders.CONTENT_TYPE, "text/html;  charset = utf-8");
    response.close();
  }

  void _cookie1Handler(HttpRequest request) {
    var response = request.response;

    // No cookies passed with this request.
    Expect.equals(0, request.cookies.length);

    Cookie cookie1 = new Cookie("name1", "value1");
    DateTime date = new DateTime.utc(2014, DateTime.january, 5, 23, 59, 59, 0);
    cookie1.expires = date;
    cookie1.domain = "www.example.com";
    cookie1.httpOnly = true;
    response.cookies.add(cookie1);
    Cookie cookie2 = new Cookie("name2", "value2");
    cookie2.maxAge = 100;
    cookie2.domain = ".example.com";
    cookie2.path = "/shop";
    response.cookies.add(cookie2);
    response.close();
  }

  void _cookie2Handler(HttpRequest request) {
    var response = request.response;

    // Two cookies passed with this request.
    Expect.equals(2, request.cookies.length);
    response.close();
  }

  void init() {
    // Setup request handlers.
    _requestHandlers = new Map();
    _requestHandlers["/host"] = _hostHandler;
    _requestHandlers["/expires1"] = _expires1Handler;
    _requestHandlers["/expires2"] = _expires2Handler;
    _requestHandlers["/contenttype1"] = _contentType1Handler;
    _requestHandlers["/contenttype2"] = _contentType2Handler;
    _requestHandlers["/cookie1"] = _cookie1Handler;
    _requestHandlers["/cookie2"] = _cookie2Handler;
    _dispatchPort = new ReceivePort();
    _dispatchPort.listen(dispatch);
  }

  SendPort get dispatchSendPort => _dispatchPort.sendPort;

  void dispatch(message) {
    IsolatedHttpServerCommand command = message[0];
    SendPort replyTo = message[1];
    if (command.isStart) {
      try {
        HttpServer.bind("127.0.0.1", 0).then((server) {
          _server = server;
          _server.listen(_requestReceivedHandler);
          replyTo.send(new IsolatedHttpServerStatus.started(_server.port));
        });
      } catch (e) {
        replyTo.send(new IsolatedHttpServerStatus.error());
      }
    } else if (command.isStop) {
      _server.close();
      _dispatchPort.close();
      replyTo.send(new IsolatedHttpServerStatus.stopped());
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

Future testHost() {
  Completer completer = new Completer();
  IsolatedHttpServer server = new IsolatedHttpServer();
  server.setServerStartedHandler((int port) {
    HttpClient httpClient = new HttpClient();
    httpClient.get("127.0.0.1", port, "/host").then((request) {
      Expect.equals("127.0.0.1:$port", request.headers["host"][0]);
      request.headers.host = "www.dartlang.com";
      Expect.equals("www.dartlang.com:$port", request.headers["host"][0]);
      Expect.equals("www.dartlang.com", request.headers.host);
      Expect.equals(port, request.headers.port);
      request.headers.port = 1234;
      Expect.equals("www.dartlang.com:1234", request.headers["host"][0]);
      Expect.equals(1234, request.headers.port);
      request.headers.port = HttpClient.DEFAULT_HTTP_PORT;
      Expect.equals(HttpClient.DEFAULT_HTTP_PORT, request.headers.port);
      Expect.equals("www.dartlang.com", request.headers["host"][0]);
      request.headers.set("Host", "www.dartlang.org");
      Expect.equals("www.dartlang.org", request.headers.host);
      Expect.equals(HttpClient.DEFAULT_HTTP_PORT, request.headers.port);
      request.headers.set("Host", "www.dartlang.org:");
      Expect.equals("www.dartlang.org", request.headers.host);
      Expect.equals(HttpClient.DEFAULT_HTTP_PORT, request.headers.port);
      request.headers.set("Host", "www.dartlang.org:1234");
      Expect.equals("www.dartlang.org", request.headers.host);
      Expect.equals(1234, request.headers.port);
      return request.close();
    }).then((response) {
      Expect.equals(HttpStatus.OK, response.statusCode);
      response.listen((_) {}, onDone: () {
        httpClient.close();
        server.shutdown();
        completer.complete(true);
      });
    });
  });
  server.start();
  return completer.future;
}

Future testExpires() {
  Completer completer = new Completer();
  IsolatedHttpServer server = new IsolatedHttpServer();
  server.setServerStartedHandler((int port) {
    int responses = 0;
    HttpClient httpClient = new HttpClient();

    void processResponse(HttpClientResponse response) {
      Expect.equals(HttpStatus.OK, response.statusCode);
      Expect.equals(
          "Fri, 11 Jun 1999 18:46:53 GMT", response.headers["expires"][0]);
      Expect.equals(new DateTime.utc(1999, DateTime.june, 11, 18, 46, 53, 0),
          response.headers.expires);
      response.listen((_) {}, onDone: () {
        responses++;
        if (responses == 2) {
          httpClient.close();
          server.shutdown();
          completer.complete(true);
        }
      });
    }

    httpClient
        .get("127.0.0.1", port, "/expires1")
        .then((request) => request.close())
        .then(processResponse);
    httpClient
        .get("127.0.0.1", port, "/expires2")
        .then((request) => request.close())
        .then(processResponse);
  });
  server.start();
  return completer.future;
}

Future testContentType() {
  Completer completer = new Completer();
  IsolatedHttpServer server = new IsolatedHttpServer();
  server.setServerStartedHandler((int port) {
    int responses = 0;
    HttpClient httpClient = new HttpClient();

    void processResponse(HttpClientResponse response) {
      Expect.equals(HttpStatus.OK, response.statusCode);
      Expect.equals(
          "text/html; charset=utf-8", response.headers.contentType.toString());
      Expect.equals("text/html", response.headers.contentType.value);
      Expect.equals("text", response.headers.contentType.primaryType);
      Expect.equals("html", response.headers.contentType.subType);
      Expect.equals(
          "utf-8", response.headers.contentType.parameters["charset"]);
      response.listen((_) {}, onDone: () {
        responses++;
        if (responses == 2) {
          httpClient.close();
          server.shutdown();
          completer.complete(true);
        }
      });
    }

    httpClient.get("127.0.0.1", port, "/contenttype1").then((request) {
      request.headers.contentType =
          new ContentType("text", "html", charset: "utf-8");
      return request.close();
    }).then(processResponse);

    httpClient.get("127.0.0.1", port, "/contenttype2").then((request) {
      request.headers
          .set(HttpHeaders.CONTENT_TYPE, "text/html;  charset = utf-8");
      return request.close();
    }).then(processResponse);
  });
  server.start();
  return completer.future;
}

Future testCookies() {
  Completer completer = new Completer();
  IsolatedHttpServer server = new IsolatedHttpServer();
  server.setServerStartedHandler((int port) {
    int responses = 0;
    HttpClient httpClient = new HttpClient();

    httpClient
        .get("127.0.0.1", port, "/cookie1")
        .then((request) => request.close())
        .then((response) {
      Expect.equals(2, response.cookies.length);
      response.cookies.forEach((cookie) {
        if (cookie.name == "name1") {
          Expect.equals("value1", cookie.value);
          DateTime date =
              new DateTime.utc(2014, DateTime.january, 5, 23, 59, 59, 0);
          Expect.equals(date, cookie.expires);
          Expect.equals("www.example.com", cookie.domain);
          Expect.isTrue(cookie.httpOnly);
        } else if (cookie.name == "name2") {
          Expect.equals("value2", cookie.value);
          Expect.equals(100, cookie.maxAge);
          Expect.equals(".example.com", cookie.domain);
          Expect.equals("/shop", cookie.path);
        } else {
          Expect.fail("Unexpected cookie");
        }
      });

      response.listen((_) {}, onDone: () {
        httpClient.get("127.0.0.1", port, "/cookie2").then((request) {
          request.cookies.add(response.cookies[0]);
          request.cookies.add(response.cookies[1]);
          return request.close();
        }).then((response) {
          response.listen((_) {}, onDone: () {
            httpClient.close();
            server.shutdown();
            completer.complete(true);
          });
        });
      });
    });
  });
  server.start();
  return completer.future;
}

void main() {
  testHost().then((_) {
    return testExpires().then((_) {
      return testContentType().then((_) {
        return testCookies();
      });
    });
  });
}
