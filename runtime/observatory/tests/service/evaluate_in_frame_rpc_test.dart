// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

void method(int value, _) {
  debugger();
}

void testFunction() {
  int i = 0;
  while (true) {
    if (++i % 100000000 == 0) {
      method(10000, 50);
    }
  }
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,

// Evaluate against library, class, and instance.
  (Isolate isolate) async {
    Instance result;
    result = await isolate.evalFrame(0, 'value') as Instance;
    expect(result.valueAsString, equals('10000'));

    result = await isolate.evalFrame(0, '_') as Instance;
    expect(result.valueAsString, equals('50'));

    result = await isolate.evalFrame(0, 'value + _') as Instance;
    expect(result.valueAsString, equals('10050'));

    result = await isolate.evalFrame(1, 'i') as Instance;
    expect(result.valueAsString, equals('100000000'));
  },
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
