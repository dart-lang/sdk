// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

var tests = <IsolateTest>[
  (Isolate isolate) {
    VM vm = isolate.owner;
    expect(vm.targetCPU, isNotNull);
    expect(vm.architectureBits == 32 || vm.architectureBits == 64, isTrue);
    expect(vm.embedder, equals("Dart VM"));
    expect(vm.currentMemory, isNotNull);
    expect(vm.currentMemory, greaterThan(0));
    expect(vm.currentRSS, isNotNull);
    expect(vm.currentRSS, greaterThan(0));
    expect(vm.maxRSS, isNotNull);
    expect(vm.maxRSS, greaterThan(0));
    expect(vm.maxRSS, greaterThanOrEqualTo(vm.currentRSS));
  },
];

main(args) => runIsolateTests(args, tests);
