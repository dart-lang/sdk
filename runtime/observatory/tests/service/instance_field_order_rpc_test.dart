// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

library get_object_rpc_test;

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

class Super {
  var z = 1;
  var y = 2;
}

class Sub extends Super {
  var y = 3;
  var x = 4;
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
    // Call eval to get a Dart list.
    var evalResult = await eval(isolate, 'new Sub()');
    var params = {
      'objectId': evalResult['id'],
    };
    var result = await isolate.invokeRpcNoUpgrade('getObject', params);
    print(result);
    expect(result['type'], equals('Instance'));
    expect(result['kind'], equals('PlainInstance'));
    expect(result['class']['name'], equals('Sub'));
    expect(result['size'], isPositive);
    expect(result['fields'][0]['decl']['name'], 'z');
    expect(result['fields'][0]['value']['valueAsString'], '1');
    expect(result['fields'][1]['decl']['name'], 'y');
    expect(result['fields'][1]['value']['valueAsString'], '2');
    expect(result['fields'][2]['decl']['name'], 'y');
    expect(result['fields'][2]['value']['valueAsString'], '3');
    expect(result['fields'][3]['decl']['name'], 'x');
    expect(result['fields'][3]['value']['valueAsString'], '4');
  },
];

main(args) async => runIsolateTests(args, tests);
