// (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "dart:async";
import "dart:isolate";
import "dart:io";
import "package:expect/expect.dart";

// Client makes a HTTP 1.0 request without connection keep alive. The
// server sets a content length but still needs to close the
// connection as there is no keep alive.
void testHttp10NoKeepAlive() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((HttpRequest request) {
      Expect.isNull(request.headers.value('content-length'));
      Expect.equals(-1, request.contentLength);
      var response = request.response;
      response.contentLength = 1;
      Expect.equals("1.0", request.protocolVersion);
      response.done
          .then((_) => Expect.fail("Unexpected response completion"))
          .catchError((error) => Expect.isTrue(error is HttpException));
      response.write("Z");
      response.write("Z");
      response.close();
      response.write("x");
    }, onError: (e, trace) {
      String msg = "Unexpected error $e";
      if (trace != null) msg += "\nStackTrace: $trace";
      Expect.fail(msg);
    });

    int count = 0;
    makeRequest() {
      Socket.connect("127.0.0.1", server.port).then((socket) {
        socket.write("GET / HTTP/1.0\r\n\r\n");

        List<int> response = [];
        socket.listen(response.addAll, onDone: () {
          count++;
          socket.destroy();
          String s = new String.fromCharCodes(response).toLowerCase();
          Expect.equals(-1, s.indexOf("keep-alive"));
          if (count < 10) {
            makeRequest();
          } else {
            server.close();
          }
        });
      });
    }

    makeRequest();
  });
}

// Client makes a HTTP 1.0 request and the server does not set a
// content length so it has to close the connection to mark the end of
// the response.
void testHttp10ServerClose() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((HttpRequest request) {
      Expect.isNull(request.headers.value('content-length'));
      Expect.equals(-1, request.contentLength);
      request.listen((_) {}, onDone: () {
        var response = request.response;
        Expect.equals("1.0", request.protocolVersion);
        response.write("Z");
        response.close();
      });
    }, onError: (e, trace) {
      String msg = "Unexpected error $e";
      if (trace != null) msg += "\nStackTrace: $trace";
      Expect.fail(msg);
    });

    int count = 0;
    makeRequest() {
      Socket.connect("127.0.0.1", server.port).then((socket) {
        socket.write("GET / HTTP/1.0\r\n");
        socket.write("Connection: Keep-Alive\r\n\r\n");

        List<int> response = [];
        socket.listen(response.addAll,
            onDone: () {
              socket.destroy();
              count++;
              String s = new String.fromCharCodes(response).toLowerCase();
              Expect.equals("z", s[s.length - 1]);
              Expect.equals(-1, s.indexOf("content-length:"));
              Expect.equals(-1, s.indexOf("keep-alive"));
              if (count < 10) {
                makeRequest();
              } else {
                server.close();
              }
            },
            onError: (e) => print(e));
      });
    }

    makeRequest();
  });
}

// Client makes a HTTP 1.0 request with connection keep alive. The
// server sets a content length so the persistent connection can be
// used.
void testHttp10KeepAlive() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((HttpRequest request) {
      Expect.isNull(request.headers.value('content-length'));
      Expect.equals(-1, request.contentLength);
      var response = request.response;
      response.contentLength = 1;
      response.persistentConnection = true;
      Expect.equals("1.0", request.protocolVersion);
      response.write("Z");
      response.close();
    }, onError: (e, trace) {
      String msg = "Unexpected error $e";
      if (trace != null) msg += "\nStackTrace: $trace";
      Expect.fail(msg);
    });

    Socket.connect("127.0.0.1", server.port).then((socket) {
      void sendRequest() {
        socket.write("GET / HTTP/1.0\r\n");
        socket.write("Connection: Keep-Alive\r\n\r\n");
      }

      List<int> response = [];
      int count = 0;
      socket.listen((d) {
        response.addAll(d);
        if (response[response.length - 1] == "Z".codeUnitAt(0)) {
          String s = new String.fromCharCodes(response).toLowerCase();
          Expect.isTrue(s.indexOf("\r\nconnection: keep-alive\r\n") > 0);
          Expect.isTrue(s.indexOf("\r\ncontent-length: 1\r\n") > 0);
          count++;
          if (count < 10) {
            response = [];
            sendRequest();
          } else {
            socket.close();
          }
        }
      }, onDone: () {
        socket.destroy();
        server.close();
      });
      sendRequest();
    });
  });
}

// Client makes a HTTP 1.0 request with connection keep alive. The
// server does not set a content length so it cannot honor connection
// keep alive.
void testHttp10KeepAliveServerCloses() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((HttpRequest request) {
      Expect.isNull(request.headers.value('content-length'));
      Expect.equals(-1, request.contentLength);
      var response = request.response;
      Expect.equals("1.0", request.protocolVersion);
      response.write("Z");
      response.close();
    }, onError: (e, trace) {
      String msg = "Unexpected error $e";
      if (trace != null) msg += "\nStackTrace: $trace";
      Expect.fail(msg);
    });

    int count = 0;
    makeRequest() {
      Socket.connect("127.0.0.1", server.port).then((socket) {
        socket.write("GET / HTTP/1.0\r\n");
        socket.write("Connection: Keep-Alive\r\n\r\n");

        List<int> response = [];
        socket.listen(response.addAll, onDone: () {
          socket.destroy();
          count++;
          String s = new String.fromCharCodes(response).toLowerCase();
          Expect.equals("z", s[s.length - 1]);
          Expect.equals(-1, s.indexOf("content-length"));
          Expect.equals(-1, s.indexOf("connection"));
          if (count < 10) {
            makeRequest();
          } else {
            server.close();
          }
        });
      });
    }

    makeRequest();
  });
}

void main() {
  testHttp10NoKeepAlive();
  testHttp10ServerClose();
  testHttp10KeepAlive();
  testHttp10KeepAliveServerCloses();
}
