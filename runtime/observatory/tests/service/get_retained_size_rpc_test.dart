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

@pragma("vm:entry-point")
var myVar;

@pragma("vm:entry-point")
invoke1() => myVar = new _TestClass(null, null);

@pragma("vm:entry-point")
invoke2() => myVar = new _TestClass(new _TestClass(null, null), null);

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
    // One instance of _TestClass retained.
    var evalResult = await invoke(isolate, 'invoke1');
    var params = {
      'targetId': evalResult['id'],
    };
    var result = await isolate.invokeRpcNoUpgrade('_getRetainedSize', params);
    expect(result['type'], equals('@Instance'));
    expect(result['kind'], equals('Int'));
    int value1 = int.parse(result['valueAsString']);
    expect(value1, isPositive);

    // Two instances of _TestClass retained.
    evalResult = await invoke(isolate, 'invoke2');
    params = {
      'targetId': evalResult['id'],
    };
    result = await isolate.invokeRpcNoUpgrade('_getRetainedSize', params);
    expect(result['type'], equals('@Instance'));
    expect(result['kind'], equals('Int'));
    int value2 = int.parse(result['valueAsString']);
    expect(value2, isPositive);

    // Size has doubled.
    expect(value2, equals(2 * value1));

    // Get the retained size for class _TestClass.
    params = {
      'targetId': evalResult['class']['id'],
    };
    result = await isolate.invokeRpcNoUpgrade('_getRetainedSize', params);
    expect(result['type'], equals('@Instance'));
    expect(result['kind'], equals('Int'));
    int value3 = int.parse(result['valueAsString']);
    expect(value3, isPositive);
    expect(value3, equals(value2));
  },
];

main(args) async => runIsolateTests(args, tests);
