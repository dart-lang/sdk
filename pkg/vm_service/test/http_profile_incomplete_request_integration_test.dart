// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

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

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;

    // Fetch HTTP profiles which calls _createHttpProfileRequestFromProfileMap
    // on this incomplete connection. Safely logic should assert safely no TypeError.
    final profile = await service.getHttpProfile(isolateId);
    expect(profile.requests.length, greaterThanOrEqualTo(1));

    final requestId = profile.requests.first.id;
    await service.getHttpProfileRequest(isolateId, requestId);
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'http_profile_incomplete_request_integration_test.dart',
      testeeBefore: testMain,
    );
