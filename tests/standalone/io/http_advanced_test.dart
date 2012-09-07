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
    _serverPort = spawnFunction(startTestServer);
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


void startTestServer() {
  var server = new TestServer();
  server.init();
  port.receive(server.dispatch);
}


class TestServer {
  // Return a 404.
  void _notFoundHandler(HttpRequest request, HttpResponse response) {
    response.statusCode = HttpStatus.NOT_FOUND;
    response.headers.set("Content-Type", "text/html; charset=UTF-8");
    response.outputStream.writeString("Page not found");
    response.outputStream.close();
  }

  // Check the "Host" header.
  void _hostHandler(HttpRequest request, HttpResponse response) {
    Expect.equals(1, request.headers["Host"].length);
    Expect.equals("www.dartlang.org:1234", request.headers["Host"][0]);
    Expect.equals("www.dartlang.org", request.headers.host);
    Expect.equals(1234, request.headers.port);
    response.statusCode = HttpStatus.OK;
    response.outputStream.close();
  }

  // Set the "Expires" header using the expires property.
  void _expires1Handler(HttpRequest request, HttpResponse response) {
    Date date = new Date(1999, Date.JUN, 11, 18, 46, 53, 0, isUtc: true);
    response.headers.expires = date;
    Expect.equals(date, response.headers.expires);
    response.outputStream.close();
  }

  // Set the "Expires" header.
  void _expires2Handler(HttpRequest request, HttpResponse response) {
    response.headers.set("Expires", "Fri, 11 Jun 1999 18:46:53 GMT");
    Date date = new Date(1999, Date.JUN, 11, 18, 46, 53, 0, isUtc: true);
    Expect.equals(date, response.headers.expires);
    response.outputStream.close();
  }

  void _contentType1Handler(HttpRequest request, HttpResponse response) {
    Expect.equals("text/html", request.headers.contentType.value);
    Expect.equals("text", request.headers.contentType.primaryType);
    Expect.equals("html", request.headers.contentType.subType);
    Expect.equals("utf-8", request.headers.contentType.parameters["charset"]);

    ContentType contentType = new ContentType("text", "html");
    contentType.parameters["charset"] = "utf-8";
    response.headers.contentType = contentType;
    response.outputStream.close();
  }

  void _contentType2Handler(HttpRequest request, HttpResponse response) {
    Expect.equals("text/html", request.headers.contentType.value);
    Expect.equals("text", request.headers.contentType.primaryType);
    Expect.equals("html", request.headers.contentType.subType);
    Expect.equals("utf-8", request.headers.contentType.parameters["charset"]);

    response.headers.set(HttpHeaders.CONTENT_TYPE,
                         "text/html;  charset = utf-8");
    response.outputStream.close();
  }

  void _cookie1Handler(HttpRequest request, HttpResponse response) {
    // No cookies passed with this request.
    Expect.equals(0, request.cookies.length);

    Cookie cookie1 = new Cookie("name1", "value1");
    Date date = new Date(2014, Date.JAN, 5, 23, 59, 59, 0, isUtc: true);
    cookie1.expires = date;
    cookie1.domain = "www.example.com";
    cookie1.httpOnly = true;
    response.cookies.add(cookie1);
    Cookie cookie2 = new Cookie("name2", "value2");
    cookie2.maxAge = 100;
    cookie2.domain = ".example.com";
    cookie2.path = "/shop";
    response.cookies.add(cookie2);
    response.outputStream.close();
  }

  void _cookie2Handler(HttpRequest request, HttpResponse response) {
    // Two cookies passed with this request.
    Expect.equals(2, request.cookies.length);
    response.outputStream.close();
  }

  void init() {
    // Setup request handlers.
    _requestHandlers = new Map();
    _requestHandlers["/host"] =
        (HttpRequest request, HttpResponse response) {
          _hostHandler(request, response);
        };
    _requestHandlers["/expires1"] =
        (HttpRequest request, HttpResponse response) {
          _expires1Handler(request, response);
        };
    _requestHandlers["/expires2"] =
        (HttpRequest request, HttpResponse response) {
          _expires2Handler(request, response);
        };
    _requestHandlers["/contenttype1"] =
        (HttpRequest request, HttpResponse response) {
          _contentType1Handler(request, response);
        };
    _requestHandlers["/contenttype2"] =
        (HttpRequest request, HttpResponse response) {
          _contentType2Handler(request, response);
        };
    _requestHandlers["/cookie1"] =
        (HttpRequest request, HttpResponse response) {
          _cookie1Handler(request, response);
        };
    _requestHandlers["/cookie2"] =
        (HttpRequest request, HttpResponse response) {
          _cookie2Handler(request, response);
        };
  }

  void dispatch(message, replyTo) {
    if (message.isStart) {
      _server = new HttpServer();
      try {
        _server.listen("127.0.0.1", 0);
        _server.defaultRequestHandler = (HttpRequest req, HttpResponse rsp) {
          _requestReceivedHandler(req, rsp);
        };
        replyTo.send(new TestServerStatus.started(_server.port), null);
      } catch (e) {
        replyTo.send(new TestServerStatus.error(), null);
      }
    } else if (message.isStop) {
      _server.close();
      port.close();
      replyTo.send(new TestServerStatus.stopped(), null);
    } else if (message.isChunkedEncoding) {
      _chunkedEncoding = true;
    }
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

void testHost() {
  TestServerMain testServerMain = new TestServerMain();
  testServerMain.setServerStartedHandler((int port) {
    HttpClient httpClient = new HttpClient();
    HttpClientConnection conn =
        httpClient.get("127.0.0.1", port, "/host");
    conn.onRequest = (HttpClientRequest request) {
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
      request.outputStream.close();
    };
    conn.onResponse = (HttpClientResponse response) {
      Expect.equals(HttpStatus.OK, response.statusCode);
      httpClient.shutdown();
      testServerMain.shutdown();
    };
  });
  testServerMain.start();
}

void testExpires() {
  TestServerMain testServerMain = new TestServerMain();
  testServerMain.setServerStartedHandler((int port) {
    int responses = 0;
    HttpClient httpClient = new HttpClient();

    void processResponse(HttpClientResponse response) {
      Expect.equals(HttpStatus.OK, response.statusCode);
      Expect.equals("Fri, 11 Jun 1999 18:46:53 GMT",
                    response.headers["expires"][0]);
      Expect.equals(new Date(1999, Date.JUN, 11, 18, 46, 53, 0, isUtc: true),
                    response.headers.expires);
      responses++;
      if (responses == 2) {
        httpClient.shutdown();
        testServerMain.shutdown();
      }
    }

    HttpClientConnection conn1 = httpClient.get("127.0.0.1", port, "/expires1");
    conn1.onResponse = (HttpClientResponse response) {
      processResponse(response);
    };
    HttpClientConnection conn2 = httpClient.get("127.0.0.1", port, "/expires2");
    conn2.onResponse = (HttpClientResponse response) {
      processResponse(response);
    };
  });
  testServerMain.start();
}

void testContentType() {
  TestServerMain testServerMain = new TestServerMain();
  testServerMain.setServerStartedHandler((int port) {
    int responses = 0;
    HttpClient httpClient = new HttpClient();

    void processResponse(HttpClientResponse response) {
      Expect.equals(HttpStatus.OK, response.statusCode);
      Expect.equals("text/html; charset=utf-8",
                    response.headers.contentType.toString());
      Expect.equals("text/html", response.headers.contentType.value);
      Expect.equals("text", response.headers.contentType.primaryType);
      Expect.equals("html", response.headers.contentType.subType);
      Expect.equals("utf-8",
                    response.headers.contentType.parameters["charset"]);
      responses++;
      if (responses == 2) {
        httpClient.shutdown();
        testServerMain.shutdown();
      }
    }

    HttpClientConnection conn1 =
        httpClient.get("127.0.0.1", port, "/contenttype1");
    conn1.onRequest = (HttpClientRequest request) {
      ContentType contentType = new ContentType();
      contentType.value = "text/html";
      contentType.parameters["charset"] = "utf-8";
      request.headers.contentType = contentType;
      request.outputStream.close();
    };
    conn1.onResponse = (HttpClientResponse response) {
      processResponse(response);
    };
    HttpClientConnection conn2 =
        httpClient.get("127.0.0.1", port, "/contenttype2");
    conn2.onRequest = (HttpClientRequest request) {
      request.headers.set(HttpHeaders.CONTENT_TYPE,
                          "text/html;  charset = utf-8");
      request.outputStream.close();
    };
    conn2.onResponse = (HttpClientResponse response) {
      processResponse(response);
    };
  });
  testServerMain.start();
}

void testCookies() {
  TestServerMain testServerMain = new TestServerMain();
  testServerMain.setServerStartedHandler((int port) {
    int responses = 0;
    HttpClient httpClient = new HttpClient();

    HttpClientConnection conn1 =
        httpClient.get("127.0.0.1", port, "/cookie1");
    conn1.onResponse = (HttpClientResponse response) {
      Expect.equals(2, response.cookies.length);
      response.cookies.forEach((cookie) {
        if (cookie.name == "name1") {
          Expect.equals("value1", cookie.value);
          Date date = new Date(2014, Date.JAN, 5, 23, 59, 59, 0, isUtc: true);
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
      HttpClientConnection conn2 =
          httpClient.get("127.0.0.1", port, "/cookie2");
      conn2.onRequest = (HttpClientRequest request) {
        request.cookies.add(response.cookies[0]);
        request.cookies.add(response.cookies[1]);
        request.outputStream.close();
      };
      conn2.onResponse = (HttpClientResponse ignored) {
        httpClient.shutdown();
        testServerMain.shutdown();
      };
    };
  });
  testServerMain.start();
}

void main() {
  testHost();
  testExpires();
  testContentType();
  testCookies();
}
