// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";
import "dart:io";

void testNoBody(int totalConnections, bool explicitContentLength) {
  var errors = 0;
  HttpServer.bind("127.0.0.1", 0, totalConnections).then((server) {
    server.listen(
        (HttpRequest request) {
          Expect.equals("0", request.headers.value('content-length'));
          Expect.equals(0, request.contentLength);
          var response = request.response;
          response.contentLength = 0;
          response.done
            .then((_) {
              Expect.fail("Unexpected successful response completion");
            })
            .catchError((e) {
              Expect.isTrue(e.error is HttpException);
            });
          // addString with content length 0 closes the connection and
          // reports an error.
          response.addString("x");
          // Subsequent addString are ignored as there is already an
          // error.
          response.addString("x");
          // After an explicit close, addString becomes a state error
          // because we have said we will not add more.
          response.close();
          Expect.throws(() => response.addString("x"),
                        (e) => e is StateError);
        },
        onError: (e) {
          Expect.fail("Unexpected server error $e");
        });

    int count = 0;
    HttpClient client = new HttpClient();
    for (int i = 0; i < totalConnections; i++) {
      client.get("127.0.0.1", server.port, "/")
          .then((request) {
            if (explicitContentLength) {
              request.contentLength = 0;
            }
            return request.close();
          })
          .then((response) {
            Expect.equals("0", response.headers.value('content-length'));
            Expect.equals(0, response.contentLength);
            response.listen(
                (d) {},
                onDone: () {
                  if (++count == totalConnections) {
                    client.close();
                    server.close();
                  }
                });
          })
          .catchError((e) {
            Expect.fail("Unexpected error $e");
          });
    }
  });
}

void testBody(int totalConnections, bool useHeader) {
  HttpServer.bind("127.0.0.1", 0, totalConnections).then((server) {
    server.listen(
        (HttpRequest request) {
          Expect.equals("2", request.headers.value('content-length'));
          Expect.equals(2, request.contentLength);
          var response = request.response;
          if (useHeader) {
            response.contentLength = 2;
          } else {
            response.headers.set("content-length", 2);
          }
          request.listen(
              (d) {},
              onDone: () {
                response.addString("x");
                Expect.throws(() => response.contentLength = 3,
                              (e) => e is HttpException);
                response.addString("x");
                response.addString("x");
                response.done
                    .then((_) {
                      Expect.fail("Unexpected successful response completion");
                    })
                    .catchError((e) {
                      Expect.isTrue(e.error is HttpException, "[$e] [${e.error}]");
                    });
                response.close();
                Expect.throws(() => response.addString("x"),
                              (e) => e is StateError);
              });
        },
        onError: (e) => Expect.fail("Unexpected error $e"));

    int count = 0;
    HttpClient client = new HttpClient();
    for (int i = 0; i < totalConnections; i++) {
      client.get("127.0.0.1", server.port, "/")
          .then((request) {
            if (useHeader) {
              request.contentLength = 2;
            } else {
              request.headers.add(HttpHeaders.CONTENT_LENGTH, "7");
              request.headers.add(HttpHeaders.CONTENT_LENGTH, "2");
            }
            request.addString("x");
            Expect.throws(() => request.contentLength = 3,
                          (e) => e is HttpException);
            request.addString("x");
            return request.close();
          })
          .then((response) {
            Expect.equals("2", response.headers.value('content-length'));
            Expect.equals(2, response.contentLength);
            response.listen(
                (d) {},
                onDone: () {
                  if (++count == totalConnections) {
                    client.close();
                    server.close();
                  }
                });
          });
    }
  });
}

void testBodyChunked(int totalConnections, bool useHeader) {
  HttpServer.bind("127.0.0.1", 0, totalConnections).then((server) {
    server.listen(
        (HttpRequest request) {
          Expect.isNull(request.headers.value('content-length'));
          Expect.equals(-1, request.contentLength);
          var response = request.response;
          if (useHeader) {
            response.contentLength = 2;
            response.headers.chunkedTransferEncoding = true;
          } else {
            response.headers.set("content-length", 2);
            response.headers.set("transfer-encoding", "chunked");
          }
          request.listen(
              (d) {},
              onDone: () {
                response.addString("x");
                Expect.throws(
                    () => response.headers.chunkedTransferEncoding = false,
                    (e) => e is HttpException);
                response.addString("x");
                response.addString("x");
                response.close();
                Expect.throws(() => response.addString("x"),
                              (e) => e is StateError);
              });
        },
        onError: (e) => Expect.fail("Unexpected error $e"));

    int count = 0;
    HttpClient client = new HttpClient();
    for (int i = 0; i < totalConnections; i++) {
      client.get("127.0.0.1", server.port, "/")
          .then((request) {
            if (useHeader) {
              request.contentLength = 2;
              request.headers.chunkedTransferEncoding = true;
            } else {
              request.headers.add(HttpHeaders.CONTENT_LENGTH, "2");
              request.headers.set(HttpHeaders.TRANSFER_ENCODING, "chunked");
            }
            request.addString("x");
            Expect.throws(() => request.headers.chunkedTransferEncoding = false,
                          (e) => e is HttpException);
            request.addString("x");
            request.addString("x");
            return request.close();
          })
          .then((response) {
            Expect.isNull(response.headers.value('content-length'));
            Expect.equals(-1, response.contentLength);
            response.listen(
                (d) {},
                onDone: () {
                  if (++count == totalConnections) {
                    client.close();
                    server.close();
                  }
                });
          })
          .catchError((e) => Expect.fail("Unexpected error $e"));
    }
  });
}

void testHttp10() {
  HttpServer.bind("127.0.0.1", 0, 5).then((server) {
    server.listen(
        (HttpRequest request) {
          Expect.isNull(request.headers.value('content-length'));
          Expect.equals(-1, request.contentLength);
          var response = request.response;
          response.contentLength = 0;
          Expect.equals("1.0", request.protocolVersion);
          response.done
              .then((_) => Expect.fail("Unexpected response completion"))
              .catchError((e) => Expect.isTrue(e.error is HttpException));
          response.addString("x");
          response.close();
          Expect.throws(() => response.addString("x"),
                        (e) => e is StateError);
        },
        onError: (e) => Expect.fail("Unexpected error $e"));

    Socket.connect("127.0.0.1", server.port).then((socket) {
      socket.addString("GET / HTTP/1.0\r\n\r\n");
      socket.close();
      socket.listen(
          (d) { },
          onDone: () {
            socket.destroy();
            server.close();
          });
    });
  });
}

void testSetContentLength() {
  HttpServer.bind().then((server) {
    server.listen(
        (HttpRequest request) {
          var response = request.response;
          Expect.isNull(response.headers.value('content-length'));
          Expect.equals(-1, response.contentLength);
          response.headers.set("content-length", 3);
          Expect.equals("3", response.headers.value('content-length'));
          Expect.equals(3, response.contentLength);
          response.addString("xxx");
          response.close();
        });

    var client = new HttpClient();
    client.get("127.0.0.1", server.port, "/")
        .then((request) => request.close())
        .then((response) {
          response.listen(
              (_) { },
              onDone: () {
                client.close();
                server.close();
              });
        });
  });
}

void main() {
  testNoBody(5, false);
  testNoBody(5, true);
  testBody(5, false);
  testBody(5, true);
  testBodyChunked(5, false);
  testBodyChunked(5, true);
  testHttp10();
  testSetContentLength();
}
