// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' as io;

import 'common/test_helper.dart';

const String content = 'some random content';
const String udpContent = 'aghfkjdb';
const String localhost = '127.0.0.1';

Future<void> setup() async {}

Future<void> socketTest() async {
  // Socket
  final serverSocket = await io.ServerSocket.bind(localhost, 0);
  final socket = await io.Socket.connect(localhost, serverSocket.port);
  socket.write(content);
  await socket.flush();
  socket.destroy();

  // rawDatagram
  final doneCompleter = Completer<void>();
  final server = await io.RawDatagramSocket.bind(localhost, 0);
  server.listen((io.RawSocketEvent event) {
    if (event == io.RawSocketEvent.read) {
      server.receive();
      if (!doneCompleter.isCompleted) {
        doneCompleter.complete();
      }
    }
  });
  final client = await io.RawDatagramSocket.bind(localhost, 0);
  client.send(
    utf8.encode(udpContent),
    io.InternetAddress(localhost),
    server.port,
  );
  client.send([1, 2, 3], io.InternetAddress(localhost), server.port);

  // Wait for datagram to arrive.
  await doneCompleter.future;
  // Post finish event
  postEvent('socketTest', {'socket': 'test'});
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeBefore: setup);
}
