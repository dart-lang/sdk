// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/157296

import 'dart:async';

import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

Future<void> testMain() async {}

final tests = <IsolateTest>[
  hasStoppedAtExit,
  (VmService service, IsolateRef isolateRef) async {
    final continueExtensionExecutionCompleter = Completer<void>();
    final extensionInvokedCompleter = Completer<void>();

    // Setup the service extension.
    const String serviceName = 'testService';
    service.registerServiceCallback(
      serviceName,
      (Map<String, dynamic> params) async {
        extensionInvokedCompleter.complete();
        // Wait for the connection to go down before trying to send the
        // response.
        await continueExtensionExecutionCompleter.future;
        return <String, dynamic>{};
      },
    );
    await service.registerService(serviceName, '');

    // Create a secondary service client to invoke the extension.
    final client = await vmServiceConnectUri(service.wsUri!);
    final serviceExtensionCompleter = Completer<String>();
    client.onServiceEvent.listen((e) {
      if (e.kind == EventKind.kServiceRegistered) {
        print('Service extension registered: ${e.method}');
        serviceExtensionCompleter.complete(e.method!);
      }
    });
    await client.streamListen(EventStreams.kService);

    // Invoke the extension and wait for the extension to begin executing.
    final extensionName = await serviceExtensionCompleter.future;
    unawaited(
      client
          .callServiceExtension(extensionName)
          .catchError((_) => Response(), test: (o) => o is RPCError),
    );
    await extensionInvokedCompleter.future;

    // Dispose the connection for the VmService instance with the service
    // extension registered to simulate the VM service connection disappearing
    // in the middle of handling a service extension request.
    await service.dispose();

    // Resume the service extension handler. This will cause a
    // `Bad state: StreamSink is closed` error if there's a regression.
    continueExtensionExecutionCompleter.complete();

    // Wait a bit to make sure the exception is thrown before the test
    // completes.
    await Future.delayed(const Duration(milliseconds: 200));
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'regress_157296_test.dart',
      testeeConcurrent: testMain,
      pauseOnExit: true,
    );
