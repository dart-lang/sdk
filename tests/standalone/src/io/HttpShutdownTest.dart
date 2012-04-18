// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

#import("dart:isolate");
#import("dart:io");

void test1(int totalConnections) {
  // Server which just closes immediately.
  HttpServer server = new HttpServer();
  server.listen("127.0.0.1", 0, totalConnections);
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
  server.listen("127.0.0.1", 0, totalConnections);
  server.defaultRequestHandler = (HttpRequest request, HttpResponse response) {
    response.outputStream.writeString("!dlrow ,olleH");
    response.outputStream.close();
  };

  int count = 0;
  HttpClient client = new HttpClient();
  for (int i = 0; i < totalConnections; i++) {
    HttpClientConnection conn = client.get("127.0.0.1", server.port, "/");
    conn.onRequest = (HttpClientRequest request) {
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
  server.listen("127.0.0.1", 0, totalConnections);
  server.defaultRequestHandler = (HttpRequest request, HttpResponse response) {
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


void main() {
  test1(1);
  test1(10);
  test2(1);
  test2(10);
  test3(1);
  test3(10);
}
