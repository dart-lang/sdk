// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:typed_data";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void testDefaultResponseHeaders() {
  checkDefaultHeaders(headers) {
    Expect.listEquals(
        headers[HttpHeaders.CONTENT_TYPE], ['text/plain; charset=utf-8']);
    Expect.listEquals(headers['X-Frame-Options'], ['SAMEORIGIN']);
    Expect.listEquals(headers['X-Content-Type-Options'], ['nosniff']);
    Expect.listEquals(headers['X-XSS-Protection'], ['1; mode=block']);
  }

  checkDefaultHeadersClear(headers) {
    Expect.isNull(headers[HttpHeaders.CONTENT_TYPE]);
    Expect.isNull(headers['X-Frame-Options']);
    Expect.isNull(headers['X-Content-Type-Options']);
    Expect.isNull(headers['X-XSS-Protection']);
  }

  checkDefaultHeadersClearAB(headers) {
    Expect.isNull(headers[HttpHeaders.CONTENT_TYPE]);
    Expect.isNull(headers['X-Frame-Options']);
    Expect.isNull(headers['X-Content-Type-Options']);
    Expect.isNull(headers['X-XSS-Protection']);
    Expect.listEquals(headers['a'], ['b']);
  }

  test(bool clearHeaders, Map defaultHeaders, Function checker) {
    HttpServer.bind("127.0.0.1", 0).then((server) {
      if (clearHeaders) server.defaultResponseHeaders.clear();
      if (defaultHeaders != null) {
        defaultHeaders.forEach(
            (name, value) => server.defaultResponseHeaders.add(name, value));
      }
      checker(server.defaultResponseHeaders);
      server.listen((request) {
        request.response.close();
      });

      HttpClient client = new HttpClient();
      client
          .get("127.0.0.1", server.port, "/")
          .then((request) => request.close())
          .then((response) {
        checker(response.headers);
        server.close();
        client.close();
      });
    });
  }

  test(false, null, checkDefaultHeaders);
  test(true, null, checkDefaultHeadersClear);
  test(true, {'a': 'b'}, checkDefaultHeadersClearAB);
}

void testDefaultResponseHeadersContentType() {
  test(bool clearHeaders, String requestBody, List<int> responseBody) {
    HttpServer.bind("127.0.0.1", 0).then((server) {
      if (clearHeaders) server.defaultResponseHeaders.clear();
      server.listen((request) {
        request.response.write(requestBody);
        request.response.close();
      });

      HttpClient client = new HttpClient();
      client
          .get("127.0.0.1", server.port, "/")
          .then((request) => request.close())
          .then((response) {
        response.fold([], (a, b) => a..addAll(b)).then((body) {
          Expect.listEquals(body, responseBody);
        }).whenComplete(() {
          server.close();
          client.close();
        });
      });
    });
  }

  test(false, 'æøå', [195, 166, 195, 184, 195, 165]);
  test(true, 'æøå', [230, 248, 229]);
}

void testListenOn() {
  ServerSocket socket;
  HttpServer server;

  void test(void onDone()) {
    Expect.equals(socket.port, server.port);

    HttpClient client = new HttpClient();
    client.get("127.0.0.1", socket.port, "/").then((request) {
      return request.close();
    }).then((response) {
      response.listen((_) {}, onDone: () {
        client.close();
        onDone();
      });
    }).catchError((e, trace) {
      String msg = "Unexpected error in Http Client: $e";
      if (trace != null) msg += "\nStackTrace: $trace";
      Expect.fail(msg);
    });
  }

  // Test two connection after each other.
  asyncStart();
  ServerSocket.bind("127.0.0.1", 0).then((s) {
    socket = s;
    server = new HttpServer.listenOn(socket);
    Expect.equals(server.address.address, '127.0.0.1');
    Expect.equals(server.address.host, '127.0.0.1');
    server.listen((HttpRequest request) {
      request.listen((_) {}, onDone: () => request.response.close());
    });

    test(() {
      test(() {
        server.close();
        Expect.throws(() => server.port);
        Expect.throws(() => server.address);
        socket.close();
        asyncEnd();
      });
    });
  });
}

void testHttpServerZone() {
  asyncStart();
  Expect.equals(Zone.ROOT, Zone.current);
  runZoned(() {
    Expect.notEquals(Zone.ROOT, Zone.current);
    HttpServer.bind("127.0.0.1", 0).then((server) {
      Expect.notEquals(Zone.ROOT, Zone.current);
      server.listen((request) {
        Expect.notEquals(Zone.ROOT, Zone.current);
        request.response.close();
        server.close();
      });
      new HttpClient()
          .get("127.0.0.1", server.port, '/')
          .then((request) => request.close())
          .then((response) => response.drain())
          .then((_) => asyncEnd());
    });
  });
}

void testHttpServerZoneError() {
  asyncStart();
  Expect.equals(Zone.ROOT, Zone.current);
  runZoned(() {
    Expect.notEquals(Zone.ROOT, Zone.current);
    HttpServer.bind("127.0.0.1", 0).then((server) {
      Expect.notEquals(Zone.ROOT, Zone.current);
      server.listen((request) {
        Expect.notEquals(Zone.ROOT, Zone.current);
        request.listen((_) {}, onError: (error) {
          Expect.notEquals(Zone.ROOT, Zone.current);
          server.close();
          throw error;
        });
      });
      Socket.connect("127.0.0.1", server.port).then((socket) {
        socket.write('GET / HTTP/1.1\r\nContent-Length: 100\r\n\r\n');
        socket.write('some body');
        socket.close();
        socket.listen(null);
      });
    });
  }, onError: (e) {
    asyncEnd();
  });
}

void testHttpServerClientClose() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    runZoned(() {
      server.listen((request) {
        request.response.bufferOutput = false;
        request.response.add(new Uint8List(64 * 1024));
        new Timer(const Duration(milliseconds: 100), () {
          request.response.close().then((_) {
            server.close();
          });
        });
      });
    }, onError: (e, s) {
      Expect.fail("Unexpected error: $e(${e.hashCode})\n$s");
    });
    var client = new HttpClient();
    client
        .get("127.0.0.1", server.port, "/")
        .then((request) => request.close())
        .then((response) {
      response.listen((_) {}).cancel();
    });
  });
}

void main() {
  testDefaultResponseHeaders();
  testDefaultResponseHeadersContentType();
  testListenOn();
  testHttpServerZone();
  testHttpServerZoneError();
  testHttpServerClientClose();
}
