// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

var tests = <VMTest>[
  (VM vm) async {
    var params = {
      'isolateId': vm.isolates.first.id,
    };
    var result = await vm.invokeRpcNoUpgrade('getMemoryUsage', params);
    expect(result['type'], equals('MemoryUsage'));
    expect(result['heapUsage'], isPositive);
    expect(result['heapCapacity'], isPositive);
    expect(result['externalUsage'], isPositive);
  },
  (VM vm) async {
    var params = {
      'isolateId': 'badid',
    };
    bool caughtException = false;
    try {
      await vm.invokeRpcNoUpgrade('getMemoryUsage', params);
      expect(false, isTrue, reason: 'Unreachable');
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kInvalidParams));
      expect(e.message, "getMemoryUsage: invalid 'isolateId' parameter: badid");
    }
    expect(caughtException, isTrue);
  },

  // Plausible isolate id, not found.
  (VM vm) async {
    var params = {
      'isolateId': 'isolates/9999999999',
    };
    var result = await vm.invokeRpcNoUpgrade('getMemoryUsage', params);
    expect(result['type'], equals('Sentinel'));
    expect(result['kind'], equals('Collected'));
    expect(result['valueAsString'], equals('<collected>'));
  },
];

main(args) async => runVMTests(args, tests);
