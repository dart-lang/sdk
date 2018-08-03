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
import "dart:isolate";
import "package:expect/expect.dart";

Future sendData(List<int> data, int port) {
  return Socket.connect("127.0.0.1", port).then((socket) {
    socket.listen((data) {
      Expect.fail("No data response was expected");
    });
    socket.add(data);
    return socket.close().then((_) {
      socket.destroy();
    });
  });
}

class EarlyCloseTest {
  EarlyCloseTest(this.data,
      [String this.exception, bool this.expectRequest = false]);

  Future execute() {
    return HttpServer.bind("127.0.0.1", 0).then((server) {
      Completer c = new Completer();

      bool calledOnRequest = false;
      bool calledOnError = false;
      bool calledOnDone = false;
      ReceivePort port = new ReceivePort();
      var requestCompleter = new Completer();
      server.listen((request) {
        Expect.isTrue(expectRequest);
        Expect.isFalse(calledOnError);
        Expect.isFalse(calledOnRequest, "onRequest called multiple times");
        calledOnRequest = true;
        request.listen((_) {}, onDone: () {
          requestCompleter.complete();
        }, onError: (error) {
          Expect.isFalse(calledOnError);
          Expect.equals(exception, error.message);
          calledOnError = true;
          if (exception != null) port.close();
        });
      }, onDone: () {
        Expect.equals(expectRequest, calledOnRequest);
        calledOnDone = true;
        if (exception == null) port.close();
        c.complete(null);
      });

      List<int> d;
      if (data is List<int>) d = data;
      if (data is String) d = data.codeUnits;
      if (d == null) Expect.fail("Invalid data");
      sendData(d, server.port).then((_) {
        if (!expectRequest) requestCompleter.complete();
        requestCompleter.future.then((_) => server.close());
      });

      return c.future;
    });
  }

  final data;
  final String exception;
  final bool expectRequest;
}

void testEarlyClose1() {
  List<EarlyCloseTest> tests = new List<EarlyCloseTest>();
  void add(Object data, [String exception, bool expectRequest = false]) {
    tests.add(new EarlyCloseTest(data, exception, expectRequest));
  }
  // The empty packet is valid.

  // Close while sending header
  add("G");
  add("GET /");
  add("GET / HTTP/1.1");
  add("GET / HTTP/1.1\r\n");

  // Close while sending content
  add("GET / HTTP/1.1\r\nContent-Length: 100\r\n\r\n",
      "Connection closed while receiving data", true);
  add("GET / HTTP/1.1\r\nContent-Length: 100\r\n\r\n1",
      "Connection closed while receiving data", true);

  void runTest(Iterator it) {
    if (it.moveNext()) {
      it.current.execute().then((_) {
        runTest(it);
      });
    }
  }

  runTest(tests.iterator);
}

testEarlyClose2() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      String name = Platform.script.toFilePath();
      new File(name)
          .openRead()
          .pipe(request.response)
          .catchError((e) {/* ignore */});
    });

    var count = 0;
    makeRequest() {
      Socket.connect("127.0.0.1", server.port).then((socket) {
        var data = "GET / HTTP/1.1\r\nContent-Length: 0\r\n\r\n";
        socket.write(data);
        socket.close();
        socket.done.then((_) {
          socket.destroy();
          if (++count < 10) {
            makeRequest();
          } else {
            scheduleMicrotask(server.close);
          }
        });
      });
    }

    makeRequest();
  });
}

void testEarlyClose3() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      var subscription;
      subscription = request.listen((_) {}, onError: (error) {
        // subscription.cancel should not trigger an error.
        subscription.cancel();
        server.close();
      });
    });
    Socket.connect("127.0.0.1", server.port).then((socket) {
      socket.write("GET / HTTP/1.1\r\n");
      socket.write("Content-Length: 10\r\n");
      socket.write("\r\n");
      socket.write("data");
      socket.close();
      socket.listen((_) {}, onError: (_) {});
      socket.done.catchError((_) {});
    });
  });
}

void main() {
  testEarlyClose1();
  testEarlyClose2();
  testEarlyClose3();
}
