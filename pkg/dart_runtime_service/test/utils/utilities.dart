// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:isolate';

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:test/test.dart';

import 'mocks.dart';

/// Creates an instance of [DartRuntimeService] with a
/// [FakeDartRuntimeServiceBackend].
///
/// The returned service is automatically cleaned up when the test completes.
Future<DartRuntimeService> createDartRuntimeServiceForTest({
  required DartRuntimeServiceOptions config,
}) async {
  DartRuntimeService? service;
  addTearDown(() async => await service?.shutdown());

  service = await DartRuntimeService.start(
    config: config,
    backend: FakeDartRuntimeServiceBackend(),
  );
  return service;
}

/// Returns a port available on the IPv4 loopback interface.
Future<int> getAvailablePort() async {
  final tmpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final port = tmpServer.port;
  await tmpServer.close();
  return port;
}

/// Resolves a path as if it was relative to the `test` dir in this package.
Uri resolveTestRelativePath(String relativePath) =>
    Isolate.resolvePackageUriSync(
      Uri.parse('package:dart_runtime_service/'),
    )!.resolve('../test/$relativePath');
