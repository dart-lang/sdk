// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void testGetEmptyRequest() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      request.pipe(request.response);
    });

    var client = new HttpClient();
    client
        .get("127.0.0.1", server.port, "/")
        .then((request) => request.close())
        .then((response) {
      response.listen((data) {}, onDone: server.close);
    });
  });
}

void testGetDataRequest() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    var data = "lalala".codeUnits;
    server.listen((request) {
      request.response.add(data);
      request.pipe(request.response);
    });

    var client = new HttpClient();
    client
        .get("127.0.0.1", server.port, "/")
        .then((request) => request.close())
        .then((response) {
      int count = 0;
      response.listen((data) => count += data.length, onDone: () {
        server.close();
        Expect.equals(data.length, count);
      });
    });
  });
}

void testGetInvalidHost() {
  asyncStart();
  var client = new HttpClient();
  client.get("__SOMETHING_INVALID__", 8888, "/").catchError((error) {
    client.close();
    asyncEnd();
  });
}

void testGetServerClose() {
  asyncStart();
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      server.close();
      new Timer(const Duration(milliseconds: 100), () {
        request.response.close();
      });
    });

    var client = new HttpClient();
    client
        .get("127.0.0.1", server.port, "/")
        .then((request) => request.close())
        .then((response) => response.drain())
        .then((_) => asyncEnd());
  });
}

void testGetServerCloseNoKeepAlive() {
  asyncStart();
  var client = new HttpClient();
  HttpServer.bind("127.0.0.1", 0).then((server) {
    int port = server.port;
    server.first.then((request) => request.response.close());

    client
        .get("127.0.0.1", port, "/")
        .then((request) => request.close())
        .then((response) => response.drain())
        .then((_) => client.get("127.0.0.1", port, "/"))
        .then((request) => request.close())
        .then((_) => Expect.fail('should not succeed'), onError: (_) {})
        .then((_) => asyncEnd());
  });
}

void testGetServerForceClose() {
  asyncStart();
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      server.close(force: true);
    });

    var client = new HttpClient();
    client
        .get("127.0.0.1", server.port, "/")
        .then((request) => request.close())
        .then((response) {
      Expect.fail("Request not expected");
    }).catchError((error) => asyncEnd(),
            test: (error) => error is HttpException);
  });
}

void testGetDataServerForceClose() {
  asyncStart();
  var completer = new Completer();
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      request.response.bufferOutput = false;
      request.response.contentLength = 100;
      request.response.write("data");
      request.response.write("more data");
      completer.future.then((_) => server.close(force: true));
    });

    var client = new HttpClient();
    client
        .get("127.0.0.1", server.port, "/")
        .then((request) => request.close())
        .then((response) {
      // Close the (incomplete) response, now that we have seen
      // the response object.
      completer.complete(null);
      int errors = 0;
      response.listen((data) {},
          onError: (error) => errors++,
          onDone: () {
            Expect.equals(1, errors);
            asyncEnd();
          });
    });
  });
}

typedef Future<HttpClientRequest> Callback1(String a1, int a2, String a3);
void testOpenEmptyRequest() {
  var client = new HttpClient();
  var methods = [
    [client.get, 'GET'],
    [client.post, 'POST'],
    [client.put, 'PUT'],
    [client.delete, 'DELETE'],
    [client.patch, 'PATCH'],
    [client.head, 'HEAD']
  ];

  for (var method in methods) {
    HttpServer.bind("127.0.0.1", 0).then((server) {
      server.listen((request) {
        Expect.equals(method[1], request.method);
        request.pipe(request.response);
      });

      Callback1 cb = method[0] as Callback1;
      cb("127.0.0.1", server.port, "/")
          .then((request) => request.close())
          .then((response) {
        response.listen((data) {}, onDone: server.close);
      });
    });
  }
}

typedef Future<HttpClientRequest> Callback2(Uri a1);
void testOpenUrlEmptyRequest() {
  var client = new HttpClient();
  var methods = [
    [client.getUrl, 'GET'],
    [client.postUrl, 'POST'],
    [client.putUrl, 'PUT'],
    [client.deleteUrl, 'DELETE'],
    [client.patchUrl, 'PATCH'],
    [client.headUrl, 'HEAD']
  ];

  for (var method in methods) {
    HttpServer.bind("127.0.0.1", 0).then((server) {
      server.listen((request) {
        Expect.equals(method[1], request.method);
        request.pipe(request.response);
      });

      Callback2 cb = method[0] as Callback2;
      cb(Uri.parse("http://127.0.0.1:${server.port}/"))
          .then((request) => request.close())
          .then((response) {
        response.listen((data) {}, onDone: server.close);
      });
    });
  }
}

void testNoBuffer() {
  asyncStart();
  HttpServer.bind("127.0.0.1", 0).then((server) {
    var response;
    server.listen((request) {
      response = request.response;
      response.bufferOutput = false;
      response.writeln('init');
    });

    var client = new HttpClient();
    client
        .get("127.0.0.1", server.port, "/")
        .then((request) => request.close())
        .then((clientResponse) {
      var iterator = new StreamIterator(
          clientResponse.transform(UTF8.decoder).transform(new LineSplitter()));
      iterator.moveNext().then((hasValue) {
        Expect.isTrue(hasValue);
        Expect.equals('init', iterator.current);
        int count = 0;
        void run() {
          if (count == 10) {
            response.close();
            iterator.moveNext().then((hasValue) {
              Expect.isFalse(hasValue);
              server.close();
              asyncEnd();
            });
          } else {
            response.writeln('output$count');
            iterator.moveNext().then((hasValue) {
              Expect.isTrue(hasValue);
              Expect.equals('output$count', iterator.current);
              count++;
              run();
            });
          }
        }

        run();
      });
    });
  });
}

void testMaxConnectionsPerHost(int connectionCap, int connections) {
  asyncStart();
  HttpServer.bind("127.0.0.1", 0).then((server) {
    int handled = 0;
    server.listen((request) {
      Expect.isTrue(server.connectionsInfo().total <= connectionCap);
      request.response.close();
      handled++;
      if (handled == connections) {
        asyncEnd();
        server.close();
      }
    });

    var client = new HttpClient();
    client.maxConnectionsPerHost = connectionCap;
    for (int i = 0; i < connections; i++) {
      asyncStart();
      client
          .get("127.0.0.1", server.port, "/")
          .then((request) => request.close())
          .then((response) {
        response.listen(null, onDone: () {
          asyncEnd();
        });
      });
    }
  });
}

void main() {
  testGetEmptyRequest();
  testGetDataRequest();
  testGetInvalidHost();
  testGetServerClose();
  testGetServerCloseNoKeepAlive();
  testGetServerForceClose();
  testGetDataServerForceClose();
  testOpenEmptyRequest();
  testOpenUrlEmptyRequest();
  testNoBuffer();
  testMaxConnectionsPerHost(1, 1);
  testMaxConnectionsPerHost(1, 10);
  testMaxConnectionsPerHost(5, 10);
  testMaxConnectionsPerHost(10, 50);
}
