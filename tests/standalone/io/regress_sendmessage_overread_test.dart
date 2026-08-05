// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:expect/expect.dart';

Future<void> main() async {
  // sendMessage with control messages is POSIX-only.
  if (!(Platform.isLinux || Platform.isMacOS)) {
    return;
  }

  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final got = Completer<List<int>>();

  server.listen((sock) {
    sock.close();
    got.complete(sock.expand((v) => v).toList());
  });

  final client = await RawSocket.connect(
    InternetAddress.loopbackIPv4,
    server.port,
  );

  // `data` is a plain `List<int>` (not a `Uint8List`), forcing the helper
  // to take its copy path.
  final data = List<int>.generate(16, (i) => i);

  client.sendMessage(const <SocketControlMessage>[], data, 5, 10);
  client.close();

  final received = await got.future.timeout(const Duration(seconds: 5));
  await server.close();

  Expect.equals(10, received.length);
  Expect.listEquals(<int>[5, 6, 7, 8, 9, 10, 11, 12, 13, 14], received);
}
