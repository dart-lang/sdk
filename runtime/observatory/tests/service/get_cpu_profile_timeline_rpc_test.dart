// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

import 'test_helper.dart';

fib(n) {
  if (n < 0) return 0;
  if (n == 0) return 1;
  return fib(n - 1) + fib(n - 2);
}

testeeDo() {
  print("Testee doing something.");
  fib(25);
  print("Testee did something.");
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    var params = {'tags': 'VMUser'};
    var result =
        await isolate.invokeRpcNoUpgrade('_getCpuProfileTimeline', params);
    print(result);
    expect(result['type'], equals('_CpuProfileTimeline'));

    var isString = new isInstanceOf<String>();
    var isInt = new isInstanceOf<int>();

    Map frames = result['stackFrames'];
    for (Map frame in frames.values) {
      expect(frame['category'], isString);
      expect(frame['name'], isString);
      if (frame['parent'] != null) {
        expect(frames.containsKey(frame['parent']), isTrue);
      }
    }

    List events = result['traceEvents'];
    for (Map event in events) {
      expect(event['ph'], equals('P'));
      expect(event['pid'], isInt);
      expect(event['tid'], isInt);
      expect(event['ts'], isInt);
      expect(event['cat'], equals("Dart"));
      expect(frames.containsKey(event['sf']), isTrue);
    }
  },
];

main(args) async => runIsolateTests(args, tests, testeeBefore: testeeDo);
