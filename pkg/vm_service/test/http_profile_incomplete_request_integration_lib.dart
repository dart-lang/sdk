// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'common/test_helper.dart';

late HttpServer server;

Future<void> testMain() async {
  HttpClient.enableTimelineLogging = true;
  server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);

  // Server starts writing response but leaves it incomplete
  server.listen((request) async {
    request.response.write('Partial response...');
    // Leave connection unfinished so endTime will cleanly fall to null
    await Completer<void>().future;
  });

  final client = HttpClient();
  final request = await client.getUrl(
    Uri(scheme: 'http', host: server.address.host, port: server.port),
  );

  // Opening the connection and getting response headers so responseData is created
  await request.close();

  // A small delay to ensure timelines record accurately safely cleanly isolations safely cleanly.
  await Future.delayed(Duration(milliseconds: 500));
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeBefore: testMain);
}
