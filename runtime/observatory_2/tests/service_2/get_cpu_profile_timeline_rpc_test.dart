// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory_2/src/repositories/timeline_base.dart';
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';

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

Future checkTimeline(VM vm) async {
  var result = await TimelineRepositoryBase().getCpuProfileTimeline(vm);
  var isString = isA<String>();
  var isInt = isA<int>();
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
  expect(events.length, greaterThan(0), reason: "Should have samples");
  for (Map event in events) {
    expect(event['ph'], equals('P'));
    expect(event['pid'], isInt);
    expect(event['tid'], isInt);
    expect(event['ts'], isInt);
    expect(event['cat'], equals("Dart"));
    expect(frames.containsKey(event['sf']), isTrue);
  }
}

var tests = <VMTest>[
  (VM vm) => checkTimeline(vm),
];

var vmArgs = [
  '--profiler=true',
  '--profile-vm=false', // So this also works with KBC.
];

main(args) async =>
    runVMTests(args, tests, testeeBefore: testeeDo, extraArgs: vmArgs);
