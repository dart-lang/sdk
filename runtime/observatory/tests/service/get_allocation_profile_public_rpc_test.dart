// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:observatory/service_io.dart';
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
        await isolate.invokeRpcNoUpgrade('getAllocationProfile', params);
    expect(result['type'], equals('AllocationProfile'));
    expect(result.containsKey('dateLastAccumulatorReset'), isFalse);
    expect(result.containsKey('dateLastServiceGC'), isFalse);
    expect(result.containsKey('_heaps'), isFalse);
    expect(result['members'].length, isPositive);

    var member = result['members'][0];
    expect(member['type'], equals('ClassHeapStats'));
    expect(member.containsKey('_new'), isFalse);
    expect(member.containsKey('_old'), isFalse);
    expect(member.containsKey('_promotedInstances'), isFalse);
    expect(member.containsKey('_promotedBytes'), isFalse);
    expect(member.containsKey('instancesAccumulated'), isTrue);
    expect(member.containsKey('instancesCurrent'), isTrue);
    expect(member.containsKey('bytesCurrent'), isTrue);
    expect(member.containsKey('accumulatedSize'), isTrue);

    // reset.
    params = {
      'reset': 'true',
    };
    result = await isolate.invokeRpcNoUpgrade('getAllocationProfile', params);
    expect(result['type'], equals('AllocationProfile'));
    var firstReset = result['dateLastAccumulatorReset'];
    expect(firstReset, isA<String>());
    expect(result.containsKey('dateLastServiceGC'), isFalse);
    expect(result.containsKey('_heaps'), isFalse);
    expect(result['members'].length, isPositive);

    member = result['members'][0];
    expect(member['type'], equals('ClassHeapStats'));
    expect(member.containsKey('_new'), isFalse);
    expect(member.containsKey('_old'), isFalse);
    expect(member.containsKey('_promotedInstances'), isFalse);
    expect(member.containsKey('_promotedBytes'), isFalse);
    expect(member.containsKey('instancesAccumulated'), isTrue);
    expect(member.containsKey('instancesCurrent'), isTrue);
    expect(member.containsKey('bytesCurrent'), isTrue);
    expect(member.containsKey('accumulatedSize'), isTrue);

    await sleep(1000);

    result = await isolate.invokeRpcNoUpgrade('getAllocationProfile', params);
    var secondReset = result['dateLastAccumulatorReset'];
    expect(secondReset, isNot(equals(firstReset)));

    // gc.
    params = {
      'gc': 'true',
    };
    result = await isolate.invokeRpcNoUpgrade('getAllocationProfile', params);
    expect(result['type'], equals('AllocationProfile'));
    expect(result['dateLastAccumulatorReset'], equals(secondReset));
    var firstGC = result['dateLastServiceGC'];
    expect(firstGC, isA<String>());
    expect(result.containsKey('_heaps'), isFalse);
    expect(result['members'].length, isPositive);

    member = result['members'][0];
    expect(member['type'], equals('ClassHeapStats'));
    expect(member.containsKey('_new'), isFalse);
    expect(member.containsKey('_old'), isFalse);
    expect(member.containsKey('_promotedInstances'), isFalse);
    expect(member.containsKey('_promotedBytes'), isFalse);
    expect(member.containsKey('instancesAccumulated'), isTrue);
    expect(member.containsKey('instancesCurrent'), isTrue);
    expect(member.containsKey('bytesCurrent'), isTrue);
    expect(member.containsKey('accumulatedSize'), isTrue);

    await sleep(1000);

    result = await isolate.invokeRpcNoUpgrade('getAllocationProfile', params);
    var secondGC = result['dateLastAccumulatorReset'];
    expect(secondGC, isNot(equals(firstGC)));
  },
  (Isolate isolate) async {
    var params = {
      'reset': 'banana',
    };
    bool caughtException = false;
    try {
      await isolate.invokeRpcNoUpgrade('getAllocationProfile', params);
      expect(false, isTrue, reason: 'Unreachable');
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kInvalidParams));
      expect(e.data!['details'],
          "getAllocationProfile: invalid \'reset\' parameter: banana");
    }
    expect(caughtException, isTrue);
  },
  (Isolate isolate) async {
    var params = {
      'gc': 'banana',
    };
    bool caughtException = false;
    try {
      await isolate.invokeRpcNoUpgrade('getAllocationProfile', params);
      expect(false, isTrue, reason: 'Unreachable');
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kInvalidParams));
      expect(e.data!['details'],
          "getAllocationProfile: invalid \'gc\' parameter: banana");
    }
    expect(caughtException, isTrue);
  },
];

main(args) async => runIsolateTests(args, tests);
