// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
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

    test('successfully falls back to random port when port is in use and '
        'enableServicePortFallback is true', () async {
      final tmpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(tmpServer.close);

      final service = await createDartRuntimeServiceForTest(
        config: DartRuntimeServiceOptions(
          enableLogging: true,
          port: tmpServer.port,
          enableServicePortFallback: true,
        ),
      );
      expect(service.uri.port, isNot(equals(tmpServer.port)));
      expect(service.uri.port, isNot(equals(0)));
      expect(service.isServerRunning, true);
    });

    test('successfully binds to loopback IPv6 when configured', () async {
      final service = await createDartRuntimeServiceForTest(
        config: const DartRuntimeServiceOptions(
          enableLogging: true,
          host: '::1',
        ),
      );
      expect(service.uri.host, equals('::1'));
      expect(service.isServerRunning, true);
    });

    test('allows non-HTTP backend to start and stop without binding an HTTP '
        'server', () async {
      final service = await DartRuntimeService.initialize(
        config: const DartRuntimeServiceOptions(),
        backendBuilder: _NonHttpBackend.new,
      );
      addTearDown(service.shutdown);

      expect(service.isServerRunning, isTrue);
      expect(
        () => service.uri,
        throwsA(isA<DartRuntimeServiceServerNotRunning>()),
      );

      await service.serverControl(enable: false);
      expect(service.isServerRunning, isFalse);

      await service.serverControl(enable: true);
      expect(service.isServerRunning, isTrue);
    });

    test('default writeLogRecord prints via the current Zone', () async {
      final printed = <String>[];
      await runZoned(
        () async {
          final service = await DartRuntimeService.initialize(
            config: const DartRuntimeServiceOptions(
              autoStart: false,
              enableLogging: true,
            ),
            backendBuilder: _NonHttpBackend.new,
          );
          await service.shutdown();
        },
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, line) => printed.add(line),
        ),
      );
      expect(printed, isNotEmpty);
    });
  });
}

final class _NonHttpBackend extends DartRuntimeServiceBackend {
  _NonHttpBackend(DartRuntimeService frontend) : super(frontend: frontend);

  @override
  IsolateManager get isolateManager => throw UnimplementedError();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> onServiceReady(DartRuntimeService service) async {}

  @override
  Future<void> shutdown() async {}

  @override
  Future<void> clearState() async {}

  @override
  Future<void> onServerStarted() async {}

  @override
  Future<void> onServerShutdown() async {}
}
