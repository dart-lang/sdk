// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

import "dart:async";
import "dart:io";

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

void testHttp10Close(bool closeRequest) {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      request.response.close();
    });

    Socket.connect("127.0.0.1", server.port).then((socket) {
      socket.write("GET / HTTP/1.0\r\n\r\n");
      socket.listen(
        (data) {},
        onDone: () {
          if (!closeRequest) socket.destroy();
          server.close();
        },
      );
      if (closeRequest) socket.close();
    });
  });
}

void testHttp11Close(bool closeRequest) {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      request.response.close();
    });

    Socket.connect("127.0.0.1", server.port).then((socket) {
      List<int> buffer = new List<int>.filled(1024, 0);
      socket.write("GET / HTTP/1.1\r\nConnection: close\r\n\r\n");
      socket.listen(
        (data) {},
        onDone: () {
          if (!closeRequest) socket.destroy();
          server.close();
        },
      );
      if (closeRequest) socket.close();
    });
  });
}

void testStreamResponse() {
  HttpServer.bind("127.0.0.1", 0).then((server) {
    server.listen((request) {
      var timer = new Timer.periodic(const Duration(milliseconds: 0), (_) {
        request.response.write(
          'data:${new DateTime.now().millisecondsSinceEpoch}\n\n',
        );
      });
      request.response.done
          .whenComplete(() {
            timer.cancel();
          })
          .catchError((_) {});
    });

    var client = new HttpClient();
    client
        .getUrl(Uri.parse("http://127.0.0.1:${server.port}"))
        .then((request) => request.close())
        .then((response) {
          int bytes = 0;
          response.listen(
            (data) {
              bytes += data.length;
              if (bytes > 100) {
                client.close(force: true);
              }
            },
            onError: (error) {
              server.close();
            },
          );
        });
  });
}

Future<void> testStreamResponseFlush() async {
  final server = await HttpServer.bind("127.0.0.1", 0);
  final doneCompleter = Completer<Object?>();
  final handlerFinished = Completer<void>();

  server.listen((request) async {
    final response = request.response..bufferOutput = false;
    unawaited(response.done.then(doneCompleter.complete));
    while (!doneCompleter.isCompleted) {
      response.write("data: tick\n\n");
      await response.flush();
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    // Subsequent writes, flushes, and close remain silent after disconnect.
    response.write("data: after-disconnect\n\n");
    await response.flush();
    Expect.equals(response, await response.close());
    handlerFinished.complete();
  });

  final socket = await Socket.connect("127.0.0.1", server.port);
  socket.write("GET / HTTP/1.1\r\nHost: localhost\r\n\r\n");
  await socket.flush();
  await socket.first;
  socket.destroy();

  final doneValue = await doneCompleter.future;
  Expect.isTrue(doneValue is HttpResponse);
  await handlerFinished.future;
  Expect.equals(0, server.connectionsInfo().active);
  await server.close();
}

Future<void> testCloseInsideDoneDuringFlush() async {
  final server = await HttpServer.bind("127.0.0.1", 0);
  final closeFromDone = Completer<Object?>();
  final handlerFinished = Completer<void>();

  server.listen((request) async {
    final response = request.response..bufferOutput = false;
    unawaited(
      response.done.then((_) {
        // Calling close() inside a done callback must not throw StateError
        // ("StreamSink is bound to a stream") while flush() unwinds.
        closeFromDone.complete(response.close());
      }),
    );
    while (!closeFromDone.isCompleted) {
      response.write("data: tick\n\n");
      await response.flush();
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    Expect.equals(response, await closeFromDone.future);
    handlerFinished.complete();
  });

  final socket = await Socket.connect("127.0.0.1", server.port);
  socket.write("GET / HTTP/1.1\r\nHost: localhost\r\n\r\n");
  await socket.flush();
  await socket.first;
  socket.destroy();

  await handlerFinished.future;
  Expect.equals(0, server.connectionsInfo().active);
  await server.close();
}

Future<void> testFlushAfterUnflushedDisconnect() async {
  final server = await HttpServer.bind("127.0.0.1", 0);
  final handlerFinished = Completer<void>();

  server.listen((request) async {
    final response = request.response..bufferOutput = false;
    var isDone = false;
    unawaited(response.done.then((_) => isDone = true));
    while (!isDone) {
      response.write("data: tick\n\n");
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    // Calling flush() and addStream() after an unflushed write triggered
    // disconnect must not hang on a stale _controllerCompleter.
    Expect.equals(response, await response.flush());
    Expect.equals(
      response,
      await response.addStream(
        Stream<List<int>>.fromIterable([
          [1, 2, 3],
        ]),
      ),
    );
    response.write("data: after\n\n");
    Expect.equals(response, await response.close());
    handlerFinished.complete();
  });

  final socket = await Socket.connect("127.0.0.1", server.port);
  socket.write("GET / HTTP/1.1\r\nHost: localhost\r\n\r\n");
  await socket.flush();
  await socket.first;
  socket.destroy();

  await handlerFinished.future;
  Expect.equals(0, server.connectionsInfo().active);
  await server.close();
}

Future<void> testAddStreamResponseDisconnect() async {
  final server = await HttpServer.bind("127.0.0.1", 0);
  final doneCompleter = Completer<Object?>();
  final addStreamFinished = Completer<void>();

  server.listen((request) async {
    final response = request.response..bufferOutput = false;
    unawaited(response.done.then(doneCompleter.complete));
    final stream = Stream<List<int>>.periodic(
      const Duration(milliseconds: 10),
      (_) => "data: tick\n\n".codeUnits,
    );
    await response.addStream(stream);
    // done must complete before close() is called.
    Expect.equals(response, await doneCompleter.future);
    response.write("data: after-stream\n\n");
    Expect.equals(response, await response.close());
    addStreamFinished.complete();
  });

  final socket = await Socket.connect("127.0.0.1", server.port);
  socket.write("GET / HTTP/1.1\r\nHost: localhost\r\n\r\n");
  await socket.flush();
  await socket.first;
  socket.destroy();

  await addStreamFinished.future;
  Expect.isTrue(await doneCompleter.future is HttpResponse);
  Expect.equals(0, server.connectionsInfo().active);
  await server.close();
}

Future<void> testResetBetweenFlushes() async {
  final server = await HttpServer.bind("127.0.0.1", 0);
  final firstFlushDone = Completer<void>();
  final clientDestroyed = Completer<void>();
  final doneCompleter = Completer<Object?>();
  final handlerFinished = Completer<void>();

  server.listen((request) async {
    final response = request.response..bufferOutput = false;
    unawaited(response.done.then(doneCompleter.complete));
    response.write("data: unread-before-rst\n\n");
    await response.flush();
    firstFlushDone.complete();

    // Wait while no flush/addStream is active so a peer TCP RST arrives on the
    // idle server socket before the next write + flush. On stacks such as
    // Fuchsia Netstack3 where close() with unread data sends a graceful FIN
    // instead of a RST, the first write + flush into CLOSE_WAIT provokes a RST
    // from FIN_WAIT_2 during the idle delay, and the next iteration observes it.
    await clientDestroyed.future;
    await Future<void>.delayed(const Duration(milliseconds: 50));

    while (!doneCompleter.isCompleted) {
      response.write("data: after-idle-rst\n\n");
      Expect.equals(response, await response.flush());
      if (!doneCompleter.isCompleted) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }
    Expect.equals(response, await doneCompleter.future);
    response.write("data: after-done\n\n");
    Expect.equals(response, await response.flush());
    Expect.equals(response, await response.close());
    handlerFinished.complete();
  });

  // Do not read the response body so destroy() closes with unread data in the
  // OS receive buffer and transmits a TCP RST while the server is between
  // flush() calls.
  final socket = await Socket.connect("127.0.0.1", server.port);
  socket.write("GET / HTTP/1.1\r\nHost: localhost\r\n\r\n");
  await socket.flush();
  await firstFlushDone.future;
  await Future<void>.delayed(const Duration(milliseconds: 20));
  socket.destroy();
  clientDestroyed.complete();

  await handlerFinished.future;
  Expect.equals(0, server.connectionsInfo().active);
  await server.close();
}

Future<void> runDisconnectTests() async {
  asyncStart();
  await testStreamResponseFlush();
  await testCloseInsideDoneDuringFlush();
  await testFlushAfterUnflushedDisconnect();
  await testAddStreamResponseDisconnect();
  await testResetBetweenFlushes();
  asyncEnd();
}

void main() {
  testHttp10Close(false);
  testHttp10Close(true);
  testHttp11Close(false);
  testHttp11Close(true);
  testStreamResponse();
  runDisconnectTests();
}
