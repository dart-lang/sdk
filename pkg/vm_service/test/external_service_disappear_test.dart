// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service_io.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const serviceName = 'disappearService';
const serviceAlias = 'serviceAlias';
const paramKey = 'pkey';
const paramValue = 'pvalue';
const repetition = 5;

final tests = <IsolateTest>[
  (VmService primaryClient, IsolateRef isolateRef) async {
    final secondaryClient = await vmServiceConnectUri(primaryClient.wsUri!);

    final allRequestsReceivedCompleter = Completer<void>();
    final requests = <Map<String, dynamic>>[];

    // Register the service.
    final serviceMethodName = await registerServiceHelper(
      primaryClient,
      secondaryClient,
      serviceName,
      (params) async {
        final completer = Completer<Map<String, dynamic>>();
        requests.add(params);
        if (requests.length == repetition) {
          allRequestsReceivedCompleter.complete();
        }
        // We never complete this future as we want to see how the client
        // handles the service disappearing while there are outstanding
        // requests.
        return await completer.future;
      },
    );

    // Invoke the service multiple times.
    {
      final results = <Future<Response>>[
        for (int i = 0; i < repetition; ++i)
          primaryClient.callServiceExtension(
            serviceMethodName,
            args: {
              paramKey + i.toString(): paramValue + i.toString(),
            },
          )
            // We ignore these futures so that when they complete with an error
            // without being awaited or do not have an error handler registered
            // they won't cause an unhandled exception.
            ..ignore(),
      ];

      // Wait for all of the requests to be received before processing.
      await allRequestsReceivedCompleter.future;

      // Verify the request parameters as a sanity check.
      for (final params in requests) {
        final iteration = requests.indexOf(params);
        final end = iteration.toString();

        // check requests while they arrive
        expect(params[paramKey + end], paramValue + end);
      }

      // Disconnect the service client that registered the service extension.
      await secondaryClient.dispose();

      // Check that all of the outstanding requests complete with an RPC error.
      for (final future in results) {
        try {
          await future;
          fail('Service should have disappeared');
        } on RPCError catch (e) {
          expect(e.code, RPCErrorKind.kServiceDisappeared.code);
          expect(e.message, 'Service has disappeared');
        }
      }
    }
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'external_service_disappear_test.dart',
    );
