// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

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

eval(Isolate isolate, String expression) async {
  Map params = {
    'targetId': isolate.rootLibrary.id,
    'expression': expression,
  };
  return await isolate.invokeRpcNoUpgrade('evaluate', params);
}

var tests = [
  // Expect a simple path through variable x instead of long path filled
  // with VM objects
  (Isolate isolate) async {
    var target1 = await eval(isolate, 'x;');
    var params = {
      'targetId': target1['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('_getRetainingPath', params);
    expect(result['type'], equals('RetainingPath'));
    expect(result['elements'].length, equals(2));
    expect(
        result['elements'][0]['value']['class']['name'], equals('_TestConst'));
    expect(result['elements'][1]['value']['name'], equals('x'));
  },

  // Expect a simple path through variable fn instead of long path filled
  // with VM objects
  (Isolate isolate) async {
    var target2 = await eval(isolate, 'fn;');
    var params = {
      'targetId': target2['id'],
      'limit': 100,
    };
    var result = await isolate.invokeRpcNoUpgrade('_getRetainingPath', params);
    expect(result['type'], equals('RetainingPath'));
    expect(result['elements'].length, equals(2));
    expect(result['elements'][0]['value']['class']['name'], equals('_Closure'));
    expect(result['elements'][1]['value']['name'], equals('fn'));
  }
];

main(args) async => runIsolateTests(args, tests, testeeBefore: warmup);
