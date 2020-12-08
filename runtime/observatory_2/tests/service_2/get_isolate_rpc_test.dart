// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

var tests = <VMTest>[
  (VM vm) async {
    var params = {
      'isolateId': vm.isolates.first.id,
    };
    var result = await vm.invokeRpcNoUpgrade('getIsolate', params);
    expect(result['type'], equals('Isolate'));
    expect(result['id'], startsWith('isolates/'));
    expect(result['number'], isA<String>());
    expect(result['isSystemIsolate'], isFalse);
    expect(result['_originNumber'], equals(result['number']));
    expect(result['startTime'], isPositive);
    expect(result['livePorts'], isPositive);
    expect(result['pauseOnExit'], isFalse);
    expect(result['pauseEvent']['type'], equals('Event'));
    expect(result['error'], isNull);
    expect(result['rootLib']['type'], equals('@Library'));
    expect(result['libraries'].length, isPositive);
    expect(result['libraries'][0]['type'], equals('@Library'));
    expect(result['breakpoints'].length, isZero);
    expect(result['_heaps']['new']['type'], equals('HeapSpace'));
    expect(result['_heaps']['old']['type'], equals('HeapSpace'));
  },

  (VM vm) async {
    var params = {
      'isolateId': 'badid',
    };
    bool caughtException;
    try {
      await vm.invokeRpcNoUpgrade('getIsolate', params);
      expect(false, isTrue, reason: 'Unreachable');
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kInvalidParams));
      expect(e.message, "getIsolate: invalid 'isolateId' parameter: badid");
    }
    expect(caughtException, isTrue);
  },

  // Plausible isolate id, not found.
  (VM vm) async {
    var params = {
      'isolateId': 'isolates/9999999999',
    };
    var result = await vm.invokeRpcNoUpgrade('getIsolate', params);
    expect(result['type'], equals('Sentinel'));
    expect(result['kind'], equals('Collected'));
    expect(result['valueAsString'], equals('<collected>'));
  },
];

main(args) async => runVMTests(args, tests);
