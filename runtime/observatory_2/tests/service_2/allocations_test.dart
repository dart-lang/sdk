// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library allocations_test;

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

class Foo {}

// Prevent TFA from removing this static field to ensure the objects are kept
// alive, so the allocation stats will report them via the service api.
@pragma('vm:entry-point')
List<Foo> foos;

void script() {
  foos = [new Foo(), new Foo(), new Foo()];
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    var profile = await isolate.invokeRpcNoUpgrade('_getAllocationProfile', {});
    var classHeapStats = profile['members'].singleWhere((stats) {
      return stats['class']['name'] == 'Foo';
    });
    expect(classHeapStats['instancesCurrent'], equals(3));
    expect(classHeapStats['instancesAccumulated'], equals(3));
  },
];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
