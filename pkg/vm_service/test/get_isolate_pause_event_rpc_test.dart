// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

var tests = <VMTest>[
  (VmService service) async {
    final vm = await service.getVM();
    final result = await service.getIsolatePauseEvent(vm.isolates!.first.id!);
    expect(result.type, 'Event');
    expect(result.kind, isNotNull);
  },
  // Plausible isolate id, not found.
  (VmService service) async {
    try {
      await service.getIsolatePauseEvent('isolates/9999999999');
      fail('successfully got isolate with bad ID');
    } on SentinelException catch (e) {
      expect(e.sentinel.kind, 'Collected');
      expect(e.sentinel.valueAsString, '<collected>');
    }
  },
  // Verify that the returned event is the same as returned from getIsolate()
  (VmService service) async {
    final vm = await service.getVM();
    final result = await service.getIsolatePauseEvent(vm.isolates!.first.id!);
    final isolate = await service.getIsolate(vm.isolates!.first.id!);
    expect(result.toJson(), isolate.pauseEvent?.toJson());
  },
];

main(args) async => runVMTests(
      args,
      tests,
      'get_isolate_pause_event_rpc_test.dart',
    );
