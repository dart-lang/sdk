// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'chrome.dart';

/// Tests that [createDriverWithRetry] tries again when creating a session
/// fails, against a fake ChromeDriver, so it needs neither Chrome nor
/// ChromeDriver.
void main() {
  late HttpServer fakeChromeDriver;
  late Uri uri;

  /// How many of the first requests the fake ChromeDriver answers with an
  /// error.
  late int failingRequests;
  late int requests;

  setUp(() async {
    requests = 0;
    fakeChromeDriver = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => fakeChromeDriver.close(force: true));
    uri = Uri.parse('http://127.0.0.1:${fakeChromeDriver.port}/');
    fakeChromeDriver.listen((request) async {
      await request.drain<void>();
      requests++;
      final failed = requests <= failingRequests;
      request.response
        ..statusCode = failed ? HttpStatus.internalServerError : HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode(
            failed
                ? {
                    'status': 13,
                    'value': {'message': 'failure $requests'},
                  }
                : {
                    'sessionId': 'session $requests',
                    'status': 0,
                    'value': <String, Object?>{},
                  },
          ),
        );
      await request.response.close();
    });
  });

  test('returns the session of the first attempt that succeeds', () async {
    failingRequests = 2;
    final driver = await createDriverWithRetry(uri: uri, desired: const {});
    expect(driver.id, 'session 3');
    expect(requests, 3);
  });

  test('does not try again after a successful attempt', () async {
    failingRequests = 0;
    final driver = await createDriverWithRetry(uri: uri, desired: const {});
    expect(driver.id, 'session 1');
    expect(requests, 1);
  });

  test("fails with the last attempt's error after maxAttempts", () async {
    failingRequests = 5;
    await expectLater(
      createDriverWithRetry(uri: uri, desired: const {}, maxAttempts: 2),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('failure 2'),
        ),
      ),
    );
    expect(requests, 2);
  });
}
