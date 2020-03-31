// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

var tests = <VMTest>[
  (VmService vm) async {
    try {
      final res = await vm.getIsolate('isolates/12321');
      fail('Expected SentinelException, got $res');
    } on SentinelException {
      // Expected.
    } catch (e) {
      fail('Expected SentinelException, got $e');
    }
  },
];

main([args = const <String>[]]) async => await runVMTests(args, tests);
