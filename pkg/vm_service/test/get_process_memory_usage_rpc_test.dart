// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

final tests = <VMTest>[
  (VmService service) async {
    final result = await service.getProcessMemoryUsage();
    void checkProcessMemoryItem(ProcessMemoryItem item) {
      expect(item.name, isNotNull);
      expect(item.description, isNotNull);
      expect(item.size, greaterThanOrEqualTo(0));
      for (final child in item.children!) {
        checkProcessMemoryItem(child);
      }
    }

    checkProcessMemoryItem(result.root!);
  },
];

void main([args = const <String>[]]) => runVMTests(
      args,
      tests,
      'get_process_memory_usage_rpc_test.dart',
    );
