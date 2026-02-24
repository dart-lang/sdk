// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate' as isolate;

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

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
    isolate.Isolate.resolvePackageUriSync(
      Uri.parse('package:dart_runtime_service/'),
    )!.resolve('../test/$relativePath');

/// Registers a service extension and returns the actual service name used to
/// invoke the service.
Future<String> registerServiceHelper({
  required VmService client,
  required VmService serviceProvider,
  required String serviceName,
  required ServiceCallback callback,
}) async {
  final serviceNameCompleter = Completer<String>();
  late final StreamSubscription<void> sub;
  sub = client.onServiceEvent.listen((event) {
    if (event.kind == EventKind.kServiceRegistered &&
        event.method!.endsWith(serviceName)) {
      serviceNameCompleter.complete(event.method!);
      sub.cancel();
    }
  });
  await client.streamListen(EventStreams.kService);

  // Register the service.
  serviceProvider.registerServiceCallback(serviceName, callback);
  await serviceProvider.registerService(serviceName, serviceName);

  // Wait for the service registered event on the non-registering client to get
  // the actual service name.
  final actualServiceName = await serviceNameCompleter.future;
  await client.streamCancel(EventStreams.kService);
  return actualServiceName;
}
