// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:test/test.dart';

import 'utils/matchers.dart';
import 'utils/utilities.dart';

void main() {
  group('Server configuration:', () {
    test('successfully binds to specified port', () async {
      final port = await getAvailablePort();
      final service = await createDartRuntimeServiceForTest(
        config: DartRuntimeServiceOptions(enableLogging: true, port: port),
      );
      expect(service.uri.port, port);
    });

    test('fails to binds to specified port already in use', () async {
      final tmpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(tmpServer.close);

      expect(
        () async => await createDartRuntimeServiceForTest(
          config: DartRuntimeServiceOptions(
            enableLogging: true,
            port: tmpServer.port,
          ),
        ),
        throwsFailedToStartException,
      );
    });
  });
}
