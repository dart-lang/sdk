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

var global;

void warmup() {
  global = new _TestClass(new _TestClass(1, 2), null);
}

eval(Isolate isolate, String expression) async {
  Map params = {
    'targetId': isolate.rootLibrary.id,
    'expression': expression,
  };
  return await isolate.invokeRpcNoUpgrade('evaluate', params);
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    var obj = await eval(isolate, 'global');
    var params = {
      'classId': obj['class']['id'],
      'limit': 4,
    };
    var result = await isolate.invokeRpcNoUpgrade('_getInstances', params);
    expect(result['type'], equals('InstanceSet'));
    expect(result['totalCount'], equals(2));
    expect(result['samples'].length, equals(2));
    expect(result['samples'][0]['type'], equals('@Instance'));

    // Limit is respected.
    params = {
      'classId': obj['class']['id'],
      'limit': 1,
    };
    result = await isolate.invokeRpcNoUpgrade('_getInstances', params);
    expect(result['type'], equals('InstanceSet'));
    expect(result['totalCount'], equals(2));
    expect(result['samples'].length, equals(1));
    expect(result['samples'][0]['type'], equals('@Instance'));
  },
];

main(args) async => runIsolateTests(args, tests, testeeBefore: warmup);
