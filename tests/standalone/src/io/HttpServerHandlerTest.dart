// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

#import("dart:io");
#import("dart:isolate");

class Handler1 {
  void onRequest(HttpRequest request, HttpResponse response) {
    response.outputStream.writeString("Handler 1");
    response.outputStream.close();
  }
}

class Handler2 {
  void onRequest(HttpRequest request, HttpResponse response) {
    response.outputStream.writeString("Handler 2");
    response.outputStream.close();
  }
}

class French404Handler {
  void onRequest(HttpRequest request, HttpResponse response) {
    response.statusCode = HttpStatus.NOT_FOUND;
    response.reasonPhrase = "Non Trouvé";
    response.outputStream.close();
  }
}

class Server {
  Server() {
    server = new HttpServer();
    server.listen("127.0.0.1", 0);
    port = server.port;
    server.onError = (e) {
      Expect.fail("No server errors expected: $e");
    };
  }

  void addHandler(Function matcher, handler) {
    if (handler is Function) {
      server.addRequestHandler(matcher, handler);
    } else {
      server.addRequestHandler(matcher, handler.onRequest);
    }
  }

  void set defaultHandler(handler) {
    if (handler is Function) {
      server.defaultRequestHandler = handler;
    } else {
      server.defaultRequestHandler = handler.onRequest;
    }
  }

  void close() {
    server.close();
  }

  int port;
  HttpServer server;
}

void testDefaultHandler() {
  Server server = new Server();
  HttpClient client = new HttpClient();

  void done() {
    server.close();
    client.shutdown();
  }

  void error(e) {
    Expect.fail("No client error expected $e");
    done();
  };

  void german404(HttpRequest request, HttpResponse response) {
    response.statusCode = HttpStatus.NOT_FOUND;
    response.reasonPhrase = "Nicht Gefunden";
    response.outputStream.close();
  }

  // Test the standard default handler.
  HttpClientConnection conn = client.get("127.0.0.1", server.port, "/");
  conn.onResponse = (HttpClientResponse response) {
    Expect.equals(HttpStatus.NOT_FOUND, response.statusCode);
    Expect.equals("Not Found", response.reasonPhrase);

    // Install a default handler.
    server.defaultHandler = german404;
    HttpClientConnection conn = client.get("127.0.0.1", server.port, "/");
    conn.onResponse = (HttpClientResponse response) {
      Expect.equals(HttpStatus.NOT_FOUND, response.statusCode);
      Expect.equals("Nicht Gefunden", response.reasonPhrase);

      // Install another default handler.
      server.defaultHandler = new French404Handler();
      HttpClientConnection conn = client.get("127.0.0.1", server.port, "/");
      conn.onResponse = (HttpClientResponse response) {
        Expect.equals(HttpStatus.NOT_FOUND, response.statusCode);
        Expect.equals("Non Trouvé", response.reasonPhrase);
        done();
      };
      conn.onError = error;
    };
    conn.onError = error;
  };
  conn.onError = error;
}

void testHandlers() {
  Server server = new Server();
  HttpClient client = new HttpClient();
  int requests = 0;
  int doneCount = 0;

  void done() {
    doneCount++;
    if (doneCount == requests) {
      server.close();
      client.shutdown();
    }
  }

  void error(e) {
    Expect.fail("No client error expected $e");
    done();
  };

  void handler3(HttpRequest request, HttpResponse response) {
    response.statusCode = HttpStatus.OK;
    response.outputStream.writeString("Handler 3");
    response.outputStream.close();
  }

  void handler4(HttpRequest request, HttpResponse response) {
    response.statusCode = HttpStatus.OK;
    response.outputStream.writeString("Handler 4");
    response.outputStream.close();
  }

  void checkBody(HttpClientResponse response, String expected) {
    StringBuffer sb = new StringBuffer();
    StringInputStream stream = new StringInputStream(response.inputStream);
    stream.onData = () {
      sb.add(stream.read());
    };
    stream.onClosed = () {
      Expect.equals(expected, sb.toString());
      done();
    };
  }

  server.addHandler(
      (request) => request.path.startsWith("/xxx/yyy/"), new Handler1());
  server.addHandler(
      (request) => new RegExp("^/xxx").hasMatch(request.path), new Handler2());
  server.addHandler(
      (request) => request.path == "/yyy.dat", handler3);
  server.addHandler(
      (request) => request.path.endsWith(".dat"), handler4);

  void testRequest(String path, int expectedStatus, String expectedBody) {
    HttpClientConnection conn =
        client.get("127.0.0.1", server.port, path);
    requests++;
    conn.onResponse = (HttpClientResponse response) {
      Expect.equals(expectedStatus, response.statusCode);
      checkBody(response, expectedBody);
    };
    conn.onError = error;
  }

  testRequest("/xxx/yyy/zzz", HttpStatus.OK, "Handler 1");
  testRequest("/xxx/zzz", HttpStatus.OK, "Handler 2");
  testRequest("/yyy.dat", HttpStatus.OK, "Handler 3");
  testRequest("/abc.dat", HttpStatus.OK, "Handler 4");
  testRequest("/abcdat", HttpStatus.NOT_FOUND, "");
  testRequest("/xxx.dat", HttpStatus.OK, "Handler 2");
}

main() {
  testDefaultHandler();
  testHandlers();
}
