// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// See https://github.com/dart-lang/sdk/issues/52893

import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

var tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    var profile = await service.getAllocationProfile(isolateRef.id!);
    for (var entry in profile.members!) {
      if (entry.instancesCurrent == 0) continue;

      var classRef = entry.classRef!;
      print(classRef);
      var instanceSet =
          await service.getInstances(isolateRef.id!, classRef.id!, 10);
      for (var instance in instanceSet.instances!) {
        await service.getObject(isolateRef.id!, instance.id!);
      }
    }
  },
];

main(args) => runIsolateTests(
      args,
      tests,
      'fetch_all_types_test.dart',
    );
