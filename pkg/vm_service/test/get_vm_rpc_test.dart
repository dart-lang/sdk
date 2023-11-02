// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--vm-name=Walter

import 'dart:io';

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

final tests = <VMTest>[
  (VmService service) async {
    final vm = await service.getVM();
    expect(vm.name, equals('Walter'));
    expect(vm.architectureBits, isPositive);
    expect(vm.targetCPU, isA<String>());
    expect(vm.hostCPU, isA<String>());
    expect(vm.operatingSystem, Platform.operatingSystem);
    expect(vm.version, isA<String>());
    expect(vm.pid, isA<int>());
    expect(vm.startTime, isPositive);
    final isolates = vm.isolates!;
    expect(isolates.length, isPositive);
    expect(isolates[0].id, startsWith('isolates/'));
    expect(isolates[0].isolateGroupId, startsWith('isolateGroups/'));
    final isolateGroups = vm.isolateGroups!;
    expect(isolateGroups.length, isPositive);
    expect(isolateGroups[0].id, startsWith('isolateGroups/'));
  },
];

void main([args = const <String>[]]) => runVMTests(
      args,
      tests,
      'get_vm_rpc_test.dart',
    );
