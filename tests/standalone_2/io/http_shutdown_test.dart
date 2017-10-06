// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "dart:async";
import "dart:io";
import "package:expect/expect.dart";

void test1(int totalConnections) {
  // Server which just closes immediately.
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((HttpRequest request) {
      request.response.close();
    });

    int count = 0;
    HttpClient client = new HttpClient();
    for (int i = 0; i < totalConnections; i++) {
      client
          .get("127.0.0.1", server.port, "/")
          .then((HttpClientRequest request) => request.close())
          .then((HttpClientResponse response) {
        response.listen((_) {}, onDone: () {
          count++;
          if (count == totalConnections) {
            client.close();
            server.close();
          }
        });
      });
    }
  });
}

void test2(int totalConnections, int outputStreamWrites) {
  // Server which responds without waiting for request body.
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((HttpRequest request) {
      request.response.write("!dlrow ,olleH");
      request.response.close();
    });

    int count = 0;
    HttpClient client = new HttpClient();
    for (int i = 0; i < totalConnections; i++) {
      client
          .get("127.0.0.1", server.port, "/")
          .then((HttpClientRequest request) {
        request.contentLength = -1;
        for (int i = 0; i < outputStreamWrites; i++) {
          request.write("Hello, world!");
        }
        request.done.catchError((_) {});
        return request.close();
      }).then((HttpClientResponse response) {
        response.listen((_) {}, onDone: () {
          count++;
          if (count == totalConnections) {
            client.close(force: true);
            server.close();
          }
        }, onError: (e) {} /* ignore */);
      }).catchError((error) {
        count++;
        if (count == totalConnections) {
          client.close();
          server.close();
        }
      });
    }
  });
}

void test3(int totalConnections) {
  // Server which responds when request body has been received.
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((HttpRequest request) {
      request.listen((_) {}, onDone: () {
        request.response.write("!dlrow ,olleH");
        request.response.close();
      });
    });

    int count = 0;
    HttpClient client = new HttpClient();
    for (int i = 0; i < totalConnections; i++) {
      client
          .get("127.0.0.1", server.port, "/")
          .then((HttpClientRequest request) {
        request.contentLength = -1;
        request.write("Hello, world!");
        return request.close();
      }).then((HttpClientResponse response) {
        response.listen((_) {}, onDone: () {
          count++;
          if (count == totalConnections) {
            client.close();
            server.close();
          }
        });
      });
    }
  });
}

void test4() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((var request) {
      request.listen((_) {}, onDone: () {
        new Timer.periodic(new Duration(milliseconds: 100), (timer) {
          if (server.connectionsInfo().total == 0) {
            server.close();
            timer.cancel();
          }
        });
        request.response.close();
      });
    });

    var client = new HttpClient();
    client
        .get("127.0.0.1", server.port, "/")
        .then((request) => request.close())
        .then((response) {
      response.listen((_) {}, onDone: () {
        client.close();
      });
    });
  });
}

void test5(int totalConnections) {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      request.listen((_) {}, onDone: () {
        request.response.close();
        request.response.done.catchError((e) {});
      }, onError: (error) {});
    }, onError: (error) {});

    // Create a number of client requests and keep then active. Then
    // close the client and wait for the server to lose all active
    // connections.
    var client = new HttpClient();
    client.maxConnectionsPerHost = totalConnections;
    for (int i = 0; i < totalConnections; i++) {
      client
          .post("127.0.0.1", server.port, "/")
          .then((request) {
            request.add([0]);
            // TODO(sgjesse): Make this test work with
            //request.response instead of request.close() return
            //return request.response;
            request.done.catchError((e) {});
            return request.close();
          })
          .then((response) {})
          .catchError((e) {}, test: (e) => e is HttpException);
    }
    bool clientClosed = false;
    new Timer.periodic(new Duration(milliseconds: 100), (timer) {
      if (!clientClosed) {
        if (server.connectionsInfo().total == totalConnections) {
          clientClosed = true;
          client.close(force: true);
        }
      } else {
        if (server.connectionsInfo().total == 0) {
          server.close();
          timer.cancel();
        }
      }
    });
  });
}

void main() {
  test1(1);
  test1(10);
  test2(1, 10);
  test2(10, 10);
  test2(10, 1000);
  test3(1);
  test3(10);
  test4();
  test5(1);
  test5(10);
}
