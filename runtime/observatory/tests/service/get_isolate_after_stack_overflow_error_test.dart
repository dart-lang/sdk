// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';
import 'service_test_common.dart';

// Non tailable recursive function that should trigger a Stack Overflow.
num factorialGrowth([num n = 1]) {
  return factorialGrowth(n + 1) * n;
}

void nonTailableRecursion() {
  factorialGrowth();
}

var tests = <IsolateTest>[
  hasStoppedAtExit,
  (Isolate isolate) async {
    await isolate.reload();
    expect(isolate.error, isNotNull);
    expect(isolate.error!.message!.contains('Stack Overflow'), isTrue);
  }
];

main(args) async => runIsolateTests(args, tests,
    pause_on_exit: true, testeeConcurrent: nonTailableRecursion);
