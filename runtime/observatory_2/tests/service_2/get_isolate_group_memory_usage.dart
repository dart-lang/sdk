// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

var tests = <VMTest>[
  (VM vm) async {
    final params = {
      'isolateGroupId': vm.isolateGroups.first.id,
    };
    final result =
        await vm.invokeRpcNoUpgrade('getIsolateGroupMemoryUsage', params);
    expect(result['type'], equals('MemoryUsage'));
    expect(result['heapUsage'], isPositive);
    expect(result['heapCapacity'], isPositive);
    expect(result['externalUsage'], isPositive);
  },
  (VM vm) async {
    final params = {
      'isolateGroupId': 'badid',
    };
    bool caughtException;
    try {
      await vm.invokeRpcNoUpgrade('getIsolateGroupMemoryUsage', params);
      expect(false, isTrue, reason: 'Unreachable');
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kInvalidParams));
      expect(e.message,
          "getIsolateGroupMemoryUsage: invalid 'isolateGroupId' parameter: badid");
    }
    expect(caughtException, isTrue);
  },

  // Plausible isolate group id, not found.
  (VM vm) async {
    final params = {
      'isolateGroupId': 'isolateGroups/9999999999',
    };
    final result =
        await vm.invokeRpcNoUpgrade('getIsolateGroupMemoryUsage', params);
    expect(result['type'], equals('Sentinel'));
    expect(result['kind'], equals('Expired'));
    expect(result['valueAsString'], equals('<expired>'));
  },

  // isolate id was passed instead of isolate group id.
  (VM vm) async {
    final params = {
      'isolateId': 'isolates/9999999999',
    };
    final result =
        await vm.invokeRpcNoUpgrade('getIsolateGroupMemoryUsage', params);
    expect(result['type'], equals('Sentinel'));
    expect(result['kind'], equals('Expired'));
    expect(result['valueAsString'], equals('<expired>'));
  },
];

main(args) async => runVMTests(args, tests);
