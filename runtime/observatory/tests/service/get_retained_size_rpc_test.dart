// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

import 'test_helper.dart';

class _TestClass {
  _TestClass(this.x, this.y);
  var x;
  var y;
}

var myVar;

eval(Isolate isolate, String expression) async {
  // Silence analyzer.
  new _TestClass(null, null);
  Map params = {
    'targetId': isolate.rootLibrary.id,
    'expression': expression,
  };
  return await isolate.invokeRpcNoUpgrade('evaluate', params);
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    // One instance of _TestClass retained.
    var evalResult = await eval(isolate, 'myVar = new _TestClass(null, null)');
    var params = {
      'targetId': evalResult['id'],
    };
    var result = await isolate.invokeRpcNoUpgrade('_getRetainedSize', params);
    expect(result['type'], equals('@Instance'));
    expect(result['kind'], equals('Int'));
    int value1 = int.parse(result['valueAsString']);
    expect(value1, isPositive);

    // Two instances of _TestClass retained.
    evalResult = await eval(
        isolate, 'myVar = new _TestClass(new _TestClass(null, null), null)');
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
