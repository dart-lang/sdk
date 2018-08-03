// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'dart:async';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

import 'test_helper.dart';

Future sleep(int milliseconds) {
  Completer completer = new Completer();
  Duration duration = new Duration(milliseconds: milliseconds);
  new Timer(duration, () => completer.complete());
  return completer.future;
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    var params = {};
    var result =
        await isolate.invokeRpcNoUpgrade('_getAllocationProfile', params);
    expect(result['type'], equals('AllocationProfile'));
    expect(result.containsKey('dateLastAccumulatorReset'), isFalse);
    expect(result.containsKey('dateLastServiceGC'), isFalse);
    expect(result['heaps'].length, isPositive);
    expect(result['heaps']['new']['type'], equals('HeapSpace'));
    expect(result['heaps']['old']['type'], equals('HeapSpace'));
    expect(result['members'].length, isPositive);
    expect(result['members'][0]['type'], equals('ClassHeapStats'));

    // reset.
    params = {
      'reset': 'true',
    };
    result = await isolate.invokeRpcNoUpgrade('_getAllocationProfile', params);
    expect(result['type'], equals('AllocationProfile'));
    var firstReset = result['dateLastAccumulatorReset'];
    expect(firstReset, new isInstanceOf<String>());
    expect(result.containsKey('dateLastServiceGC'), isFalse);
    expect(result['heaps'].length, isPositive);
    expect(result['heaps']['new']['type'], equals('HeapSpace'));
    expect(result['heaps']['old']['type'], equals('HeapSpace'));
    expect(result['members'].length, isPositive);
    expect(result['members'][0]['type'], equals('ClassHeapStats'));

    await sleep(1000);

    result = await isolate.invokeRpcNoUpgrade('_getAllocationProfile', params);
    var secondReset = result['dateLastAccumulatorReset'];
    expect(secondReset, isNot(equals(firstReset)));

    // gc.
    params = {
      'gc': 'full',
    };
    result = await isolate.invokeRpcNoUpgrade('_getAllocationProfile', params);
    expect(result['type'], equals('AllocationProfile'));
    expect(result['dateLastAccumulatorReset'], equals(secondReset));
    var firstGC = result['dateLastServiceGC'];
    expect(firstGC, new isInstanceOf<String>());
    expect(result['heaps'].length, isPositive);
    expect(result['heaps']['new']['type'], equals('HeapSpace'));
    expect(result['heaps']['old']['type'], equals('HeapSpace'));
    expect(result['members'].length, isPositive);
    expect(result['members'][0]['type'], equals('ClassHeapStats'));

    await sleep(1000);

    result = await isolate.invokeRpcNoUpgrade('_getAllocationProfile', params);
    var secondGC = result['dateLastAccumulatorReset'];
    expect(secondGC, isNot(equals(firstGC)));
  },
  (Isolate isolate) async {
    var params = {
      'reset': 'banana',
    };
    bool caughtException;
    try {
      await isolate.invokeRpcNoUpgrade('_getAllocationProfile', params);
      expect(false, isTrue, reason: 'Unreachable');
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kInvalidParams));
      expect(e.data['details'],
          "_getAllocationProfile: invalid \'reset\' parameter: banana");
    }
    expect(caughtException, isTrue);
  },
  (Isolate isolate) async {
    var params = {
      'gc': 'banana',
    };
    bool caughtException;
    try {
      await isolate.invokeRpcNoUpgrade('_getAllocationProfile', params);
      expect(false, isTrue, reason: 'Unreachable');
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kInvalidParams));
      expect(e.data['details'],
          "_getAllocationProfile: invalid \'gc\' parameter: banana");
    }
    expect(caughtException, isTrue);
  },
];

main(args) async => runIsolateTests(args, tests);
