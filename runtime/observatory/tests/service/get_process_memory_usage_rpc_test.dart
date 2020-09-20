// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

var tests = <VMTest>[
  (VM vm) async {
    var result = await vm.invokeRpcNoUpgrade("getProcessMemoryUsage", {});
    expect(result['type'], equals('ProcessMemoryUsage'));
    checkProcessMemoryItem(item) {
      expect(item['name'], isA<String>());
      expect(item['description'], isA<String>());
      expect(item['size'], isA<int>());
      expect(item['size'], greaterThanOrEqualTo(0));
      for (var child in item['children']) {
        checkProcessMemoryItem(child);
      }
    }

    checkProcessMemoryItem(result['root']);
  },
];

main(args) async => runVMTests(args, tests);
