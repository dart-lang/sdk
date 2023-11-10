// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--vm-name=Walter

import 'dart:async';

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';

final tests = <VMTest>[
  (VmService service) async {
    VM vm = await service.getVM();
    expect(vm.name, 'Walter');

    final completer = Completer<void>();
    late final StreamSubscription sub;
    sub = service.onVMEvent.listen((event) async {
      if (event.kind == EventKind.kVMUpdate) {
        expect(event.vm!.name, 'Barbara');
        sub.cancel();
        await service.streamCancel(EventStreams.kVM);
        completer.complete();
      }
    });
    await service.streamListen(EventStreams.kVM);

    await service.setVMName('Barbara');
    await completer.future;
    vm = await service.getVM();
    expect(vm.name, 'Barbara');
  },
];

void main([args = const <String>[]]) => runVMTests(
      args,
      tests,
      'set_vm_name_rpc_test.dart',
      extraArgs: [
        '--trace-service',
        '--trace-service-verbose',
      ],
    );
