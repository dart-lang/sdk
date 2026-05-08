// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:test/test.dart';

import 'utils/matchers.dart';
import 'utils/utilities.dart';

Future<WebSocket> _connectWithAuthCode(
  DartRuntimeService service,
  String authCode,
) {
  return WebSocket.connect(service.uri.replace(path: authCode).toString());
}

void main() {
  group('Authentication tokens:', () {
    test('connection with valid token is accepted', () async {
      final service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(enableLogging: true),
      );
      expectAuthenticationCodesEnabled(service);
      // Expect no exception.
      final ws = await WebSocket.connect(service.uri.toString());
      await ws.close();
    });

    test('connection with invalid token is rejected', () async {
      final service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(enableLogging: true),
      );
      expectAuthenticationCodesEnabled(service);

      expect(
        () async => await _connectWithAuthCode(service, 'invalidAuthCode'),
        throwsConnectionNotUpgradedToWebSocket,
      );
    });

    test('connection with no token is rejected', () async {
      final service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(enableLogging: true),
      );
      expectAuthenticationCodesEnabled(service);
      expect(
        () async => await _connectWithAuthCode(service, ''),
        throwsConnectionNotUpgradedToWebSocket,
      );
    });

    test('connection with no token is accepted when authentication codes are '
        'disabled', () async {
      final service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(
          enableLogging: true,
          disableAuthCodes: true,
        ),
      );
      expectAuthenticationCodesDisabled(service);
      // Expect no exception.
      final ws = await WebSocket.connect(service.uri.toString());
      await ws.close();
    });
  });
}
