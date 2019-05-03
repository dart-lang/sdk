// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
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

Future checkTimeline(Isolate isolate, Map params) async {
  print(params);
  var result =
      await isolate.invokeRpcNoUpgrade('_getCpuProfileTimeline', params);
  print(result);
  expect(result['type'], equals('_CpuProfileTimeline'));

  var isString = new isInstanceOf<String>();
  var isInt = new isInstanceOf<int>();
  Map frames = result['stackFrames'];
  expect(frames.length, greaterThan(10), reason: "Should have many samples");
  for (Map frame in frames.values) {
    expect(frame['category'], isString);
    expect(frame['name'], isString);
    if (frame['resolvedUrl'] != null) {
      expect(frame['resolvedUrl'], isString);
    }
    if (frame['parent'] != null) {
      expect(frames.containsKey(frame['parent']), isTrue);
    }
  }

  List events = result['traceEvents'];
  expect(events.length, greaterThan(10), reason: "Should have many samples");
  for (Map event in events) {
    expect(event['ph'], equals('P'));
    expect(event['pid'], isInt);
    expect(event['tid'], isInt);
    expect(event['ts'], isInt);
    expect(event['cat'], equals("Dart"));
    expect(frames.containsKey(event['sf']), isTrue);
  }
}

var tests = <IsolateTest>[
  (Isolate i) => checkTimeline(i, {'tags': 'VMUser'}),
  (Isolate i) => checkTimeline(i, {'tags': 'VMUser', 'code': true}),
  (Isolate i) => checkTimeline(i, {'tags': 'VMUser', 'code': false}),
  (Isolate i) => checkTimeline(i, {'tags': 'VMOnly'}),
  (Isolate i) => checkTimeline(i, {'tags': 'VMOnly', 'code': true}),
  (Isolate i) => checkTimeline(i, {'tags': 'VMOnly', 'code': false}),
  (Isolate i) => checkTimeline(i, {'tags': 'None'}),
  (Isolate i) => checkTimeline(i, {'tags': 'None', 'code': true}),
  (Isolate i) => checkTimeline(i, {'tags': 'None', 'code': false}),
];

var vmArgs = [
  '--profiler=true',
  '--profile-vm=false', // So this also works with DBC and KBC.
  '--timeline_recorder=ring',
  '--timeline_streams=Profiler'
];

main(args) async =>
    runIsolateTests(args, tests, testeeBefore: testeeDo, extraArgs: vmArgs);
