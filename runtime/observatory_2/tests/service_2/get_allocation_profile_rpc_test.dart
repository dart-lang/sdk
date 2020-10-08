// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';

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
    expect(result['_heaps'].length, isPositive);
    expect(result['_heaps']['new']['type'], equals('HeapSpace'));
    expect(result['_heaps']['old']['type'], equals('HeapSpace'));
    expect(result['members'].length, isPositive);

    var member = result['members'][0];
    expect(member['type'], equals('ClassHeapStats'));
    expect(member.containsKey('_new'), isTrue);
    expect(member.containsKey('_old'), isTrue);
    expect(member.containsKey('instancesAccumulated'), isTrue);
    expect(member.containsKey('instancesCurrent'), isTrue);
    expect(member.containsKey('bytesCurrent'), isTrue);
    expect(member.containsKey('accumulatedSize'), isTrue);

    // reset.
    params = {
      'reset': 'true',
    };
    result = await isolate.invokeRpcNoUpgrade('_getAllocationProfile', params);
    expect(result['type'], equals('AllocationProfile'));
    var firstReset = result['dateLastAccumulatorReset'];
    expect(firstReset, isA<String>());
    expect(result.containsKey('dateLastServiceGC'), isFalse);
    expect(result['_heaps'].length, isPositive);
    expect(result['_heaps']['new']['type'], equals('HeapSpace'));
    expect(result['_heaps']['old']['type'], equals('HeapSpace'));
    expect(result['members'].length, isPositive);

    member = result['members'][0];
    expect(member['type'], equals('ClassHeapStats'));
    expect(member.containsKey('_new'), isTrue);
    expect(member.containsKey('_old'), isTrue);
    expect(member.containsKey('instancesAccumulated'), isTrue);
    expect(member.containsKey('instancesCurrent'), isTrue);
    expect(member.containsKey('bytesCurrent'), isTrue);
    expect(member.containsKey('accumulatedSize'), isTrue);

    await sleep(1000);

    result = await isolate.invokeRpcNoUpgrade('_getAllocationProfile', params);
    var secondReset = result['dateLastAccumulatorReset'];
    expect(secondReset, isNot(equals(firstReset)));

    // gc.
    params = {
      'gc': 'true',
    };
    result = await isolate.invokeRpcNoUpgrade('_getAllocationProfile', params);
    expect(result['type'], equals('AllocationProfile'));
    expect(result['dateLastAccumulatorReset'], equals(secondReset));
    var firstGC = result['dateLastServiceGC'];
    expect(firstGC, isA<String>());
    expect(result['_heaps'].length, isPositive);
    expect(result['_heaps']['new']['type'], equals('HeapSpace'));
    expect(result['_heaps']['old']['type'], equals('HeapSpace'));
    expect(result['members'].length, isPositive);

    member = result['members'][0];
    expect(member['type'], equals('ClassHeapStats'));
    expect(member.containsKey('_new'), isTrue);
    expect(member.containsKey('_old'), isTrue);
    expect(member.containsKey('instancesAccumulated'), isTrue);
    expect(member.containsKey('instancesCurrent'), isTrue);
    expect(member.containsKey('bytesCurrent'), isTrue);
    expect(member.containsKey('accumulatedSize'), isTrue);

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
