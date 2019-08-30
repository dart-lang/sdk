// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  fib(30);
  print("Testee did something.");
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    var params = {'tags': 'None'};
    var result =
        await isolate.invokeRpcNoUpgrade('_writeCpuProfileTimeline', params);
    print(result);
    expect(result['type'], equals('Success'));

    result = await isolate.vm.invokeRpcNoUpgrade('getVMTimeline', {});
    expect(result['type'], equals('Timeline'));
    expect(result['traceEvents'], new isInstanceOf<List>());

    var events = result['traceEvents'];
    print(events);
    var profilerSampleEvents = result['traceEvents'].where((event) {
      return event['name'] == "Dart CPU sample";
    }).toList();

    var isString = new isInstanceOf<String>();
    var isInt = new isInstanceOf<int>();

    expect(profilerSampleEvents.length, greaterThan(10),
        reason: "Should have many samples");
    for (Map event in profilerSampleEvents) {
      print(event);

      // Sadly this is an "Instant" event because there is no way to add a
      // proper "Sample" event in Fuchsia's tracing.
      expect(event['ph'], equals('i'));

      expect(event['pid'], isInt);
      expect(event['tid'], isInt);
      expect(event['ts'], isInt);
      expect(event['cat'], equals("Developer"));
      expect(event['args']['backtrace'], isString);
    }
  },
];

var vmArgs = [
  '--profiler=true',
  '--profile-vm=false', // So this also works with DBC and KBC.
  '--timeline_recorder=ring',
  '--timeline_streams=Developer'
];

main(args) async =>
    runIsolateTests(args, tests, testeeBefore: testeeDo, extraArgs: vmArgs);
