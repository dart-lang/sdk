// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "package:expect/expect.dart";
import "dart:async";
import "dart:isolate";
import "dart:io";

void testNoBody(int totalConnections, bool explicitContentLength) {
  int count = 0;
  HttpServer.bind("127.0.0.1", 0, backlog: totalConnections).then((server) {
    server.listen((HttpRequest request) {
      Expect.equals("0", request.headers.value('content-length'));
      Expect.equals(0, request.contentLength);
      var response = request.response;
      response.contentLength = 0;
      response.done.then((_) {
        Expect.fail("Unexpected successful response completion");
      }).catchError((error) {
        Expect.isTrue(error is HttpException);
        if (++count == totalConnections) {
          server.close();
        }
      });
      // write with content length 0 closes the connection and
      // reports an error.
      response.write("x");
      // Subsequent write are ignored as there is already an
      // error.
      response.write("x");
      // After an explicit close, write becomes a state error
      // because we have said we will not add more.
      response.close();
      response.write("x");
    }, onError: (e, trace) {
      String msg = "Unexpected server error $e";
      if (trace != null) msg += "\nStackTrace: $trace";
      Expect.fail(msg);
    });

    HttpClient client = new HttpClient();
    for (int i = 0; i < totalConnections; i++) {
      client.get("127.0.0.1", server.port, "/").then((request) {
        if (explicitContentLength) {
          request.contentLength = 0;
        }
        return request.close();
      }).then((response) {
        Expect.equals("0", response.headers.value('content-length'));
        Expect.equals(0, response.contentLength);
        response.drain();
      }).catchError((e, trace) {
        // It's also okay to fail, as headers may not be written.
      });
    }
  });
}

void testBody(int totalConnections, bool useHeader) {
  HttpServer.bind("127.0.0.1", 0, backlog: totalConnections).then((server) {
    int serverCount = 0;
    server.listen((HttpRequest request) {
      Expect.equals("2", request.headers.value('content-length'));
      Expect.equals(2, request.contentLength);
      var response = request.response;
      if (useHeader) {
        response.contentLength = 2;
      } else {
        response.headers.set("content-length", 2);
      }
      request.listen((d) {}, onDone: () {
        response.write("x");
        Expect.throws(
            () => response.contentLength = 3, (e) => e is HttpException);
        response.write("x");
        response.write("x");
        response.done.then((_) {
          Expect.fail("Unexpected successful response completion");
        }).catchError((error) {
          Expect.isTrue(error is HttpException, "[$error]");
          if (++serverCount == totalConnections) {
            server.close();
          }
        });
        response.close();
        response.write("x");
      });
    }, onError: (e, trace) {
      String msg = "Unexpected error $e";
      if (trace != null) msg += "\nStackTrace: $trace";
      Expect.fail(msg);
    });

    int clientCount = 0;
    HttpClient client = new HttpClient();
    for (int i = 0; i < totalConnections; i++) {
      client.get("127.0.0.1", server.port, "/").then((request) {
        if (useHeader) {
          request.contentLength = 2;
        } else {
          request.headers.add(HttpHeaders.CONTENT_LENGTH, "7");
          request.headers.add(HttpHeaders.CONTENT_LENGTH, "2");
        }
        request.write("x");
        Expect.throws(
            () => request.contentLength = 3, (e) => e is HttpException);
        request.write("x");
        return request.close();
      }).then((response) {
        Expect.equals("2", response.headers.value('content-length'));
        Expect.equals(2, response.contentLength);
        response.listen((d) {}, onDone: () {
          if (++clientCount == totalConnections) {
            client.close();
          }
        }, onError: (error, trace) {
          // Undefined what server response sends.
        });
      }).catchError((error) {
        // It's also okay to fail, as headers may not be written.
      });
    }
  });
}

void testBodyChunked(int totalConnections, bool useHeader) {
  HttpServer.bind("127.0.0.1", 0, backlog: totalConnections).then((server) {
    server.listen((HttpRequest request) {
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
      request.listen((d) {}, onDone: () {
        response.write("x");
        Expect.throws(() => response.headers.chunkedTransferEncoding = false,
            (e) => e is HttpException);
        response.write("x");
        response.write("x");
        response.close();
        response.write("x");
      });
    }, onError: (e, trace) {
      String msg = "Unexpected error $e";
      if (trace != null) msg += "\nStackTrace: $trace";
      Expect.fail(msg);
    });

    int count = 0;
    HttpClient client = new HttpClient();
    for (int i = 0; i < totalConnections; i++) {
      client.get("127.0.0.1", server.port, "/").then((request) {
        if (useHeader) {
          request.contentLength = 2;
          request.headers.chunkedTransferEncoding = true;
        } else {
          request.headers.add(HttpHeaders.CONTENT_LENGTH, "2");
          request.headers.set(HttpHeaders.TRANSFER_ENCODING, "chunked");
        }
        request.write("x");
        Expect.throws(() => request.headers.chunkedTransferEncoding = false,
            (e) => e is HttpException);
        request.write("x");
        request.write("x");
        return request.close();
      }).then((response) {
        Expect.isNull(response.headers.value('content-length'));
        Expect.equals(-1, response.contentLength);
        response.listen((d) {}, onDone: () {
          if (++count == totalConnections) {
            client.close();
            server.close();
          }
        });
      }).catchError((e, trace) {
        String msg = "Unexpected error $e";
        if (trace != null) msg += "\nStackTrace: $trace";
        Expect.fail(msg);
      });
    }
  });
}

void testSetContentLength() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((HttpRequest request) {
      var response = request.response;
      Expect.isNull(response.headers.value('content-length'));
      Expect.equals(-1, response.contentLength);
      response.headers.set("content-length", 3);
      Expect.equals("3", response.headers.value('content-length'));
      Expect.equals(3, response.contentLength);
      response.write("xxx");
      response.close();
    });

    var client = new HttpClient();
    client
        .get("127.0.0.1", server.port, "/")
        .then((request) => request.close())
        .then((response) {
      response.listen((_) {}, onDone: () {
        client.close();
        server.close();
      });
    });
  });
}

void main() {
  testNoBody(5, false);
  testNoBody(25, false);
  testNoBody(5, true);
  testNoBody(25, true);
  testBody(5, false);
  testBody(5, true);
  testBodyChunked(5, false);
  testBodyChunked(5, true);
  testSetContentLength();
}
