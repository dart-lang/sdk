// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

import 'test_helper.dart';

var tests = [
  (Isolate isolate) async {
    var params = {
    };
    var result = await isolate.invokeRpcNoUpgrade(
        '_getAllocationProfile', params);
    expect(result['type'], equals('AllocationProfile'));
    var lastReset = result['dateLastAccumulatorReset'];
    expect(lastReset, new isInstanceOf<String>());
    var lastGC = result['dateLastServiceGC'];
    expect(lastGC, new isInstanceOf<String>());
    expect(result['heaps'].length, isPositive);
    expect(result['heaps']['new']['type'], equals('HeapSpace'));
    expect(result['heaps']['old']['type'], equals('HeapSpace'));
    expect(result['members'].length, isPositive);
    expect(result['members'][0]['type'], equals('ClassHeapStats'));

    // reset.
    params = {
      'reset' : 'true',
    };
    result = await isolate.invokeRpcNoUpgrade('_getAllocationProfile', params);
    expect(result['type'], equals('AllocationProfile'));
    var newReset = result['dateLastAccumulatorReset'];
    expect(newReset, isNot(equals(lastReset)));
    expect(result['dateLastServiceGC'], equals(lastGC));
    expect(result['heaps'].length, isPositive);
    expect(result['heaps']['new']['type'], equals('HeapSpace'));
    expect(result['heaps']['old']['type'], equals('HeapSpace'));
    expect(result['members'].length, isPositive);
    expect(result['members'][0]['type'], equals('ClassHeapStats'));

    // gc.
    params = {
      'gc' : 'full',
    };
    result = await isolate.invokeRpcNoUpgrade('_getAllocationProfile', params);
    expect(result['type'], equals('AllocationProfile'));
    expect(result['dateLastAccumulatorReset'], equals(newReset));
    var newGC = result['dateLastServiceGCt'];
    expect(newGC, isNot(equals(lastGC)));
    expect(result['heaps'].length, isPositive);
    expect(result['heaps']['new']['type'], equals('HeapSpace'));
    expect(result['heaps']['old']['type'], equals('HeapSpace'));
    expect(result['members'].length, isPositive);
    expect(result['members'][0]['type'], equals('ClassHeapStats'));
  },

  (Isolate isolate) async {
    var params = {
      'reset' : 'banana',
    };
    bool caughtException;
    try {
      await isolate.invokeRpcNoUpgrade('_getAllocationProfile', params);
      expect(false, isTrue, reason:'Unreachable');
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
      'gc' : 'banana',
    };
    bool caughtException;
    try {
      await isolate.invokeRpcNoUpgrade(
          '_getAllocationProfile', params);
      expect(false, isTrue, reason:'Unreachable');
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
