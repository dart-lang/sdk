// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service_io.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const successServiceName = 'successService';
const errorServiceName = 'errorService';
const serviceAlias = 'serviceAlias';
const paramKey = 'pkey';
const paramValue = 'pvalue';
const resultKey = 'rkey';
const resultValue = 'rvalue';
const errorCode = 5000;
const errorKey = 'ekey';
const errorValue = 'evalue';
const repetition = 5;

Future<void> testSuccessService(
  VmService primaryClient,
  VmService secondaryClient,
) async {
  final successServiceRequests =
      <(Map<String, dynamic>, Completer<Map<String, dynamic>>)>[];
  final allRequestsReceivedCompleter = Completer<void>();

  final successServiceMethod = await registerServiceHelper(
    primaryClient,
    secondaryClient,
    successServiceName,
    (params) async {
      final completer = Completer<Map<String, dynamic>>();
      successServiceRequests.add((params, completer));
      if (successServiceRequests.length == repetition) {
        allRequestsReceivedCompleter.complete();
      }
      return await completer.future;
    },
  );

  // Testing parallel invocation of service which succeeds
  final results = <Future<Response>>[
    for (int i = 0; i < repetition; ++i)
      primaryClient.callServiceExtension(
        successServiceMethod,
        args: {
          paramKey + i.toString(): paramValue + i.toString(),
        },
      ),
  ];

  // Wait for all of the requests to be received before processing.
  await allRequestsReceivedCompleter.future;

  final completions = <Function>[];
  for (final request in successServiceRequests) {
    final (params, responseCompleter) = request;
    final iteration = successServiceRequests.indexOf(request);
    final end = iteration.toString();

    // check requests while they arrive
    expect(params[paramKey + end], paramValue + end);
    // answer later
    completions.add(() => responseCompleter.complete({
          'result': {
            resultKey + end: resultValue + end,
          },
        }));
  }

  // Shuffle and respond out of order.
  completions.shuffle();
  for (final c in completions) {
    c();
  }

  final responses = await Future.wait(results);
  for (int i = 0; i < responses.length; ++i) {
    final response = responses[i];
    expect(response, isNotNull);
    expect(
      response.json![resultKey + i.toString()],
      resultValue + i.toString(),
    );
  }
}

Future<void> testErrorService(
  VmService primaryClient,
  VmService secondaryClient,
) async {
  final serviceRequests =
      <(Map<String, dynamic>, Completer<Map<String, dynamic>>)>[];
  final allRequestsReceivedCompleter = Completer<void>();

  final errorServiceMethod = await registerServiceHelper(
    primaryClient,
    secondaryClient,
    errorServiceName,
    (params) async {
      final completer = Completer<Map<String, dynamic>>();
      serviceRequests.add((params, completer));
      if (serviceRequests.length == repetition) {
        allRequestsReceivedCompleter.complete();
      }
      return await completer.future;
    },
  );

  // Testing parallel invocation of service which returns an error
  final results = <Future<Response>>[
    for (int i = 0; i < repetition; ++i)
      primaryClient.callServiceExtension(
        errorServiceMethod,
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

  final completions = <Function>[];
  for (final request in serviceRequests) {
    final (params, responseCompleter) = request;
    final iteration = serviceRequests.indexOf(request);
    final end = iteration.toString();

    // check requests while they arrive
    expect(params[paramKey + end], paramValue + end);
    // answer later
    completions.add(
      () => responseCompleter.complete(
        {
          'error': {
            'code': errorCode + iteration,
            'data': {errorKey + end: errorValue + end},
            'message': 'error message',
          },
        },
      ),
    );
  }

  // Shuffle and respond out of order.
  completions.shuffle();
  for (final c in completions) {
    c();
  }

  for (int i = 0; i < results.length; ++i) {
    final response = results[i];
    try {
      await response;
      fail('Response should be an error');
    } on RPCError catch (e) {
      expect(
        e.data![errorKey + i.toString()],
        errorValue + i.toString(),
      );
    }
  }
}

final tests = <IsolateTest>[
  (VmService primaryClient, IsolateRef isolateRef) async {
    final secondaryClient = await vmServiceConnectUri(primaryClient.wsUri!);
    await testSuccessService(primaryClient, secondaryClient);
    await testErrorService(primaryClient, secondaryClient);
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'external_service_asynchronous_invocation_test.dart',
    );
