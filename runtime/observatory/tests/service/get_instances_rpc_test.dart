// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

class _TestClass {
  _TestClass(this.x, this.y);
  // Make sure these fields are not removed by the tree shaker.
  @pragma("vm:entry-point")
  var x;
  @pragma("vm:entry-point")
  var y;
}

var global;

void warmup() {
  global = new _TestClass(new _TestClass(1, 2), null);
}

@pragma("vm:entry-point")
getGlobal() => global;

invoke(Isolate isolate, String selector) async {
  Map params = {
    'targetId': isolate.rootLibrary.id,
    'selector': selector,
    'argumentIds': <String>[],
  };
  return await isolate.invokeRpcNoUpgrade('invoke', params);
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    var obj = await invoke(isolate, 'getGlobal');
    var params = {
      'objectId': obj['class']['id'],
      'limit': 4,
    };
    var result = await isolate.invokeRpcNoUpgrade('getInstances', params);
    expect(result['type'], equals('InstanceSet'));
    expect(result['totalCount'], equals(2));
    expect(result['instances'].length, equals(2));
    expect(result['instances'][0]['type'], equals('@Instance'));

    // Limit is respected.
    params = {
      'objectId': obj['class']['id'],
      'limit': 1,
    };
    result = await isolate.invokeRpcNoUpgrade('getInstances', params);
    expect(result['type'], equals('InstanceSet'));
    expect(result['totalCount'], equals(2));
    expect(result['instances'].length, equals(1));
    expect(result['instances'][0]['type'], equals('@Instance'));

    // Try an object ID that isn't a class ID
    params = {
      'objectId': isolate.rootLibrary.id,
      'limit': 1,
    };
    try {
      await isolate.invokeRpcNoUpgrade('getInstances', params);
    } on ServerRpcException catch (_) {
      // Success.
    } catch (e) {
      fail('Failed with exception: $e');
    }
  },
];

main(args) async => runIsolateTests(args, tests, testeeBefore: warmup);
