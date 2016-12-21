// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

import 'test_helper.dart';

var tests = [
  (VM vm) async {
    isInstanceOf<int> isInt = new isInstanceOf<int>();
    // Just iterate over all the isolates to confirm they have
    // the correct fields needed to examine zone memory usage.
    for (Isolate isolate in vm.isolates) {
      await isolate.reload();

      expect(isolate.threads, isNotNull);
      List<Thread> threads = isolate.threads;

      for (Thread thread in threads) {
        expect(thread.type, equals('_Thread'));
        expect(thread.id, isNotNull);
        expect(thread.kind, isNotNull);
        expect(thread.zones, isNotNull);
        List<Zone> zones = thread.zones;

        for (Zone zone in zones) {
          expect(zone.capacity, isInt);
          expect(zone.used, isInt);
        }
      }
    }
  },
];

main(args) async => runVMTests(args, tests);
