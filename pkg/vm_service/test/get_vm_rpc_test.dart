// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--vm-name=Walter

import 'dart:io';

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

extension on VM {
  String get embedder => json!['_embedder'];
  int get currentMemory => json!['_currentMemory'];
  int get currentRSS => json!['_currentRSS'];
  int get maxRSS => json!['_maxRSS'];
}

final tests = <VMTest>[
  (VmService service) async {
    final vm = await service.getVM();
    expect(vm.name, 'Walter');
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

    // Private properties.
    expect(vm.embedder, 'Dart VM');
    expect(vm.currentMemory, greaterThan(0));
    expect(vm.currentRSS, greaterThan(0));
    expect(vm.maxRSS, greaterThan(0));
    expect(vm.maxRSS, greaterThanOrEqualTo(vm.currentRSS));
  },
];

void main([args = const <String>[]]) => runVMTests(
      args,
      tests,
      'get_vm_rpc_test.dart',
    );
