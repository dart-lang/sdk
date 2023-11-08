// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// See https://github.com/dart-lang/sdk/issues/52893

import 'package:observatory/service_io.dart';
import 'test_helper.dart';

var tests = <IsolateTest>[
  (Isolate isolate) async {
    dynamic profile = await isolate.invokeRpc('getAllocationProfile', {});
    for (var entry in profile["members"]) {
      if (entry["instancesCurrent"] == 0) continue;

      Class cls = entry["class"];
      print(cls);
      dynamic rawInstanceSet = await isolate.invokeRpcNoUpgrade(
          'getInstances', {'objectId': cls.id, 'limit': 10});
      dynamic instanceSet = await isolate.getInstances(cls, 10);
      for (var instance in instanceSet.instances) {
        await instance.load();
      }
    }
  },
];

main(args) async => runIsolateTests(args, tests);
