// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

#import("dart:isolate");
#import("dart:io");

void test1(int totalConnections) {
  // Server which just closes immediately.
  HttpServer server = new HttpServer();
  server.listen("127.0.0.1", 0, backlog: totalConnections);
  server.defaultRequestHandler = (HttpRequest request, HttpResponse response) {
    response.outputStream.close();
  };

  int count = 0;
  HttpClient client = new HttpClient();
  for (int i = 0; i < totalConnections; i++) {
    HttpClientConnection conn = client.get("127.0.0.1", server.port, "/");
    conn.onRequest = (HttpClientRequest request) {
      request.outputStream.close();
    };
    conn.onResponse = (HttpClientResponse response) {
      count++;
      if (count == totalConnections) {
        client.shutdown();
        server.close();
      }
    };
  }
}


void test2(int totalConnections) {
  // Server which responds without waiting for request body.
  HttpServer server = new HttpServer();
  server.listen("127.0.0.1", 0, backlog: totalConnections);
  server.defaultRequestHandler = (HttpRequest request, HttpResponse response) {
    response.outputStream.writeString("!dlrow ,olleH");
    response.outputStream.close();
  };

  int count = 0;
  HttpClient client = new HttpClient();
  for (int i = 0; i < totalConnections; i++) {
    HttpClientConnection conn = client.get("127.0.0.1", server.port, "/");
    conn.onRequest = (HttpClientRequest request) {
      request.contentLength = -1;
      request.outputStream.writeString("Hello, world!");
      request.outputStream.close();
    };
    conn.onResponse = (HttpClientResponse response) {
      count++;
      if (count == totalConnections) {
        client.shutdown();
        server.close();
      }
    };
  }
}


void test3(int totalConnections) {
  // Server which responds when request body has been received.
  HttpServer server = new HttpServer();
  server.listen("127.0.0.1", 0, backlog: totalConnections);
  server.defaultRequestHandler = (HttpRequest request, HttpResponse response) {
    request.inputStream.onData = () {
      request.inputStream.read();
    };
    request.inputStream.onClosed = () {
      response.outputStream.writeString("!dlrow ,olleH");
      response.outputStream.close();
    };
  };

  int count = 0;
  HttpClient client = new HttpClient();
  for (int i = 0; i < totalConnections; i++) {
    HttpClientConnection conn = client.get("127.0.0.1", server.port, "/");
    conn.onRequest = (HttpClientRequest request) {
      request.contentLength = -1;
      request.outputStream.writeString("Hello, world!");
      request.outputStream.close();
    };
    conn.onResponse = (HttpClientResponse response) {
      count++;
      if (count == totalConnections) {
        client.shutdown();
        server.close();
      }
    };
  }
}


void test4() {
  var server = new HttpServer();
  server.listen("127.0.0.1", 0);
  server.defaultRequestHandler = (var request, var response) {
    request.inputStream.onClosed = () {
      new Timer.repeating(100, (timer) {
        if (server.connectionsInfo().total == 0) {
          server.close();
          timer.cancel();
        }
      });
      response.outputStream.close();
    };
  };

  var client= new HttpClient();
  var conn = client.get("127.0.0.1", server.port, "/");
  conn.onResponse = (var response) {
    response.inputStream.onClosed = () {
      client.shutdown();
    };
  };
}


void test5(int totalConnections) {
  var server = new HttpServer();
  server.listen("127.0.0.1", 0, backlog: totalConnections);
  server.defaultRequestHandler = (var request, var response) {
    request.inputStream.onClosed = () {
      response.outputStream.close();
    };
  };
  server.onError = (e) => { };

  // Create a number of client requests and keep then active. Then
  // close the client and wait for the server to lose all active
  // connections.
  var client= new HttpClient();
  for (int i = 0; i < totalConnections; i++) {
    var conn = client.post("127.0.0.1", server.port, "/");
    conn.onRequest = (req) { req.outputStream.write([0]); };
  }
  bool clientClosed = false;
  new Timer.repeating(100, (timer) {
    if (!clientClosed) {
      if (server.connectionsInfo().total == totalConnections) {
        clientClosed = true;
        client.shutdown();
      }
    } else {
      if (server.connectionsInfo().total == 0) {
        server.close();
        timer.cancel();
      }
    }
  });
}


void main() {
  test1(1);
  test1(10);
  test2(1);
  test2(10);
  test3(1);
  test3(10);
  test4();
  test5(1);
  test5(10);
}
