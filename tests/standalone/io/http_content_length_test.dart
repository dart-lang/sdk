// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";
import "dart:io";

void testNoBody(int totalConnections, bool explicitContentLength) {
  HttpServer server = new HttpServer();
  server.onError = (e) => Expect.fail("Unexpected error $e");
  server.listen("127.0.0.1", 0, backlog: totalConnections);
  server.defaultRequestHandler = (HttpRequest request, HttpResponse response) {
    Expect.equals("0", request.headers.value('content-length'));
    Expect.equals(0, request.contentLength);
    response.contentLength = 0;
    OutputStream stream = response.outputStream;
    Expect.throws(() => stream.writeString("x"), (e) => e is HttpException);
    stream.close();
    Expect.throws(() => stream.writeString("x"), (e) => e is HttpException);
  };

  int count = 0;
  HttpClient client = new HttpClient();
  for (int i = 0; i < totalConnections; i++) {
    HttpClientConnection conn = client.get("127.0.0.1", server.port, "/");
    conn.onError = (e) => Expect.fail("Unexpected error $e");
    conn.onRequest = (HttpClientRequest request) {
      OutputStream stream = request.outputStream;
      if (explicitContentLength) {
        request.contentLength = 0;
        Expect.throws(() => stream.writeString("x"), (e) => e is HttpException);
      }
      stream.close();
      Expect.throws(() => stream.writeString("x"), (e) => e is HttpException);
    };
    conn.onResponse = (HttpClientResponse response) {
      Expect.equals("0", response.headers.value('content-length'));
      Expect.equals(0, response.contentLength);
      response.inputStream.onData = response.inputStream.read;
      response.inputStream.onClosed = () {
        if (++count == totalConnections) {
          client.shutdown();
          server.close();
        }
      };
    };
  }
}

void testBody(int totalConnections, bool useHeader) {
  HttpServer server = new HttpServer();
  server.onError = (e) => Expect.fail("Unexpected error $e");
  server.listen("127.0.0.1", 0, backlog: totalConnections);
  server.defaultRequestHandler = (HttpRequest request, HttpResponse response) {
    Expect.equals("2", request.headers.value('content-length'));
    Expect.equals(2, request.contentLength);
    if (useHeader) {
      response.contentLength = 2;
    } else {
      response.headers.set("content-length", 2);
    }
    request.inputStream.onData = request.inputStream.read;
    request.inputStream.onClosed = () {
      OutputStream stream = response.outputStream;
      stream.writeString("x");
      Expect.throws(() => response.contentLength = 3, (e) => e is HttpException);
      stream.writeString("x");
      Expect.throws(() => stream.writeString("x"), (e) => e is HttpException);
      stream.close();
      Expect.throws(() => stream.writeString("x"), (e) => e is HttpException);
    };
  };

  int count = 0;
  HttpClient client = new HttpClient();
  for (int i = 0; i < totalConnections; i++) {
    HttpClientConnection conn = client.get("127.0.0.1", server.port, "/");
    conn.onError = (e) => Expect.fail("Unexpected error $e");
    conn.onRequest = (HttpClientRequest request) {
      if (useHeader) {
        request.contentLength = 2;
      } else {
        request.headers.add(HttpHeaders.CONTENT_LENGTH, "7");
        request.headers.add(HttpHeaders.CONTENT_LENGTH, "2");
      }
      OutputStream stream = request.outputStream;
      stream.writeString("x");
      Expect.throws(() => request.contentLength = 3, (e) => e is HttpException);
      stream.writeString("x");
      Expect.throws(() => stream.writeString("x"), (e) => e is HttpException);
      stream.close();
      Expect.throws(() => stream.writeString("x"), (e) => e is HttpException);
    };
    conn.onResponse = (HttpClientResponse response) {
      Expect.equals("2", response.headers.value('content-length'));
      Expect.equals(2, response.contentLength);
      response.inputStream.onData = response.inputStream.read;
      response.inputStream.onClosed = () {
        if (++count == totalConnections) {
          client.shutdown();
          server.close();
        }
      };
    };
  }
}

void testBodyChunked(int totalConnections, bool useHeader) {
  HttpServer server = new HttpServer();
  server.onError = (e) => Expect.fail("Unexpected error $e");
  server.listen("127.0.0.1", 0, backlog: totalConnections);
  server.defaultRequestHandler = (HttpRequest request, HttpResponse response) {
    Expect.isNull(request.headers.value('content-length'));
    Expect.equals(-1, request.contentLength);
    if (useHeader) {
      response.contentLength = 2;
      response.headers.chunkedTransferEncoding = true;
    } else {
      response.headers.set("content-length", 2);
      response.headers.set("transfer-encoding", "chunked");
    }
    request.inputStream.onData = request.inputStream.read;
    request.inputStream.onClosed = () {
      OutputStream stream = response.outputStream;
      stream.writeString("x");
      Expect.throws(() => response.headers.chunkedTransferEncoding = false,
                    (e) => e is HttpException);
      stream.writeString("x");
      stream.writeString("x");
      stream.close();
      Expect.throws(() => stream.writeString("x"), (e) => e is HttpException);
    };
  };

  int count = 0;
  HttpClient client = new HttpClient();
  for (int i = 0; i < totalConnections; i++) {
    HttpClientConnection conn = client.get("127.0.0.1", server.port, "/");
    conn.onError = (e) => Expect.fail("Unexpected error $e");
    conn.onRequest = (HttpClientRequest request) {
      if (useHeader) {
        request.contentLength = 2;
        request.headers.chunkedTransferEncoding = true;
      } else {
        request.headers.add(HttpHeaders.CONTENT_LENGTH, "2");
        request.headers.set(HttpHeaders.TRANSFER_ENCODING, "chunked");
      }
      OutputStream stream = request.outputStream;
      stream.writeString("x");
      Expect.throws(() => request.headers.chunkedTransferEncoding = false,
                    (e) => e is HttpException);
      stream.writeString("x");
      stream.writeString("x");
      stream.close();
      Expect.throws(() => stream.writeString("x"), (e) => e is HttpException);
    };
    conn.onResponse = (HttpClientResponse response) {
      Expect.isNull(response.headers.value('content-length'));
      Expect.equals(-1, response.contentLength);
      response.inputStream.onData = response.inputStream.read;
      response.inputStream.onClosed = () {
        if (++count == totalConnections) {
          client.shutdown();
          server.close();
        }
      };
    };
  }
}

void testHttp10() {
  HttpServer server = new HttpServer();
  server.onError = (e) => Expect.fail("Unexpected error $e");
  server.listen("127.0.0.1", 0, backlog: 5);
  server.defaultRequestHandler = (HttpRequest request, HttpResponse response) {
    Expect.isNull(request.headers.value('content-length'));
    Expect.equals(-1, request.contentLength);
    response.contentLength = 0;
    OutputStream stream = response.outputStream;
    Expect.equals("1.0", request.protocolVersion);
    Expect.throws(() => stream.writeString("x"), (e) => e is HttpException);
    stream.close();
  };

  Socket socket = new Socket("127.0.0.1", server.port);
  socket.onConnect = () {
    List<int> buffer = new List<int>.fixedLength(1024);
    socket.outputStream.writeString("GET / HTTP/1.0\r\n\r\n");
    socket.onData = () => socket.readList(buffer, 0, buffer.length);
    socket.onClosed = () {
      socket.close(true);
      server.close();
    };
  };
}

void main() {
  testNoBody(5, false);
  testNoBody(5, true);
  testBody(5, false);
  testBody(5, true);
  testBodyChunked(5, false);
  testBodyChunked(5, true);
  testHttp10();
}
