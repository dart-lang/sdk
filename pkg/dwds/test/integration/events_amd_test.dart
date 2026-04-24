// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Timeout(Duration(minutes: 2))
library;

import 'dart:async';
import 'dart:io';

import 'package:dwds/src/events.dart';
import 'package:dwds/src/utilities/server.dart';
import 'package:dwds_test_common/logging.dart';
import 'package:dwds_test_common/test_sdk_configuration.dart';
import 'package:test/test.dart';

import 'events_common.dart';

void main() {
  final provider = TestSdkConfigurationProvider();
  tearDownAll(provider.dispose);

  group('serve requests', () {
    late HttpServer server;

    setUp(() async {
      setCurrentLogWriter();
      server = await startHttpServer('localhost', port: 0);
    });

    tearDown(() async {
      await server.close();
    });

    test('emits HTTP_REQUEST_EXCEPTION event', () async {
      Future<void> throwAsyncException() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        throw Exception('async error');
      }

      // The events stream is a broadcast stream so start listening
      // before the action.
      final events = expectLater(
        pipe(eventStream),
        emitsThrough(
          matchesEvent(DwdsEventKind.httpRequestException, {
            'server': 'FakeServer',
            'exception': startsWith('Exception: async error'),
          }),
        ),
      );

      // Start serving requests with a failing handler in an error zone.
      serveHttpRequests(
        server,
        (request) async {
          unawaited(throwAsyncException());
          return Future.error('error');
        },
        (e, s) {
          emitEvent(DwdsEvent.httpRequestException('FakeServer', '$e:$s'));
        },
      );

      // Send a request.
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('http://localhost:${server.port}/foo'),
      );

      // Ignore the response.
      final response = await request.close();
      await response.drain<void>();

      // Wait for expected events.
      await events;
    });
  });

  testWithDwds(provider: provider);
}
