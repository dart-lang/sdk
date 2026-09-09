// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'common/test_helper.dart';

final rng = Random();

const int maxMessageDelayMs = 200;

/// Creates a WebSocket server.
Future<HttpServer> startServer() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

  server.listen((HttpRequest request) async {
    final ws = await WebSocketTransformer.upgrade(request);

    ws.listen(
      (Object? message) {
        ws.add(message);
      },
      onDone: () {},
      onError: (_) async {
        await ws.close(WebSocketStatus.internalServerError, 'Server Error');
      },
      cancelOnError: true,
    );
  });

  return server;
}

Future<void> randomDelay({int maxMilliseconds = maxMessageDelayMs}) async {
  await Future.delayed(
    Duration(milliseconds: rng.nextInt(maxMilliseconds) + 1),
  );
}

Uri buildUri(HttpServer server) {
  return Uri(scheme: 'ws', host: server.address.host, port: server.port);
}

Future<void> sendText(WebSocket socket, String text) async {
  socket.add(text);

  await randomDelay();
}

Future<void> sendBinary(WebSocket socket, List<int> bytes) async {
  socket.add(Uint8List.fromList(bytes));

  await randomDelay();
}

/// Creates one normal websocket session.
Future<void> runNormalSession(Uri uri) async {
  final socket = await WebSocket.connect(uri.toString());
  await randomDelay();

  final subscription = socket.listen((_) {}, onError: (_) {}, onDone: () {});

  await sendText(socket, 'hello');

  await sendBinary(socket, <int>[1, 2, 3, 4, 5]);

  await sendText(socket, 'dart websocket');

  await sendBinary(
    socket,
    Uint8List.fromList(List<int>.generate(32, (i) => i)),
  );

  await randomDelay(maxMilliseconds: 500);

  socket.pingInterval = const Duration(milliseconds: 200);

  await Future.delayed(const Duration(seconds: 1));

  await socket.close(WebSocketStatus.normalClosure, 'normal shutdown');

  await subscription.cancel();
}

/// Creates one heavy websocket session.
Future<void> runHeavyTrafficSession(Uri uri) async {
  const connectionCount = 5;
  const messagesPerConnection = 50;

  Future<void> runConnection(int id) async {
    final socket = await WebSocket.connect(uri.toString());

    final subscription = socket.listen((_) {}, onError: (_) {}, onDone: () {});

    for (int i = 0; i < messagesPerConnection; i++) {
      await sendText(socket, 'connection-$id message-$i');

      await sendBinary(
        socket,
        List<int>.generate(64, (index) => (index + i) % 256),
      );
    }

    await Future.delayed(const Duration(milliseconds: 500));

    await socket.close(WebSocketStatus.normalClosure, 'heavy traffic complete');

    await subscription.cancel();
  }

  await Future.wait(List.generate(connectionCount, runConnection));
}

Future<void> testMain() async {
  final server = await startServer();
  HttpClient.enableTimelineLogging = true;

  try {
    final uri = buildUri(server);

    // Exercise a normal WebSocket lifecycle.
    await runNormalSession(uri);

    // Exercise multiple concurrent WebSocket connections.
    await runHeavyTrafficSession(uri);

    // Allow profiler events to flush.
    await Future.delayed(const Duration(seconds: 1));
  } finally {
    await server.close(force: true);
  }
}

Future<void> main([List<String> args = const []]) {
  return startServiceTest(testeeBefore: testMain);
}
