// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

class _TestClass {
  _TestClass();
  var x;
  var y;
}

class _TestConst {
  const _TestConst();
}

_TopLevelClosure() {}

var x;
var fn;

void warmup() {
  x = const _TestConst();
  fn = _TopLevelClosure;
}

@pragma("vm:entry-point")
getX() => x;

@pragma("vm:entry-point")
getFn() => fn;

invoke(Isolate isolate, String selector) async {
  Map params = {
    'targetId': isolate.rootLibrary.id,
    'selector': selector,
    'argumentIds': <String>[],
  };
  return await isolate.invokeRpcNoUpgrade('invoke', params);
}

var tests = <IsolateTest>[
  // Expect a simple path through variable x instead of long path filled
  // with VM objects
  (Isolate isolate) async {
    var target1 = await invoke(isolate, 'getX');
    var params = {
      'targetId': target1['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('getRetainingPath', params);
    expect(result['type'], equals('RetainingPath'));
    expect(result['elements'].length, equals(2));
    expect(
        result['elements'][0]['value']['class']['name'], equals('_TestConst'));
    expect(result['elements'][1]['value']['name'], equals('x'));
  },

  // Expect a simple path through variable fn instead of long path filled
  // with VM objects
  (Isolate isolate) async {
    var target2 = await invoke(isolate, 'getFn');
    var params = {
      'targetId': target2['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('getRetainingPath', params);
    expect(result['type'], equals('RetainingPath'));
    expect(result['elements'].length, equals(2));
    expect(result['elements'][0]['value']['class']['name'], equals('_Closure'));
    expect(result['elements'][1]['value']['name'], equals('fn'));
  }
];

main(args) async => runIsolateTests(args, tests, testeeBefore: warmup);
