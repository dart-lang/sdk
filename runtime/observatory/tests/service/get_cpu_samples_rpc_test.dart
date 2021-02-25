// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
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

Future checkSamples(Isolate isolate) async {
  final result =
      await isolate.invokeRpcNoUpgrade('getCpuSamples', {'_code': true});
  expect(result['type'], equals('CpuSamples'));

  final isString = isA<String>();
  final isInt = isA<int>();
  final isList = isA<List>();
  final functions = result['functions'];
  expect(functions.length, greaterThan(10),
      reason: "Should have many functions");
  final codes = result['_codes'];
  expect(functions.length, greaterThan(10),
      reason: "Should have many code objects");

  final samples = result['samples'];
  expect(samples.length, greaterThan(0), reason: "Should have samples");
  final sample = samples.first;
  expect(sample['tid'], isInt);
  expect(sample['timestamp'], isInt);
  if (sample.containsKey('vmTag')) {
    expect(sample['vmTag'], isString);
  }
  if (sample.containsKey('userTag')) {
    expect(sample['userTag'], isString);
  }
  expect(sample['stack'], isList);
  expect(sample['_codeStack'], isList);
}

var tests = <IsolateTest>[
  (Isolate i) => checkSamples(i),
];

var vmArgs = [
  '--profiler=true',
  '--profile-vm=false', // So this also works with KBC.
];

main(args) async =>
    runIsolateTests(args, tests, testeeBefore: testeeDo, extraArgs: vmArgs);
