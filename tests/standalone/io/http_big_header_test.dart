// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:expect/expect.dart';

// This test checks whether a big header is accepted.

Future<void> testClient(int limit) async {
  final server = await HttpServer.bind('127.0.0.1', 0);
  final str = 'a' * (1000);
  int size = 0;
  server.listen((request) async {
    for (int i = 0; i < 10000; i++) {
      request.response.headers.add('dummy', str);
      size += 1000;
      if (size > limit) {
        break;
      }
    }
    await request.response.close();
    server.close();
  });

  final client = HttpClient();
  final request = await client.get('127.0.0.1', server.port, '/');
  await request.close();
}

Future<void> client() async {
  int i = 64;
  try {
    for (; i < 101 * 1024 * 1024; i *= 100) {
      await testClient(i);
    }
  } on HttpException catch (e) {
    Expect.isTrue(e.toString().contains('size limit'));
    Expect.isTrue(i > 1024 * 1024);
    return;
  }
  Expect.fail('An exception is expected');
}

Future<void> testServer(int limit, int port) async {
  final str = 'a' * (1000);
  final client = HttpClient();
  final request = await client.get('127.0.0.1', port, '/');
  for (int size = 0; size < limit; size += 1000) {
    request.headers.add('dummy', str);
  }
  await request.close();
}

Future<void> server() async {
  final server = await HttpServer.bind('127.0.0.1', 0);
  int i = 64;
  try {
    server.listen((request) async {
      await request.response.close();
    });
    for (; i < 101 * 1024 * 1024; i *= 100) {
      print(i);
      await testServer(i, server.port);
    }
  } on SocketException catch (_) {
    // Server will close on error and writing to the socket will be blocked due
    // to broken pipe.
    Expect.isTrue(i > 1024 * 1024);
    server.close();
    return;
  }
  server.close();
  Expect.fail('An exception is expected');
}

Future<void> main() async {
  await client();
  await server();
}
