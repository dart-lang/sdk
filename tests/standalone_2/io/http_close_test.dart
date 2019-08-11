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
import "dart:io";
import "dart:typed_data";
import "dart:math";

testClientAndServerCloseNoListen(int connections) {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    int closed = 0;
    server.listen((request) {
      request.response.close();
      request.response.done.then((_) {
        closed++;
        if (closed == connections) {
          Expect.equals(0, server.connectionsInfo().active);
          Expect.equals(
              server.connectionsInfo().total, server.connectionsInfo().idle);
          server.close();
        }
      });
    });
    var client = HttpClient();
    for (int i = 0; i < connections; i++) {
      client
          .get("127.0.0.1", server.port, "/")
          .then((request) => request.close())
          .then((response) {});
    }
  });
}

testClientCloseServerListen(int connections) {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    int closed = 0;
    check() {
      closed++;
      if (closed == connections * 2) {
        Expect.equals(0, server.connectionsInfo().active);
        Expect.equals(
            server.connectionsInfo().total, server.connectionsInfo().idle);
        server.close();
      }
    }

    server.listen((request) {
      request.listen((_) {}, onDone: () {
        request.response.close();
        request.response.done.then((_) => check());
      });
    });
    var client = HttpClient();
    for (int i = 0; i < connections; i++) {
      client
          .get("127.0.0.1", server.port, "/")
          .then((request) => request.close())
          .then((response) => check());
    }
  });
}

testClientCloseSendingResponse(int connections) {
  var buffer = Uint8List(64 * 1024);
  var rand = Random();
  for (int i = 0; i < buffer.length; i++) {
    buffer[i] = rand.nextInt(256);
  }
  HttpServer.bind("127.0.0.1", 0).then((server) {
    int closed = 0;
    check() {
      closed++;
      // Wait for both server and client to see the connections as closed.
      if (closed == connections * 2) {
        Expect.equals(0, server.connectionsInfo().active);
        Expect.equals(
            server.connectionsInfo().total, server.connectionsInfo().idle);
        server.close();
      }
    }

    server.listen((request) {
      var timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        request.response.add(buffer);
      });
      request.response.done.catchError((_) {}).whenComplete(() {
        check();
        timer.cancel();
      });
    });
    var client = HttpClient();
    for (int i = 0; i < connections; i++) {
      client
          .get("127.0.0.1", server.port, "/")
          .then((request) => request.close())
          .then((response) {
        // Ensure we don't accept the response until we have send the entire
        // request.
        var subscription = response.listen((_) {});
        Timer(const Duration(milliseconds: 20), () {
          subscription.cancel();
          check();
        });
      });
    }
  });
}

// Closing the request early, before sending the full request payload should
// result in an error on both server and client.
testClientCloseWhileSendingRequest(int connections) {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    int serverErrors = 0;
    int clientErrors = 0;
    server.listen((request) {
      request.listen((_) {}, onError: (_) {
        serverErrors++;
        if (serverErrors == connections) {
          server.close();
        }
      });
    }, onDone: () {
      Expect.equals(connections, clientErrors);
      Expect.equals(connections, serverErrors);
    });
    var client = HttpClient();
    for (int i = 0; i < connections; i++) {
      client.post("127.0.0.1", server.port, "/").then((request) {
        request.contentLength = 110;
        request.write("0123456789");
        return request.close();
      }).catchError((_) {
        clientErrors++;
      });
    }
  });
}

main() {
  testClientAndServerCloseNoListen(10);
  testClientCloseServerListen(10);
  testClientCloseSendingResponse(10);
  testClientCloseWhileSendingRequest(10);
}
