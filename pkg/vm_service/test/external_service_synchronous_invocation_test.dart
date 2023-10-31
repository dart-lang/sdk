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
const errorMessage = 'Error message';

Future<void> testSuccessService(
  VmService primaryClient,
  VmService secondaryClient,
) async {
  int requestCount = 0;
  final successServiceMethod = await registerServiceHelper(
    primaryClient,
    secondaryClient,
    successServiceName,
    (params) async {
      final i = requestCount.toString();
      expect(params[paramKey + i], paramValue + i);
      ++requestCount;
      return {
        'result': {
          resultKey + i: resultValue + i,
        },
      };
    },
  );

  // Testing serial invocation of service which succeeds
  {
    for (int i = 0; i < repetition; ++i) {
      final response = await primaryClient.callServiceExtension(
        successServiceMethod,
        args: {
          paramKey + i.toString(): paramValue + i.toString(),
        },
      );
      expect(
        response.json![resultKey + i.toString()],
        resultValue + i.toString(),
      );
    }
  }
}

Future<void> testErrorService(
  VmService primaryClient,
  VmService secondaryClient,
) async {
  int requestCount = 0;
  final errorServiceMethod = await registerServiceHelper(
    primaryClient,
    secondaryClient,
    errorServiceName,
    (params) async {
      final i = requestCount++;
      final iStr = i.toString();
      return {
        'error': {
          'code': errorCode + i,
          'data': {errorKey + iStr: errorValue + iStr},
          'message': errorMessage,
        },
      };
    },
  );

  // Testing serial invocation of service which returns an error
  for (int i = 0; i < repetition; ++i) {
    try {
      await primaryClient.callServiceExtension(
        errorServiceMethod,
        args: {
          paramKey + i.toString(): paramValue + i.toString(),
        },
      );
      fail('Response should be an error');
    } on RPCError catch (e) {
      expect(e.code, errorCode + i);
      expect(e.data![errorKey + i.toString()], errorValue + i.toString());
      expect(e.message, errorMessage);
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
