// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

var tests = <VMTest>[
  (VM vm) async {
    isInstanceOf<int> isInt = new isInstanceOf<int>();
    // Just iterate over all the isolates to confirm they have
    // the correct fields needed to examine zone memory usage.
    for (Isolate isolate in new List.from(vm.isolates)) {
      await isolate.reload();
      expect(isolate.zoneHighWatermark, isInt);
      expect(isolate.threads, isNotNull);
      List<Thread> threads = isolate.threads;

      for (Thread thread in threads) {
        expect(thread.type, equals('_Thread'));
        expect(thread.id, isNotNull);
        expect(thread.kind, isNotNull);
        expect(thread.zoneHighWatermark, isInt);
        expect(thread.zoneCapacity, isInt);
      }
    }
  },
];

main(args) async => runVMTests(args, tests);
